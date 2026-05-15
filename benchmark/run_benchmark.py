#!/usr/bin/env python3
"""
Benchmark runner for L-DINF/DALI2 quantitative evaluation.

For each scenario:
  1. Starts DALI2 server with the scenario .pl file
  2. Waits for agents to be ready
  3. Injects schedule_ready events for all patients
  4. Injects disruptions (doctor unavailability)
  5. Injects probabilistic selection events for patients
  6. Triggers metrics computation in the logger
  7. Collects metrics from the logger's beliefs
  8. Stops the server

Usage:
    python run_benchmark.py --scenarios-dir scenarios --dali2-dir ../../DALI2 --runs 3
    python run_benchmark.py --scenarios-dir scenarios --dali2-dir ../../DALI2 --runs 3 --docker
"""

import argparse
import json
import os
import re
import subprocess
import sys
import time
import csv

try:
    import requests
except ImportError:
    print("ERROR: 'requests' package required. Install with: pip install requests")
    sys.exit(1)


BASE_URL = "http://localhost:{port}"
STARTUP_TIMEOUT = 60   # seconds to wait for server
SETTLE_DELAY = 3.0     # seconds between event phases
METRICS_DELAY = 5.0    # seconds to wait before collecting metrics


def check_redis():
    """Ensure Redis container is running. Start it if needed."""
    try:
        result = subprocess.run(
            ["docker", "exec", "ldinf-redis", "redis-cli", "PING"],
            capture_output=True, text=True, timeout=5
        )
        if "PONG" in result.stdout:
            return True
    except Exception:
        pass
    # Try to start it
    print("  Redis not running, starting container...")
    try:
        subprocess.run(["docker", "start", "ldinf-redis"],
                        capture_output=True, timeout=10)
        time.sleep(2)
        result = subprocess.run(
            ["docker", "exec", "ldinf-redis", "redis-cli", "PING"],
            capture_output=True, text=True, timeout=5
        )
        return "PONG" in result.stdout
    except Exception:
        return False


def flush_redis():
    """Flush Redis to ensure clean state between runs."""
    if not check_redis():
        print("  ERROR: Redis is not available!")
        return False
    try:
        result = subprocess.run(
            ["docker", "exec", "ldinf-redis", "redis-cli", "FLUSHALL"],
            capture_output=True, text=True, timeout=5
        )
        return result.returncode == 0
    except Exception:
        return False


def kill_orphan_swipl():
    """Kill any leftover swipl processes."""
    try:
        if sys.platform == "win32":
            subprocess.run(["taskkill", "/F", "/IM", "swipl.exe"],
                           capture_output=True, timeout=5)
        else:
            subprocess.run(["pkill", "-f", "swipl"],
                           capture_output=True, timeout=5)
        time.sleep(3)  # Wait longer for ports/handles to be released on Windows
    except Exception:
        pass


def wait_for_server(port, timeout=STARTUP_TIMEOUT):
    """Wait until the DALI2 server responds."""
    url = f"{BASE_URL.format(port=port)}/api/agents"
    start = time.time()
    while time.time() - start < timeout:
        try:
            r = requests.get(url, timeout=2)
            if r.status_code == 200:
                return True
        except requests.ConnectionError:
            pass
        time.sleep(0.5)
    return False


def send_event(port, to, content, timeout=20, retries=3):
    """Send an event to an agent via the DALI2 HTTP API, with retries."""
    url = f"{BASE_URL.format(port=port)}/api/send"
    payload = {"to": to, "content": content}
    for attempt in range(retries):
        try:
            r = requests.post(url, json=payload, timeout=timeout)
            if r.status_code == 200:
                return True
        except requests.RequestException as e:
            if attempt < retries - 1:
                wait = 2 ** attempt
                print(f"  RETRY ({attempt+1}/{retries}): {to} <- {content} (wait {wait}s)")
                time.sleep(wait)
            else:
                print(f"  WARN: Failed to send {content} to {to} after {retries} attempts: {e}")
    return False


def get_beliefs(port, agent):
    """Get beliefs of an agent."""
    url = f"{BASE_URL.format(port=port)}/api/beliefs?agent={agent}"
    try:
        r = requests.get(url, timeout=5)
        if r.status_code == 200:
            return r.json() if r.headers.get("content-type", "").startswith("application/json") else r.text
    except requests.RequestException:
        pass
    return None


def get_logs(port):
    """Get all logs from the server."""
    url = f"{BASE_URL.format(port=port)}/api/logs"
    try:
        r = requests.get(url, timeout=5)
        if r.status_code == 200:
            return r.text
    except requests.RequestException:
        pass
    return ""


def extract_metrics_from_logs(logs_text):
    """Parse METRICS lines from log output."""
    metrics = {}

    # Look for METRICS lines
    for line in logs_text.split("\n"):
        if "METRICS:" not in line:
            continue

        # Parse key=value pairs
        pairs = re.findall(r'(\w+)=([\d.]+)', line)
        for key, val in pairs:
            try:
                metrics[key] = float(val)
            except ValueError:
                metrics[key] = val

    return metrics


def extract_metrics_from_beliefs(beliefs_data):
    """Extract metrics_summary from logger beliefs."""
    if isinstance(beliefs_data, str):
        # Parse metrics_summary(...) from text
        match = re.search(
            r'metrics_summary\((\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+)\)',
            beliefs_data
        )
        if match:
            return {
                "total_events": int(match.group(1)),
                "disruptions": int(match.group(2)),
                "repairs": int(match.group(3)),
                "lendings": int(match.group(4)),
                "selections": int(match.group(5)),
                "repair_ms": float(match.group(6)),
                "lending_pct": float(match.group(7)),
                "selector_ms": float(match.group(8)),
            }
    elif isinstance(beliefs_data, (list, dict)):
        # JSON format — search for metrics_summary
        text = json.dumps(beliefs_data)
        return extract_metrics_from_beliefs(text)

    return {}


def run_single_scenario(scenario_name, pl_path, plan_path, dali2_dir, port, run_id):
    """Run a single scenario and return metrics."""
    print(f"\n{'='*60}")
    print(f"Running: {scenario_name} (run {run_id})")
    print(f"{'='*60}")

    with open(plan_path) as f:
        plan = json.load(f)

    # Resolve paths
    pl_abs = os.path.abspath(pl_path)
    dali2_abs = os.path.abspath(dali2_dir)
    server_pl = os.path.join(dali2_abs, "src", "server.pl")

    # Clean state before starting
    kill_orphan_swipl()
    flush_redis()
    time.sleep(1)

    # Start DALI2 server
    cmd = [
        "swipl", "-l", server_pl, "-g", "main", "--",
        str(port), pl_abs
    ]
    print(f"  Starting server: {' '.join(cmd)}")
    # IMPORTANT: Use a log file, not PIPE. If we pipe stdout and never read it,
    # the buffer fills up and the server process deadlocks on write.
    log_dir = os.path.join(os.path.dirname(pl_abs), "logs")
    os.makedirs(log_dir, exist_ok=True)
    log_file = os.path.join(log_dir, f"{scenario_name}_run{run_id}.log")
    log_fh = open(log_file, "w")
    proc = subprocess.Popen(
        cmd,
        stdout=log_fh,
        stderr=log_fh,
        cwd=dali2_abs
    )

    try:
        # Wait for server
        print(f"  Waiting for server on port {port}...")
        if not wait_for_server(port):
            print(f"  ERROR: Server did not start in {STARTUP_TIMEOUT}s")
            return None

        print(f"  Server ready. Agents: {plan['agents']}")
        time.sleep(1.0)

        # Scale inter-event delay with number of agents
        n_agents = plan["agents"]
        event_gap = 0.3 if n_agents <= 20 else 0.8

        # Phase 1: schedule_ready for all patients
        print(f"  Phase 1: Loading schedules for {len(plan['schedule_ready_patients'])} patients")
        for pat in plan["schedule_ready_patients"]:
            send_event(port, pat, "schedule_ready")
            time.sleep(event_gap)

        time.sleep(SETTLE_DELAY)

        # Phase 2: Inject disruptions
        print(f"  Phase 2: Injecting {len(plan['disruptions'])} disruptions")
        t_disruption_start = time.time()
        for disr in plan["disruptions"]:
            send_event(port, disr["doctor"], f"become_unavailable({disr['timeslot']})")
            time.sleep(max(1.0, event_gap * 2))

        # Scale settle time: each disruption triggers multi-hop repair chain
        repair_settle = max(SETTLE_DELAY * 3, len(plan['disruptions']) * 4)
        print(f"  Waiting {repair_settle:.0f}s for repair chains...")
        time.sleep(repair_settle)

        # Phase 3: Probabilistic selection for all patients
        print(f"  Phase 3: Triggering {len(plan['patient_selections'])} probabilistic selections")
        for sel in plan["patient_selections"]:
            send_event(port, sel["patient"], f"select_action({sel['timeslot']})")
            time.sleep(event_gap)

        time.sleep(SETTLE_DELAY)
        t_all_done = time.time()

        # Phase 4: Trigger metrics computation
        print(f"  Phase 4: Computing metrics")
        send_event(port, "logger", "compute_metrics")
        time.sleep(METRICS_DELAY)

        # Phase 5: Collect results
        print(f"  Phase 5: Collecting results")
        logs = get_logs(port)
        beliefs = get_beliefs(port, "logger")

        # Extract metrics
        metrics_from_logs = extract_metrics_from_logs(logs)
        metrics_from_beliefs = extract_metrics_from_beliefs(beliefs) if beliefs else {}

        # Merge — prefer beliefs-based metrics
        metrics = {**metrics_from_logs, **metrics_from_beliefs}

        # Add wall-clock total time
        metrics["wall_clock_ms"] = (t_all_done - t_disruption_start) * 1000
        metrics["scenario"] = scenario_name
        metrics["run_id"] = run_id
        metrics["agents"] = plan["agents"]
        metrics["config_disruptions"] = plan["num_disruptions"]
        metrics["config_patients"] = plan["patients"]
        metrics["config_clinics"] = plan["clinics"]
        metrics["config_docs_per_clinic"] = plan["doctors_per_clinic"]
        metrics["config_equiv_actions"] = plan["num_equiv_actions"]

        print(f"  Results: {json.dumps(metrics, indent=2)}")
        return metrics

    finally:
        # Stop server
        print(f"  Stopping server...")
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
        log_fh.close()


def aggregate_results(all_results):
    """Aggregate results across runs for each scenario."""
    from collections import defaultdict

    by_scenario = defaultdict(list)
    for r in all_results:
        if r:
            by_scenario[r["scenario"]].append(r)

    aggregated = []
    for scenario, runs in sorted(by_scenario.items()):
        agg = {
            "scenario": scenario,
            "agents": runs[0]["agents"],
            "clinics": runs[0]["config_clinics"],
            "docs_per_clinic": runs[0]["config_docs_per_clinic"],
            "patients": runs[0]["config_patients"],
            "disruptions_cfg": runs[0]["config_disruptions"],
            "equiv_actions": runs[0]["config_equiv_actions"],
            "runs": len(runs),
        }

        # Average numeric metrics
        numeric_keys = [
            "disruptions", "repairs", "lendings", "selections",
            "repair_ms", "lending_pct", "selector_ms",
            "total_events", "wall_clock_ms"
        ]
        for key in numeric_keys:
            vals = [r.get(key, 0) for r in runs if key in r]
            if vals:
                agg[f"avg_{key}"] = round(sum(vals) / len(vals), 2)
            else:
                agg[f"avg_{key}"] = 0

        aggregated.append(agg)

    return aggregated


def print_latex_table(aggregated):
    """Print a LaTeX-formatted table of results."""
    print("\n" + "=" * 70)
    print("LaTeX Table")
    print("=" * 70)
    print(r"\begin{table}[H]")
    print(r"\caption{Quantitative evaluation across scenario configurations.}")
    print(r"\label{tab:eval}")
    print(r"\centering")
    print(r"\small")
    print(r"\begin{tabular}{@{}lrrrrrrr@{}}")
    print(r"\toprule")
    print(r"\textbf{Config} & \textbf{Agents} & \textbf{Disrupt.} & "
          r"\textbf{Repairs} & \textbf{Lendings} & "
          r"\textbf{Repair (ms)} & \textbf{Lend. \%} & "
          r"\textbf{Sel. (ms)} \\")
    print(r"\midrule")
    for a in aggregated:
        print(f"{a['scenario']} & {a['agents']} & "
              f"{a['disruptions_cfg']} & "
              f"{a.get('avg_repairs', 0):.0f} & "
              f"{a.get('avg_lendings', 0):.0f} & "
              f"{a.get('avg_repair_ms', 0):.1f} & "
              f"{a.get('avg_lending_pct', 0):.0f} & "
              f"{a.get('avg_selector_ms', 0):.1f} \\\\")
    print(r"\bottomrule")
    print(r"\end{tabular}")
    print(r"\end{table}")


def main():
    parser = argparse.ArgumentParser(description="L-DINF/DALI2 Benchmark Runner")
    parser.add_argument("--scenarios-dir", type=str, default="scenarios",
                        help="Directory containing .pl and _plan.json files")
    parser.add_argument("--dali2-dir", type=str, default="../../DALI2",
                        help="Path to DALI2 repository")
    parser.add_argument("--port", type=int, default=8080)
    parser.add_argument("--runs", type=int, default=3,
                        help="Number of runs per scenario")
    parser.add_argument("--output", type=str, default="results.json",
                        help="Output file for raw results")
    parser.add_argument("--output-csv", type=str, default="results.csv",
                        help="Output CSV file for aggregated results")
    args = parser.parse_args()

    # Find scenarios
    scenarios = []
    for f in sorted(os.listdir(args.scenarios_dir)):
        if f.endswith("_plan.json"):
            name = f.replace("_plan.json", "")
            pl_path = os.path.join(args.scenarios_dir, f"{name}.pl")
            plan_path = os.path.join(args.scenarios_dir, f)
            if os.path.exists(pl_path):
                scenarios.append((name, pl_path, plan_path))

    if not scenarios:
        print(f"No scenarios found in {args.scenarios_dir}/")
        print("Run generate_scenario.py --use-defaults --outdir scenarios first.")
        sys.exit(1)

    print(f"Found {len(scenarios)} scenarios: {[s[0] for s in scenarios]}")
    print(f"Runs per scenario: {args.runs}")
    print(f"DALI2 directory: {os.path.abspath(args.dali2_dir)}")

    all_results = []
    for name, pl_path, plan_path in scenarios:
        for run_id in range(1, args.runs + 1):
            result = run_single_scenario(
                name, pl_path, plan_path,
                args.dali2_dir, args.port, run_id
            )
            all_results.append(result)
            time.sleep(1.0)  # cool-down between runs

    # Save raw results
    with open(args.output, "w") as f:
        json.dump([r for r in all_results if r], f, indent=2)
    print(f"\nRaw results saved to {args.output}")

    # Aggregate and display
    aggregated = aggregate_results(all_results)

    # Save aggregated CSV
    if aggregated:
        keys = list(aggregated[0].keys())
        with open(args.output_csv, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=keys)
            writer.writeheader()
            writer.writerows(aggregated)
        print(f"Aggregated results saved to {args.output_csv}")

    # Print summary
    print("\n" + "=" * 70)
    print("SUMMARY")
    print("=" * 70)
    for a in aggregated:
        print(f"  {a['scenario']}: {a['agents']} agents, "
              f"{a['disruptions_cfg']} disruptions, "
              f"repair={a.get('avg_repair_ms', 0):.1f}ms, "
              f"lending={a.get('avg_lending_pct', 0):.0f}%, "
              f"selector={a.get('avg_selector_ms', 0):.1f}ms")

    # Print LaTeX table
    print_latex_table(aggregated)


if __name__ == "__main__":
    main()

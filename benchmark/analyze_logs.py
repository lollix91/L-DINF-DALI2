#!/usr/bin/env python3
"""Post-process DALI2 benchmark log files to extract accurate metrics.

Parses TRACE lines from server log files to count unique events,
compute repair latencies, and selector overhead.
"""

import re
import os
import json
import sys
import csv
from collections import defaultdict
from pathlib import Path


TRACE_RE = re.compile(
    r'TRACE \[(\w+)\] (\w+): (.+?) @([\d.]+)'
)

METRICS_RE = re.compile(
    r'METRICS: (.+)'
)


def build_agent_whitelist(plan):
    """Build set of agent names that exist in this scenario."""
    agents = set()
    agents.add('logger')
    agents.add('mediator')
    n_clinics = plan.get('clinics', 0)
    n_docs = plan.get('doctors_per_clinic', 0)
    n_patients = plan.get('patients', 0)
    
    clinic_letters = [chr(ord('a') + i) for i in range(n_clinics)]
    for letter in clinic_letters:
        agents.add(f'clinic_{letter}_mgr')
        for j in range(1, n_docs + 1):
            agents.add(f'doc_{letter}_{j}')
    for i in range(1, n_patients + 1):
        agents.add(f'patient_{i}')
    return agents


def parse_trace_lines(log_path, agent_whitelist=None):
    """Parse all TRACE lines from a log file, returning unique events.
    
    If agent_whitelist is provided, only include events from those agents.
    """
    events = []
    seen = set()
    
    with open(log_path, 'r', encoding='utf-8', errors='replace') as f:
        for line in f:
            m = TRACE_RE.search(line)
            if m:
                etype = m.group(1)
                source = m.group(2)
                data = m.group(3)
                ts = float(m.group(4))
                # Skip events from agents not in this scenario
                if agent_whitelist and source not in agent_whitelist:
                    continue
                # Also filter data: skip if it references agents not in whitelist
                # (e.g., disruption for a doctor not in this scenario)
                if agent_whitelist and etype in ('disruption', 'unavailability', 'group_update'):
                    # Check if any referenced agent in data is outside whitelist
                    refs = re.findall(r'(doc_\w+|patient_\d+|clinic_\w+_mgr|mediator|logger)', data)
                    if refs and not any(r in agent_whitelist for r in refs):
                        continue
                # Deduplicate by (type, source, data)
                key = (etype, source, data)
                if key not in seen:
                    seen.add(key)
                    events.append({
                        'type': etype,
                        'source': source,
                        'data': data,
                        'timestamp': ts
                    })
    return events


def parse_metrics_lines(log_path):
    """Parse METRICS: key=value lines from a log file."""
    metrics = {}
    with open(log_path, 'r', encoding='utf-8', errors='replace') as f:
        for line in f:
            if 'METRICS:' not in line:
                continue
            pairs = re.findall(r'(\w+)=([\d.]+)', line)
            for key, val in pairs:
                try:
                    metrics[key] = float(val)
                except ValueError:
                    metrics[key] = val
            break  # Only take the FIRST METRICS line
    return metrics


def compute_metrics(events):
    """Compute metrics from deduplicated TRACE events."""
    total_events = len(events)
    
    disruptions = [e for e in events if e['type'] == 'disruption']
    repairs_done = [e for e in events if e['type'] == 'consultation_done']
    lendings = [e for e in events if e['type'] == 'lending_approved']
    delegations = [e for e in events if e['type'] == 'delegation_complete']
    selector_starts = [e for e in events if e['type'] == 'selector_start']
    prob_selections = [e for e in events if e['type'] == 'prob_selection']
    decisions = [e for e in events if e['type'] == 'decision']
    
    # Decisions breakdown
    allows = [e for e in decisions if 'allow' in e['data']]
    delegates = [e for e in decisions if 'delegate' in e['data']]
    blocks = [e for e in decisions if 'block' in e['data']]
    
    # Repair latency: time from first disruption to last consultation_done (or delegation_complete)
    repair_endpoints = repairs_done + delegations
    if disruptions and repair_endpoints:
        t_first_disruption = min(e['timestamp'] for e in disruptions)
        t_last_repair = max(e['timestamp'] for e in repair_endpoints)
        repair_ms = (t_last_repair - t_first_disruption) * 1000
    elif disruptions and decisions:
        t_first_disruption = min(e['timestamp'] for e in disruptions)
        t_last_decision = max(e['timestamp'] for e in decisions)
        repair_ms = (t_last_decision - t_first_disruption) * 1000
    else:
        repair_ms = 0
    
    # Selector overhead: average time from selector_start to prob_selection per patient
    selector_times = []
    for start in selector_starts:
        # Find matching prob_selection for same source
        for end in prob_selections:
            if end['source'] == start['source']:
                selector_times.append((end['timestamp'] - start['timestamp']) * 1000)
                break
    avg_selector_ms = sum(selector_times) / len(selector_times) if selector_times else 0
    
    # Lending percentage
    n_disr = len(disruptions)
    n_lend = len(lendings)
    lending_pct = (n_lend / n_disr * 100) if n_disr > 0 else 0
    
    return {
        'total_events': total_events,
        'disruptions': len(disruptions),
        'decisions': len(decisions),
        'allows': len(allows),
        'delegates': len(delegates),
        'blocks': len(blocks),
        'repairs_done': len(repairs_done),
        'lendings': len(lendings),
        'delegations': len(delegations),
        'selections': len(prob_selections),
        'repair_ms': round(repair_ms, 2),
        'lending_pct': round(lending_pct, 1),
        'avg_selector_ms': round(avg_selector_ms, 3),
    }


def main():
    logs_dir = sys.argv[1] if len(sys.argv) > 1 else 'benchmark/scenarios/logs'
    plans_dir = sys.argv[2] if len(sys.argv) > 2 else 'benchmark/scenarios'
    output_csv = sys.argv[3] if len(sys.argv) > 3 else 'benchmark/metrics_from_logs.csv'
    
    log_files = sorted(Path(logs_dir).glob('*.log'))
    if not log_files:
        print(f"No log files found in {logs_dir}")
        return
    
    all_results = []
    by_scenario = defaultdict(list)
    
    for log_file in log_files:
        # Parse scenario name and run id from filename: S1_small_run1.log
        stem = log_file.stem  # e.g., S1_small_run1
        parts = stem.rsplit('_run', 1)
        if len(parts) != 2:
            continue
        scenario_name = parts[0]
        run_id = int(parts[1])
        
        # Load plan
        plan_path = Path(plans_dir) / f"{scenario_name}_plan.json"
        if plan_path.exists():
            with open(plan_path) as f:
                plan = json.load(f)
        else:
            plan = {}
        
        # Build agent whitelist from plan
        whitelist = build_agent_whitelist(plan) if plan else None
        
        # Parse and compute
        events = parse_trace_lines(str(log_file), whitelist)
        metrics = compute_metrics(events)
        
        # Also get the in-agent METRICS (first occurrence only)
        agent_metrics = parse_metrics_lines(str(log_file))
        
        result = {
            'scenario': scenario_name,
            'run_id': run_id,
            'agents': plan.get('agents', 0),
            'config_disruptions': plan.get('num_disruptions', 0),
            'config_patients': plan.get('patients', 0),
            'config_clinics': plan.get('clinics', 0),
            'config_docs_per_clinic': plan.get('doctors_per_clinic', 0),
            **metrics,
            'agent_repair_ms': agent_metrics.get('repair_ms', ''),
            'agent_selector_ms': agent_metrics.get('selector_ms', ''),
        }
        
        all_results.append(result)
        by_scenario[scenario_name].append(result)
        
        print(f"{stem}: events={metrics['total_events']} disr={metrics['disruptions']} "
              f"decisions={metrics['decisions']}(A{metrics['allows']}/D{metrics['delegates']}/B{metrics['blocks']}) "
              f"lend={metrics['lendings']} repair={metrics['repair_ms']:.0f}ms sel={metrics['avg_selector_ms']:.1f}ms")
    
    # Aggregate per scenario
    print(f"\n{'='*80}")
    print("AGGREGATED (mean over runs)")
    print(f"{'='*80}")
    
    agg_rows = []
    for scenario in sorted(by_scenario.keys()):
        runs = by_scenario[scenario]
        n = len(runs)
        
        def avg(key):
            vals = [r[key] for r in runs if isinstance(r.get(key), (int, float))]
            return round(sum(vals) / len(vals), 2) if vals else 0
        
        agg = {
            'scenario': scenario,
            'agents': runs[0]['agents'],
            'clinics': runs[0]['config_clinics'],
            'docs_per_clinic': runs[0]['config_docs_per_clinic'],
            'patients': runs[0]['config_patients'],
            'disruptions_cfg': runs[0]['config_disruptions'],
            'runs': n,
            'avg_events': avg('total_events'),
            'avg_disruptions': avg('disruptions'),
            'avg_decisions': avg('decisions'),
            'avg_allows': avg('allows'),
            'avg_delegates': avg('delegates'),
            'avg_blocks': avg('blocks'),
            'avg_lendings': avg('lendings'),
            'avg_repairs_done': avg('repairs_done'),
            'avg_repair_ms': avg('repair_ms'),
            'avg_lending_pct': avg('lending_pct'),
            'avg_selector_ms': avg('avg_selector_ms'),
        }
        agg_rows.append(agg)
        
        print(f"  {scenario}: {agg['agents']} agents, {agg['disruptions_cfg']} disr cfg")
        print(f"    events={agg['avg_events']:.0f} disr_observed={agg['avg_disruptions']:.1f} "
              f"decisions={agg['avg_decisions']:.1f} (A{agg['avg_allows']:.1f}/D{agg['avg_delegates']:.1f}/B{agg['avg_blocks']:.1f})")
        print(f"    lendings={agg['avg_lendings']:.1f} repair={agg['avg_repair_ms']:.0f}ms "
              f"selector={agg['avg_selector_ms']:.1f}ms")
    
    # Write CSV
    if agg_rows:
        with open(output_csv, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=agg_rows[0].keys())
            writer.writeheader()
            writer.writerows(agg_rows)
        print(f"\nAggregated CSV: {output_csv}")
    
    # Write per-run CSV
    per_run_csv = output_csv.replace('.csv', '_per_run.csv')
    if all_results:
        with open(per_run_csv, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=all_results[0].keys())
            writer.writeheader()
            writer.writerows(all_results)
        print(f"Per-run CSV: {per_run_csv}")
    
    # Generate LaTeX table
    print(f"\n{'='*80}")
    print("LaTeX Table")
    print(f"{'='*80}")
    print(r"\begin{table}[t]")
    print(r"\caption{Quantitative evaluation of L-DINF/DALI2 adaptation.}")
    print(r"\label{tab:eval}")
    print(r"\centering\small")
    print(r"\begin{tabular}{@{}lrrrrrrrr@{}}")
    print(r"\toprule")
    print(r"\textbf{Scenario} & \textbf{Agents} & \textbf{Disr.} & "
          r"\textbf{Dec.} & \textbf{A/D/B} & \textbf{Lend.} & "
          r"\textbf{Repair (ms)} & \textbf{Lend.\%} & \textbf{Sel. (ms)} \\")
    print(r"\midrule")
    for a in agg_rows:
        adb = f"{a['avg_allows']:.0f}/{a['avg_delegates']:.0f}/{a['avg_blocks']:.0f}"
        print(f"{a['scenario']} & {a['agents']} & {a['disruptions_cfg']} & "
              f"{a['avg_decisions']:.0f} & {adb} & {a['avg_lendings']:.0f} & "
              f"{a['avg_repair_ms']:.0f} & {a['avg_lending_pct']:.0f} & "
              f"{a['avg_selector_ms']:.1f} \\\\")
    print(r"\bottomrule")
    print(r"\end{tabular}")
    print(r"\end{table}")


if __name__ == '__main__':
    main()

# L-DINF in DALI2: Epistemic Logic for Adaptive Multi-Agent Scheduling

> An executable implementation of L-DINF constructs in the DALI2 multi-agent framework, applied to a healthcare scheduling case study with trust-aware delegation and probabilistic action selection.

## Overview

This repository implements the L-DINF epistemic logic constructs as DALI2 agent code, demonstrating:

- **Belief management** (`B_i`) — agents maintain and update dynamic beliefs
- **Intentions** (`intend_i`) — baseline schedule atoms imported as intentions
- **Feasibility checking** (`can_do_i`, `can_do_G`) — guarded rules check compiled preconditions
- **Preference-guided repair** (`pref_do_i`) — ranked selection among feasible alternatives
- **Trust-aware decisions** (`trust_K(i, τ)`) — three-valued policy: allow / delegate / block
- **Inter-group delegation** (`lend_G(i, H, φ_A)`) — mediated lending protocol
- **Probabilistic action selection** (`F^prob_π`) — score-based selection combining probability, preference, cost
- **Explanation traces** — full log of belief updates, decisions, and delegations

## Prerequisites

- **DALI2** must be available at `../DALI2` (relative path)
- **Redis** must be running (see [DALI2 prerequisites](../DALI2/README.md#prerequisites))

## Quick Start

### With Docker (recommended)

```bash
docker compose up --build
```

### Without Docker

```bash
# Step 1: Start Redis
redis-server
# Or via Docker:
docker run -d --name dali2-redis -p 6379:6379 redis:7-alpine

# Step 2: Start the system
swipl -l ../DALI2/src/server.pl -g main -- 8080 examples/healthcare_ldinf.pl
```

Open **http://localhost:8080** for the web UI.

## Scenario

Two clinics (`clinic_a`, `clinic_b`) with doctors and patients. A baseline ASP schedule assigns patients to doctors. The scenario demonstrates runtime adaptation when disruptions occur.

### Agents

| Agent | Group | Role | L-DINF Constructs |
|-------|-------|------|-------------------|
| `alice` | clinic_a | Patient | `B_i`, `intend_i`, `+φ`, trust-aware decision |
| `bob` | clinic_a | Patient | `B_i`, `F^prob_π` (probabilistic selector) |
| `doc_jones` | clinic_a | Doctor | `can_do_i`, `do_i` — becomes unavailable |
| `doc_smith` | clinic_b | Doctor | `can_do_i`, lending participation |
| `doc_lee` | clinic_a | Doctor | `can_do_i` — local alternative |
| `clinic_a_mgr` | clinic_a | Manager | `can_do_G`, preference ranking |
| `clinic_b_mgr` | clinic_b | Manager | Lending authorization |
| `mediator` | — | Mediator | `lend_G(i, H, φ_A)` protocol |
| `logger` | — | Logger | Explanation trace |

### Test Commands

After starting the system, use the Web UI or curl commands:

#### Step 1: Load baseline schedule

```powershell
curl.exe -X POST http://localhost:8080/api/send -H "Content-Type: application/json" -d "{""to"":""alice"",""content"":""schedule_ready""}"
```

**Expected:** Alice loads her baseline schedule (doc_jones at t1).

#### Step 2: Trigger disruption (doctor unavailable)

```powershell
curl.exe -X POST http://localhost:8080/api/send -H "Content-Type: application/json" -d "{""to"":""doc_jones"",""content"":""become_unavailable(t1)""}"
```

**Expected flow:**
1. `doc_jones` becomes unavailable, notifies `clinic_a_mgr`
2. `clinic_a_mgr` notifies patients (`alice`, `bob`), checks local candidates
3. `clinic_a_mgr` finds `doc_lee` (trust=medium, pref=5) — offers local repair to `alice`
4. `alice` evaluates trust: `doc_lee` has medium trust, autonomy threshold is high → **decision = DELEGATE**
5. `alice` asks `mediator` for inter-group lending
6. `mediator` asks `clinic_b_mgr` for available doctors
7. `clinic_b_mgr` offers `doc_smith` (trust=high)
8. `mediator` checks lending threshold (high ≥ high) → **LENDING APPROVED**
9. `doc_smith` accepts lending, temporarily joins `clinic_a`
10. `doc_smith` performs consultation for `alice`
11. `alice` records `do^P(consultation_with(doc_smith, t1))`

#### Step 3: Probabilistic action selection for Bob

```powershell
curl.exe -X POST http://localhost:8080/api/send -H "Content-Type: application/json" -d "{""to"":""bob"",""content"":""select_action(t2)""}"
```

**Expected:** Bob evaluates three equivalent actions using `F^prob_π`:
- `visit_standard`: score = 100×0.90 + 10×(8/10) − 20×(5/12) = **89.67**
- `visit_home`: score = 100×0.85 + 10×(7/10) − 20×(8/12) = **78.67**
- `visit_telemedicine`: score = 100×0.75 + 10×(6/10) − 20×(2/12) = **77.67**

**Selected:** `visit_standard` (highest score).

#### Step 4: Check state

```powershell
curl.exe http://localhost:8080/api/beliefs?agent=alice
curl.exe http://localhost:8080/api/beliefs?agent=mediator
curl.exe http://localhost:8080/api/beliefs?agent=bob
curl.exe http://localhost:8080/api/logs
```

### Verified Execution Trace

The following trace was produced by the logger agent during a complete test run:

```
TRACE [schedule_loaded]     alice:          [consultation,t1,doc_jones]
TRACE [unavailability]      doc_jones:      [t1]
TRACE [group_update]        clinic_a_mgr:   [unavailable,doc_jones,t1]
TRACE [disruption]          alice:          [unavailable,doc_jones,t1]
TRACE [disruption]          bob:            [unavailable,doc_jones,t1]
TRACE [decision]            alice:          [delegate,doc_lee,t1]
TRACE [lending_request]     mediator:       [alice,clinic_a,consultation,t1]
TRACE [lending_approved]    mediator:       [doc_smith,clinic_b,clinic_a,t1]
TRACE [lending_accepted]    doc_smith:      [clinic_a,consultation,t1]
TRACE [lending_executed]    mediator:       [doc_smith,clinic_a,t1]
TRACE [consultation]        doc_smith:      [alice,t1]
TRACE [delegation_complete] alice:          [doc_smith,t1]
TRACE [consultation_done]   alice:          [doc_smith,t1]
TRACE [prob_selection]      bob:            [visit_standard,89.67,t2]
```

Each trace entry corresponds to a formal L-DINF transition, providing a transparent account of the adaptation chain.

## L-DINF to DALI2 Mapping

| L-DINF Construct | DALI2 Implementation |
|------------------|----------------------|
| `B_i(belief)` | `believes(fact).` / `assert_belief` / `retract_belief` |
| `intend_i(φ_A)` | `believes(intend(action)).` |
| `can_do_i(φ_A)` | Guarded rule checking `believes(can_do(...))` and constraints |
| `can_do_G(φ_A)` | Manager agent `findall` over group members |
| `pref_do_i(φ_A, d)` | `believes(pref_do(action, degree)).` — sorted selection |
| `do_i(φ_A)` | Action execution + `assert_belief(done(...))` |
| `do^P_i(φ_A)` | Past event in DALI2 memory |
| `+φ` (belief update) | `assert_belief(...)` in reactive rule body |
| `−φ` (belief removal) | `retract_belief(...)` in reactive rule body |
| `trust_K(i, τ)` | `believes(trust_val(level, num)).` — numeric ordering |
| `decision(allow/delegate/block)` | Arithmetic comparison (`>=`, `>`) in reactive rule |
| `lend_G(i, H, φ_A)` | Mediated message protocol via `mediator` agent |
| `F^prob_π` selector | Score computation with `findall` + `sort` |
| Explanation trace | `logger` agent recording all events |

## File Structure

```
LDINF-DALI2/
├── README.md                          # This file
├── L-DINF.md                          # Complete L-DINF rule reference
├── docker-compose.yml                 # Docker configuration
├── examples/
│   └── healthcare_ldinf.pl            # Main agent file
```

## References

- Costantini, S., Formisano, A., Pitoni, V. (2023). *An epistemic logic for formalizing group dynamics of agents.* Interaction Studies 23, 391–426.
- Costantini, S., Pitoni, V. (2026). *A Trust Extension of L-DINF.* CILC 2026.
- Costantini, S., Pitoni, V. (2026). *A Probabilistic Package for L-DINF.* LAMAS 2026.
- Costantini, S., Pitoni, V., Formisano, A., De Lauretis, L. (2026). *From Constraints to Cognition: A Hybrid Framework.* NMR 2026.
- DALI2: [github.com/AAAI-DISIM-UnivAQ/DALI2](https://github.com/AAAI-DISIM-UnivAQ/DALI2)

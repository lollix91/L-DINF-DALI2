#!/usr/bin/env python3
"""
Scenario generator for L-DINF/DALI2 quantitative evaluation.

Generates parameterized .pl files with configurable numbers of:
  - clinics
  - doctors per clinic
  - patients (each assigned to a random doctor)
  - equivalent actions per patient (for probabilistic selector)
  - disruptions (doctors becoming unavailable)

Usage:
    python generate_scenario.py --config configs.json --outdir ../examples/bench
    python generate_scenario.py --clinics 3 --docs-per-clinic 4 --patients 8 --disruptions 3 --equiv-actions 4 --outdir ../examples/bench
"""

import argparse
import json
import math
import os
import random
import string

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

TRUST_LEVELS = ["very_low", "low", "medium", "high", "very_high"]
TRUST_NUMS   = {l: i + 1 for i, l in enumerate(TRUST_LEVELS)}

def _rand_trust(min_level="low"):
    """Return a random trust level >= min_level."""
    idx = TRUST_LEVELS.index(min_level)
    return random.choice(TRUST_LEVELS[idx:])

def _rand_prob():
    return round(random.uniform(0.55, 0.98), 2)

def _rand_pref(max_val=10):
    return random.randint(2, max_val)

def _rand_cost(max_val=8):
    return random.randint(1, max_val)

# ---------------------------------------------------------------------------
# Agent generators
# ---------------------------------------------------------------------------

def gen_patient(name, clinic, assigned_doc, timeslot, doctors_in_all_clinics,
                equiv_actions, trust_thresholds):
    """Generate a patient agent block."""
    lines = []
    lines.append(f":- agent({name}, [cycle(2)]).")
    lines.append("")
    lines.append(f"believes(needs_consultation({timeslot})).")
    lines.append(f"believes(member_of({clinic})).")
    lines.append(f"believes(intend(consultation({timeslot}))).")
    lines.append(f"believes(assigned_doctor({assigned_doc})).")
    lines.append(f"believes(assigned_clinic({clinic})).")
    lines.append("")

    # Trust for every doctor the patient might interact with
    for doc, doc_clinic, trust in doctors_in_all_clinics:
        lines.append(f"believes(trust({doc}, {trust})).")

    lines.append("")

    # Preference degrees
    for doc, doc_clinic, trust in doctors_in_all_clinics:
        pref = _rand_pref()
        lines.append(f"believes(pref_do(visit({doc}), {pref})).")

    lines.append("")

    # Success probabilities
    for doc, doc_clinic, trust in doctors_in_all_clinics:
        prob = _rand_prob()
        lines.append(f"believes(success_prob(visit({doc}), {prob})).")

    lines.append("")

    # Resource costs + budget
    for doc, doc_clinic, trust in doctors_in_all_clinics:
        cost = _rand_cost()
        lines.append(f"believes(action_cost(visit({doc}), {cost})).")

    budget = random.randint(8, 20)
    lines.append(f"believes(budget({budget})).")
    lines.append("")

    # Trust numeric mapping
    for level, num in TRUST_NUMS.items():
        lines.append(f"believes(trust_val({level}, {num})).")

    lines.append("")

    # Trust thresholds
    for kind, val in trust_thresholds.items():
        lines.append(f"believes(trust_threshold_num(consultation, {kind}, {val})).")

    lines.append("")

    # Equivalent actions for probabilistic selection
    pref_max = 10
    for act in equiv_actions:
        lines.append(f"believes(equivalent_action(consultation, {act})).")

    lines.append("")
    for act in equiv_actions:
        rho = _rand_prob()
        pref = _rand_pref(pref_max)
        cost = _rand_cost()
        lines.append(f"believes(action_data({act}, {rho}, {pref}, {cost})).")

    lines.append(f"believes(policy_weights(100, 10, 20)).")
    lines.append(f"believes(pref_max({pref_max})).")
    lines.append("")

    # Reactive rules ----------------------------------------------------------

    # schedule_ready
    lines.append("schedule_readyE :>")
    lines.append(f'    log("{name}: Baseline schedule loaded"),')
    lines.append(f"    believes(intend(consultation({timeslot}))),")
    lines.append(f"    believes(assigned_doctor(Doc)),")
    lines.append(f'    send(logger, log_event(schedule_loaded, {name}, [consultation, {timeslot}, Doc])).')
    lines.append("")

    # unavailable
    lines.append("unavailableE(Doctor, TimeSlot) :>")
    lines.append(f'    log("{name}: DISRUPTION — ~w unavailable at ~w", [Doctor, TimeSlot]),')
    lines.append(f"    assert_belief(unavailable(Doctor, TimeSlot)),")
    lines.append(f"    retract_belief(assigned_doctor(Doctor)),")
    lines.append(f"    send(logger, log_event(disruption, {name}, [unavailable, Doctor, TimeSlot])),")
    lines.append(f"    send({clinic}_mgr, repair_request({name}, consultation, TimeSlot)).")
    lines.append("")

    # local_repair — trust-aware decision
    lines.append("local_repairE(Doctor, TimeSlot, TrustLevel, PrefDegree) :>")
    lines.append(f'    log("{name}: Local repair offered — ~w (trust=~w, pref=~w)", [Doctor, TrustLevel, PrefDegree]),')
    lines.append(f"    believes(trust_val(TrustLevel, TrustNum)),")
    lines.append(f"    believes(trust_threshold_num(consultation, autonomy, AutThr)),")
    lines.append(f"    believes(trust_threshold_num(consultation, blocking, BlkThr)),")
    lines.append(f"    (   TrustNum >= AutThr")
    lines.append(f"    ->  assert_belief(assigned_doctor(Doctor)),")
    lines.append(f"        retract_belief(intend(consultation(TimeSlot))),")
    lines.append(f"        assert_belief(intend(consultation_with(Doctor, TimeSlot))),")
    lines.append(f"        send(logger, log_event(decision, {name}, [allow, Doctor, TimeSlot]))")
    lines.append(f"    ;   TrustNum > BlkThr")
    lines.append(f"    ->  send(logger, log_event(decision, {name}, [delegate, Doctor, TimeSlot])),")
    lines.append(f"        send(mediator, lending_request({name}, {clinic}, consultation, TimeSlot))")
    lines.append(f"    ;   send(logger, log_event(decision, {name}, [block, Doctor, TimeSlot]))")
    lines.append(f"    ).")
    lines.append("")

    # delegation_complete
    lines.append("delegation_completeE(Doctor, TimeSlot) :>")
    lines.append(f"    assert_belief(assigned_doctor(Doctor)),")
    lines.append(f"    retract_belief(intend(consultation(TimeSlot))),")
    lines.append(f"    assert_belief(intend(consultation_with(Doctor, TimeSlot))),")
    lines.append(f"    send(logger, log_event(delegation_complete, {name}, [Doctor, TimeSlot])).")
    lines.append("")

    # consultation_done
    lines.append("consultation_doneE(Doctor, TimeSlot) :>")
    lines.append(f"    assert_belief(done(consultation_with(Doctor, TimeSlot))),")
    lines.append(f"    retract_belief(intend(consultation_with(Doctor, TimeSlot))),")
    lines.append(f"    retract_belief(needs_consultation(TimeSlot)),")
    lines.append(f"    send(logger, log_event(consultation_done, {name}, [Doctor, TimeSlot])).")
    lines.append("")

    # select_action (probabilistic selector)
    lines.append("select_actionE(TimeSlot) :>")
    lines.append(f'    log("{name}: Probabilistic action selection"),')
    lines.append(f"    send(logger, log_event(selector_start, {name}, [consultation, TimeSlot])),")
    lines.append(f"    believes(policy_weights(LR, LP, LC)),")
    lines.append(f"    believes(pref_max(Pmax)),")
    lines.append(f"    believes(budget(Budget)),")
    lines.append(f"    findall(Score-Action, (")
    lines.append(f"        believes(equivalent_action(consultation, Action)),")
    lines.append(f"        believes(action_data(Action, Rho, Pref, Cost)),")
    lines.append(f"        Cost =< Budget,")
    lines.append(f"        Score is LR*Rho + LP*(Pref/Pmax) - LC*(Cost/Budget)")
    lines.append(f"    ), ScoresRaw),")
    lines.append(f"    sort(ScoresRaw, ScoresUniq),")
    lines.append(f"    reverse(ScoresUniq, [BestScore-BestAction | _]),")
    lines.append(f"    assert_belief(selected_action(BestAction, TimeSlot)),")
    lines.append(f"    send(logger, log_event(prob_selection, {name}, [BestAction, BestScore, TimeSlot])).")
    lines.append("")

    # fallback
    lines.append("fallback_aspE(TimeSlot) :>")
    lines.append(f"    send(logger, log_event(fallback, {name}, [asp_reoptimization, TimeSlot])).")
    lines.append("")

    return "\n".join(lines)


def gen_doctor(name, clinic, timeslots, trust_level):
    """Generate a doctor agent block."""
    lines = []
    lines.append(f":- agent({name}, [cycle(2)]).")
    lines.append("")
    lines.append(f"believes(member_of({clinic})).")
    lines.append(f"believes(role(doctor)).")
    lines.append(f"believes(specialization(general_practice)).")
    lines.append(f"believes(trust_level({trust_level})).")

    for ts in timeslots:
        lines.append(f"believes(can_do(consultation, {ts})).")
        lines.append(f"believes(available({ts})).")

    lines.append("")

    # become_unavailable
    lines.append("become_unavailableE(TimeSlot) :>")
    lines.append(f'    log("{name}: Becoming unavailable at ~w", [TimeSlot]),')
    lines.append(f"    retract_belief(can_do(consultation, TimeSlot)),")
    lines.append(f"    retract_belief(available(TimeSlot)),")
    lines.append(f"    assert_belief(unavailable(TimeSlot)),")
    lines.append(f"    send({clinic}_mgr, doctor_unavailable({name}, TimeSlot)),")
    lines.append(f"    send(logger, log_event(unavailability, {name}, [TimeSlot])).")
    lines.append("")

    # perform_consultation
    lines.append("perform_consultationE(Patient, TimeSlot) :>")
    lines.append(f"    believes(can_do(consultation, TimeSlot)),")
    lines.append(f'    log("{name}: Performing consultation for ~w at ~w", [Patient, TimeSlot]),')
    lines.append(f"    retract_belief(can_do(consultation, TimeSlot)),")
    lines.append(f"    assert_belief(done(consultation, Patient, TimeSlot)),")
    lines.append(f"    send(Patient, consultation_done({name}, TimeSlot)),")
    lines.append(f"    send(logger, log_event(consultation, {name}, [Patient, TimeSlot])),")
    lines.append(f"    (   believes(temporarily_in(Clinic))")
    lines.append(f"    ->  send(mediator, lending_task_done({name}, Clinic, TimeSlot))")
    lines.append(f"    ;   true")
    lines.append(f"    ).")
    lines.append("")

    # lend_to
    lines.append("lend_toE(RequestingClinic, Action, TimeSlot) :>")
    lines.append(f"    believes(can_do(Action, TimeSlot)),")
    lines.append(f"    believes(available(TimeSlot)),")
    lines.append(f"    assert_belief(temporarily_in(RequestingClinic)),")
    lines.append(f"    retract_belief(available(TimeSlot)),")
    lines.append(f"    send(mediator, lending_accepted({name}, RequestingClinic, Action, TimeSlot)),")
    lines.append(f"    send(logger, log_event(lending_accepted, {name}, [RequestingClinic, Action, TimeSlot])).")
    lines.append("")

    # return_to_group
    lines.append("return_to_groupE :>")
    lines.append(f"    believes(temporarily_in(Clinic)),")
    lines.append(f"    retract_belief(temporarily_in(Clinic)),")
    lines.append(f"    send(logger, log_event(return_group, {name}, [{clinic}])).")
    lines.append("")

    return "\n".join(lines)


def gen_manager(clinic, doctor_info, patient_names):
    """Generate a clinic manager agent block.
    doctor_info: list of (doc_name, trust_level, pref_degree)
    patient_names: list of patient names in this clinic
    """
    mgr_name = f"{clinic}_mgr"
    lines = []
    lines.append(f":- agent({mgr_name}, [cycle(1)]).")
    lines.append("")

    # Group membership
    for doc, trust, pref in doctor_info:
        lines.append(f"believes(member({clinic}, {doc})).")
    for pat in patient_names:
        lines.append(f"believes(member({clinic}, {pat})).")

    lines.append("")

    # Doctor capabilities
    for doc, trust, pref in doctor_info:
        lines.append(f"believes(doctor_trust({doc}, {trust})).")
        lines.append(f"believes(doctor_pref({doc}, {pref})).")
        lines.append(f"believes(doctor_available({doc})).")

    lines.append("")

    # doctor_unavailable event
    lines.append("doctor_unavailableE(Doctor, TimeSlot) :>")
    lines.append(f'    log("{mgr_name}: ~w unavailable at ~w", [Doctor, TimeSlot]),')
    lines.append(f"    retract_belief(doctor_available(Doctor)),")
    lines.append(f"    assert_belief(doctor_unavailable_at(Doctor, TimeSlot)),")
    # Notify all patients in this clinic
    for pat in patient_names:
        lines.append(f"    send({pat}, unavailable(Doctor, TimeSlot)),")
    lines.append(f"    send(logger, log_event(group_update, {mgr_name}, [unavailable, Doctor, TimeSlot])).")
    lines.append("")

    # repair_request event
    lines.append("repair_requestE(Patient, Action, TimeSlot) :>")
    lines.append(f"    findall(Pref-Doc-Trust, (")
    lines.append(f"        believes(member({clinic}, Doc)),")
    lines.append(f"        believes(doctor_available(Doc)),")
    lines.append(f"        believes(doctor_trust(Doc, Trust)),")
    lines.append(f"        believes(doctor_pref(Doc, Pref))")
    lines.append(f"    ), CandidatesRaw),")
    lines.append(f"    sort(CandidatesRaw, CandidatesUniq),")
    lines.append(f"    reverse(CandidatesUniq, Sorted),")
    lines.append(f"    (   Sorted = [BestPref-BestDoc-BestTrust | _]")
    lines.append(f"    ->  send(Patient, local_repair(BestDoc, TimeSlot, BestTrust, BestPref))")
    lines.append(f"    ;   send(mediator, lending_request(Patient, {clinic}, Action, TimeSlot)),")
    lines.append(f"        send(logger, log_event(no_local_repair, {mgr_name}, [Patient, TimeSlot]))")
    lines.append(f"    ).")
    lines.append("")

    return "\n".join(lines)


def gen_mediator(clinics, lending_threshold_num=4):
    """Generate the mediator agent block."""
    lines = []
    lines.append(":- agent(mediator, [cycle(1)]).")
    lines.append("")
    lines.append(f"believes(lending_threshold_num(consultation, {lending_threshold_num})).")
    lines.append("")
    for level, num in TRUST_NUMS.items():
        lines.append(f"believes(trust_val({level}, {num})).")
    lines.append("")

    # lending_request — try each clinic in order (skip requesting clinic)
    lines.append("lending_requestE(Patient, RequestingClinic, Action, TimeSlot) :>")
    lines.append(f"    assert_belief(pending_lending(Patient, RequestingClinic, Action, TimeSlot)),")
    # Query the first non-requesting clinic manager
    # For simplicity, broadcast to all other clinic managers
    for clinic in clinics:
        lines.append(f"    (   RequestingClinic \\= {clinic}")
        lines.append(f"    ->  send({clinic}_mgr, lending_inquiry(RequestingClinic, Action, TimeSlot))")
        lines.append(f"    ;   true")
        lines.append(f"    ),")
    lines.append(f"    send(logger, log_event(lending_request, mediator, [Patient, RequestingClinic, Action, TimeSlot])).")
    lines.append("")

    # lending_offer — guard: only process if pending_lending still exists
    # (prevents duplicate processing when multiple clinics respond)
    lines.append("lending_offerE(Doctor, SourceClinic, TrustLevel, Action, TimeSlot) :>")
    lines.append(f"    (   believes(pending_lending(Patient, RequestingClinic, Action, TimeSlot))")
    lines.append(f"    ->  believes(lending_threshold_num(Action, RequiredNum)),")
    lines.append(f"        believes(trust_val(TrustLevel, TrustNum)),")
    lines.append(f"        (   TrustNum >= RequiredNum")
    lines.append(f"        ->  retract_belief(pending_lending(Patient, RequestingClinic, Action, TimeSlot)),")
    lines.append(f"            assert_belief(active_lending(Doctor, SourceClinic, RequestingClinic, Patient, TimeSlot)),")
    lines.append(f"            send(Doctor, lend_to(RequestingClinic, Action, TimeSlot)),")
    lines.append(f"            send(logger, log_event(lending_approved, mediator, [Doctor, SourceClinic, RequestingClinic, TimeSlot]))")
    lines.append(f"        ;   send(Patient, fallback_asp(TimeSlot)),")
    lines.append(f"            send(logger, log_event(lending_denied, mediator, [Doctor, TrustLevel, RequiredNum]))")
    lines.append(f"        )")
    lines.append(f"    ;   true  %% already handled, ignore duplicate offer")
    lines.append(f"    ).")
    lines.append("")

    # lending_accepted
    lines.append("lending_acceptedE(Doctor, RequestingClinic, Action, TimeSlot) :>")
    lines.append(f"    believes(active_lending(Doctor, _, RequestingClinic, Patient, TimeSlot)),")
    lines.append(f"    send(Patient, delegation_complete(Doctor, TimeSlot)),")
    lines.append(f"    send(Doctor, perform_consultation(Patient, TimeSlot)),")
    lines.append(f"    send(logger, log_event(lending_executed, mediator, [Doctor, RequestingClinic, TimeSlot])).")
    lines.append("")

    # lending_task_done
    lines.append("lending_task_doneE(Doctor, RequestingClinic, TimeSlot) :>")
    lines.append(f"    (   believes(active_lending(Doctor, SourceClinic, RequestingClinic, _Patient, TimeSlot))")
    lines.append(f"    ->  retract_belief(active_lending(Doctor, SourceClinic, RequestingClinic, _Patient, TimeSlot)),")
    lines.append(f"        send(Doctor, return_to_group)")
    lines.append(f"    ;   true")
    lines.append(f"    ).")
    lines.append("")

    # lending_denied
    lines.append("lending_deniedE(SourceClinic, Action, TimeSlot) :>")
    lines.append(f"    believes(pending_lending(Patient, RequestingClinic, Action, TimeSlot)),")
    lines.append(f"    retract_belief(pending_lending(Patient, RequestingClinic, Action, TimeSlot)),")
    lines.append(f"    send(Patient, fallback_asp(TimeSlot)),")
    lines.append(f"    send(logger, log_event(lending_failed, mediator, [SourceClinic, Action, TimeSlot])).")
    lines.append("")

    # lending_inquiry handler for managers
    for clinic in clinics:
        pass  # handled in manager gen

    return "\n".join(lines)


def gen_logger():
    """Generate the logger agent block (with timing)."""
    lines = []
    lines.append(":- agent(logger, [cycle(1)]).")
    lines.append("")
    lines.append("log_eventE(Type, Source, Data) :>")
    lines.append('    get_time(T),')
    lines.append('    log("TRACE [~w] ~w: ~w @~6f", [Type, Source, Data, T]),')
    lines.append("    assert_belief(logged(Type, Source, Data, T)).")
    lines.append("")

    # Instability warning
    lines.append("believes(logged(disruption, _, _, _)) :< ")
    lines.append("    \\+ believes(warned_instability),")
    lines.append("    findall(x, believes(logged(disruption, _, _, _)), Disruptions),")
    lines.append("    length(Disruptions, N),")
    lines.append("    N > 2,")
    lines.append("    assert_belief(warned_instability),")
    lines.append('    log("LOGGER WARNING: ~w disruptions recorded!", [N]).')
    lines.append("")

    # Metrics computation
    lines.append("compute_metricsE :>")
    lines.append("    findall(T, believes(logged(disruption, _, _, T)), DispTimes),")
    lines.append("    findall(T, believes(logged(consultation_done, _, _, T)), DoneTimes),")
    lines.append("    findall(T, believes(logged(lending_approved, _, _, T)), LendTimes),")
    lines.append("    findall(T, believes(logged(prob_selection, _, _, T)), SelTimes),")
    lines.append("    findall(x, believes(logged(_, _, _, _)), AllEvents),")
    lines.append("    length(AllEvents, TotalEvents),")
    lines.append("    length(DispTimes, NumDisruptions),")
    lines.append("    length(DoneTimes, NumRepairs),")
    lines.append("    length(LendTimes, NumLendings),")
    lines.append("    length(SelTimes, NumSelections),")
    lines.append("    ( DispTimes = [DT0|_], DoneTimes \\= []")
    lines.append("    -> last(DoneTimes, DTLast),")
    lines.append("       AvgRepairMs is (DTLast - DT0) * 1000")
    lines.append("    ;  AvgRepairMs = 0")
    lines.append("    ),")
    lines.append("    ( NumDisruptions > 0")
    lines.append("    -> LendingPct is (NumLendings / NumDisruptions) * 100")
    lines.append("    ;  LendingPct = 0")
    lines.append("    ),")
    lines.append("    findall(T, believes(logged(selector_start, _, _, T)), SelStartTimes),")
    lines.append("    findall(T, believes(logged(prob_selection, _, _, T)), SelEndTimes),")
    lines.append("    ( SelStartTimes = [SS|_], SelEndTimes = [SE|_]")
    lines.append("    -> SelectorMs is (SE - SS) * 1000")
    lines.append("    ;  SelectorMs = 0")
    lines.append("    ),")
    lines.append("    assert_belief(metrics_summary(TotalEvents, NumDisruptions, NumRepairs,")
    lines.append("                                  NumLendings, NumSelections, AvgRepairMs,")
    lines.append("                                  LendingPct, SelectorMs)),")
    lines.append('    log("METRICS: events=~w disruptions=~w repairs=~w lendings=~w selections=~w",')
    lines.append("        [TotalEvents, NumDisruptions, NumRepairs, NumLendings, NumSelections]),")
    lines.append('    log("METRICS: repair_ms=~2f lending_pct=~1f selector_ms=~3f",')
    lines.append("        [AvgRepairMs, LendingPct, SelectorMs]).")
    lines.append("")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Lending inquiry handler for managers
# ---------------------------------------------------------------------------

def gen_lending_inquiry(clinic):
    """Generate lending_inquiry handler for a clinic manager."""
    mgr_name = f"{clinic}_mgr"
    lines = []
    lines.append("lending_inquiryE(RequestingClinic, Action, TimeSlot) :>")
    lines.append(f"    findall(Doc-Trust, (")
    lines.append(f"        believes(member({clinic}, Doc)),")
    lines.append(f"        believes(doctor_available(Doc)),")
    lines.append(f"        believes(doctor_trust(Doc, Trust))")
    lines.append(f"    ), AvailableRaw),")
    lines.append(f"    sort(AvailableRaw, Available),")
    lines.append(f"    (   Available = [BestDoc-BestTrust | _]")
    lines.append(f"    ->  send(mediator, lending_offer(BestDoc, {clinic}, BestTrust, Action, TimeSlot))")
    lines.append(f"    ;   send(mediator, lending_denied({clinic}, Action, TimeSlot))")
    lines.append(f"    ).")
    lines.append("")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Main generator
# ---------------------------------------------------------------------------

def generate_scenario(num_clinics, docs_per_clinic, num_patients, num_disruptions,
                      num_equiv_actions, seed=42):
    """Generate a complete .pl scenario file content."""
    random.seed(seed)

    clinics = [f"clinic_{chr(ord('a') + i)}" for i in range(num_clinics)]
    timeslots = [f"t{i+1}" for i in range(max(num_patients, num_disruptions) + 2)]

    # Generate equivalent action names
    equiv_action_names = [f"visit_type_{i+1}" for i in range(num_equiv_actions)]

    # Generate doctors
    all_doctors = []  # (name, clinic, trust_level)
    doctor_info_by_clinic = {}  # clinic -> [(name, trust, pref)]
    for ci, clinic in enumerate(clinics):
        doctor_info_by_clinic[clinic] = []
        for di in range(docs_per_clinic):
            doc_name = f"doc_{clinic[7]}_{di+1}"  # e.g., doc_a_1
            trust = _rand_trust("low")
            pref = _rand_pref()
            all_doctors.append((doc_name, clinic, trust))
            doctor_info_by_clinic[clinic].append((doc_name, trust, pref))

    # Generate patients — distribute across clinics
    patients = []  # (name, clinic, assigned_doc, timeslot)
    patients_by_clinic = {c: [] for c in clinics}
    for pi in range(num_patients):
        clinic = clinics[pi % num_clinics]
        # Assign to a random available doctor in the clinic
        clinic_docs = doctor_info_by_clinic[clinic]
        assigned_doc = clinic_docs[pi % len(clinic_docs)][0]
        ts = timeslots[pi]
        pat_name = f"patient_{pi+1}"
        patients.append((pat_name, clinic, assigned_doc, ts))
        patients_by_clinic[clinic].append(pat_name)

    # Select disruptions — only disrupt doctors that are actually assigned to
    # patients, so that the disruption triggers a meaningful repair chain.
    assigned_docs = list({(p[2], p[1]) for p in patients})  # (doc, clinic) unique
    random.shuffle(assigned_docs)

    # If we need more disruptions than assigned doctors, also pick unassigned
    # doctors (these still generate unavailability events & group updates).
    extra_docs = [(d, c) for d, c, _ in all_doctors
                  if (d, c) not in assigned_docs]
    random.shuffle(extra_docs)
    disruptable_pool = assigned_docs + extra_docs

    disruptions = []
    for di in range(min(num_disruptions, len(disruptable_pool))):
        doc_name, clinic = disruptable_pool[di]
        ts = timeslots[di]
        disruptions.append((doc_name, ts))

    # Trust thresholds (same for all patients)
    trust_thresholds = {
        "intention": 3,
        "feasibility": 3,
        "lending": 4,
        "blocking": 1,
        "autonomy": 4
    }

    # Build the file
    sections = []

    header = f"""%% =============================================================================
%% L-DINF Healthcare Scheduling — Generated Scenario
%% =============================================================================
%% Clinics: {num_clinics}, Doctors/clinic: {docs_per_clinic}, Patients: {num_patients}
%% Disruptions: {num_disruptions}, Equivalent actions: {num_equiv_actions}
%% Total agents: {num_clinics * docs_per_clinic + num_patients + num_clinics + 2}
%% Seed: {seed}
%% =============================================================================
"""
    sections.append(header)

    # Patient agents
    for pat_name, clinic, assigned_doc, ts in patients:
        sections.append(f"%% === {pat_name.upper()} ===")
        sections.append(gen_patient(pat_name, clinic, assigned_doc, ts,
                                     all_doctors, equiv_action_names,
                                     trust_thresholds))

    # Doctor agents
    for doc_name, clinic, trust in all_doctors:
        sections.append(f"%% === {doc_name.upper()} ===")
        sections.append(gen_doctor(doc_name, clinic, timeslots[:docs_per_clinic + 2], trust))

    # Manager agents
    for clinic in clinics:
        sections.append(f"%% === {clinic.upper()}_MGR ===")
        mgr_block = gen_manager(clinic, doctor_info_by_clinic[clinic],
                                patients_by_clinic[clinic])
        # Append lending_inquiry handler
        mgr_block += "\n" + gen_lending_inquiry(clinic)
        sections.append(mgr_block)

    # Mediator
    sections.append("%% === MEDIATOR ===")
    sections.append(gen_mediator(clinics))

    # Logger
    sections.append("%% === LOGGER ===")
    sections.append(gen_logger())

    content = "\n\n".join(sections)

    # Also generate a disruption plan (JSON) for the benchmark runner
    disruption_plan = {
        "agents": num_clinics * docs_per_clinic + num_patients + num_clinics + 2,
        "clinics": num_clinics,
        "doctors_per_clinic": docs_per_clinic,
        "patients": num_patients,
        "num_disruptions": num_disruptions,
        "num_equiv_actions": num_equiv_actions,
        "disruptions": [{"doctor": d, "timeslot": t} for d, t in disruptions],
        "patient_selections": [
            {"patient": pat_name, "timeslot": ts}
            for pat_name, clinic, assigned_doc, ts in patients
        ],
        "schedule_ready_patients": [pat_name for pat_name, _, _, _ in patients]
    }

    return content, disruption_plan


# ---------------------------------------------------------------------------
# Predefined configurations
# ---------------------------------------------------------------------------

DEFAULT_CONFIGS = [
    {
        "name": "S1_small",
        "clinics": 2, "docs_per_clinic": 2, "patients": 2,
        "disruptions": 1, "equiv_actions": 3, "seed": 42
    },
    {
        "name": "S2_medium",
        "clinics": 3, "docs_per_clinic": 3, "patients": 6,
        "disruptions": 3, "equiv_actions": 4, "seed": 43
    },
    {
        "name": "S3_large",
        "clinics": 3, "docs_per_clinic": 4, "patients": 8,
        "disruptions": 5, "equiv_actions": 5, "seed": 44
    },
    {
        "name": "S4_xlarge",
        "clinics": 4, "docs_per_clinic": 3, "patients": 10,
        "disruptions": 8, "equiv_actions": 6, "seed": 45
    }
]


def main():
    parser = argparse.ArgumentParser(description="Generate L-DINF/DALI2 benchmark scenarios")
    parser.add_argument("--config", type=str, help="JSON config file with scenario list")
    parser.add_argument("--clinics", type=int, default=2)
    parser.add_argument("--docs-per-clinic", type=int, default=2)
    parser.add_argument("--patients", type=int, default=2)
    parser.add_argument("--disruptions", type=int, default=1)
    parser.add_argument("--equiv-actions", type=int, default=3)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--name", type=str, default="scenario")
    parser.add_argument("--outdir", type=str, default="scenarios")
    parser.add_argument("--use-defaults", action="store_true",
                        help="Generate all default S1-S4 configurations")
    args = parser.parse_args()

    os.makedirs(args.outdir, exist_ok=True)

    if args.use_defaults:
        configs = DEFAULT_CONFIGS
    elif args.config:
        with open(args.config) as f:
            configs = json.load(f)
    else:
        configs = [{
            "name": args.name,
            "clinics": args.clinics,
            "docs_per_clinic": args.docs_per_clinic,
            "patients": args.patients,
            "disruptions": args.disruptions,
            "equiv_actions": args.equiv_actions,
            "seed": args.seed
        }]

    for cfg in configs:
        name = cfg["name"]
        content, plan = generate_scenario(
            cfg["clinics"], cfg["docs_per_clinic"], cfg["patients"],
            cfg["disruptions"], cfg["equiv_actions"], cfg.get("seed", 42)
        )

        pl_path = os.path.join(args.outdir, f"{name}.pl")
        plan_path = os.path.join(args.outdir, f"{name}_plan.json")

        with open(pl_path, "w", encoding="utf-8") as f:
            f.write(content)

        with open(plan_path, "w", encoding="utf-8") as f:
            json.dump(plan, f, indent=2)

        print(f"Generated: {pl_path} ({plan['agents']} agents, "
              f"{plan['num_disruptions']} disruptions)")
        print(f"  Plan:    {plan_path}")


if __name__ == "__main__":
    main()

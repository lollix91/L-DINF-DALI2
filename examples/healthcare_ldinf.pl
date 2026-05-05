%% =============================================================================
%% L-DINF Healthcare Scheduling — DALI2 Implementation
%% =============================================================================
%%
%% A complete implementation of L-DINF constructs in DALI2 for a healthcare
%% scheduling scenario with runtime adaptation.
%%
%% Scenario: Two clinics (clinic_a and clinic_b) with doctors and patients.
%% A baseline schedule assigns patients to doctors. When disruptions occur
%% (e.g., doctor unavailability), the system performs:
%%   1. Belief update (L-DINF mental action +phi)
%%   2. Feasibility checking (can_do)
%%   3. Preference-guided local repair (pref_do)
%%   4. Trust-aware decision making (allow/delegate/block)
%%   5. Inter-group delegation via lending (lend_G)
%%   6. Probabilistic action selection (F^prob_pi)
%%
%% Agents (9):
%%   - alice:        Patient agent — needs consultation, triggers adaptation
%%   - bob:          Patient agent — needs consultation, demonstrates preference
%%   - doc_jones:    Doctor at clinic_a — becomes unavailable (disruption)
%%   - doc_smith:    Doctor at clinic_b — available for delegation
%%   - doc_lee:      Doctor at clinic_a — available but lower preference
%%   - clinic_a_mgr: Group manager for clinic_a — coordinates local repair
%%   - clinic_b_mgr: Group manager for clinic_b — handles lending requests
%%   - mediator:     Delegation manager — validates and executes lending
%%   - logger:       Logs all events for explanation traces
%%
%% Run:
%%   swipl -l ../DALI2/src/server.pl -g main -- 8080 examples/healthcare_ldinf.pl
%%
%% Or with Docker (DALI2 must be at ../DALI2):
%%   docker compose up --build
%%
%% =============================================================================

%% ============================================================
%% ALICE — Patient agent (member of clinic_a)
%% ============================================================
%% Implements: B_i, intend_i, can_do checking, belief update (+phi),
%%             preference-guided repair, trust-aware delegation

:- agent(alice, [cycle(2)]).

%% --- Initial beliefs (L-DINF: B_alice) ---
believes(needs_consultation(t1)).
believes(member_of(clinic_a)).
believes(preferred_doctor(doc_jones)).
believes(preferred_clinic(clinic_a)).
believes(appointment_preference(clinic_a, slot_9am, slot_12pm)).
believes(sensory_preference(quiet)).

%% Baseline schedule imported as intention (L-DINF: intend_alice(consultation(t1)))
believes(intend(consultation(t1))).
believes(assigned_doctor(doc_jones)).
believes(assigned_clinic(clinic_a)).

%% Trust levels for known doctors (L-DINF: trust_K(i, tau))
believes(trust(doc_jones, very_high)).
believes(trust(doc_smith, high)).
believes(trust(doc_lee, medium)).

%% Preference degrees for doctors (L-DINF: pref_do_i(visit(D), d))
believes(pref_do(visit(doc_jones), 10)).
believes(pref_do(visit(doc_smith), 7)).
believes(pref_do(visit(doc_lee), 5)).

%% Success probabilities (L-DINF probabilistic: rho)
believes(success_prob(visit(doc_jones), 0.95)).
believes(success_prob(visit(doc_smith), 0.90)).
believes(success_prob(visit(doc_lee), 0.70)).

%% Resource costs (L-DINF: C2)
believes(action_cost(visit(doc_jones), 3)).
believes(action_cost(visit(doc_smith), 5)).
believes(action_cost(visit(doc_lee), 2)).
believes(budget(10)).

%% Trust thresholds for consultation action (L-DINF: Theta)
believes(trust_threshold(consultation, intention, medium)).
believes(trust_threshold(consultation, feasibility, medium)).
believes(trust_threshold(consultation, lending, high)).
believes(trust_threshold(consultation, blocking, very_low)).
believes(trust_threshold(consultation, autonomy, high)).

%% Feasibility constraints (compiled from ASP: tau^IC)
%% A doctor cannot do consultation if unavailable
believes(constraint(unavailable(D) -> neg_can_do(D, consultation))).

%% --- External event: baseline schedule loaded ---
schedule_readyE :>
    log("Alice: Baseline schedule loaded"),
    log("Alice: intend(consultation(t1)) with doc_jones at clinic_a"),
    believes(intend(consultation(t1))),
    believes(assigned_doctor(Doc)),
    believes(trust(Doc, Trust)),
    log("Alice: B_alice(assigned_doctor(~w)), trust=~w", [Doc, Trust]),
    send(logger, log_event(schedule_loaded, alice, [consultation, t1, Doc])).

%% --- External event: doctor becomes unavailable (L-DINF: +neg_can_do) ---
unavailableE(Doctor, TimeSlot) :>
    log("Alice: DISRUPTION — ~w unavailable at ~w", [Doctor, TimeSlot]),
    %% L-DINF mental action +phi: belief update
    assert_belief(unavailable(Doctor, TimeSlot)),
    retract_belief(assigned_doctor(Doctor)),
    log("Alice: B_alice(unavailable(~w, ~w)) — belief updated", [Doctor, TimeSlot]),
    %% Check feasibility of current intention
    send(logger, log_event(disruption, alice, [unavailable, Doctor, TimeSlot])),
    %% Trigger repair process
    send(clinic_a_mgr, repair_request(alice, consultation, TimeSlot)).

%% --- External event: local repair found ---
local_repairE(Doctor, TimeSlot, TrustLevel, PrefDegree) :>
    log("Alice: Local repair offered — ~w (trust=~w, pref=~w)", [Doctor, TrustLevel, PrefDegree]),
    %% L-DINF trust-aware decision
    believes(trust_threshold(consultation, autonomy, AutonomyThreshold)),
    believes(trust_threshold(consultation, blocking, BlockThreshold)),
    (   trust_ge(TrustLevel, AutonomyThreshold)
    ->  log("Alice: decision = ALLOW — ~w trusted for autonomous execution", [Doctor]),
        assert_belief(assigned_doctor(Doctor)),
        retract_belief(intend(consultation(TimeSlot))),
        assert_belief(intend(consultation_with(Doctor, TimeSlot))),
        send(logger, log_event(decision, alice, [allow, Doctor, TimeSlot]))
    ;   trust_gt(TrustLevel, BlockThreshold)
    ->  log("Alice: decision = DELEGATE — ~w in grey zone, requesting lending", [Doctor]),
        send(logger, log_event(decision, alice, [delegate, Doctor, TimeSlot])),
        send(mediator, lending_request(alice, clinic_a, consultation, TimeSlot))
    ;   log("Alice: decision = BLOCK — ~w trust too low", [Doctor]),
        send(logger, log_event(decision, alice, [block, Doctor, TimeSlot]))
    ).

%% --- External event: delegation completed ---
delegation_completeE(Doctor, TimeSlot) :>
    log("Alice: Delegation successful — ~w assigned via lending", [Doctor]),
    assert_belief(assigned_doctor(Doctor)),
    retract_belief(intend(consultation(TimeSlot))),
    assert_belief(intend(consultation_with(Doctor, TimeSlot))),
    send(logger, log_event(delegation_complete, alice, [Doctor, TimeSlot])).

%% --- External event: consultation performed ---
consultation_doneE(Doctor, TimeSlot) :>
    log("Alice: Consultation completed with ~w at ~w", [Doctor, TimeSlot]),
    %% L-DINF: do^P_alice(consultation(t1))
    assert_belief(done(consultation_with(Doctor, TimeSlot))),
    retract_belief(intend(consultation_with(Doctor, TimeSlot))),
    retract_belief(needs_consultation(TimeSlot)),
    send(logger, log_event(consultation_done, alice, [Doctor, TimeSlot])).

%% --- External event: no repair possible, fallback to ASP ---
fallback_aspE(TimeSlot) :>
    log("Alice: No local/delegation repair — FALLBACK to ASP re-optimization"),
    send(logger, log_event(fallback, alice, [asp_reoptimization, TimeSlot])).

%% --- Helper: trust level comparison ---
helper(trust_ge(T1, T2)) :-
    trust_order(T1, N1), trust_order(T2, N2), N1 >= N2.
helper(trust_gt(T1, T2)) :-
    trust_order(T1, N1), trust_order(T2, N2), N1 > N2.
helper(trust_order(very_low, 1)).
helper(trust_order(low, 2)).
helper(trust_order(medium, 3)).
helper(trust_order(high, 4)).
helper(trust_order(very_high, 5)).


%% ============================================================
%% BOB — Second patient agent (member of clinic_a)
%% ============================================================
%% Demonstrates: probabilistic action selection (F^prob_pi)

:- agent(bob, [cycle(2)]).

believes(needs_consultation(t2)).
believes(member_of(clinic_a)).
believes(intend(consultation(t2))).
believes(assigned_doctor(doc_jones)).
believes(assigned_clinic(clinic_a)).

%% Equivalent actions for consultation (L-DINF: Q(consultation, w))
believes(equivalent_action(consultation, visit_standard)).
believes(equivalent_action(consultation, visit_telemedicine)).
believes(equivalent_action(consultation, visit_home)).

%% Probabilistic data for each equivalent action
believes(action_data(visit_standard, 0.90, 8, 5)).   % (success_prob, pref, cost)
believes(action_data(visit_telemedicine, 0.75, 6, 2)).
believes(action_data(visit_home, 0.85, 7, 8)).
believes(budget(12)).

%% Policy weights (L-DINF: pi = (lambda_rho, lambda_P, lambda_C))
believes(policy_weights(100, 10, 20)).
believes(pref_max(10)).

%% --- External event: select best action probabilistically ---
select_actionE(TimeSlot) :>
    log("Bob: Probabilistic action selection for consultation at ~w", [TimeSlot]),
    believes(policy_weights(LambdaRho, LambdaP, LambdaC)),
    believes(pref_max(Pmax)),
    believes(budget(Budget)),
    %% Compute scores for each equivalent action
    findall(Score-Action, (
        believes(equivalent_action(consultation, Action)),
        believes(action_data(Action, Rho, Pref, Cost)),
        Cost =< Budget,
        Score is LambdaRho * Rho + LambdaP * (Pref / Pmax) - LambdaC * (Cost / Budget),
        log("Bob:   ~w — score=~2f (rho=~w, pref=~w, cost=~w)",
            [Action, Score, Rho, Pref, Cost])
    ), Scores),
    sort(0, @>=, Scores, [BestScore-BestAction | _]),
    log("Bob: SELECTED ~w (score=~2f) via F^prob_pi", [BestAction, BestScore]),
    assert_belief(selected_action(BestAction, TimeSlot)),
    send(logger, log_event(prob_selection, bob, [BestAction, BestScore, TimeSlot])).

%% --- External event: disruption for Bob too ---
unavailableE(Doctor, TimeSlot) :>
    believes(assigned_doctor(Doctor)),
    log("Bob: DISRUPTION — ~w unavailable at ~w, triggering action selection", [Doctor, TimeSlot]),
    retract_belief(assigned_doctor(Doctor)),
    assert_belief(unavailable(Doctor, TimeSlot)),
    send(logger, log_event(disruption, bob, [unavailable, Doctor, TimeSlot])).


%% ============================================================
%% DOC_JONES — Doctor agent at clinic_a
%% ============================================================
%% Implements: can_do_i, do_i, role-based enabling (H)

:- agent(doc_jones, [cycle(2)]).

believes(member_of(clinic_a)).
believes(role(doctor)).
believes(specialization(general_practice)).
believes(experience(15)).
believes(can_do(consultation, t1)).
believes(can_do(consultation, t2)).
believes(available(t1)).
believes(available(t2)).

%% External event: become unavailable (simulates disruption)
become_unavailableE(TimeSlot) :>
    log("DocJones: Becoming unavailable at ~w", [TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    retract_belief(available(TimeSlot)),
    assert_belief(unavailable(TimeSlot)),
    %% Notify clinic manager and affected patients
    send(clinic_a_mgr, doctor_unavailable(doc_jones, TimeSlot)),
    send(logger, log_event(unavailability, doc_jones, [TimeSlot])).

%% External event: perform consultation
perform_consultationE(Patient, TimeSlot) :>
    believes(can_do(consultation, TimeSlot)),
    log("DocJones: Performing consultation for ~w at ~w", [Patient, TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    assert_belief(done(consultation, Patient, TimeSlot)),
    send(Patient, consultation_done(doc_jones, TimeSlot)),
    send(logger, log_event(consultation, doc_jones, [Patient, TimeSlot])).


%% ============================================================
%% DOC_SMITH — Doctor agent at clinic_b
%% ============================================================
%% Implements: can_do_i, lending participation

:- agent(doc_smith, [cycle(2)]).

believes(member_of(clinic_b)).
believes(role(doctor)).
believes(specialization(general_practice)).
believes(experience(12)).
believes(can_do(consultation, t1)).
believes(can_do(consultation, t2)).
believes(available(t1)).
believes(available(t2)).
believes(trust_level(high)).

%% External event: lending request — temporarily join another group
lend_toE(RequestingClinic, Action, TimeSlot) :>
    believes(can_do(Action, TimeSlot)),
    believes(available(TimeSlot)),
    log("DocSmith: Accepting lending to ~w for ~w at ~w", [RequestingClinic, Action, TimeSlot]),
    %% L-DINF: join_group and do
    assert_belief(temporarily_in(RequestingClinic)),
    retract_belief(available(TimeSlot)),
    send(mediator, lending_accepted(doc_smith, RequestingClinic, Action, TimeSlot)),
    send(logger, log_event(lending_accepted, doc_smith, [RequestingClinic, Action, TimeSlot])).

%% External event: perform consultation as lent doctor
perform_consultationE(Patient, TimeSlot) :>
    log("DocSmith: Performing consultation for ~w at ~w (as lent doctor)", [Patient, TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    assert_belief(done(consultation, Patient, TimeSlot)),
    send(Patient, consultation_done(doc_smith, TimeSlot)),
    send(logger, log_event(consultation, doc_smith, [Patient, TimeSlot])).

%% External event: return to original group after lending
return_to_groupE :>
    believes(temporarily_in(Clinic)),
    log("DocSmith: Returning to clinic_b from ~w", [Clinic]),
    retract_belief(temporarily_in(Clinic)),
    send(logger, log_event(return_group, doc_smith, [clinic_b])).


%% ============================================================
%% DOC_LEE — Doctor agent at clinic_a (lower preference)
%% ============================================================

:- agent(doc_lee, [cycle(2)]).

believes(member_of(clinic_a)).
believes(role(doctor)).
believes(specialization(general_practice)).
believes(experience(3)).
believes(can_do(consultation, t1)).
believes(can_do(consultation, t2)).
believes(available(t1)).
believes(available(t2)).
believes(trust_level(medium)).

perform_consultationE(Patient, TimeSlot) :>
    believes(can_do(consultation, TimeSlot)),
    log("DocLee: Performing consultation for ~w at ~w", [Patient, TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    assert_belief(done(consultation, Patient, TimeSlot)),
    send(Patient, consultation_done(doc_lee, TimeSlot)),
    send(logger, log_event(consultation, doc_lee, [Patient, TimeSlot])).


%% ============================================================
%% CLINIC_A_MGR — Group manager for clinic_a
%% ============================================================
%% Implements: can_do_G (group feasibility), preference ranking,
%%             trust checking, local repair coordination

:- agent(clinic_a_mgr, [cycle(1)]).

%% Group membership (L-DINF: i in G)
believes(member(clinic_a, doc_jones)).
believes(member(clinic_a, doc_lee)).
believes(member(clinic_a, alice)).
believes(member(clinic_a, bob)).

%% Doctor capabilities and trust
believes(doctor_trust(doc_jones, very_high)).
believes(doctor_trust(doc_lee, medium)).
believes(doctor_pref(doc_jones, 10)).
believes(doctor_pref(doc_lee, 5)).
believes(doctor_available(doc_jones)).
believes(doctor_available(doc_lee)).

%% --- External event: doctor becomes unavailable ---
doctor_unavailableE(Doctor, TimeSlot) :>
    log("ClinicA_Mgr: ~w unavailable at ~w — updating group state", [Doctor, TimeSlot]),
    retract_belief(doctor_available(Doctor)),
    assert_belief(doctor_unavailable_at(Doctor, TimeSlot)),
    %% Notify affected patients
    send(alice, unavailable(Doctor, TimeSlot)),
    send(bob, unavailable(Doctor, TimeSlot)),
    send(logger, log_event(group_update, clinic_a_mgr, [unavailable, Doctor, TimeSlot])).

%% --- External event: repair request from patient ---
repair_requestE(Patient, Action, TimeSlot) :>
    log("ClinicA_Mgr: Repair request from ~w for ~w at ~w", [Patient, Action, TimeSlot]),
    %% L-DINF: can_do_G(consultation) — check if any local doctor can do it
    findall(Pref-Doc-Trust, (
        believes(member(clinic_a, Doc)),
        believes(doctor_available(Doc)),
        believes(doctor_trust(Doc, Trust)),
        believes(doctor_pref(Doc, Pref))
    ), Candidates),
    sort(0, @>=, Candidates, Sorted),
    log("ClinicA_Mgr: Local candidates (sorted by pref): ~w", [Sorted]),
    (   Sorted = [BestPref-BestDoc-BestTrust | _]
    ->  log("ClinicA_Mgr: Best local candidate: ~w (trust=~w, pref=~w)",
            [BestDoc, BestTrust, BestPref]),
        %% L-DINF: can_do_i found locally — offer local repair
        send(Patient, local_repair(BestDoc, TimeSlot, BestTrust, BestPref))
    ;   %% L-DINF: no local can_do — need inter-group delegation
        log("ClinicA_Mgr: No local candidates — requesting lending from clinic_b"),
        send(mediator, lending_request(Patient, clinic_a, Action, TimeSlot)),
        send(logger, log_event(no_local_repair, clinic_a_mgr, [Patient, TimeSlot]))
    ).


%% ============================================================
%% CLINIC_B_MGR — Group manager for clinic_b
%% ============================================================
%% Implements: lending authorization from the lending group's side

:- agent(clinic_b_mgr, [cycle(1)]).

believes(member(clinic_b, doc_smith)).
believes(doctor_trust(doc_smith, high)).
believes(doctor_pref(doc_smith, 7)).
believes(doctor_available(doc_smith)).

%% --- External event: lending inquiry from mediator ---
lending_inquiryE(RequestingClinic, Action, TimeSlot) :>
    log("ClinicB_Mgr: Lending inquiry from ~w for ~w at ~w", [RequestingClinic, Action, TimeSlot]),
    %% Check if any doctor is available and qualified
    findall(Doc-Trust, (
        believes(member(clinic_b, Doc)),
        believes(doctor_available(Doc)),
        believes(doctor_trust(Doc, Trust))
    ), Available),
    (   Available = [BestDoc-BestTrust | _]
    ->  log("ClinicB_Mgr: Offering ~w (trust=~w) for lending", [BestDoc, BestTrust]),
        send(mediator, lending_offer(BestDoc, clinic_b, BestTrust, Action, TimeSlot))
    ;   log("ClinicB_Mgr: No doctors available for lending"),
        send(mediator, lending_denied(clinic_b, Action, TimeSlot))
    ).


%% ============================================================
%% MEDIATOR — Delegation manager
%% ============================================================
%% Implements: lend_G(i, H, phi_A) — validates requests, coordinates
%%             membership updates, enforces trust thresholds

:- agent(mediator, [cycle(1)]).

%% Lending trust threshold for consultation (L-DINF: tau^Pi_L)
believes(lending_threshold(consultation, high)).

%% --- External event: lending request ---
lending_requestE(Patient, RequestingClinic, Action, TimeSlot) :>
    log("Mediator: Lending request — ~w needs ~w at ~w from ~w",
        [Patient, Action, TimeSlot, RequestingClinic]),
    assert_belief(pending_lending(Patient, RequestingClinic, Action, TimeSlot)),
    %% Ask clinic_b for available doctors
    send(clinic_b_mgr, lending_inquiry(RequestingClinic, Action, TimeSlot)),
    send(logger, log_event(lending_request, mediator, [Patient, RequestingClinic, Action, TimeSlot])).

%% --- External event: lending offer from another clinic ---
lending_offerE(Doctor, SourceClinic, TrustLevel, Action, TimeSlot) :>
    believes(pending_lending(Patient, RequestingClinic, Action, TimeSlot)),
    log("Mediator: Offer — ~w from ~w (trust=~w)", [Doctor, SourceClinic, TrustLevel]),
    %% L-DINF: check trust threshold for lending
    believes(lending_threshold(Action, RequiredTrust)),
    (   trust_ge(TrustLevel, RequiredTrust)
    ->  log("Mediator: Trust OK (~w >= ~w) — LENDING APPROVED", [TrustLevel, RequiredTrust]),
        %% L-DINF: lend_G(i, H, phi_A) — execute lending protocol
        retract_belief(pending_lending(Patient, RequestingClinic, Action, TimeSlot)),
        assert_belief(active_lending(Doctor, SourceClinic, RequestingClinic, TimeSlot)),
        send(Doctor, lend_to(RequestingClinic, Action, TimeSlot)),
        send(logger, log_event(lending_approved, mediator,
            [Doctor, SourceClinic, RequestingClinic, TimeSlot]))
    ;   log("Mediator: Trust INSUFFICIENT (~w < ~w) — LENDING DENIED", [TrustLevel, RequiredTrust]),
        send(Patient, fallback_asp(TimeSlot)),
        send(logger, log_event(lending_denied, mediator, [Doctor, TrustLevel, RequiredTrust]))
    ).

%% --- External event: lending accepted by doctor ---
lending_acceptedE(Doctor, RequestingClinic, Action, TimeSlot) :>
    log("Mediator: ~w accepted lending to ~w", [Doctor, RequestingClinic]),
    believes(active_lending(Doctor, _, RequestingClinic, TimeSlot)),
    %% Notify patient about delegation completion
    %% Find the patient from pending context
    send(alice, delegation_complete(Doctor, TimeSlot)),
    %% Schedule the actual consultation
    send(Doctor, perform_consultation(alice, TimeSlot)),
    send(logger, log_event(lending_executed, mediator, [Doctor, RequestingClinic, TimeSlot])).

%% --- External event: lending denied by source clinic ---
lending_deniedE(SourceClinic, Action, TimeSlot) :>
    believes(pending_lending(Patient, RequestingClinic, Action, TimeSlot)),
    log("Mediator: Lending denied by ~w — fallback to ASP", [SourceClinic]),
    retract_belief(pending_lending(Patient, RequestingClinic, Action, TimeSlot)),
    send(Patient, fallback_asp(TimeSlot)),
    send(logger, log_event(lending_failed, mediator, [SourceClinic, Action, TimeSlot])).

%% --- Helper: trust comparison ---
helper(trust_ge(T1, T2)) :-
    trust_order(T1, N1), trust_order(T2, N2), N1 >= N2.
helper(trust_gt(T1, T2)) :-
    trust_order(T1, N1), trust_order(T2, N2), N1 > N2.
helper(trust_order(very_low, 1)).
helper(trust_order(low, 2)).
helper(trust_order(medium, 3)).
helper(trust_order(high, 4)).
helper(trust_order(very_high, 5)).


%% ============================================================
%% LOGGER — Explanation trace generator
%% ============================================================
%% Records all events for explainability (L-DINF execution trace)

:- agent(logger, [cycle(1)]).

log_eventE(Type, Source, Data) :>
    log("TRACE [~w] ~w: ~w", [Type, Source, Data]),
    assert_belief(logged(Type, Source, Data)).

%% Condition monitor: warn when many disruptions logged
when(believes(logged(disruption, _, _)), believes(logged(disruption, _, _))) :-
    findall(_, believes(logged(disruption, _, _)), Disruptions),
    length(Disruptions, N),
    N > 2,
    log("LOGGER WARNING: ~w disruptions recorded — system instability!", [N]).

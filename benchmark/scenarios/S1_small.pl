%% =============================================================================
%% L-DINF Healthcare Scheduling — Generated Scenario
%% =============================================================================
%% Clinics: 2, Doctors/clinic: 2, Patients: 2
%% Disruptions: 1, Equivalent actions: 3
%% Total agents: 10
%% Seed: 42
%% =============================================================================


%% === PATIENT_1 ===

:- agent(patient_1, [cycle(2)]).

believes(needs_consultation(t1)).
believes(member_of(clinic_a)).
believes(intend(consultation(t1))).
believes(assigned_doctor(doc_a_1)).
believes(assigned_clinic(clinic_a)).

believes(trust(doc_a_1, low)).
believes(trust(doc_a_2, high)).
believes(trust(doc_b_1, medium)).
believes(trust(doc_b_2, low)).

believes(pref_do(visit(doc_a_1), 2)).
believes(pref_do(visit(doc_a_2), 2)).
believes(pref_do(visit(doc_b_1), 3)).
believes(pref_do(visit(doc_b_2), 5)).

believes(success_prob(visit(doc_a_1), 0.65)).
believes(success_prob(visit(doc_a_2), 0.81)).
believes(success_prob(visit(doc_b_1), 0.79)).
believes(success_prob(visit(doc_b_2), 0.86)).

believes(action_cost(visit(doc_a_1), 7)).
believes(action_cost(visit(doc_a_2), 4)).
believes(action_cost(visit(doc_b_1), 8)).
believes(action_cost(visit(doc_b_2), 5)).
believes(budget(20)).

believes(trust_val(very_low, 1)).
believes(trust_val(low, 2)).
believes(trust_val(medium, 3)).
believes(trust_val(high, 4)).
believes(trust_val(very_high, 5)).

believes(trust_threshold_num(consultation, intention, 3)).
believes(trust_threshold_num(consultation, feasibility, 3)).
believes(trust_threshold_num(consultation, lending, 4)).
believes(trust_threshold_num(consultation, blocking, 1)).
believes(trust_threshold_num(consultation, autonomy, 4)).

believes(equivalent_action(consultation, visit_type_1)).
believes(equivalent_action(consultation, visit_type_2)).
believes(equivalent_action(consultation, visit_type_3)).

believes(action_data(visit_type_1, 0.92, 4, 7)).
believes(action_data(visit_type_2, 0.7, 4, 4)).
believes(action_data(visit_type_3, 0.96, 7, 2)).
believes(policy_weights(100, 10, 20)).
believes(pref_max(10)).

schedule_readyE :>
    log("patient_1: Baseline schedule loaded"),
    believes(intend(consultation(t1))),
    believes(assigned_doctor(Doc)),
    send(logger, log_event(schedule_loaded, patient_1, [consultation, t1, Doc])).

unavailableE(Doctor, TimeSlot) :>
    log("patient_1: DISRUPTION — ~w unavailable at ~w", [Doctor, TimeSlot]),
    assert_belief(unavailable(Doctor, TimeSlot)),
    retract_belief(assigned_doctor(Doctor)),
    send(logger, log_event(disruption, patient_1, [unavailable, Doctor, TimeSlot])),
    send(clinic_a_mgr, repair_request(patient_1, consultation, TimeSlot)).

local_repairE(Doctor, TimeSlot, TrustLevel, PrefDegree) :>
    log("patient_1: Local repair offered — ~w (trust=~w, pref=~w)", [Doctor, TrustLevel, PrefDegree]),
    believes(trust_val(TrustLevel, TrustNum)),
    believes(trust_threshold_num(consultation, autonomy, AutThr)),
    believes(trust_threshold_num(consultation, blocking, BlkThr)),
    (   TrustNum >= AutThr
    ->  assert_belief(assigned_doctor(Doctor)),
        retract_belief(intend(consultation(TimeSlot))),
        assert_belief(intend(consultation_with(Doctor, TimeSlot))),
        send(logger, log_event(decision, patient_1, [allow, Doctor, TimeSlot]))
    ;   TrustNum > BlkThr
    ->  send(logger, log_event(decision, patient_1, [delegate, Doctor, TimeSlot])),
        send(mediator, lending_request(patient_1, clinic_a, consultation, TimeSlot))
    ;   send(logger, log_event(decision, patient_1, [block, Doctor, TimeSlot]))
    ).

delegation_completeE(Doctor, TimeSlot) :>
    assert_belief(assigned_doctor(Doctor)),
    retract_belief(intend(consultation(TimeSlot))),
    assert_belief(intend(consultation_with(Doctor, TimeSlot))),
    send(logger, log_event(delegation_complete, patient_1, [Doctor, TimeSlot])).

consultation_doneE(Doctor, TimeSlot) :>
    assert_belief(done(consultation_with(Doctor, TimeSlot))),
    retract_belief(intend(consultation_with(Doctor, TimeSlot))),
    retract_belief(needs_consultation(TimeSlot)),
    send(logger, log_event(consultation_done, patient_1, [Doctor, TimeSlot])).

select_actionE(TimeSlot) :>
    log("patient_1: Probabilistic action selection"),
    send(logger, log_event(selector_start, patient_1, [consultation, TimeSlot])),
    believes(policy_weights(LR, LP, LC)),
    believes(pref_max(Pmax)),
    believes(budget(Budget)),
    findall(Score-Action, (
        believes(equivalent_action(consultation, Action)),
        believes(action_data(Action, Rho, Pref, Cost)),
        Cost =< Budget,
        Score is LR*Rho + LP*(Pref/Pmax) - LC*(Cost/Budget)
    ), ScoresRaw),
    sort(ScoresRaw, ScoresUniq),
    reverse(ScoresUniq, [BestScore-BestAction | _]),
    assert_belief(selected_action(BestAction, TimeSlot)),
    send(logger, log_event(prob_selection, patient_1, [BestAction, BestScore, TimeSlot])).

fallback_aspE(TimeSlot) :>
    send(logger, log_event(fallback, patient_1, [asp_reoptimization, TimeSlot])).


%% === PATIENT_2 ===

:- agent(patient_2, [cycle(2)]).

believes(needs_consultation(t2)).
believes(member_of(clinic_b)).
believes(intend(consultation(t2))).
believes(assigned_doctor(doc_b_2)).
believes(assigned_clinic(clinic_b)).

believes(trust(doc_a_1, low)).
believes(trust(doc_a_2, high)).
believes(trust(doc_b_1, medium)).
believes(trust(doc_b_2, low)).

believes(pref_do(visit(doc_a_1), 3)).
believes(pref_do(visit(doc_a_2), 8)).
believes(pref_do(visit(doc_b_1), 3)).
believes(pref_do(visit(doc_b_2), 7)).

believes(success_prob(visit(doc_a_1), 0.91)).
believes(success_prob(visit(doc_a_2), 0.81)).
believes(success_prob(visit(doc_b_1), 0.9)).
believes(success_prob(visit(doc_b_2), 0.86)).

believes(action_cost(visit(doc_a_1), 2)).
believes(action_cost(visit(doc_a_2), 7)).
believes(action_cost(visit(doc_b_1), 2)).
believes(action_cost(visit(doc_b_2), 5)).
believes(budget(18)).

believes(trust_val(very_low, 1)).
believes(trust_val(low, 2)).
believes(trust_val(medium, 3)).
believes(trust_val(high, 4)).
believes(trust_val(very_high, 5)).

believes(trust_threshold_num(consultation, intention, 3)).
believes(trust_threshold_num(consultation, feasibility, 3)).
believes(trust_threshold_num(consultation, lending, 4)).
believes(trust_threshold_num(consultation, blocking, 1)).
believes(trust_threshold_num(consultation, autonomy, 4)).

believes(equivalent_action(consultation, visit_type_1)).
believes(equivalent_action(consultation, visit_type_2)).
believes(equivalent_action(consultation, visit_type_3)).

believes(action_data(visit_type_1, 0.82, 7, 4)).
believes(action_data(visit_type_2, 0.85, 2, 4)).
believes(action_data(visit_type_3, 0.88, 3, 4)).
believes(policy_weights(100, 10, 20)).
believes(pref_max(10)).

schedule_readyE :>
    log("patient_2: Baseline schedule loaded"),
    believes(intend(consultation(t2))),
    believes(assigned_doctor(Doc)),
    send(logger, log_event(schedule_loaded, patient_2, [consultation, t2, Doc])).

unavailableE(Doctor, TimeSlot) :>
    log("patient_2: DISRUPTION — ~w unavailable at ~w", [Doctor, TimeSlot]),
    assert_belief(unavailable(Doctor, TimeSlot)),
    retract_belief(assigned_doctor(Doctor)),
    send(logger, log_event(disruption, patient_2, [unavailable, Doctor, TimeSlot])),
    send(clinic_b_mgr, repair_request(patient_2, consultation, TimeSlot)).

local_repairE(Doctor, TimeSlot, TrustLevel, PrefDegree) :>
    log("patient_2: Local repair offered — ~w (trust=~w, pref=~w)", [Doctor, TrustLevel, PrefDegree]),
    believes(trust_val(TrustLevel, TrustNum)),
    believes(trust_threshold_num(consultation, autonomy, AutThr)),
    believes(trust_threshold_num(consultation, blocking, BlkThr)),
    (   TrustNum >= AutThr
    ->  assert_belief(assigned_doctor(Doctor)),
        retract_belief(intend(consultation(TimeSlot))),
        assert_belief(intend(consultation_with(Doctor, TimeSlot))),
        send(logger, log_event(decision, patient_2, [allow, Doctor, TimeSlot]))
    ;   TrustNum > BlkThr
    ->  send(logger, log_event(decision, patient_2, [delegate, Doctor, TimeSlot])),
        send(mediator, lending_request(patient_2, clinic_b, consultation, TimeSlot))
    ;   send(logger, log_event(decision, patient_2, [block, Doctor, TimeSlot]))
    ).

delegation_completeE(Doctor, TimeSlot) :>
    assert_belief(assigned_doctor(Doctor)),
    retract_belief(intend(consultation(TimeSlot))),
    assert_belief(intend(consultation_with(Doctor, TimeSlot))),
    send(logger, log_event(delegation_complete, patient_2, [Doctor, TimeSlot])).

consultation_doneE(Doctor, TimeSlot) :>
    assert_belief(done(consultation_with(Doctor, TimeSlot))),
    retract_belief(intend(consultation_with(Doctor, TimeSlot))),
    retract_belief(needs_consultation(TimeSlot)),
    send(logger, log_event(consultation_done, patient_2, [Doctor, TimeSlot])).

select_actionE(TimeSlot) :>
    log("patient_2: Probabilistic action selection"),
    send(logger, log_event(selector_start, patient_2, [consultation, TimeSlot])),
    believes(policy_weights(LR, LP, LC)),
    believes(pref_max(Pmax)),
    believes(budget(Budget)),
    findall(Score-Action, (
        believes(equivalent_action(consultation, Action)),
        believes(action_data(Action, Rho, Pref, Cost)),
        Cost =< Budget,
        Score is LR*Rho + LP*(Pref/Pmax) - LC*(Cost/Budget)
    ), ScoresRaw),
    sort(ScoresRaw, ScoresUniq),
    reverse(ScoresUniq, [BestScore-BestAction | _]),
    assert_belief(selected_action(BestAction, TimeSlot)),
    send(logger, log_event(prob_selection, patient_2, [BestAction, BestScore, TimeSlot])).

fallback_aspE(TimeSlot) :>
    send(logger, log_event(fallback, patient_2, [asp_reoptimization, TimeSlot])).


%% === DOC_A_1 ===

:- agent(doc_a_1, [cycle(2)]).

believes(member_of(clinic_a)).
believes(role(doctor)).
believes(specialization(general_practice)).
believes(trust_level(low)).
believes(can_do(consultation, t1)).
believes(available(t1)).
believes(can_do(consultation, t2)).
believes(available(t2)).
believes(can_do(consultation, t3)).
believes(available(t3)).
believes(can_do(consultation, t4)).
believes(available(t4)).

become_unavailableE(TimeSlot) :>
    log("doc_a_1: Becoming unavailable at ~w", [TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    retract_belief(available(TimeSlot)),
    assert_belief(unavailable(TimeSlot)),
    send(clinic_a_mgr, doctor_unavailable(doc_a_1, TimeSlot)),
    send(logger, log_event(unavailability, doc_a_1, [TimeSlot])).

perform_consultationE(Patient, TimeSlot) :>
    believes(can_do(consultation, TimeSlot)),
    log("doc_a_1: Performing consultation for ~w at ~w", [Patient, TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    assert_belief(done(consultation, Patient, TimeSlot)),
    send(Patient, consultation_done(doc_a_1, TimeSlot)),
    send(logger, log_event(consultation, doc_a_1, [Patient, TimeSlot])),
    (   believes(temporarily_in(Clinic))
    ->  send(mediator, lending_task_done(doc_a_1, Clinic, TimeSlot))
    ;   true
    ).

lend_toE(RequestingClinic, Action, TimeSlot) :>
    believes(can_do(Action, TimeSlot)),
    believes(available(TimeSlot)),
    assert_belief(temporarily_in(RequestingClinic)),
    retract_belief(available(TimeSlot)),
    send(mediator, lending_accepted(doc_a_1, RequestingClinic, Action, TimeSlot)),
    send(logger, log_event(lending_accepted, doc_a_1, [RequestingClinic, Action, TimeSlot])).

return_to_groupE :>
    believes(temporarily_in(Clinic)),
    retract_belief(temporarily_in(Clinic)),
    send(logger, log_event(return_group, doc_a_1, [clinic_a])).


%% === DOC_A_2 ===

:- agent(doc_a_2, [cycle(2)]).

believes(member_of(clinic_a)).
believes(role(doctor)).
believes(specialization(general_practice)).
believes(trust_level(high)).
believes(can_do(consultation, t1)).
believes(available(t1)).
believes(can_do(consultation, t2)).
believes(available(t2)).
believes(can_do(consultation, t3)).
believes(available(t3)).
believes(can_do(consultation, t4)).
believes(available(t4)).

become_unavailableE(TimeSlot) :>
    log("doc_a_2: Becoming unavailable at ~w", [TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    retract_belief(available(TimeSlot)),
    assert_belief(unavailable(TimeSlot)),
    send(clinic_a_mgr, doctor_unavailable(doc_a_2, TimeSlot)),
    send(logger, log_event(unavailability, doc_a_2, [TimeSlot])).

perform_consultationE(Patient, TimeSlot) :>
    believes(can_do(consultation, TimeSlot)),
    log("doc_a_2: Performing consultation for ~w at ~w", [Patient, TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    assert_belief(done(consultation, Patient, TimeSlot)),
    send(Patient, consultation_done(doc_a_2, TimeSlot)),
    send(logger, log_event(consultation, doc_a_2, [Patient, TimeSlot])),
    (   believes(temporarily_in(Clinic))
    ->  send(mediator, lending_task_done(doc_a_2, Clinic, TimeSlot))
    ;   true
    ).

lend_toE(RequestingClinic, Action, TimeSlot) :>
    believes(can_do(Action, TimeSlot)),
    believes(available(TimeSlot)),
    assert_belief(temporarily_in(RequestingClinic)),
    retract_belief(available(TimeSlot)),
    send(mediator, lending_accepted(doc_a_2, RequestingClinic, Action, TimeSlot)),
    send(logger, log_event(lending_accepted, doc_a_2, [RequestingClinic, Action, TimeSlot])).

return_to_groupE :>
    believes(temporarily_in(Clinic)),
    retract_belief(temporarily_in(Clinic)),
    send(logger, log_event(return_group, doc_a_2, [clinic_a])).


%% === DOC_B_1 ===

:- agent(doc_b_1, [cycle(2)]).

believes(member_of(clinic_b)).
believes(role(doctor)).
believes(specialization(general_practice)).
believes(trust_level(medium)).
believes(can_do(consultation, t1)).
believes(available(t1)).
believes(can_do(consultation, t2)).
believes(available(t2)).
believes(can_do(consultation, t3)).
believes(available(t3)).
believes(can_do(consultation, t4)).
believes(available(t4)).

become_unavailableE(TimeSlot) :>
    log("doc_b_1: Becoming unavailable at ~w", [TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    retract_belief(available(TimeSlot)),
    assert_belief(unavailable(TimeSlot)),
    send(clinic_b_mgr, doctor_unavailable(doc_b_1, TimeSlot)),
    send(logger, log_event(unavailability, doc_b_1, [TimeSlot])).

perform_consultationE(Patient, TimeSlot) :>
    believes(can_do(consultation, TimeSlot)),
    log("doc_b_1: Performing consultation for ~w at ~w", [Patient, TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    assert_belief(done(consultation, Patient, TimeSlot)),
    send(Patient, consultation_done(doc_b_1, TimeSlot)),
    send(logger, log_event(consultation, doc_b_1, [Patient, TimeSlot])),
    (   believes(temporarily_in(Clinic))
    ->  send(mediator, lending_task_done(doc_b_1, Clinic, TimeSlot))
    ;   true
    ).

lend_toE(RequestingClinic, Action, TimeSlot) :>
    believes(can_do(Action, TimeSlot)),
    believes(available(TimeSlot)),
    assert_belief(temporarily_in(RequestingClinic)),
    retract_belief(available(TimeSlot)),
    send(mediator, lending_accepted(doc_b_1, RequestingClinic, Action, TimeSlot)),
    send(logger, log_event(lending_accepted, doc_b_1, [RequestingClinic, Action, TimeSlot])).

return_to_groupE :>
    believes(temporarily_in(Clinic)),
    retract_belief(temporarily_in(Clinic)),
    send(logger, log_event(return_group, doc_b_1, [clinic_b])).


%% === DOC_B_2 ===

:- agent(doc_b_2, [cycle(2)]).

believes(member_of(clinic_b)).
believes(role(doctor)).
believes(specialization(general_practice)).
believes(trust_level(low)).
believes(can_do(consultation, t1)).
believes(available(t1)).
believes(can_do(consultation, t2)).
believes(available(t2)).
believes(can_do(consultation, t3)).
believes(available(t3)).
believes(can_do(consultation, t4)).
believes(available(t4)).

become_unavailableE(TimeSlot) :>
    log("doc_b_2: Becoming unavailable at ~w", [TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    retract_belief(available(TimeSlot)),
    assert_belief(unavailable(TimeSlot)),
    send(clinic_b_mgr, doctor_unavailable(doc_b_2, TimeSlot)),
    send(logger, log_event(unavailability, doc_b_2, [TimeSlot])).

perform_consultationE(Patient, TimeSlot) :>
    believes(can_do(consultation, TimeSlot)),
    log("doc_b_2: Performing consultation for ~w at ~w", [Patient, TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    assert_belief(done(consultation, Patient, TimeSlot)),
    send(Patient, consultation_done(doc_b_2, TimeSlot)),
    send(logger, log_event(consultation, doc_b_2, [Patient, TimeSlot])),
    (   believes(temporarily_in(Clinic))
    ->  send(mediator, lending_task_done(doc_b_2, Clinic, TimeSlot))
    ;   true
    ).

lend_toE(RequestingClinic, Action, TimeSlot) :>
    believes(can_do(Action, TimeSlot)),
    believes(available(TimeSlot)),
    assert_belief(temporarily_in(RequestingClinic)),
    retract_belief(available(TimeSlot)),
    send(mediator, lending_accepted(doc_b_2, RequestingClinic, Action, TimeSlot)),
    send(logger, log_event(lending_accepted, doc_b_2, [RequestingClinic, Action, TimeSlot])).

return_to_groupE :>
    believes(temporarily_in(Clinic)),
    retract_belief(temporarily_in(Clinic)),
    send(logger, log_event(return_group, doc_b_2, [clinic_b])).


%% === CLINIC_A_MGR ===

:- agent(clinic_a_mgr, [cycle(1)]).

believes(member(clinic_a, doc_a_1)).
believes(member(clinic_a, doc_a_2)).
believes(member(clinic_a, patient_1)).

believes(doctor_trust(doc_a_1, low)).
believes(doctor_pref(doc_a_1, 2)).
believes(doctor_available(doc_a_1)).
believes(doctor_trust(doc_a_2, high)).
believes(doctor_pref(doc_a_2, 5)).
believes(doctor_available(doc_a_2)).

doctor_unavailableE(Doctor, TimeSlot) :>
    log("clinic_a_mgr: ~w unavailable at ~w", [Doctor, TimeSlot]),
    retract_belief(doctor_available(Doctor)),
    assert_belief(doctor_unavailable_at(Doctor, TimeSlot)),
    send(patient_1, unavailable(Doctor, TimeSlot)),
    send(logger, log_event(group_update, clinic_a_mgr, [unavailable, Doctor, TimeSlot])).

repair_requestE(Patient, Action, TimeSlot) :>
    findall(Pref-Doc-Trust, (
        believes(member(clinic_a, Doc)),
        believes(doctor_available(Doc)),
        believes(doctor_trust(Doc, Trust)),
        believes(doctor_pref(Doc, Pref))
    ), CandidatesRaw),
    sort(CandidatesRaw, CandidatesUniq),
    reverse(CandidatesUniq, Sorted),
    (   Sorted = [BestPref-BestDoc-BestTrust | _]
    ->  send(Patient, local_repair(BestDoc, TimeSlot, BestTrust, BestPref))
    ;   send(mediator, lending_request(Patient, clinic_a, Action, TimeSlot)),
        send(logger, log_event(no_local_repair, clinic_a_mgr, [Patient, TimeSlot]))
    ).

lending_inquiryE(RequestingClinic, Action, TimeSlot) :>
    findall(Doc-Trust, (
        believes(member(clinic_a, Doc)),
        believes(doctor_available(Doc)),
        believes(doctor_trust(Doc, Trust))
    ), AvailableRaw),
    sort(AvailableRaw, Available),
    (   Available = [BestDoc-BestTrust | _]
    ->  send(mediator, lending_offer(BestDoc, clinic_a, BestTrust, Action, TimeSlot))
    ;   send(mediator, lending_denied(clinic_a, Action, TimeSlot))
    ).


%% === CLINIC_B_MGR ===

:- agent(clinic_b_mgr, [cycle(1)]).

believes(member(clinic_b, doc_b_1)).
believes(member(clinic_b, doc_b_2)).
believes(member(clinic_b, patient_2)).

believes(doctor_trust(doc_b_1, medium)).
believes(doctor_pref(doc_b_1, 4)).
believes(doctor_available(doc_b_1)).
believes(doctor_trust(doc_b_2, low)).
believes(doctor_pref(doc_b_2, 10)).
believes(doctor_available(doc_b_2)).

doctor_unavailableE(Doctor, TimeSlot) :>
    log("clinic_b_mgr: ~w unavailable at ~w", [Doctor, TimeSlot]),
    retract_belief(doctor_available(Doctor)),
    assert_belief(doctor_unavailable_at(Doctor, TimeSlot)),
    send(patient_2, unavailable(Doctor, TimeSlot)),
    send(logger, log_event(group_update, clinic_b_mgr, [unavailable, Doctor, TimeSlot])).

repair_requestE(Patient, Action, TimeSlot) :>
    findall(Pref-Doc-Trust, (
        believes(member(clinic_b, Doc)),
        believes(doctor_available(Doc)),
        believes(doctor_trust(Doc, Trust)),
        believes(doctor_pref(Doc, Pref))
    ), CandidatesRaw),
    sort(CandidatesRaw, CandidatesUniq),
    reverse(CandidatesUniq, Sorted),
    (   Sorted = [BestPref-BestDoc-BestTrust | _]
    ->  send(Patient, local_repair(BestDoc, TimeSlot, BestTrust, BestPref))
    ;   send(mediator, lending_request(Patient, clinic_b, Action, TimeSlot)),
        send(logger, log_event(no_local_repair, clinic_b_mgr, [Patient, TimeSlot]))
    ).

lending_inquiryE(RequestingClinic, Action, TimeSlot) :>
    findall(Doc-Trust, (
        believes(member(clinic_b, Doc)),
        believes(doctor_available(Doc)),
        believes(doctor_trust(Doc, Trust))
    ), AvailableRaw),
    sort(AvailableRaw, Available),
    (   Available = [BestDoc-BestTrust | _]
    ->  send(mediator, lending_offer(BestDoc, clinic_b, BestTrust, Action, TimeSlot))
    ;   send(mediator, lending_denied(clinic_b, Action, TimeSlot))
    ).


%% === MEDIATOR ===

:- agent(mediator, [cycle(1)]).

believes(lending_threshold_num(consultation, 4)).

believes(trust_val(very_low, 1)).
believes(trust_val(low, 2)).
believes(trust_val(medium, 3)).
believes(trust_val(high, 4)).
believes(trust_val(very_high, 5)).

lending_requestE(Patient, RequestingClinic, Action, TimeSlot) :>
    assert_belief(pending_lending(Patient, RequestingClinic, Action, TimeSlot)),
    (   RequestingClinic \= clinic_a
    ->  send(clinic_a_mgr, lending_inquiry(RequestingClinic, Action, TimeSlot))
    ;   true
    ),
    (   RequestingClinic \= clinic_b
    ->  send(clinic_b_mgr, lending_inquiry(RequestingClinic, Action, TimeSlot))
    ;   true
    ),
    send(logger, log_event(lending_request, mediator, [Patient, RequestingClinic, Action, TimeSlot])).

lending_offerE(Doctor, SourceClinic, TrustLevel, Action, TimeSlot) :>
    (   believes(pending_lending(Patient, RequestingClinic, Action, TimeSlot))
    ->  believes(lending_threshold_num(Action, RequiredNum)),
        believes(trust_val(TrustLevel, TrustNum)),
        (   TrustNum >= RequiredNum
        ->  retract_belief(pending_lending(Patient, RequestingClinic, Action, TimeSlot)),
            assert_belief(active_lending(Doctor, SourceClinic, RequestingClinic, Patient, TimeSlot)),
            send(Doctor, lend_to(RequestingClinic, Action, TimeSlot)),
            send(logger, log_event(lending_approved, mediator, [Doctor, SourceClinic, RequestingClinic, TimeSlot]))
        ;   send(Patient, fallback_asp(TimeSlot)),
            send(logger, log_event(lending_denied, mediator, [Doctor, TrustLevel, RequiredNum]))
        )
    ;   true  %% already handled, ignore duplicate offer
    ).

lending_acceptedE(Doctor, RequestingClinic, Action, TimeSlot) :>
    believes(active_lending(Doctor, _, RequestingClinic, Patient, TimeSlot)),
    send(Patient, delegation_complete(Doctor, TimeSlot)),
    send(Doctor, perform_consultation(Patient, TimeSlot)),
    send(logger, log_event(lending_executed, mediator, [Doctor, RequestingClinic, TimeSlot])).

lending_task_doneE(Doctor, RequestingClinic, TimeSlot) :>
    (   believes(active_lending(Doctor, SourceClinic, RequestingClinic, _Patient, TimeSlot))
    ->  retract_belief(active_lending(Doctor, SourceClinic, RequestingClinic, _Patient, TimeSlot)),
        send(Doctor, return_to_group)
    ;   true
    ).

lending_deniedE(SourceClinic, Action, TimeSlot) :>
    believes(pending_lending(Patient, RequestingClinic, Action, TimeSlot)),
    retract_belief(pending_lending(Patient, RequestingClinic, Action, TimeSlot)),
    send(Patient, fallback_asp(TimeSlot)),
    send(logger, log_event(lending_failed, mediator, [SourceClinic, Action, TimeSlot])).


%% === LOGGER ===

:- agent(logger, [cycle(1)]).

log_eventE(Type, Source, Data) :>
    get_time(T),
    log("TRACE [~w] ~w: ~w @~6f", [Type, Source, Data, T]),
    assert_belief(logged(Type, Source, Data, T)).

believes(logged(disruption, _, _, _)) :< 
    \+ believes(warned_instability),
    findall(x, believes(logged(disruption, _, _, _)), Disruptions),
    length(Disruptions, N),
    N > 2,
    assert_belief(warned_instability),
    log("LOGGER WARNING: ~w disruptions recorded!", [N]).

compute_metricsE :>
    findall(T, believes(logged(disruption, _, _, T)), DispTimes),
    findall(T, believes(logged(consultation_done, _, _, T)), DoneTimes),
    findall(T, believes(logged(lending_approved, _, _, T)), LendTimes),
    findall(T, believes(logged(prob_selection, _, _, T)), SelTimes),
    findall(x, believes(logged(_, _, _, _)), AllEvents),
    length(AllEvents, TotalEvents),
    length(DispTimes, NumDisruptions),
    length(DoneTimes, NumRepairs),
    length(LendTimes, NumLendings),
    length(SelTimes, NumSelections),
    ( DispTimes = [DT0|_], DoneTimes \= []
    -> last(DoneTimes, DTLast),
       AvgRepairMs is (DTLast - DT0) * 1000
    ;  AvgRepairMs = 0
    ),
    ( NumDisruptions > 0
    -> LendingPct is (NumLendings / NumDisruptions) * 100
    ;  LendingPct = 0
    ),
    findall(T, believes(logged(selector_start, _, _, T)), SelStartTimes),
    findall(T, believes(logged(prob_selection, _, _, T)), SelEndTimes),
    ( SelStartTimes = [SS|_], SelEndTimes = [SE|_]
    -> SelectorMs is (SE - SS) * 1000
    ;  SelectorMs = 0
    ),
    assert_belief(metrics_summary(TotalEvents, NumDisruptions, NumRepairs,
                                  NumLendings, NumSelections, AvgRepairMs,
                                  LendingPct, SelectorMs)),
    log("METRICS: events=~w disruptions=~w repairs=~w lendings=~w selections=~w",
        [TotalEvents, NumDisruptions, NumRepairs, NumLendings, NumSelections]),
    log("METRICS: repair_ms=~2f lending_pct=~1f selector_ms=~3f",
        [AvgRepairMs, LendingPct, SelectorMs]).

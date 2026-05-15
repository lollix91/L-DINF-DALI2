%% =============================================================================
%% L-DINF Healthcare Scheduling — Generated Scenario
%% =============================================================================
%% Clinics: 4, Doctors/clinic: 3, Patients: 10
%% Disruptions: 8, Equivalent actions: 6
%% Total agents: 28
%% Seed: 45
%% =============================================================================


%% === PATIENT_1 ===

:- agent(patient_1, [cycle(2)]).

believes(needs_consultation(t1)).
believes(member_of(clinic_a)).
believes(intend(consultation(t1))).
believes(assigned_doctor(doc_a_1)).
believes(assigned_clinic(clinic_a)).

believes(trust(doc_a_1, high)).
believes(trust(doc_a_2, very_high)).
believes(trust(doc_a_3, low)).
believes(trust(doc_b_1, high)).
believes(trust(doc_b_2, low)).
believes(trust(doc_b_3, low)).
believes(trust(doc_c_1, high)).
believes(trust(doc_c_2, high)).
believes(trust(doc_c_3, low)).
believes(trust(doc_d_1, high)).
believes(trust(doc_d_2, medium)).
believes(trust(doc_d_3, low)).

believes(pref_do(visit(doc_a_1), 8)).
believes(pref_do(visit(doc_a_2), 3)).
believes(pref_do(visit(doc_a_3), 2)).
believes(pref_do(visit(doc_b_1), 7)).
believes(pref_do(visit(doc_b_2), 7)).
believes(pref_do(visit(doc_b_3), 8)).
believes(pref_do(visit(doc_c_1), 10)).
believes(pref_do(visit(doc_c_2), 10)).
believes(pref_do(visit(doc_c_3), 6)).
believes(pref_do(visit(doc_d_1), 2)).
believes(pref_do(visit(doc_d_2), 9)).
believes(pref_do(visit(doc_d_3), 7)).

believes(success_prob(visit(doc_a_1), 0.94)).
believes(success_prob(visit(doc_a_2), 0.7)).
believes(success_prob(visit(doc_a_3), 0.82)).
believes(success_prob(visit(doc_b_1), 0.56)).
believes(success_prob(visit(doc_b_2), 0.76)).
believes(success_prob(visit(doc_b_3), 0.82)).
believes(success_prob(visit(doc_c_1), 0.68)).
believes(success_prob(visit(doc_c_2), 0.73)).
believes(success_prob(visit(doc_c_3), 0.91)).
believes(success_prob(visit(doc_d_1), 0.61)).
believes(success_prob(visit(doc_d_2), 0.75)).
believes(success_prob(visit(doc_d_3), 0.59)).

believes(action_cost(visit(doc_a_1), 7)).
believes(action_cost(visit(doc_a_2), 1)).
believes(action_cost(visit(doc_a_3), 1)).
believes(action_cost(visit(doc_b_1), 5)).
believes(action_cost(visit(doc_b_2), 6)).
believes(action_cost(visit(doc_b_3), 5)).
believes(action_cost(visit(doc_c_1), 3)).
believes(action_cost(visit(doc_c_2), 3)).
believes(action_cost(visit(doc_c_3), 1)).
believes(action_cost(visit(doc_d_1), 5)).
believes(action_cost(visit(doc_d_2), 1)).
believes(action_cost(visit(doc_d_3), 7)).
believes(budget(9)).

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
believes(equivalent_action(consultation, visit_type_4)).
believes(equivalent_action(consultation, visit_type_5)).
believes(equivalent_action(consultation, visit_type_6)).

believes(action_data(visit_type_1, 0.55, 7, 5)).
believes(action_data(visit_type_2, 0.75, 5, 6)).
believes(action_data(visit_type_3, 0.67, 5, 4)).
believes(action_data(visit_type_4, 0.76, 4, 1)).
believes(action_data(visit_type_5, 0.81, 6, 8)).
believes(action_data(visit_type_6, 0.59, 5, 2)).
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

believes(trust(doc_a_1, high)).
believes(trust(doc_a_2, very_high)).
believes(trust(doc_a_3, low)).
believes(trust(doc_b_1, high)).
believes(trust(doc_b_2, low)).
believes(trust(doc_b_3, low)).
believes(trust(doc_c_1, high)).
believes(trust(doc_c_2, high)).
believes(trust(doc_c_3, low)).
believes(trust(doc_d_1, high)).
believes(trust(doc_d_2, medium)).
believes(trust(doc_d_3, low)).

believes(pref_do(visit(doc_a_1), 3)).
believes(pref_do(visit(doc_a_2), 3)).
believes(pref_do(visit(doc_a_3), 4)).
believes(pref_do(visit(doc_b_1), 8)).
believes(pref_do(visit(doc_b_2), 4)).
believes(pref_do(visit(doc_b_3), 3)).
believes(pref_do(visit(doc_c_1), 9)).
believes(pref_do(visit(doc_c_2), 8)).
believes(pref_do(visit(doc_c_3), 6)).
believes(pref_do(visit(doc_d_1), 8)).
believes(pref_do(visit(doc_d_2), 8)).
believes(pref_do(visit(doc_d_3), 8)).

believes(success_prob(visit(doc_a_1), 0.62)).
believes(success_prob(visit(doc_a_2), 0.78)).
believes(success_prob(visit(doc_a_3), 0.56)).
believes(success_prob(visit(doc_b_1), 0.69)).
believes(success_prob(visit(doc_b_2), 0.83)).
believes(success_prob(visit(doc_b_3), 0.97)).
believes(success_prob(visit(doc_c_1), 0.73)).
believes(success_prob(visit(doc_c_2), 0.69)).
believes(success_prob(visit(doc_c_3), 0.74)).
believes(success_prob(visit(doc_d_1), 0.8)).
believes(success_prob(visit(doc_d_2), 0.9)).
believes(success_prob(visit(doc_d_3), 0.95)).

believes(action_cost(visit(doc_a_1), 1)).
believes(action_cost(visit(doc_a_2), 7)).
believes(action_cost(visit(doc_a_3), 1)).
believes(action_cost(visit(doc_b_1), 8)).
believes(action_cost(visit(doc_b_2), 1)).
believes(action_cost(visit(doc_b_3), 4)).
believes(action_cost(visit(doc_c_1), 4)).
believes(action_cost(visit(doc_c_2), 4)).
believes(action_cost(visit(doc_c_3), 1)).
believes(action_cost(visit(doc_d_1), 1)).
believes(action_cost(visit(doc_d_2), 2)).
believes(action_cost(visit(doc_d_3), 6)).
believes(budget(17)).

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
believes(equivalent_action(consultation, visit_type_4)).
believes(equivalent_action(consultation, visit_type_5)).
believes(equivalent_action(consultation, visit_type_6)).

believes(action_data(visit_type_1, 0.83, 7, 8)).
believes(action_data(visit_type_2, 0.9, 8, 1)).
believes(action_data(visit_type_3, 0.86, 8, 8)).
believes(action_data(visit_type_4, 0.87, 8, 1)).
believes(action_data(visit_type_5, 0.72, 8, 1)).
believes(action_data(visit_type_6, 0.59, 6, 2)).
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


%% === PATIENT_3 ===

:- agent(patient_3, [cycle(2)]).

believes(needs_consultation(t3)).
believes(member_of(clinic_c)).
believes(intend(consultation(t3))).
believes(assigned_doctor(doc_c_3)).
believes(assigned_clinic(clinic_c)).

believes(trust(doc_a_1, high)).
believes(trust(doc_a_2, very_high)).
believes(trust(doc_a_3, low)).
believes(trust(doc_b_1, high)).
believes(trust(doc_b_2, low)).
believes(trust(doc_b_3, low)).
believes(trust(doc_c_1, high)).
believes(trust(doc_c_2, high)).
believes(trust(doc_c_3, low)).
believes(trust(doc_d_1, high)).
believes(trust(doc_d_2, medium)).
believes(trust(doc_d_3, low)).

believes(pref_do(visit(doc_a_1), 10)).
believes(pref_do(visit(doc_a_2), 4)).
believes(pref_do(visit(doc_a_3), 8)).
believes(pref_do(visit(doc_b_1), 7)).
believes(pref_do(visit(doc_b_2), 5)).
believes(pref_do(visit(doc_b_3), 2)).
believes(pref_do(visit(doc_c_1), 8)).
believes(pref_do(visit(doc_c_2), 7)).
believes(pref_do(visit(doc_c_3), 4)).
believes(pref_do(visit(doc_d_1), 3)).
believes(pref_do(visit(doc_d_2), 8)).
believes(pref_do(visit(doc_d_3), 3)).

believes(success_prob(visit(doc_a_1), 0.91)).
believes(success_prob(visit(doc_a_2), 0.78)).
believes(success_prob(visit(doc_a_3), 0.61)).
believes(success_prob(visit(doc_b_1), 0.87)).
believes(success_prob(visit(doc_b_2), 0.65)).
believes(success_prob(visit(doc_b_3), 0.59)).
believes(success_prob(visit(doc_c_1), 0.55)).
believes(success_prob(visit(doc_c_2), 0.61)).
believes(success_prob(visit(doc_c_3), 0.68)).
believes(success_prob(visit(doc_d_1), 0.83)).
believes(success_prob(visit(doc_d_2), 0.9)).
believes(success_prob(visit(doc_d_3), 0.79)).

believes(action_cost(visit(doc_a_1), 3)).
believes(action_cost(visit(doc_a_2), 6)).
believes(action_cost(visit(doc_a_3), 7)).
believes(action_cost(visit(doc_b_1), 5)).
believes(action_cost(visit(doc_b_2), 7)).
believes(action_cost(visit(doc_b_3), 4)).
believes(action_cost(visit(doc_c_1), 1)).
believes(action_cost(visit(doc_c_2), 4)).
believes(action_cost(visit(doc_c_3), 2)).
believes(action_cost(visit(doc_d_1), 2)).
believes(action_cost(visit(doc_d_2), 1)).
believes(action_cost(visit(doc_d_3), 8)).
believes(budget(8)).

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
believes(equivalent_action(consultation, visit_type_4)).
believes(equivalent_action(consultation, visit_type_5)).
believes(equivalent_action(consultation, visit_type_6)).

believes(action_data(visit_type_1, 0.81, 10, 6)).
believes(action_data(visit_type_2, 0.69, 10, 5)).
believes(action_data(visit_type_3, 0.67, 2, 7)).
believes(action_data(visit_type_4, 0.94, 4, 8)).
believes(action_data(visit_type_5, 0.78, 5, 2)).
believes(action_data(visit_type_6, 0.89, 4, 8)).
believes(policy_weights(100, 10, 20)).
believes(pref_max(10)).

schedule_readyE :>
    log("patient_3: Baseline schedule loaded"),
    believes(intend(consultation(t3))),
    believes(assigned_doctor(Doc)),
    send(logger, log_event(schedule_loaded, patient_3, [consultation, t3, Doc])).

unavailableE(Doctor, TimeSlot) :>
    log("patient_3: DISRUPTION — ~w unavailable at ~w", [Doctor, TimeSlot]),
    assert_belief(unavailable(Doctor, TimeSlot)),
    retract_belief(assigned_doctor(Doctor)),
    send(logger, log_event(disruption, patient_3, [unavailable, Doctor, TimeSlot])),
    send(clinic_c_mgr, repair_request(patient_3, consultation, TimeSlot)).

local_repairE(Doctor, TimeSlot, TrustLevel, PrefDegree) :>
    log("patient_3: Local repair offered — ~w (trust=~w, pref=~w)", [Doctor, TrustLevel, PrefDegree]),
    believes(trust_val(TrustLevel, TrustNum)),
    believes(trust_threshold_num(consultation, autonomy, AutThr)),
    believes(trust_threshold_num(consultation, blocking, BlkThr)),
    (   TrustNum >= AutThr
    ->  assert_belief(assigned_doctor(Doctor)),
        retract_belief(intend(consultation(TimeSlot))),
        assert_belief(intend(consultation_with(Doctor, TimeSlot))),
        send(logger, log_event(decision, patient_3, [allow, Doctor, TimeSlot]))
    ;   TrustNum > BlkThr
    ->  send(logger, log_event(decision, patient_3, [delegate, Doctor, TimeSlot])),
        send(mediator, lending_request(patient_3, clinic_c, consultation, TimeSlot))
    ;   send(logger, log_event(decision, patient_3, [block, Doctor, TimeSlot]))
    ).

delegation_completeE(Doctor, TimeSlot) :>
    assert_belief(assigned_doctor(Doctor)),
    retract_belief(intend(consultation(TimeSlot))),
    assert_belief(intend(consultation_with(Doctor, TimeSlot))),
    send(logger, log_event(delegation_complete, patient_3, [Doctor, TimeSlot])).

consultation_doneE(Doctor, TimeSlot) :>
    assert_belief(done(consultation_with(Doctor, TimeSlot))),
    retract_belief(intend(consultation_with(Doctor, TimeSlot))),
    retract_belief(needs_consultation(TimeSlot)),
    send(logger, log_event(consultation_done, patient_3, [Doctor, TimeSlot])).

select_actionE(TimeSlot) :>
    log("patient_3: Probabilistic action selection"),
    send(logger, log_event(selector_start, patient_3, [consultation, TimeSlot])),
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
    send(logger, log_event(prob_selection, patient_3, [BestAction, BestScore, TimeSlot])).

fallback_aspE(TimeSlot) :>
    send(logger, log_event(fallback, patient_3, [asp_reoptimization, TimeSlot])).


%% === PATIENT_4 ===

:- agent(patient_4, [cycle(2)]).

believes(needs_consultation(t4)).
believes(member_of(clinic_d)).
believes(intend(consultation(t4))).
believes(assigned_doctor(doc_d_1)).
believes(assigned_clinic(clinic_d)).

believes(trust(doc_a_1, high)).
believes(trust(doc_a_2, very_high)).
believes(trust(doc_a_3, low)).
believes(trust(doc_b_1, high)).
believes(trust(doc_b_2, low)).
believes(trust(doc_b_3, low)).
believes(trust(doc_c_1, high)).
believes(trust(doc_c_2, high)).
believes(trust(doc_c_3, low)).
believes(trust(doc_d_1, high)).
believes(trust(doc_d_2, medium)).
believes(trust(doc_d_3, low)).

believes(pref_do(visit(doc_a_1), 10)).
believes(pref_do(visit(doc_a_2), 9)).
believes(pref_do(visit(doc_a_3), 3)).
believes(pref_do(visit(doc_b_1), 3)).
believes(pref_do(visit(doc_b_2), 10)).
believes(pref_do(visit(doc_b_3), 8)).
believes(pref_do(visit(doc_c_1), 7)).
believes(pref_do(visit(doc_c_2), 5)).
believes(pref_do(visit(doc_c_3), 10)).
believes(pref_do(visit(doc_d_1), 7)).
believes(pref_do(visit(doc_d_2), 4)).
believes(pref_do(visit(doc_d_3), 8)).

believes(success_prob(visit(doc_a_1), 0.6)).
believes(success_prob(visit(doc_a_2), 0.98)).
believes(success_prob(visit(doc_a_3), 0.78)).
believes(success_prob(visit(doc_b_1), 0.82)).
believes(success_prob(visit(doc_b_2), 0.85)).
believes(success_prob(visit(doc_b_3), 0.73)).
believes(success_prob(visit(doc_c_1), 0.72)).
believes(success_prob(visit(doc_c_2), 0.92)).
believes(success_prob(visit(doc_c_3), 0.82)).
believes(success_prob(visit(doc_d_1), 0.56)).
believes(success_prob(visit(doc_d_2), 0.57)).
believes(success_prob(visit(doc_d_3), 0.91)).

believes(action_cost(visit(doc_a_1), 8)).
believes(action_cost(visit(doc_a_2), 8)).
believes(action_cost(visit(doc_a_3), 6)).
believes(action_cost(visit(doc_b_1), 3)).
believes(action_cost(visit(doc_b_2), 6)).
believes(action_cost(visit(doc_b_3), 1)).
believes(action_cost(visit(doc_c_1), 6)).
believes(action_cost(visit(doc_c_2), 5)).
believes(action_cost(visit(doc_c_3), 4)).
believes(action_cost(visit(doc_d_1), 3)).
believes(action_cost(visit(doc_d_2), 5)).
believes(action_cost(visit(doc_d_3), 1)).
believes(budget(12)).

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
believes(equivalent_action(consultation, visit_type_4)).
believes(equivalent_action(consultation, visit_type_5)).
believes(equivalent_action(consultation, visit_type_6)).

believes(action_data(visit_type_1, 0.95, 10, 3)).
believes(action_data(visit_type_2, 0.7, 6, 7)).
believes(action_data(visit_type_3, 0.59, 4, 2)).
believes(action_data(visit_type_4, 0.91, 8, 7)).
believes(action_data(visit_type_5, 0.87, 6, 5)).
believes(action_data(visit_type_6, 0.91, 4, 7)).
believes(policy_weights(100, 10, 20)).
believes(pref_max(10)).

schedule_readyE :>
    log("patient_4: Baseline schedule loaded"),
    believes(intend(consultation(t4))),
    believes(assigned_doctor(Doc)),
    send(logger, log_event(schedule_loaded, patient_4, [consultation, t4, Doc])).

unavailableE(Doctor, TimeSlot) :>
    log("patient_4: DISRUPTION — ~w unavailable at ~w", [Doctor, TimeSlot]),
    assert_belief(unavailable(Doctor, TimeSlot)),
    retract_belief(assigned_doctor(Doctor)),
    send(logger, log_event(disruption, patient_4, [unavailable, Doctor, TimeSlot])),
    send(clinic_d_mgr, repair_request(patient_4, consultation, TimeSlot)).

local_repairE(Doctor, TimeSlot, TrustLevel, PrefDegree) :>
    log("patient_4: Local repair offered — ~w (trust=~w, pref=~w)", [Doctor, TrustLevel, PrefDegree]),
    believes(trust_val(TrustLevel, TrustNum)),
    believes(trust_threshold_num(consultation, autonomy, AutThr)),
    believes(trust_threshold_num(consultation, blocking, BlkThr)),
    (   TrustNum >= AutThr
    ->  assert_belief(assigned_doctor(Doctor)),
        retract_belief(intend(consultation(TimeSlot))),
        assert_belief(intend(consultation_with(Doctor, TimeSlot))),
        send(logger, log_event(decision, patient_4, [allow, Doctor, TimeSlot]))
    ;   TrustNum > BlkThr
    ->  send(logger, log_event(decision, patient_4, [delegate, Doctor, TimeSlot])),
        send(mediator, lending_request(patient_4, clinic_d, consultation, TimeSlot))
    ;   send(logger, log_event(decision, patient_4, [block, Doctor, TimeSlot]))
    ).

delegation_completeE(Doctor, TimeSlot) :>
    assert_belief(assigned_doctor(Doctor)),
    retract_belief(intend(consultation(TimeSlot))),
    assert_belief(intend(consultation_with(Doctor, TimeSlot))),
    send(logger, log_event(delegation_complete, patient_4, [Doctor, TimeSlot])).

consultation_doneE(Doctor, TimeSlot) :>
    assert_belief(done(consultation_with(Doctor, TimeSlot))),
    retract_belief(intend(consultation_with(Doctor, TimeSlot))),
    retract_belief(needs_consultation(TimeSlot)),
    send(logger, log_event(consultation_done, patient_4, [Doctor, TimeSlot])).

select_actionE(TimeSlot) :>
    log("patient_4: Probabilistic action selection"),
    send(logger, log_event(selector_start, patient_4, [consultation, TimeSlot])),
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
    send(logger, log_event(prob_selection, patient_4, [BestAction, BestScore, TimeSlot])).

fallback_aspE(TimeSlot) :>
    send(logger, log_event(fallback, patient_4, [asp_reoptimization, TimeSlot])).


%% === PATIENT_5 ===

:- agent(patient_5, [cycle(2)]).

believes(needs_consultation(t5)).
believes(member_of(clinic_a)).
believes(intend(consultation(t5))).
believes(assigned_doctor(doc_a_2)).
believes(assigned_clinic(clinic_a)).

believes(trust(doc_a_1, high)).
believes(trust(doc_a_2, very_high)).
believes(trust(doc_a_3, low)).
believes(trust(doc_b_1, high)).
believes(trust(doc_b_2, low)).
believes(trust(doc_b_3, low)).
believes(trust(doc_c_1, high)).
believes(trust(doc_c_2, high)).
believes(trust(doc_c_3, low)).
believes(trust(doc_d_1, high)).
believes(trust(doc_d_2, medium)).
believes(trust(doc_d_3, low)).

believes(pref_do(visit(doc_a_1), 7)).
believes(pref_do(visit(doc_a_2), 4)).
believes(pref_do(visit(doc_a_3), 9)).
believes(pref_do(visit(doc_b_1), 9)).
believes(pref_do(visit(doc_b_2), 8)).
believes(pref_do(visit(doc_b_3), 10)).
believes(pref_do(visit(doc_c_1), 8)).
believes(pref_do(visit(doc_c_2), 4)).
believes(pref_do(visit(doc_c_3), 9)).
believes(pref_do(visit(doc_d_1), 3)).
believes(pref_do(visit(doc_d_2), 6)).
believes(pref_do(visit(doc_d_3), 3)).

believes(success_prob(visit(doc_a_1), 0.66)).
believes(success_prob(visit(doc_a_2), 0.59)).
believes(success_prob(visit(doc_a_3), 0.66)).
believes(success_prob(visit(doc_b_1), 0.87)).
believes(success_prob(visit(doc_b_2), 0.93)).
believes(success_prob(visit(doc_b_3), 0.92)).
believes(success_prob(visit(doc_c_1), 0.63)).
believes(success_prob(visit(doc_c_2), 0.92)).
believes(success_prob(visit(doc_c_3), 0.96)).
believes(success_prob(visit(doc_d_1), 0.95)).
believes(success_prob(visit(doc_d_2), 0.59)).
believes(success_prob(visit(doc_d_3), 0.86)).

believes(action_cost(visit(doc_a_1), 7)).
believes(action_cost(visit(doc_a_2), 4)).
believes(action_cost(visit(doc_a_3), 8)).
believes(action_cost(visit(doc_b_1), 7)).
believes(action_cost(visit(doc_b_2), 3)).
believes(action_cost(visit(doc_b_3), 5)).
believes(action_cost(visit(doc_c_1), 6)).
believes(action_cost(visit(doc_c_2), 8)).
believes(action_cost(visit(doc_c_3), 1)).
believes(action_cost(visit(doc_d_1), 5)).
believes(action_cost(visit(doc_d_2), 4)).
believes(action_cost(visit(doc_d_3), 7)).
believes(budget(15)).

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
believes(equivalent_action(consultation, visit_type_4)).
believes(equivalent_action(consultation, visit_type_5)).
believes(equivalent_action(consultation, visit_type_6)).

believes(action_data(visit_type_1, 0.97, 10, 2)).
believes(action_data(visit_type_2, 0.83, 4, 8)).
believes(action_data(visit_type_3, 0.89, 7, 6)).
believes(action_data(visit_type_4, 0.85, 7, 4)).
believes(action_data(visit_type_5, 0.7, 5, 5)).
believes(action_data(visit_type_6, 0.9, 4, 3)).
believes(policy_weights(100, 10, 20)).
believes(pref_max(10)).

schedule_readyE :>
    log("patient_5: Baseline schedule loaded"),
    believes(intend(consultation(t5))),
    believes(assigned_doctor(Doc)),
    send(logger, log_event(schedule_loaded, patient_5, [consultation, t5, Doc])).

unavailableE(Doctor, TimeSlot) :>
    log("patient_5: DISRUPTION — ~w unavailable at ~w", [Doctor, TimeSlot]),
    assert_belief(unavailable(Doctor, TimeSlot)),
    retract_belief(assigned_doctor(Doctor)),
    send(logger, log_event(disruption, patient_5, [unavailable, Doctor, TimeSlot])),
    send(clinic_a_mgr, repair_request(patient_5, consultation, TimeSlot)).

local_repairE(Doctor, TimeSlot, TrustLevel, PrefDegree) :>
    log("patient_5: Local repair offered — ~w (trust=~w, pref=~w)", [Doctor, TrustLevel, PrefDegree]),
    believes(trust_val(TrustLevel, TrustNum)),
    believes(trust_threshold_num(consultation, autonomy, AutThr)),
    believes(trust_threshold_num(consultation, blocking, BlkThr)),
    (   TrustNum >= AutThr
    ->  assert_belief(assigned_doctor(Doctor)),
        retract_belief(intend(consultation(TimeSlot))),
        assert_belief(intend(consultation_with(Doctor, TimeSlot))),
        send(logger, log_event(decision, patient_5, [allow, Doctor, TimeSlot]))
    ;   TrustNum > BlkThr
    ->  send(logger, log_event(decision, patient_5, [delegate, Doctor, TimeSlot])),
        send(mediator, lending_request(patient_5, clinic_a, consultation, TimeSlot))
    ;   send(logger, log_event(decision, patient_5, [block, Doctor, TimeSlot]))
    ).

delegation_completeE(Doctor, TimeSlot) :>
    assert_belief(assigned_doctor(Doctor)),
    retract_belief(intend(consultation(TimeSlot))),
    assert_belief(intend(consultation_with(Doctor, TimeSlot))),
    send(logger, log_event(delegation_complete, patient_5, [Doctor, TimeSlot])).

consultation_doneE(Doctor, TimeSlot) :>
    assert_belief(done(consultation_with(Doctor, TimeSlot))),
    retract_belief(intend(consultation_with(Doctor, TimeSlot))),
    retract_belief(needs_consultation(TimeSlot)),
    send(logger, log_event(consultation_done, patient_5, [Doctor, TimeSlot])).

select_actionE(TimeSlot) :>
    log("patient_5: Probabilistic action selection"),
    send(logger, log_event(selector_start, patient_5, [consultation, TimeSlot])),
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
    send(logger, log_event(prob_selection, patient_5, [BestAction, BestScore, TimeSlot])).

fallback_aspE(TimeSlot) :>
    send(logger, log_event(fallback, patient_5, [asp_reoptimization, TimeSlot])).


%% === PATIENT_6 ===

:- agent(patient_6, [cycle(2)]).

believes(needs_consultation(t6)).
believes(member_of(clinic_b)).
believes(intend(consultation(t6))).
believes(assigned_doctor(doc_b_3)).
believes(assigned_clinic(clinic_b)).

believes(trust(doc_a_1, high)).
believes(trust(doc_a_2, very_high)).
believes(trust(doc_a_3, low)).
believes(trust(doc_b_1, high)).
believes(trust(doc_b_2, low)).
believes(trust(doc_b_3, low)).
believes(trust(doc_c_1, high)).
believes(trust(doc_c_2, high)).
believes(trust(doc_c_3, low)).
believes(trust(doc_d_1, high)).
believes(trust(doc_d_2, medium)).
believes(trust(doc_d_3, low)).

believes(pref_do(visit(doc_a_1), 2)).
believes(pref_do(visit(doc_a_2), 4)).
believes(pref_do(visit(doc_a_3), 9)).
believes(pref_do(visit(doc_b_1), 6)).
believes(pref_do(visit(doc_b_2), 9)).
believes(pref_do(visit(doc_b_3), 10)).
believes(pref_do(visit(doc_c_1), 7)).
believes(pref_do(visit(doc_c_2), 6)).
believes(pref_do(visit(doc_c_3), 3)).
believes(pref_do(visit(doc_d_1), 3)).
believes(pref_do(visit(doc_d_2), 10)).
believes(pref_do(visit(doc_d_3), 5)).

believes(success_prob(visit(doc_a_1), 0.89)).
believes(success_prob(visit(doc_a_2), 0.88)).
believes(success_prob(visit(doc_a_3), 0.69)).
believes(success_prob(visit(doc_b_1), 0.97)).
believes(success_prob(visit(doc_b_2), 0.66)).
believes(success_prob(visit(doc_b_3), 0.63)).
believes(success_prob(visit(doc_c_1), 0.79)).
believes(success_prob(visit(doc_c_2), 0.79)).
believes(success_prob(visit(doc_c_3), 0.77)).
believes(success_prob(visit(doc_d_1), 0.95)).
believes(success_prob(visit(doc_d_2), 0.87)).
believes(success_prob(visit(doc_d_3), 0.97)).

believes(action_cost(visit(doc_a_1), 5)).
believes(action_cost(visit(doc_a_2), 5)).
believes(action_cost(visit(doc_a_3), 6)).
believes(action_cost(visit(doc_b_1), 1)).
believes(action_cost(visit(doc_b_2), 8)).
believes(action_cost(visit(doc_b_3), 1)).
believes(action_cost(visit(doc_c_1), 3)).
believes(action_cost(visit(doc_c_2), 8)).
believes(action_cost(visit(doc_c_3), 1)).
believes(action_cost(visit(doc_d_1), 6)).
believes(action_cost(visit(doc_d_2), 4)).
believes(action_cost(visit(doc_d_3), 6)).
believes(budget(16)).

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
believes(equivalent_action(consultation, visit_type_4)).
believes(equivalent_action(consultation, visit_type_5)).
believes(equivalent_action(consultation, visit_type_6)).

believes(action_data(visit_type_1, 0.66, 3, 4)).
believes(action_data(visit_type_2, 0.76, 9, 4)).
believes(action_data(visit_type_3, 0.84, 6, 3)).
believes(action_data(visit_type_4, 0.65, 4, 3)).
believes(action_data(visit_type_5, 0.76, 4, 4)).
believes(action_data(visit_type_6, 0.88, 9, 8)).
believes(policy_weights(100, 10, 20)).
believes(pref_max(10)).

schedule_readyE :>
    log("patient_6: Baseline schedule loaded"),
    believes(intend(consultation(t6))),
    believes(assigned_doctor(Doc)),
    send(logger, log_event(schedule_loaded, patient_6, [consultation, t6, Doc])).

unavailableE(Doctor, TimeSlot) :>
    log("patient_6: DISRUPTION — ~w unavailable at ~w", [Doctor, TimeSlot]),
    assert_belief(unavailable(Doctor, TimeSlot)),
    retract_belief(assigned_doctor(Doctor)),
    send(logger, log_event(disruption, patient_6, [unavailable, Doctor, TimeSlot])),
    send(clinic_b_mgr, repair_request(patient_6, consultation, TimeSlot)).

local_repairE(Doctor, TimeSlot, TrustLevel, PrefDegree) :>
    log("patient_6: Local repair offered — ~w (trust=~w, pref=~w)", [Doctor, TrustLevel, PrefDegree]),
    believes(trust_val(TrustLevel, TrustNum)),
    believes(trust_threshold_num(consultation, autonomy, AutThr)),
    believes(trust_threshold_num(consultation, blocking, BlkThr)),
    (   TrustNum >= AutThr
    ->  assert_belief(assigned_doctor(Doctor)),
        retract_belief(intend(consultation(TimeSlot))),
        assert_belief(intend(consultation_with(Doctor, TimeSlot))),
        send(logger, log_event(decision, patient_6, [allow, Doctor, TimeSlot]))
    ;   TrustNum > BlkThr
    ->  send(logger, log_event(decision, patient_6, [delegate, Doctor, TimeSlot])),
        send(mediator, lending_request(patient_6, clinic_b, consultation, TimeSlot))
    ;   send(logger, log_event(decision, patient_6, [block, Doctor, TimeSlot]))
    ).

delegation_completeE(Doctor, TimeSlot) :>
    assert_belief(assigned_doctor(Doctor)),
    retract_belief(intend(consultation(TimeSlot))),
    assert_belief(intend(consultation_with(Doctor, TimeSlot))),
    send(logger, log_event(delegation_complete, patient_6, [Doctor, TimeSlot])).

consultation_doneE(Doctor, TimeSlot) :>
    assert_belief(done(consultation_with(Doctor, TimeSlot))),
    retract_belief(intend(consultation_with(Doctor, TimeSlot))),
    retract_belief(needs_consultation(TimeSlot)),
    send(logger, log_event(consultation_done, patient_6, [Doctor, TimeSlot])).

select_actionE(TimeSlot) :>
    log("patient_6: Probabilistic action selection"),
    send(logger, log_event(selector_start, patient_6, [consultation, TimeSlot])),
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
    send(logger, log_event(prob_selection, patient_6, [BestAction, BestScore, TimeSlot])).

fallback_aspE(TimeSlot) :>
    send(logger, log_event(fallback, patient_6, [asp_reoptimization, TimeSlot])).


%% === PATIENT_7 ===

:- agent(patient_7, [cycle(2)]).

believes(needs_consultation(t7)).
believes(member_of(clinic_c)).
believes(intend(consultation(t7))).
believes(assigned_doctor(doc_c_1)).
believes(assigned_clinic(clinic_c)).

believes(trust(doc_a_1, high)).
believes(trust(doc_a_2, very_high)).
believes(trust(doc_a_3, low)).
believes(trust(doc_b_1, high)).
believes(trust(doc_b_2, low)).
believes(trust(doc_b_3, low)).
believes(trust(doc_c_1, high)).
believes(trust(doc_c_2, high)).
believes(trust(doc_c_3, low)).
believes(trust(doc_d_1, high)).
believes(trust(doc_d_2, medium)).
believes(trust(doc_d_3, low)).

believes(pref_do(visit(doc_a_1), 9)).
believes(pref_do(visit(doc_a_2), 8)).
believes(pref_do(visit(doc_a_3), 6)).
believes(pref_do(visit(doc_b_1), 10)).
believes(pref_do(visit(doc_b_2), 8)).
believes(pref_do(visit(doc_b_3), 8)).
believes(pref_do(visit(doc_c_1), 5)).
believes(pref_do(visit(doc_c_2), 8)).
believes(pref_do(visit(doc_c_3), 6)).
believes(pref_do(visit(doc_d_1), 2)).
believes(pref_do(visit(doc_d_2), 9)).
believes(pref_do(visit(doc_d_3), 10)).

believes(success_prob(visit(doc_a_1), 0.78)).
believes(success_prob(visit(doc_a_2), 0.75)).
believes(success_prob(visit(doc_a_3), 0.57)).
believes(success_prob(visit(doc_b_1), 0.76)).
believes(success_prob(visit(doc_b_2), 0.69)).
believes(success_prob(visit(doc_b_3), 0.86)).
believes(success_prob(visit(doc_c_1), 0.96)).
believes(success_prob(visit(doc_c_2), 0.78)).
believes(success_prob(visit(doc_c_3), 0.78)).
believes(success_prob(visit(doc_d_1), 0.76)).
believes(success_prob(visit(doc_d_2), 0.84)).
believes(success_prob(visit(doc_d_3), 0.63)).

believes(action_cost(visit(doc_a_1), 6)).
believes(action_cost(visit(doc_a_2), 7)).
believes(action_cost(visit(doc_a_3), 6)).
believes(action_cost(visit(doc_b_1), 4)).
believes(action_cost(visit(doc_b_2), 1)).
believes(action_cost(visit(doc_b_3), 7)).
believes(action_cost(visit(doc_c_1), 4)).
believes(action_cost(visit(doc_c_2), 7)).
believes(action_cost(visit(doc_c_3), 2)).
believes(action_cost(visit(doc_d_1), 1)).
believes(action_cost(visit(doc_d_2), 4)).
believes(action_cost(visit(doc_d_3), 5)).
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
believes(equivalent_action(consultation, visit_type_4)).
believes(equivalent_action(consultation, visit_type_5)).
believes(equivalent_action(consultation, visit_type_6)).

believes(action_data(visit_type_1, 0.81, 7, 8)).
believes(action_data(visit_type_2, 0.87, 6, 8)).
believes(action_data(visit_type_3, 0.67, 5, 3)).
believes(action_data(visit_type_4, 0.86, 7, 4)).
believes(action_data(visit_type_5, 0.94, 6, 6)).
believes(action_data(visit_type_6, 0.69, 10, 3)).
believes(policy_weights(100, 10, 20)).
believes(pref_max(10)).

schedule_readyE :>
    log("patient_7: Baseline schedule loaded"),
    believes(intend(consultation(t7))),
    believes(assigned_doctor(Doc)),
    send(logger, log_event(schedule_loaded, patient_7, [consultation, t7, Doc])).

unavailableE(Doctor, TimeSlot) :>
    log("patient_7: DISRUPTION — ~w unavailable at ~w", [Doctor, TimeSlot]),
    assert_belief(unavailable(Doctor, TimeSlot)),
    retract_belief(assigned_doctor(Doctor)),
    send(logger, log_event(disruption, patient_7, [unavailable, Doctor, TimeSlot])),
    send(clinic_c_mgr, repair_request(patient_7, consultation, TimeSlot)).

local_repairE(Doctor, TimeSlot, TrustLevel, PrefDegree) :>
    log("patient_7: Local repair offered — ~w (trust=~w, pref=~w)", [Doctor, TrustLevel, PrefDegree]),
    believes(trust_val(TrustLevel, TrustNum)),
    believes(trust_threshold_num(consultation, autonomy, AutThr)),
    believes(trust_threshold_num(consultation, blocking, BlkThr)),
    (   TrustNum >= AutThr
    ->  assert_belief(assigned_doctor(Doctor)),
        retract_belief(intend(consultation(TimeSlot))),
        assert_belief(intend(consultation_with(Doctor, TimeSlot))),
        send(logger, log_event(decision, patient_7, [allow, Doctor, TimeSlot]))
    ;   TrustNum > BlkThr
    ->  send(logger, log_event(decision, patient_7, [delegate, Doctor, TimeSlot])),
        send(mediator, lending_request(patient_7, clinic_c, consultation, TimeSlot))
    ;   send(logger, log_event(decision, patient_7, [block, Doctor, TimeSlot]))
    ).

delegation_completeE(Doctor, TimeSlot) :>
    assert_belief(assigned_doctor(Doctor)),
    retract_belief(intend(consultation(TimeSlot))),
    assert_belief(intend(consultation_with(Doctor, TimeSlot))),
    send(logger, log_event(delegation_complete, patient_7, [Doctor, TimeSlot])).

consultation_doneE(Doctor, TimeSlot) :>
    assert_belief(done(consultation_with(Doctor, TimeSlot))),
    retract_belief(intend(consultation_with(Doctor, TimeSlot))),
    retract_belief(needs_consultation(TimeSlot)),
    send(logger, log_event(consultation_done, patient_7, [Doctor, TimeSlot])).

select_actionE(TimeSlot) :>
    log("patient_7: Probabilistic action selection"),
    send(logger, log_event(selector_start, patient_7, [consultation, TimeSlot])),
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
    send(logger, log_event(prob_selection, patient_7, [BestAction, BestScore, TimeSlot])).

fallback_aspE(TimeSlot) :>
    send(logger, log_event(fallback, patient_7, [asp_reoptimization, TimeSlot])).


%% === PATIENT_8 ===

:- agent(patient_8, [cycle(2)]).

believes(needs_consultation(t8)).
believes(member_of(clinic_d)).
believes(intend(consultation(t8))).
believes(assigned_doctor(doc_d_2)).
believes(assigned_clinic(clinic_d)).

believes(trust(doc_a_1, high)).
believes(trust(doc_a_2, very_high)).
believes(trust(doc_a_3, low)).
believes(trust(doc_b_1, high)).
believes(trust(doc_b_2, low)).
believes(trust(doc_b_3, low)).
believes(trust(doc_c_1, high)).
believes(trust(doc_c_2, high)).
believes(trust(doc_c_3, low)).
believes(trust(doc_d_1, high)).
believes(trust(doc_d_2, medium)).
believes(trust(doc_d_3, low)).

believes(pref_do(visit(doc_a_1), 9)).
believes(pref_do(visit(doc_a_2), 6)).
believes(pref_do(visit(doc_a_3), 4)).
believes(pref_do(visit(doc_b_1), 3)).
believes(pref_do(visit(doc_b_2), 9)).
believes(pref_do(visit(doc_b_3), 9)).
believes(pref_do(visit(doc_c_1), 3)).
believes(pref_do(visit(doc_c_2), 6)).
believes(pref_do(visit(doc_c_3), 10)).
believes(pref_do(visit(doc_d_1), 5)).
believes(pref_do(visit(doc_d_2), 2)).
believes(pref_do(visit(doc_d_3), 7)).

believes(success_prob(visit(doc_a_1), 0.86)).
believes(success_prob(visit(doc_a_2), 0.65)).
believes(success_prob(visit(doc_a_3), 0.62)).
believes(success_prob(visit(doc_b_1), 0.97)).
believes(success_prob(visit(doc_b_2), 0.7)).
believes(success_prob(visit(doc_b_3), 0.85)).
believes(success_prob(visit(doc_c_1), 0.72)).
believes(success_prob(visit(doc_c_2), 0.86)).
believes(success_prob(visit(doc_c_3), 0.58)).
believes(success_prob(visit(doc_d_1), 0.8)).
believes(success_prob(visit(doc_d_2), 0.81)).
believes(success_prob(visit(doc_d_3), 0.87)).

believes(action_cost(visit(doc_a_1), 7)).
believes(action_cost(visit(doc_a_2), 2)).
believes(action_cost(visit(doc_a_3), 3)).
believes(action_cost(visit(doc_b_1), 8)).
believes(action_cost(visit(doc_b_2), 6)).
believes(action_cost(visit(doc_b_3), 6)).
believes(action_cost(visit(doc_c_1), 8)).
believes(action_cost(visit(doc_c_2), 7)).
believes(action_cost(visit(doc_c_3), 3)).
believes(action_cost(visit(doc_d_1), 6)).
believes(action_cost(visit(doc_d_2), 3)).
believes(action_cost(visit(doc_d_3), 5)).
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
believes(equivalent_action(consultation, visit_type_4)).
believes(equivalent_action(consultation, visit_type_5)).
believes(equivalent_action(consultation, visit_type_6)).

believes(action_data(visit_type_1, 0.56, 4, 1)).
believes(action_data(visit_type_2, 0.76, 10, 3)).
believes(action_data(visit_type_3, 0.77, 10, 5)).
believes(action_data(visit_type_4, 0.65, 10, 6)).
believes(action_data(visit_type_5, 0.96, 5, 1)).
believes(action_data(visit_type_6, 0.82, 2, 8)).
believes(policy_weights(100, 10, 20)).
believes(pref_max(10)).

schedule_readyE :>
    log("patient_8: Baseline schedule loaded"),
    believes(intend(consultation(t8))),
    believes(assigned_doctor(Doc)),
    send(logger, log_event(schedule_loaded, patient_8, [consultation, t8, Doc])).

unavailableE(Doctor, TimeSlot) :>
    log("patient_8: DISRUPTION — ~w unavailable at ~w", [Doctor, TimeSlot]),
    assert_belief(unavailable(Doctor, TimeSlot)),
    retract_belief(assigned_doctor(Doctor)),
    send(logger, log_event(disruption, patient_8, [unavailable, Doctor, TimeSlot])),
    send(clinic_d_mgr, repair_request(patient_8, consultation, TimeSlot)).

local_repairE(Doctor, TimeSlot, TrustLevel, PrefDegree) :>
    log("patient_8: Local repair offered — ~w (trust=~w, pref=~w)", [Doctor, TrustLevel, PrefDegree]),
    believes(trust_val(TrustLevel, TrustNum)),
    believes(trust_threshold_num(consultation, autonomy, AutThr)),
    believes(trust_threshold_num(consultation, blocking, BlkThr)),
    (   TrustNum >= AutThr
    ->  assert_belief(assigned_doctor(Doctor)),
        retract_belief(intend(consultation(TimeSlot))),
        assert_belief(intend(consultation_with(Doctor, TimeSlot))),
        send(logger, log_event(decision, patient_8, [allow, Doctor, TimeSlot]))
    ;   TrustNum > BlkThr
    ->  send(logger, log_event(decision, patient_8, [delegate, Doctor, TimeSlot])),
        send(mediator, lending_request(patient_8, clinic_d, consultation, TimeSlot))
    ;   send(logger, log_event(decision, patient_8, [block, Doctor, TimeSlot]))
    ).

delegation_completeE(Doctor, TimeSlot) :>
    assert_belief(assigned_doctor(Doctor)),
    retract_belief(intend(consultation(TimeSlot))),
    assert_belief(intend(consultation_with(Doctor, TimeSlot))),
    send(logger, log_event(delegation_complete, patient_8, [Doctor, TimeSlot])).

consultation_doneE(Doctor, TimeSlot) :>
    assert_belief(done(consultation_with(Doctor, TimeSlot))),
    retract_belief(intend(consultation_with(Doctor, TimeSlot))),
    retract_belief(needs_consultation(TimeSlot)),
    send(logger, log_event(consultation_done, patient_8, [Doctor, TimeSlot])).

select_actionE(TimeSlot) :>
    log("patient_8: Probabilistic action selection"),
    send(logger, log_event(selector_start, patient_8, [consultation, TimeSlot])),
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
    send(logger, log_event(prob_selection, patient_8, [BestAction, BestScore, TimeSlot])).

fallback_aspE(TimeSlot) :>
    send(logger, log_event(fallback, patient_8, [asp_reoptimization, TimeSlot])).


%% === PATIENT_9 ===

:- agent(patient_9, [cycle(2)]).

believes(needs_consultation(t9)).
believes(member_of(clinic_a)).
believes(intend(consultation(t9))).
believes(assigned_doctor(doc_a_3)).
believes(assigned_clinic(clinic_a)).

believes(trust(doc_a_1, high)).
believes(trust(doc_a_2, very_high)).
believes(trust(doc_a_3, low)).
believes(trust(doc_b_1, high)).
believes(trust(doc_b_2, low)).
believes(trust(doc_b_3, low)).
believes(trust(doc_c_1, high)).
believes(trust(doc_c_2, high)).
believes(trust(doc_c_3, low)).
believes(trust(doc_d_1, high)).
believes(trust(doc_d_2, medium)).
believes(trust(doc_d_3, low)).

believes(pref_do(visit(doc_a_1), 7)).
believes(pref_do(visit(doc_a_2), 2)).
believes(pref_do(visit(doc_a_3), 3)).
believes(pref_do(visit(doc_b_1), 6)).
believes(pref_do(visit(doc_b_2), 5)).
believes(pref_do(visit(doc_b_3), 7)).
believes(pref_do(visit(doc_c_1), 7)).
believes(pref_do(visit(doc_c_2), 7)).
believes(pref_do(visit(doc_c_3), 10)).
believes(pref_do(visit(doc_d_1), 6)).
believes(pref_do(visit(doc_d_2), 8)).
believes(pref_do(visit(doc_d_3), 5)).

believes(success_prob(visit(doc_a_1), 0.98)).
believes(success_prob(visit(doc_a_2), 0.93)).
believes(success_prob(visit(doc_a_3), 0.87)).
believes(success_prob(visit(doc_b_1), 0.92)).
believes(success_prob(visit(doc_b_2), 0.56)).
believes(success_prob(visit(doc_b_3), 0.82)).
believes(success_prob(visit(doc_c_1), 0.94)).
believes(success_prob(visit(doc_c_2), 0.7)).
believes(success_prob(visit(doc_c_3), 0.81)).
believes(success_prob(visit(doc_d_1), 0.59)).
believes(success_prob(visit(doc_d_2), 0.88)).
believes(success_prob(visit(doc_d_3), 0.64)).

believes(action_cost(visit(doc_a_1), 8)).
believes(action_cost(visit(doc_a_2), 1)).
believes(action_cost(visit(doc_a_3), 3)).
believes(action_cost(visit(doc_b_1), 4)).
believes(action_cost(visit(doc_b_2), 3)).
believes(action_cost(visit(doc_b_3), 6)).
believes(action_cost(visit(doc_c_1), 7)).
believes(action_cost(visit(doc_c_2), 2)).
believes(action_cost(visit(doc_c_3), 3)).
believes(action_cost(visit(doc_d_1), 4)).
believes(action_cost(visit(doc_d_2), 6)).
believes(action_cost(visit(doc_d_3), 6)).
believes(budget(16)).

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
believes(equivalent_action(consultation, visit_type_4)).
believes(equivalent_action(consultation, visit_type_5)).
believes(equivalent_action(consultation, visit_type_6)).

believes(action_data(visit_type_1, 0.6, 10, 8)).
believes(action_data(visit_type_2, 0.83, 4, 8)).
believes(action_data(visit_type_3, 0.93, 10, 3)).
believes(action_data(visit_type_4, 0.95, 10, 1)).
believes(action_data(visit_type_5, 0.69, 10, 7)).
believes(action_data(visit_type_6, 0.76, 4, 5)).
believes(policy_weights(100, 10, 20)).
believes(pref_max(10)).

schedule_readyE :>
    log("patient_9: Baseline schedule loaded"),
    believes(intend(consultation(t9))),
    believes(assigned_doctor(Doc)),
    send(logger, log_event(schedule_loaded, patient_9, [consultation, t9, Doc])).

unavailableE(Doctor, TimeSlot) :>
    log("patient_9: DISRUPTION — ~w unavailable at ~w", [Doctor, TimeSlot]),
    assert_belief(unavailable(Doctor, TimeSlot)),
    retract_belief(assigned_doctor(Doctor)),
    send(logger, log_event(disruption, patient_9, [unavailable, Doctor, TimeSlot])),
    send(clinic_a_mgr, repair_request(patient_9, consultation, TimeSlot)).

local_repairE(Doctor, TimeSlot, TrustLevel, PrefDegree) :>
    log("patient_9: Local repair offered — ~w (trust=~w, pref=~w)", [Doctor, TrustLevel, PrefDegree]),
    believes(trust_val(TrustLevel, TrustNum)),
    believes(trust_threshold_num(consultation, autonomy, AutThr)),
    believes(trust_threshold_num(consultation, blocking, BlkThr)),
    (   TrustNum >= AutThr
    ->  assert_belief(assigned_doctor(Doctor)),
        retract_belief(intend(consultation(TimeSlot))),
        assert_belief(intend(consultation_with(Doctor, TimeSlot))),
        send(logger, log_event(decision, patient_9, [allow, Doctor, TimeSlot]))
    ;   TrustNum > BlkThr
    ->  send(logger, log_event(decision, patient_9, [delegate, Doctor, TimeSlot])),
        send(mediator, lending_request(patient_9, clinic_a, consultation, TimeSlot))
    ;   send(logger, log_event(decision, patient_9, [block, Doctor, TimeSlot]))
    ).

delegation_completeE(Doctor, TimeSlot) :>
    assert_belief(assigned_doctor(Doctor)),
    retract_belief(intend(consultation(TimeSlot))),
    assert_belief(intend(consultation_with(Doctor, TimeSlot))),
    send(logger, log_event(delegation_complete, patient_9, [Doctor, TimeSlot])).

consultation_doneE(Doctor, TimeSlot) :>
    assert_belief(done(consultation_with(Doctor, TimeSlot))),
    retract_belief(intend(consultation_with(Doctor, TimeSlot))),
    retract_belief(needs_consultation(TimeSlot)),
    send(logger, log_event(consultation_done, patient_9, [Doctor, TimeSlot])).

select_actionE(TimeSlot) :>
    log("patient_9: Probabilistic action selection"),
    send(logger, log_event(selector_start, patient_9, [consultation, TimeSlot])),
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
    send(logger, log_event(prob_selection, patient_9, [BestAction, BestScore, TimeSlot])).

fallback_aspE(TimeSlot) :>
    send(logger, log_event(fallback, patient_9, [asp_reoptimization, TimeSlot])).


%% === PATIENT_10 ===

:- agent(patient_10, [cycle(2)]).

believes(needs_consultation(t10)).
believes(member_of(clinic_b)).
believes(intend(consultation(t10))).
believes(assigned_doctor(doc_b_1)).
believes(assigned_clinic(clinic_b)).

believes(trust(doc_a_1, high)).
believes(trust(doc_a_2, very_high)).
believes(trust(doc_a_3, low)).
believes(trust(doc_b_1, high)).
believes(trust(doc_b_2, low)).
believes(trust(doc_b_3, low)).
believes(trust(doc_c_1, high)).
believes(trust(doc_c_2, high)).
believes(trust(doc_c_3, low)).
believes(trust(doc_d_1, high)).
believes(trust(doc_d_2, medium)).
believes(trust(doc_d_3, low)).

believes(pref_do(visit(doc_a_1), 9)).
believes(pref_do(visit(doc_a_2), 10)).
believes(pref_do(visit(doc_a_3), 4)).
believes(pref_do(visit(doc_b_1), 9)).
believes(pref_do(visit(doc_b_2), 9)).
believes(pref_do(visit(doc_b_3), 9)).
believes(pref_do(visit(doc_c_1), 9)).
believes(pref_do(visit(doc_c_2), 4)).
believes(pref_do(visit(doc_c_3), 10)).
believes(pref_do(visit(doc_d_1), 9)).
believes(pref_do(visit(doc_d_2), 5)).
believes(pref_do(visit(doc_d_3), 6)).

believes(success_prob(visit(doc_a_1), 0.87)).
believes(success_prob(visit(doc_a_2), 0.66)).
believes(success_prob(visit(doc_a_3), 0.93)).
believes(success_prob(visit(doc_b_1), 0.59)).
believes(success_prob(visit(doc_b_2), 0.72)).
believes(success_prob(visit(doc_b_3), 0.94)).
believes(success_prob(visit(doc_c_1), 0.57)).
believes(success_prob(visit(doc_c_2), 0.91)).
believes(success_prob(visit(doc_c_3), 0.81)).
believes(success_prob(visit(doc_d_1), 0.86)).
believes(success_prob(visit(doc_d_2), 0.58)).
believes(success_prob(visit(doc_d_3), 0.87)).

believes(action_cost(visit(doc_a_1), 1)).
believes(action_cost(visit(doc_a_2), 1)).
believes(action_cost(visit(doc_a_3), 4)).
believes(action_cost(visit(doc_b_1), 8)).
believes(action_cost(visit(doc_b_2), 1)).
believes(action_cost(visit(doc_b_3), 4)).
believes(action_cost(visit(doc_c_1), 4)).
believes(action_cost(visit(doc_c_2), 1)).
believes(action_cost(visit(doc_c_3), 6)).
believes(action_cost(visit(doc_d_1), 5)).
believes(action_cost(visit(doc_d_2), 1)).
believes(action_cost(visit(doc_d_3), 4)).
believes(budget(12)).

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
believes(equivalent_action(consultation, visit_type_4)).
believes(equivalent_action(consultation, visit_type_5)).
believes(equivalent_action(consultation, visit_type_6)).

believes(action_data(visit_type_1, 0.72, 4, 4)).
believes(action_data(visit_type_2, 0.96, 10, 8)).
believes(action_data(visit_type_3, 0.71, 4, 4)).
believes(action_data(visit_type_4, 0.66, 10, 6)).
believes(action_data(visit_type_5, 0.79, 3, 8)).
believes(action_data(visit_type_6, 0.82, 2, 5)).
believes(policy_weights(100, 10, 20)).
believes(pref_max(10)).

schedule_readyE :>
    log("patient_10: Baseline schedule loaded"),
    believes(intend(consultation(t10))),
    believes(assigned_doctor(Doc)),
    send(logger, log_event(schedule_loaded, patient_10, [consultation, t10, Doc])).

unavailableE(Doctor, TimeSlot) :>
    log("patient_10: DISRUPTION — ~w unavailable at ~w", [Doctor, TimeSlot]),
    assert_belief(unavailable(Doctor, TimeSlot)),
    retract_belief(assigned_doctor(Doctor)),
    send(logger, log_event(disruption, patient_10, [unavailable, Doctor, TimeSlot])),
    send(clinic_b_mgr, repair_request(patient_10, consultation, TimeSlot)).

local_repairE(Doctor, TimeSlot, TrustLevel, PrefDegree) :>
    log("patient_10: Local repair offered — ~w (trust=~w, pref=~w)", [Doctor, TrustLevel, PrefDegree]),
    believes(trust_val(TrustLevel, TrustNum)),
    believes(trust_threshold_num(consultation, autonomy, AutThr)),
    believes(trust_threshold_num(consultation, blocking, BlkThr)),
    (   TrustNum >= AutThr
    ->  assert_belief(assigned_doctor(Doctor)),
        retract_belief(intend(consultation(TimeSlot))),
        assert_belief(intend(consultation_with(Doctor, TimeSlot))),
        send(logger, log_event(decision, patient_10, [allow, Doctor, TimeSlot]))
    ;   TrustNum > BlkThr
    ->  send(logger, log_event(decision, patient_10, [delegate, Doctor, TimeSlot])),
        send(mediator, lending_request(patient_10, clinic_b, consultation, TimeSlot))
    ;   send(logger, log_event(decision, patient_10, [block, Doctor, TimeSlot]))
    ).

delegation_completeE(Doctor, TimeSlot) :>
    assert_belief(assigned_doctor(Doctor)),
    retract_belief(intend(consultation(TimeSlot))),
    assert_belief(intend(consultation_with(Doctor, TimeSlot))),
    send(logger, log_event(delegation_complete, patient_10, [Doctor, TimeSlot])).

consultation_doneE(Doctor, TimeSlot) :>
    assert_belief(done(consultation_with(Doctor, TimeSlot))),
    retract_belief(intend(consultation_with(Doctor, TimeSlot))),
    retract_belief(needs_consultation(TimeSlot)),
    send(logger, log_event(consultation_done, patient_10, [Doctor, TimeSlot])).

select_actionE(TimeSlot) :>
    log("patient_10: Probabilistic action selection"),
    send(logger, log_event(selector_start, patient_10, [consultation, TimeSlot])),
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
    send(logger, log_event(prob_selection, patient_10, [BestAction, BestScore, TimeSlot])).

fallback_aspE(TimeSlot) :>
    send(logger, log_event(fallback, patient_10, [asp_reoptimization, TimeSlot])).


%% === DOC_A_1 ===

:- agent(doc_a_1, [cycle(2)]).

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
believes(can_do(consultation, t5)).
believes(available(t5)).

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
believes(trust_level(very_high)).
believes(can_do(consultation, t1)).
believes(available(t1)).
believes(can_do(consultation, t2)).
believes(available(t2)).
believes(can_do(consultation, t3)).
believes(available(t3)).
believes(can_do(consultation, t4)).
believes(available(t4)).
believes(can_do(consultation, t5)).
believes(available(t5)).

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


%% === DOC_A_3 ===

:- agent(doc_a_3, [cycle(2)]).

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
believes(can_do(consultation, t5)).
believes(available(t5)).

become_unavailableE(TimeSlot) :>
    log("doc_a_3: Becoming unavailable at ~w", [TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    retract_belief(available(TimeSlot)),
    assert_belief(unavailable(TimeSlot)),
    send(clinic_a_mgr, doctor_unavailable(doc_a_3, TimeSlot)),
    send(logger, log_event(unavailability, doc_a_3, [TimeSlot])).

perform_consultationE(Patient, TimeSlot) :>
    believes(can_do(consultation, TimeSlot)),
    log("doc_a_3: Performing consultation for ~w at ~w", [Patient, TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    assert_belief(done(consultation, Patient, TimeSlot)),
    send(Patient, consultation_done(doc_a_3, TimeSlot)),
    send(logger, log_event(consultation, doc_a_3, [Patient, TimeSlot])),
    (   believes(temporarily_in(Clinic))
    ->  send(mediator, lending_task_done(doc_a_3, Clinic, TimeSlot))
    ;   true
    ).

lend_toE(RequestingClinic, Action, TimeSlot) :>
    believes(can_do(Action, TimeSlot)),
    believes(available(TimeSlot)),
    assert_belief(temporarily_in(RequestingClinic)),
    retract_belief(available(TimeSlot)),
    send(mediator, lending_accepted(doc_a_3, RequestingClinic, Action, TimeSlot)),
    send(logger, log_event(lending_accepted, doc_a_3, [RequestingClinic, Action, TimeSlot])).

return_to_groupE :>
    believes(temporarily_in(Clinic)),
    retract_belief(temporarily_in(Clinic)),
    send(logger, log_event(return_group, doc_a_3, [clinic_a])).


%% === DOC_B_1 ===

:- agent(doc_b_1, [cycle(2)]).

believes(member_of(clinic_b)).
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
believes(can_do(consultation, t5)).
believes(available(t5)).

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
believes(can_do(consultation, t5)).
believes(available(t5)).

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


%% === DOC_B_3 ===

:- agent(doc_b_3, [cycle(2)]).

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
believes(can_do(consultation, t5)).
believes(available(t5)).

become_unavailableE(TimeSlot) :>
    log("doc_b_3: Becoming unavailable at ~w", [TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    retract_belief(available(TimeSlot)),
    assert_belief(unavailable(TimeSlot)),
    send(clinic_b_mgr, doctor_unavailable(doc_b_3, TimeSlot)),
    send(logger, log_event(unavailability, doc_b_3, [TimeSlot])).

perform_consultationE(Patient, TimeSlot) :>
    believes(can_do(consultation, TimeSlot)),
    log("doc_b_3: Performing consultation for ~w at ~w", [Patient, TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    assert_belief(done(consultation, Patient, TimeSlot)),
    send(Patient, consultation_done(doc_b_3, TimeSlot)),
    send(logger, log_event(consultation, doc_b_3, [Patient, TimeSlot])),
    (   believes(temporarily_in(Clinic))
    ->  send(mediator, lending_task_done(doc_b_3, Clinic, TimeSlot))
    ;   true
    ).

lend_toE(RequestingClinic, Action, TimeSlot) :>
    believes(can_do(Action, TimeSlot)),
    believes(available(TimeSlot)),
    assert_belief(temporarily_in(RequestingClinic)),
    retract_belief(available(TimeSlot)),
    send(mediator, lending_accepted(doc_b_3, RequestingClinic, Action, TimeSlot)),
    send(logger, log_event(lending_accepted, doc_b_3, [RequestingClinic, Action, TimeSlot])).

return_to_groupE :>
    believes(temporarily_in(Clinic)),
    retract_belief(temporarily_in(Clinic)),
    send(logger, log_event(return_group, doc_b_3, [clinic_b])).


%% === DOC_C_1 ===

:- agent(doc_c_1, [cycle(2)]).

believes(member_of(clinic_c)).
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
believes(can_do(consultation, t5)).
believes(available(t5)).

become_unavailableE(TimeSlot) :>
    log("doc_c_1: Becoming unavailable at ~w", [TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    retract_belief(available(TimeSlot)),
    assert_belief(unavailable(TimeSlot)),
    send(clinic_c_mgr, doctor_unavailable(doc_c_1, TimeSlot)),
    send(logger, log_event(unavailability, doc_c_1, [TimeSlot])).

perform_consultationE(Patient, TimeSlot) :>
    believes(can_do(consultation, TimeSlot)),
    log("doc_c_1: Performing consultation for ~w at ~w", [Patient, TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    assert_belief(done(consultation, Patient, TimeSlot)),
    send(Patient, consultation_done(doc_c_1, TimeSlot)),
    send(logger, log_event(consultation, doc_c_1, [Patient, TimeSlot])),
    (   believes(temporarily_in(Clinic))
    ->  send(mediator, lending_task_done(doc_c_1, Clinic, TimeSlot))
    ;   true
    ).

lend_toE(RequestingClinic, Action, TimeSlot) :>
    believes(can_do(Action, TimeSlot)),
    believes(available(TimeSlot)),
    assert_belief(temporarily_in(RequestingClinic)),
    retract_belief(available(TimeSlot)),
    send(mediator, lending_accepted(doc_c_1, RequestingClinic, Action, TimeSlot)),
    send(logger, log_event(lending_accepted, doc_c_1, [RequestingClinic, Action, TimeSlot])).

return_to_groupE :>
    believes(temporarily_in(Clinic)),
    retract_belief(temporarily_in(Clinic)),
    send(logger, log_event(return_group, doc_c_1, [clinic_c])).


%% === DOC_C_2 ===

:- agent(doc_c_2, [cycle(2)]).

believes(member_of(clinic_c)).
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
believes(can_do(consultation, t5)).
believes(available(t5)).

become_unavailableE(TimeSlot) :>
    log("doc_c_2: Becoming unavailable at ~w", [TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    retract_belief(available(TimeSlot)),
    assert_belief(unavailable(TimeSlot)),
    send(clinic_c_mgr, doctor_unavailable(doc_c_2, TimeSlot)),
    send(logger, log_event(unavailability, doc_c_2, [TimeSlot])).

perform_consultationE(Patient, TimeSlot) :>
    believes(can_do(consultation, TimeSlot)),
    log("doc_c_2: Performing consultation for ~w at ~w", [Patient, TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    assert_belief(done(consultation, Patient, TimeSlot)),
    send(Patient, consultation_done(doc_c_2, TimeSlot)),
    send(logger, log_event(consultation, doc_c_2, [Patient, TimeSlot])),
    (   believes(temporarily_in(Clinic))
    ->  send(mediator, lending_task_done(doc_c_2, Clinic, TimeSlot))
    ;   true
    ).

lend_toE(RequestingClinic, Action, TimeSlot) :>
    believes(can_do(Action, TimeSlot)),
    believes(available(TimeSlot)),
    assert_belief(temporarily_in(RequestingClinic)),
    retract_belief(available(TimeSlot)),
    send(mediator, lending_accepted(doc_c_2, RequestingClinic, Action, TimeSlot)),
    send(logger, log_event(lending_accepted, doc_c_2, [RequestingClinic, Action, TimeSlot])).

return_to_groupE :>
    believes(temporarily_in(Clinic)),
    retract_belief(temporarily_in(Clinic)),
    send(logger, log_event(return_group, doc_c_2, [clinic_c])).


%% === DOC_C_3 ===

:- agent(doc_c_3, [cycle(2)]).

believes(member_of(clinic_c)).
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
believes(can_do(consultation, t5)).
believes(available(t5)).

become_unavailableE(TimeSlot) :>
    log("doc_c_3: Becoming unavailable at ~w", [TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    retract_belief(available(TimeSlot)),
    assert_belief(unavailable(TimeSlot)),
    send(clinic_c_mgr, doctor_unavailable(doc_c_3, TimeSlot)),
    send(logger, log_event(unavailability, doc_c_3, [TimeSlot])).

perform_consultationE(Patient, TimeSlot) :>
    believes(can_do(consultation, TimeSlot)),
    log("doc_c_3: Performing consultation for ~w at ~w", [Patient, TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    assert_belief(done(consultation, Patient, TimeSlot)),
    send(Patient, consultation_done(doc_c_3, TimeSlot)),
    send(logger, log_event(consultation, doc_c_3, [Patient, TimeSlot])),
    (   believes(temporarily_in(Clinic))
    ->  send(mediator, lending_task_done(doc_c_3, Clinic, TimeSlot))
    ;   true
    ).

lend_toE(RequestingClinic, Action, TimeSlot) :>
    believes(can_do(Action, TimeSlot)),
    believes(available(TimeSlot)),
    assert_belief(temporarily_in(RequestingClinic)),
    retract_belief(available(TimeSlot)),
    send(mediator, lending_accepted(doc_c_3, RequestingClinic, Action, TimeSlot)),
    send(logger, log_event(lending_accepted, doc_c_3, [RequestingClinic, Action, TimeSlot])).

return_to_groupE :>
    believes(temporarily_in(Clinic)),
    retract_belief(temporarily_in(Clinic)),
    send(logger, log_event(return_group, doc_c_3, [clinic_c])).


%% === DOC_D_1 ===

:- agent(doc_d_1, [cycle(2)]).

believes(member_of(clinic_d)).
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
believes(can_do(consultation, t5)).
believes(available(t5)).

become_unavailableE(TimeSlot) :>
    log("doc_d_1: Becoming unavailable at ~w", [TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    retract_belief(available(TimeSlot)),
    assert_belief(unavailable(TimeSlot)),
    send(clinic_d_mgr, doctor_unavailable(doc_d_1, TimeSlot)),
    send(logger, log_event(unavailability, doc_d_1, [TimeSlot])).

perform_consultationE(Patient, TimeSlot) :>
    believes(can_do(consultation, TimeSlot)),
    log("doc_d_1: Performing consultation for ~w at ~w", [Patient, TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    assert_belief(done(consultation, Patient, TimeSlot)),
    send(Patient, consultation_done(doc_d_1, TimeSlot)),
    send(logger, log_event(consultation, doc_d_1, [Patient, TimeSlot])),
    (   believes(temporarily_in(Clinic))
    ->  send(mediator, lending_task_done(doc_d_1, Clinic, TimeSlot))
    ;   true
    ).

lend_toE(RequestingClinic, Action, TimeSlot) :>
    believes(can_do(Action, TimeSlot)),
    believes(available(TimeSlot)),
    assert_belief(temporarily_in(RequestingClinic)),
    retract_belief(available(TimeSlot)),
    send(mediator, lending_accepted(doc_d_1, RequestingClinic, Action, TimeSlot)),
    send(logger, log_event(lending_accepted, doc_d_1, [RequestingClinic, Action, TimeSlot])).

return_to_groupE :>
    believes(temporarily_in(Clinic)),
    retract_belief(temporarily_in(Clinic)),
    send(logger, log_event(return_group, doc_d_1, [clinic_d])).


%% === DOC_D_2 ===

:- agent(doc_d_2, [cycle(2)]).

believes(member_of(clinic_d)).
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
believes(can_do(consultation, t5)).
believes(available(t5)).

become_unavailableE(TimeSlot) :>
    log("doc_d_2: Becoming unavailable at ~w", [TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    retract_belief(available(TimeSlot)),
    assert_belief(unavailable(TimeSlot)),
    send(clinic_d_mgr, doctor_unavailable(doc_d_2, TimeSlot)),
    send(logger, log_event(unavailability, doc_d_2, [TimeSlot])).

perform_consultationE(Patient, TimeSlot) :>
    believes(can_do(consultation, TimeSlot)),
    log("doc_d_2: Performing consultation for ~w at ~w", [Patient, TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    assert_belief(done(consultation, Patient, TimeSlot)),
    send(Patient, consultation_done(doc_d_2, TimeSlot)),
    send(logger, log_event(consultation, doc_d_2, [Patient, TimeSlot])),
    (   believes(temporarily_in(Clinic))
    ->  send(mediator, lending_task_done(doc_d_2, Clinic, TimeSlot))
    ;   true
    ).

lend_toE(RequestingClinic, Action, TimeSlot) :>
    believes(can_do(Action, TimeSlot)),
    believes(available(TimeSlot)),
    assert_belief(temporarily_in(RequestingClinic)),
    retract_belief(available(TimeSlot)),
    send(mediator, lending_accepted(doc_d_2, RequestingClinic, Action, TimeSlot)),
    send(logger, log_event(lending_accepted, doc_d_2, [RequestingClinic, Action, TimeSlot])).

return_to_groupE :>
    believes(temporarily_in(Clinic)),
    retract_belief(temporarily_in(Clinic)),
    send(logger, log_event(return_group, doc_d_2, [clinic_d])).


%% === DOC_D_3 ===

:- agent(doc_d_3, [cycle(2)]).

believes(member_of(clinic_d)).
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
believes(can_do(consultation, t5)).
believes(available(t5)).

become_unavailableE(TimeSlot) :>
    log("doc_d_3: Becoming unavailable at ~w", [TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    retract_belief(available(TimeSlot)),
    assert_belief(unavailable(TimeSlot)),
    send(clinic_d_mgr, doctor_unavailable(doc_d_3, TimeSlot)),
    send(logger, log_event(unavailability, doc_d_3, [TimeSlot])).

perform_consultationE(Patient, TimeSlot) :>
    believes(can_do(consultation, TimeSlot)),
    log("doc_d_3: Performing consultation for ~w at ~w", [Patient, TimeSlot]),
    retract_belief(can_do(consultation, TimeSlot)),
    assert_belief(done(consultation, Patient, TimeSlot)),
    send(Patient, consultation_done(doc_d_3, TimeSlot)),
    send(logger, log_event(consultation, doc_d_3, [Patient, TimeSlot])),
    (   believes(temporarily_in(Clinic))
    ->  send(mediator, lending_task_done(doc_d_3, Clinic, TimeSlot))
    ;   true
    ).

lend_toE(RequestingClinic, Action, TimeSlot) :>
    believes(can_do(Action, TimeSlot)),
    believes(available(TimeSlot)),
    assert_belief(temporarily_in(RequestingClinic)),
    retract_belief(available(TimeSlot)),
    send(mediator, lending_accepted(doc_d_3, RequestingClinic, Action, TimeSlot)),
    send(logger, log_event(lending_accepted, doc_d_3, [RequestingClinic, Action, TimeSlot])).

return_to_groupE :>
    believes(temporarily_in(Clinic)),
    retract_belief(temporarily_in(Clinic)),
    send(logger, log_event(return_group, doc_d_3, [clinic_d])).


%% === CLINIC_A_MGR ===

:- agent(clinic_a_mgr, [cycle(1)]).

believes(member(clinic_a, doc_a_1)).
believes(member(clinic_a, doc_a_2)).
believes(member(clinic_a, doc_a_3)).
believes(member(clinic_a, patient_1)).
believes(member(clinic_a, patient_5)).
believes(member(clinic_a, patient_9)).

believes(doctor_trust(doc_a_1, high)).
believes(doctor_pref(doc_a_1, 8)).
believes(doctor_available(doc_a_1)).
believes(doctor_trust(doc_a_2, very_high)).
believes(doctor_pref(doc_a_2, 6)).
believes(doctor_available(doc_a_2)).
believes(doctor_trust(doc_a_3, low)).
believes(doctor_pref(doc_a_3, 6)).
believes(doctor_available(doc_a_3)).

doctor_unavailableE(Doctor, TimeSlot) :>
    log("clinic_a_mgr: ~w unavailable at ~w", [Doctor, TimeSlot]),
    retract_belief(doctor_available(Doctor)),
    assert_belief(doctor_unavailable_at(Doctor, TimeSlot)),
    send(patient_1, unavailable(Doctor, TimeSlot)),
    send(patient_5, unavailable(Doctor, TimeSlot)),
    send(patient_9, unavailable(Doctor, TimeSlot)),
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
believes(member(clinic_b, doc_b_3)).
believes(member(clinic_b, patient_2)).
believes(member(clinic_b, patient_6)).
believes(member(clinic_b, patient_10)).

believes(doctor_trust(doc_b_1, high)).
believes(doctor_pref(doc_b_1, 2)).
believes(doctor_available(doc_b_1)).
believes(doctor_trust(doc_b_2, low)).
believes(doctor_pref(doc_b_2, 9)).
believes(doctor_available(doc_b_2)).
believes(doctor_trust(doc_b_3, low)).
believes(doctor_pref(doc_b_3, 3)).
believes(doctor_available(doc_b_3)).

doctor_unavailableE(Doctor, TimeSlot) :>
    log("clinic_b_mgr: ~w unavailable at ~w", [Doctor, TimeSlot]),
    retract_belief(doctor_available(Doctor)),
    assert_belief(doctor_unavailable_at(Doctor, TimeSlot)),
    send(patient_2, unavailable(Doctor, TimeSlot)),
    send(patient_6, unavailable(Doctor, TimeSlot)),
    send(patient_10, unavailable(Doctor, TimeSlot)),
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


%% === CLINIC_C_MGR ===

:- agent(clinic_c_mgr, [cycle(1)]).

believes(member(clinic_c, doc_c_1)).
believes(member(clinic_c, doc_c_2)).
believes(member(clinic_c, doc_c_3)).
believes(member(clinic_c, patient_3)).
believes(member(clinic_c, patient_7)).

believes(doctor_trust(doc_c_1, high)).
believes(doctor_pref(doc_c_1, 3)).
believes(doctor_available(doc_c_1)).
believes(doctor_trust(doc_c_2, high)).
believes(doctor_pref(doc_c_2, 2)).
believes(doctor_available(doc_c_2)).
believes(doctor_trust(doc_c_3, low)).
believes(doctor_pref(doc_c_3, 4)).
believes(doctor_available(doc_c_3)).

doctor_unavailableE(Doctor, TimeSlot) :>
    log("clinic_c_mgr: ~w unavailable at ~w", [Doctor, TimeSlot]),
    retract_belief(doctor_available(Doctor)),
    assert_belief(doctor_unavailable_at(Doctor, TimeSlot)),
    send(patient_3, unavailable(Doctor, TimeSlot)),
    send(patient_7, unavailable(Doctor, TimeSlot)),
    send(logger, log_event(group_update, clinic_c_mgr, [unavailable, Doctor, TimeSlot])).

repair_requestE(Patient, Action, TimeSlot) :>
    findall(Pref-Doc-Trust, (
        believes(member(clinic_c, Doc)),
        believes(doctor_available(Doc)),
        believes(doctor_trust(Doc, Trust)),
        believes(doctor_pref(Doc, Pref))
    ), CandidatesRaw),
    sort(CandidatesRaw, CandidatesUniq),
    reverse(CandidatesUniq, Sorted),
    (   Sorted = [BestPref-BestDoc-BestTrust | _]
    ->  send(Patient, local_repair(BestDoc, TimeSlot, BestTrust, BestPref))
    ;   send(mediator, lending_request(Patient, clinic_c, Action, TimeSlot)),
        send(logger, log_event(no_local_repair, clinic_c_mgr, [Patient, TimeSlot]))
    ).

lending_inquiryE(RequestingClinic, Action, TimeSlot) :>
    findall(Doc-Trust, (
        believes(member(clinic_c, Doc)),
        believes(doctor_available(Doc)),
        believes(doctor_trust(Doc, Trust))
    ), AvailableRaw),
    sort(AvailableRaw, Available),
    (   Available = [BestDoc-BestTrust | _]
    ->  send(mediator, lending_offer(BestDoc, clinic_c, BestTrust, Action, TimeSlot))
    ;   send(mediator, lending_denied(clinic_c, Action, TimeSlot))
    ).


%% === CLINIC_D_MGR ===

:- agent(clinic_d_mgr, [cycle(1)]).

believes(member(clinic_d, doc_d_1)).
believes(member(clinic_d, doc_d_2)).
believes(member(clinic_d, doc_d_3)).
believes(member(clinic_d, patient_4)).
believes(member(clinic_d, patient_8)).

believes(doctor_trust(doc_d_1, high)).
believes(doctor_pref(doc_d_1, 4)).
believes(doctor_available(doc_d_1)).
believes(doctor_trust(doc_d_2, medium)).
believes(doctor_pref(doc_d_2, 8)).
believes(doctor_available(doc_d_2)).
believes(doctor_trust(doc_d_3, low)).
believes(doctor_pref(doc_d_3, 8)).
believes(doctor_available(doc_d_3)).

doctor_unavailableE(Doctor, TimeSlot) :>
    log("clinic_d_mgr: ~w unavailable at ~w", [Doctor, TimeSlot]),
    retract_belief(doctor_available(Doctor)),
    assert_belief(doctor_unavailable_at(Doctor, TimeSlot)),
    send(patient_4, unavailable(Doctor, TimeSlot)),
    send(patient_8, unavailable(Doctor, TimeSlot)),
    send(logger, log_event(group_update, clinic_d_mgr, [unavailable, Doctor, TimeSlot])).

repair_requestE(Patient, Action, TimeSlot) :>
    findall(Pref-Doc-Trust, (
        believes(member(clinic_d, Doc)),
        believes(doctor_available(Doc)),
        believes(doctor_trust(Doc, Trust)),
        believes(doctor_pref(Doc, Pref))
    ), CandidatesRaw),
    sort(CandidatesRaw, CandidatesUniq),
    reverse(CandidatesUniq, Sorted),
    (   Sorted = [BestPref-BestDoc-BestTrust | _]
    ->  send(Patient, local_repair(BestDoc, TimeSlot, BestTrust, BestPref))
    ;   send(mediator, lending_request(Patient, clinic_d, Action, TimeSlot)),
        send(logger, log_event(no_local_repair, clinic_d_mgr, [Patient, TimeSlot]))
    ).

lending_inquiryE(RequestingClinic, Action, TimeSlot) :>
    findall(Doc-Trust, (
        believes(member(clinic_d, Doc)),
        believes(doctor_available(Doc)),
        believes(doctor_trust(Doc, Trust))
    ), AvailableRaw),
    sort(AvailableRaw, Available),
    (   Available = [BestDoc-BestTrust | _]
    ->  send(mediator, lending_offer(BestDoc, clinic_d, BestTrust, Action, TimeSlot))
    ;   send(mediator, lending_denied(clinic_d, Action, TimeSlot))
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
    (   RequestingClinic \= clinic_c
    ->  send(clinic_c_mgr, lending_inquiry(RequestingClinic, Action, TimeSlot))
    ;   true
    ),
    (   RequestingClinic \= clinic_d
    ->  send(clinic_d_mgr, lending_inquiry(RequestingClinic, Action, TimeSlot))
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

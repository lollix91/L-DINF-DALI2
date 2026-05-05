# L-DINF: Logic of Inferable — Complete Rule Reference

> Comprehensive summary of all L-DINF constructs, including the base framework, the trust extension, and the probabilistic package.

L-DINF is an epistemic logic for modelling cooperative agents that reason through explicit beliefs, background knowledge, mental actions, physical actions, roles, resources, costs, preferences, equivalence classes of actions, inter-group delegation, trust, and probabilistic action selection.

L-DINF builds upon the DLEK epistemic logic for resource-bounded agents by Balbiani, Fernández-Duque, and Lorini, extending it with group dynamics, preferences, trust, and probability.

---

## 1. Core Language (L-INF / L-DINF)

### 1.1 Agents and Groups

| Symbol | Meaning |
|--------|---------|
| `Agt` | Set of agents |
| `Grp` | Set of groups of agents |
| `Atm` | Set of atomic propositions |
| `Atm_A` | Set of physical actions |
| `Res = {r_1, ..., r_ℓ}` | Set of resources |
| `Amounts` | Resource vectors `(r_1:n_1, ..., r_ℓ:n_ℓ)` with componentwise order |

Agents are partitioned into groups. An agent `i` may perform `joinA(i, j)` to join the group of agent `j`. The case `joinA(i, i)` forms the singleton group `{i}`.

### 1.2 Static Formulas

| Formula | Reading |
|---------|---------|
| `p` | Atomic proposition `p ∈ Atm` |
| `¬φ` | Negation |
| `φ ∧ ψ` | Conjunction |
| `B_i(φ)` | Agent `i` **explicitly believes** `φ` (working memory) |
| `K_i(φ)` | Agent `i` **knows** `φ` (background knowledge) |
| `intend_i(φ_A)` | Agent `i` **intends** to perform action `φ_A` |
| `intend_G(φ_A)` | All agents in group `G` intend `φ_A` |
| `can_do_i(φ_A)` | Action `φ_A` is **feasible** for agent `i` |
| `can_do_G(φ_A)` | Some agent in `G` can do `φ_A` (existential) |
| `do_i(φ_A)` | Agent `i` **executes** action `φ_A` |
| `do^P_i(φ_A)` | Agent `i` **has performed** `φ_A` in the past |
| `pref_do_i(φ_A, d)` | Agent `i` prefers `φ_A` with **degree** `d ∈ ℕ` |
| `pref_do_G(i, φ_A)` | Agent `i` is the **most preferred executor** of `φ_A` in group `G` |
| `Cl(φ_A, φ'_A)` | Actions `φ_A` and `φ'_A` are **equivalent** |
| `fCl_i(φ_A, φ'_A)` | `φ_A` is the **most convenient** equivalent of `φ'_A` for agent `i` |
| `exec_G(α)` | Some agent in `G` can execute mental action `α` |
| `lend_G(i, H, φ_A)` | Group `H` **lends** agent `i` to group `G` for action `φ_A` |

### 1.3 Dynamic Formulas

| Formula | Reading |
|---------|---------|
| `[G:α]φ` | After mental action `α` by group `G`, formula `φ` holds |

---

## 2. Mental Actions

Mental actions capture basic operations of explicit belief formation and revision:

| Action | Name | Meaning |
|--------|------|---------|
| `+φ` | **Learning** | Agent perceives formula `φ` and adds it to explicit beliefs |
| `↓(φ, ψ)` | **Inference** | Agent infers `ψ` from believed `φ` and known `φ → ψ` |
| `∩(φ, ψ)` | **Conjunction** | Agent derives `φ ∧ ψ` from two explicit beliefs |
| `⊢(φ, ψ)` | **Working-memory derivation** | Agent derives `ψ` from working-memory beliefs alone |
| `⊣(φ, ψ)` | **Belief removal** | Agent removes `ψ` when `φ` is believed and `φ → ¬ψ` is known |

### Enablement condition

A mental action `α` is enabled for group `G` at world `w` when:
```
enabled_w(G, α) : ∃j ∈ G (α ∈ E(j, w) ∧ C1(j, α, w) / |G| ≤ min_{h ∈ G} B1(h, w))
```

### Belief update

Each mental action modifies the neighbourhood function `N` (explicit beliefs):

- **`+φ`**: `N[G:+φ](i, w) = N(i, w) ∪ {‖φ‖^M_{i,w}}`
- **`↓(ψ, χ)`**: adds `‖χ‖` if `B_i(ψ) ∧ K_i(ψ → χ)` holds
- **`∩(ψ, χ)`**: adds `‖ψ ∧ χ‖` if `B_i(ψ) ∧ B_i(χ)` holds
- **`⊢(ψ, χ)`**: adds `‖χ‖` if `B_i(ψ) ∧ B_i(ψ → χ)` holds
- **`⊣(ψ, χ)`**: removes `‖χ‖` if `B_i(ψ) ∧ K_i(ψ → ¬χ)` holds

### Budget update (mental actions)

After executing `α` in group `G`:
```
B1[G:α](i, w) = B1(i, w) − C1(i, α, w) / |G|
```

---

## 3. Model Structure (Packages)

An L-INF model `M` consists of a **core** `C_M` and **packages** `P_M`.

### 3.1 Core `C_M = (W, N, R, V, S)`

| Component | Type | Role |
|-----------|------|------|
| `W` | Set | Possible worlds |
| `R = {R_i}_{i ∈ Agt}` | Equivalence relations on `W` | Background knowledge (long-term memory) |
| `N : Agt × W → 2^{2^W}` | Neighbourhood function | Explicit beliefs (working memory) |
| `V : W → 2^Atm` | Valuation | Truth values of propositions |
| `S : W → 2^{do_G(φ_A), do^P_i(φ_A)}` | Action valuation | Executed physical actions |

**Constraints:**
- **(C1)** `X ∈ N(i, w) ⟹ X ⊆ R_i(w)` — beliefs are compatible with knowledge
- **(C2)** `wR_iv ⟹ N(i, w) = N(i, v)` — epistemically equivalent worlds share beliefs

### 3.2 Packages `P_M`

| Package | Type | Description |
|---------|------|-------------|
| `E` | `Agt × W → 2^{L_ACT}` | Executability of mental actions |
| `B1` | `Agt × W → ℕ` | Budget for mental actions |
| `C1` | `Agt × L_ACT × W → ℕ` | Cost of mental actions |
| `A` | `Agt × W → 2^{Atm_A}` | Executability of physical actions |
| `B2` | `Agt × W → Amounts` | Budget for physical actions (resource vector) |
| `C2` | `Agt × Atm_A × W → Amounts` | Cost of physical actions |
| `H` | `Agt × W → 2^{Atm_A}` | **Role-based enabling** (authorized actions) |
| `P` | `Agt × W × Atm_A → ℕ` | **Preference** function on physical actions |
| `Q` | `Atm_A × W → 2^{Atm_A}` | **Equivalence classes** of physical actions |
| `F` | `Agt × W × Atm_A → Atm_A` | **Selector** — chooses preferred action in equivalence class |
| `L` | `Agt × Grp × Grp × Atm_A × W → {true, false}` | **Lending** function |

---

## 4. Truth Conditions (Base Framework)

| # | Formula | Truth condition |
|---|---------|----------------|
| 1 | `p` | `p ∈ V(w)` |
| 2 | `¬φ` | `M, w ⊭ φ` |
| 3 | `φ ∧ ψ` | `M, w ⊨ φ` and `M, w ⊨ ψ` |
| 4 | `B_i(φ)` | `‖φ‖^M_{i,w} ∈ N(i, w)` |
| 5 | `K_i(φ)` | `∀v ∈ R_i(w): M, v ⊨ φ` |
| 6 | `Cl(φ_A, φ'_A)` | `φ'_A ∈ Q(φ_A, w)` |
| 7 | `fCl_i(φ_A, φ'_A)` | `φ_A = F(i, w, φ'_A)` |
| 8 | `exec_G(α)` | `∃i ∈ G: α ∈ E(i, w)` |
| 9 | `do_G(φ_A)` or `do^P_i(φ_A)` | `φ ∈ S(w)` |
| 10 | `intend_i(φ_A)` | `φ_A ∈ A(i, w)` |
| 11 | `pref_do_i(φ_A, d)` | `φ_A ∈ A(i, w) ∩ H(i, w)` and `P(i, w, φ_A) = d` |
| 12 | `pref_do_G(i, φ_A)` | `i` has max preference in `G` for `φ_A` among feasible agents |
| 13 | `can_do_i(φ_A)` | `φ_A ∈ A(i, w) ∩ H(i, w)` |
| 14 | `can_do_G(φ_A)` | `∃i ∈ G: can_do_i(φ_A)` |
| 15 | `lend_G(i, H, φ_A)` | `G ∩ H = ∅`, `i ∈ H`, `φ_A ∈ A(i,w) ∩ H(i,w)`, `F(i, w, φ_A) = φ_A` |
| 16 | `[G:α]φ` | `M[G:α], w ⊨ φ` |

---

## 5. Trust Extension (CILC 2026)

### 5.1 Trust Predicate

| Formula | Reading |
|---------|---------|
| `trust_K(i, τ)` | Evaluator `K` assigns trust level `τ` to agent `i` |

**Trust levels** (finite ordered set):
```
very_low < low < medium < high < very_high
```

### 5.2 Trust Functions and Thresholds

| Package | Type | Description |
|---------|------|-------------|
| `T` | `Grp × Agt × W → Levels` | **Trust function** — assigns trust value |
| `Θ` | `Grp × Atm_A × W → Levels^5` | **Policy-threshold assignment** |

The threshold function assigns five thresholds per action:

| Threshold | Symbol | Description |
|-----------|--------|-------------|
| **Intention** | `τ^Π_I(φ_A, w)` | Minimum trust to **adopt the intention** |
| **Feasibility** | `τ^Π_C(φ_A, w)` | Minimum trust for **individual execution feasibility** |
| **Lending** | `τ^Π_L(φ_A, w)` | Minimum trust for **delegation** |
| **Blocking** | `τ^Π_B(φ_A, w)` | Trust level at or below which **action is blocked** |
| **Autonomy** | `τ^Π_A(φ_A, w)` | Minimum trust for **autonomous execution** |

**Invariant:** `τ^Π_B(φ_A, w) < τ^Π_A(φ_A, w)`

### 5.3 Trust-Sensitive Truth Conditions

| Formula | Trust-sensitive condition |
|---------|--------------------------|
| `intend_i(φ_A)` | `φ_A ∈ A(i,w)` **∧** `T(K,i,w) ≥ τ^Π_I(φ_A,w)` |
| `pref_do_i(φ_A, d)` | `φ_A ∈ A(i,w) ∩ H(i,w)` ∧ `P(i,w,φ_A)=d` **∧** `T(K,i,w) ≥ τ^Π_C(φ_A,w)` |
| `pref_do_G(i, φ_A)` | max preference in `G` among agents with `T(K,j,w) ≥ τ^Π_C(φ_A,w)` |
| `can_do_i(φ_A)` | `φ_A ∈ A(i,w) ∩ H(i,w)` **∧** `T(K,i,w) ≥ τ^Π_C(φ_A,w)` |
| `lend_G(i, H, φ_A)` | base conditions **∧** `T(G,i,w) ≥ τ^Π_L(φ_A,w)` |

### 5.4 Three-Valued Decision Policy

```
decision_{K,Π}(i, φ_A, w) =
    allow       if T(K, i, w) ≥ τ^Π_A(φ_A, w)
    delegate    if τ^Π_B(φ_A, w) < T(K, i, w) < τ^Π_A(φ_A, w)
    block       if T(K, i, w) ≤ τ^Π_B(φ_A, w)
```

This captures a genuine **grey zone**: an agent may be able and willing to act, yet not sufficiently trusted for autonomous execution, making delegation the appropriate outcome.

### 5.5 Trust Axioms

- **(AxT1)** `intend_i(φ_A) → Trust^{K,Π}_{≥I}(i, φ_A)`
- **(AxT2)** `intend_G(φ_A) ↔ ⋀_{i∈G} intend_i(φ_A)`
- **(AxT3)** `pref_do_i(φ_A, d) → Trust^{K,Π}_{≥C}(i, φ_A)`
- **(AxT4)** `pref_do_G(i, φ_A) → Trust^{K,Π}_{≥C}(i, φ_A)`
- **(AxT5)** `can_do_i(φ_A) → Trust^{K,Π}_{≥C}(i, φ_A)`
- **(AxT6)** `can_do_G(φ_A) ↔ ⋁_{i∈G} can_do_i(φ_A)`
- **(AxT7)** `lend_G(i, H, φ_A) → (G∩H=∅) ∧ (i∈H) ∧ can_do_i(φ_A) ∧ fCl_i(φ_A, φ_A) ∧ Trust^{G,Π}_{≥L}(i, φ_A)`

---

## 6. Probabilistic Package (LAMAS 2026)

### 6.1 Probabilistic Package `P^prob_M = (μ, ρ, θ)`

| Component | Type | Description |
|-----------|------|-------------|
| `μ(i, w)` | Probability measure over `R_i(w)` | Assigns probabilities to epistemic alternatives |
| `ρ(i, w, φ_A) ∈ [0,1]` | Success probability | Probability that action `φ_A` succeeds |
| `θ(i, w) ∈ [0,1]` | Acceptance threshold | Minimum probability for deliberation |

**Epistemic invariance:** if `wR_iv` then `μ(i,w) = μ(i,v)`, `ρ(i,w,φ_A) = ρ(i,v,φ_A)`, `θ(i,w) = θ(i,v)`.

### 6.2 Probabilistic Explicit Belief

```
M, w ⊨ B^{≥q}_i(φ)  iff  μ(i, w)(‖φ‖^M_{i,w}) ≥ q
```

Thresholded form: `B^θ_i(φ) ≡ B^{≥θ(i,w)}_i(φ)`

### 6.3 Probabilistic Executability

```
M, w ⊨ can_do^{≥q}_i(φ_A)  iff
    φ_A ∈ A(i, w) ∩ H(i, w)  ∧  C2(i, φ_A, w) ≤ B2(i, w)  ∧  ρ(i, w, φ_A) ≥ q
```

For groups: `can_do^{≥q}_G(φ_A) iff ∃i ∈ G: can_do^{≥q}_i(φ_A)`

### 6.4 Probabilistic Selector `F^prob_π`

**Candidate set** (feasible equivalent actions):
```
Cand^w_i(φ_A) = {ψ_A : ψ_A ∈ Q(φ_A, w) ∧ ψ_A ∈ A(i,w) ∩ H(i,w) ∧ C2(i,ψ_A,w) ≤ B2(i,w)}
```

**Decision policy** `π = (λ_ρ, λ_P, λ_C)`:

```
score^{w,π}_i(ψ_A) = λ_ρ · ρ(i, w, ψ_A)
                     + λ_P · P(i, w, ψ_A) / P_max
                     − λ_C · sum(C2(i, ψ_A, w)) / sum(B2(i, w))
```

**Selection rule:**
```
F^prob_π(i, w, φ_A) = arg max_{ψ_A ∈ Cand^w_i(φ_A)} score^{w,π}_i(ψ_A)
```

**Tie-breaking:** (1) maximal success probability, (2) minimal resource consumption, (3) fixed total order on action names.

### 6.5 Properties

- **Well-definedness:** If `Cand^w_i(φ_A)` is finite and non-empty, `P_max > 0`, and `sum(B2(i,w)) > 0`, then `F^prob_π` returns a unique action.
- **Conservativity:** All formulas and conditions of the original L-DINF language keep the same truth value in the probabilistic extension.

---

## 7. ASP-to-L-DINF Compilation (NMR 2026)

The compilation function `τ` bridges ASP scheduling artifacts and L-DINF theories.

### 7.1 Compilation Function

```
τ(Π_P, S) = τ_P(Π^gr_P) ∪ τ^IC_P(IC^gr_P) ∪ τ^S_P(S)
```

### 7.2 Atomic Translation `τ_P`

| ASP Atom | L-DINF Translation |
|----------|--------------------|
| Default atom `a` | `B_{i_P}(a)` — stored as belief |
| `preference(P, C)` | `B_{i_P}(prefers_clinic(C))` |
| `appointment_preference(P, C, S, E)` | `B_{i_P}(slot(C, S, E))` ∪ `{pref_do_{i_P}(slot(C, t), d_time) \| t ∈ AvailSlots(C), S ≤ t ≤ E}` |
| `sensory_preference(P, s)` | `B_{i_P}(preferences(s))` |
| `doctor_preference(P, Type, Spec, N)` | `B_{i_P}(doctor_req(Type, Spec, N))` |
| `distance(P, C, δ)` | `B_{i_P}(dist(C, δ))` |

### 7.3 Constraint Translation `τ^IC_P`

For each ground integrity constraint `κ` forbidding action `φ_A` when condition `cond` holds:
```
τ^IC_P(κ) = {B_{i_P}(cond → ¬can_do_{i_P}(φ_A))}
```

**Soundness:** If an agent believes `cond`, then it believes `¬can_do_{i_P}(φ_A)`, ensuring hard scheduling constraints are preserved during runtime adaptation.

### 7.4 Schedule Import `τ^S_P`

For each baseline schedule atom `appointment(P, C, D, t)`:
```
τ^S_P(s) = {intend_{i_P}(consultation(t))}
```

After execution: `do^P_{i_P}(consultation(t))`.

---

## 8. Hybrid Execution Model (NMR 2026)

The hybrid ASP + L-DINF architecture operates as follows:

1. **ASP Layer** computes a globally feasible baseline schedule `S` from static persona constraints
2. **Compilation** `τ` translates relevant scheduling artifacts into L-DINF beliefs, intentions, feasibility conditions, and preferences
3. **L-DINF Layer** is activated only on disruptions:
   - Disruptions update beliefs via mental action `+φ` (e.g., `+¬can_do_docJ(consultation(t1))`)
   - Compiled `can_do` conditions determine which repair actions remain feasible
   - Compiled preferences guide local choice among executable repairs
   - Inter-group **lending** allows temporary delegation when no local repair is available
4. **Fallback** to ASP re-optimization only when local repair exceeds scope

---

## 9. Summary: L-DINF Rules at a Glance

| Category | Rule / Construct | Source |
|----------|-----------------|--------|
| **Belief** | `B_i(φ)` — explicit belief | Base L-DINF |
| **Knowledge** | `K_i(φ)` — background knowledge | Base L-DINF |
| **Intention** | `intend_i(φ_A)` — BDI-style intention | Base L-DINF |
| **Feasibility** | `can_do_i(φ_A)` — action executability | Base L-DINF |
| **Preference** | `pref_do_i(φ_A, d)` — preference degree | Base L-DINF |
| **Equivalence** | `Cl(φ_A, φ'_A)`, `fCl_i(φ_A, φ'_A)` | Base L-DINF |
| **Execution** | `do_i(φ_A)`, `do^P_i(φ_A)` | Base L-DINF |
| **Group Capability** | `can_do_G(φ_A)` — existential | Base L-DINF |
| **Lending** | `lend_G(i, H, φ_A)` — inter-group delegation | Base L-DINF |
| **Mental Actions** | `+φ`, `↓(φ,ψ)`, `∩(φ,ψ)`, `⊢(φ,ψ)`, `⊣(φ,ψ)` | Base L-DINF |
| **Dynamic Operator** | `[G:α]φ` — effect of mental action | Base L-DINF |
| **Trust** | `trust_K(i, τ)` — trust predicate | CILC 2026 |
| **Trust Thresholds** | `τ_I, τ_C, τ_L, τ_B, τ_A` per action | CILC 2026 |
| **Decision Policy** | `allow / delegate / block` | CILC 2026 |
| **Prob. Belief** | `B^{≥q}_i(φ)` — graded belief | LAMAS 2026 |
| **Prob. Executability** | `can_do^{≥q}_i(φ_A)` | LAMAS 2026 |
| **Prob. Selector** | `F^prob_π` with `score(ψ_A)` | LAMAS 2026 |
| **ASP Compilation** | `τ_P`, `τ^IC_P`, `τ^S_P` | NMR 2026 |

---

## References

- Costantini, S., Formisano, A., Pitoni, V. (2023). *An epistemic logic for formalizing group dynamics of agents.* Interaction Studies 23, 391–426.
- Costantini, S., Formisano, A., Pitoni, V. (2022). *Cooperation among groups of agents in the epistemic logic L-DINF.* RuleML+RR 2022, LNCS 13752, 280–295.
- Costantini, S., Formisano, A., Pitoni, V. (2023). *Preference management in epistemic logic L-DINF.* CILC 2023, CEUR Workshop Proceedings 3428.
- Balbiani, P., Fernández-Duque, D., Lorini, E. (2016). *A logical theory of belief dynamics for resource-bounded agents.* AAMAS 2016, 644–652.
- Balbiani, P., Fernández-Duque, D., Lorini, E. (2019). *The dynamics of epistemic attitudes in resource-bounded agents.* Studia Logica 107(3), 457–488.
- Lorini, E. (2019). *Reasoning about cognitive attitudes in a qualitative setting.* JELIA 2019, 726–743.

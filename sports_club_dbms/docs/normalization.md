# Database Normalization Report

## Project: Sports Club Membership and Tournament Management System

---

## 1. Executive Summary & Normalization Objectives

Database normalization is the systematic technique of organizing relational database schemas to minimize data redundancy and eliminate anomalies during `INSERT`, `UPDATE`, and `DELETE` operations.

This architecture achieves **Third Normal Form (3NF)** and **Boyce-Codd Normal Form (BCNF)** across all **14 relational tables**. 

### Standard Relational Definitions Applied:
- **First Normal Form (1NF):** Each relation contains only atomic (indivisible) attributes; no repeating groups, comma-separated lists, or arrays; and a unique primary key identifies every row.
- **Second Normal Form (2NF):** The relation is in 1NF and contains **no partial functional dependencies** (no non-prime attribute is functionally dependent on a proper subset of any composite candidate key).
- **Third Normal Form (3NF):** The relation is in 2NF and contains **no transitive functional dependencies** (no non-prime attribute depends on another non-prime attribute; for every functional dependency $X \rightarrow Y$, $X$ is a superkey or $Y$ is a prime attribute).
- **Deliberate Denormalization:** **None.** All aggregations (points, standings, dues, loan balances) are computed dynamically via optimized views and stored procedures rather than stored redundantly in base tables.

---

## 2. Table-by-Table Normalization & Functional Dependency Analysis

---

### Table 1: `membership_plan`
- **Schema:** `(plan_id, plan_name, duration_months, fee, benefits)`
- **Candidate Keys:** `{plan_id}`, `{plan_name}`
- **Primary Key:** `plan_id`
- **Functional Dependencies (FDs):**
  - $FD_1: \text{plan_id} \rightarrow \{\text{plan_name, duration_months, fee, benefits}\}$
  - $FD_2: \text{plan_name} \rightarrow \{\text{plan_id, duration_months, fee, benefits}\}$
- **Normalization Justification:**
  - **1NF:** All attribute values are atomic; no repeating groups.
  - **2NF:** The primary key is a single attribute (`plan_id`), making partial key dependency mathematically impossible.
  - **3NF:** No non-prime attribute determines another non-prime attribute. Every determinant is a candidate key.

---

### Table 2: `member`
- **Schema:** `(member_id, name, phone, email, dob, join_date, plan_id, membership_start, membership_end, status)`
- **Candidate Keys:** `{member_id}`, `{phone}`, `{email}`
- **Primary Key:** `member_id`
- **Functional Dependencies (FDs):**
  - $FD_1: \text{member_id} \rightarrow \{\text{name, phone, email, dob, join_date, plan_id, membership_start, membership_end, status}\}$
  - $FD_2: \text{phone} \rightarrow \{\text{member_id, name, email, dob, join_date, plan_id, membership_start, membership_end, status}\}$
  - $FD_3: \text{email} \rightarrow \{\text{member_id, name, phone, dob, join_date, plan_id, membership_start, membership_end, status}\}$
- **Normalization Justification:**
  - **1NF:** Atomic attributes. Phone and email are strictly scalar strings.
  - **2NF:** Single-attribute primary key. No partial dependencies exist.
  - **3NF:** Plan fee and duration are not duplicated here; they are referenced solely via foreign key `plan_id`. All non-prime attributes depend directly on candidate keys.

---

### Table 3: `payment`
- **Schema:** `(payment_id, member_id, plan_id, amount, payment_date, mode, status)`
- **Candidate Keys:** `{payment_id}`
- **Primary Key:** `payment_id`
- **Functional Dependencies (FDs):**
  - $FD_1: \text{payment_id} \rightarrow \{\text{member_id, plan_id, amount, payment_date, mode, status}\}$
- **Normalization Justification:**
  - **1NF:** All attributes are scalar values.
  - **2NF:** Single-attribute primary key (`payment_id`).
  - **3NF:** Member name, email, and plan name are excluded to prevent transitive dependencies ($payment\_id \rightarrow member\_id \rightarrow email$ is prevented by storing only `member_id`).

---

### Table 4: `sport`
- **Schema:** `(sport_id, sport_name, category, max_team_size)`
- **Candidate Keys:** `{sport_id}`, `{sport_name}`
- **Primary Key:** `sport_id`
- **Functional Dependencies (FDs):**
  - $FD_1: \text{sport_id} \rightarrow \{\text{sport_name, category, max_team_size}\}$
  - $FD_2: \text{sport_name} \rightarrow \{\text{sport_id, category, max_team_size}\}$
- **Normalization Justification:**
  - **1NF / 2NF / 3NF:** Holds discrete sport metadata. Determinants are superkeys.

---

### Table 5: `coach`
- **Schema:** `(coach_id, name, phone, specialization, sport_id)`
- **Candidate Keys:** `{coach_id}`, `{phone}`
- **Primary Key:** `coach_id`
- **Functional Dependencies (FDs):**
  - $FD_1: \text{coach_id} \rightarrow \{\text{name, phone, specialization, sport_id}\}$
  - $FD_2: \text{phone} \rightarrow \{\text{coach_id, name, specialization, sport_id}\}$
- **Normalization Justification:**
  - **1NF / 2NF / 3NF:** Eliminates redundant sport descriptions by referencing `sport_id`.

---

### Table 6: `team`
- **Schema:** `(team_id, team_name, sport_id, coach_id, formed_on)`
- **Candidate Keys:** `{team_id}`, `{team_name}`
- **Primary Key:** `team_id`
- **Functional Dependencies (FDs):**
  - $FD_1: \text{team_id} \rightarrow \{\text{team_name, sport_id, coach_id, formed_on}\}$
  - $FD_2: \text{team_name} \rightarrow \{\text{team_id, sport_id, coach_id, formed_on}\}$
- **Normalization Justification:**
  - **1NF / 2NF / 3NF:** Decoupled from player rosters and match records. Contains only team-level attributes.

---

### Table 7: `team_member`
- **Schema:** `(team_member_id, team_id, member_id, role, joined_on)`
- **Candidate Keys:** `{team_member_id}`, `{team_id, member_id}`
- **Primary Key:** `team_member_id`
- **Functional Dependencies (FDs):**
  - $FD_1: \text{team_member_id} \rightarrow \{\text{team_id, member_id, role, joined_on}\}$
  - $FD_2: \{\text{team_id, member_id}\} \rightarrow \{\text{team_member_id, role, joined_on}\}$
- **Normalization Justification:**
  - Resolves the many-to-many relationship between `team` and `member`.
  - **2NF:** Non-prime attributes (`role`, `joined_on`) depend on the whole composite key `{team_id, member_id}`.
  - **3NF:** No non-prime attribute determines another non-prime attribute.

---

### Table 8: `facility`
- **Schema:** `(facility_id, facility_name, type, capacity, status)`
- **Candidate Keys:** `{facility_id}`, `{facility_name}`
- **Primary Key:** `facility_id`
- **Functional Dependencies (FDs):**
  - $FD_1: \text{facility_id} \rightarrow \{\text{facility_name, type, capacity, status}\}$
- **Normalization Justification:**
  - **1NF / 2NF / 3NF:** Clean physical venue definition without scheduling overlap data.

---

### Table 9: `training_session`
- **Schema:** `(session_id, team_id, coach_id, facility_id, session_date, start_time, end_time, max_attendees)`
- **Candidate Keys:** `{session_id}`, `{facility_id, session_date, start_time}`, `{team_id, session_date, start_time}`
- **Primary Key:** `session_id`
- **Functional Dependencies (FDs):**
  - $FD_1: \text{session_id} \rightarrow \{\text{team_id, coach_id, facility_id, session_date, start_time, end_time, max_attendees}\}$
- **Normalization Justification:**
  - Stores single discrete event reservations. Venue and coach names are normalized via foreign keys. In 3NF.

---

### Table 10: `tournament`
- **Schema:** `(tournament_id, tournament_name, sport_id, start_date, end_date)`
- **Candidate Keys:** `{tournament_id}`
- **Primary Key:** `tournament_id`
- **Functional Dependencies (FDs):**
  - $FD_1: \text{tournament_id} \rightarrow \{\text{tournament_name, sport_id, start_date, end_date}\}$
- **Normalization Justification:**
  - **1NF / 2NF / 3NF:** Parent entity for fixtures. Contains no embedded score arrays or round data.

---

### Table 11: `fixture`
- **Schema:** `(fixture_id, tournament_id, facility_id, team1_id, team2_id, fixture_date, start_time, end_time, status)`
- **Candidate Keys:** `{fixture_id}`, `{facility_id, fixture_date, start_time}`
- **Primary Key:** `fixture_id`
- **Functional Dependencies (FDs):**
  - $FD_1: \text{fixture_id} \rightarrow \{\text{tournament_id, facility_id, team1_id, team2_id, fixture_date, start_time, end_time, status}\}$
- **Normalization Justification:**
  - Distinct matchup scheduled between two normalized teams.
  - Does NOT embed match result scores (stored separately in `result` table to preserve 1NF and handle non-completed fixtures cleanly).

---

### Table 12: `participant`
- **Schema:** `(participant_id, fixture_id, team_id, member_id, role)`
- **Candidate Keys:** `{participant_id}`, `{fixture_id, member_id}`
- **Primary Key:** `participant_id`
- **Functional Dependencies (FDs):**
  - $FD_1: \text{participant_id} \rightarrow \{\text{fixture_id, team_id, member_id, role}\}$
  - $FD_2: \{\text{fixture_id, member_id}\} \rightarrow \{\text{participant_id, team_id, role}\}$
- **Normalization Justification:**
  - Deconstructs match lineups. In 3NF/BCNF.

---

### Table 13: `result`
- **Schema:** `(result_id, fixture_id, team1_score, team2_score, winner_team_id, remarks)`
- **Candidate Keys:** `{result_id}`, `{fixture_id}`
- **Primary Key:** `result_id`
- **Functional Dependencies (FDs):**
  - $FD_1: \text{result_id} \rightarrow \{\text{fixture_id, team1_score, team2_score, winner_team_id, remarks}\}$
  - $FD_2: \text{fixture_id} \rightarrow \{\text{result_id, team1_score, team2_score, winner_team_id, remarks}\}$
- **Normalization Justification:**
  - Separates match outcome from scheduling.
  - `winner_team_id` is an explicit foreign key verified via trigger constraints.
  - Zero denormalized standings points stored; standings are computed via view `v_tournament_standings`.

---

### Table 14: `equipment_issue`
- **Schema:** `(issue_id, member_id, equipment_name, quantity, issue_date, due_date, return_date, status)`
- **Candidate Keys:** `{issue_id}`
- **Primary Key:** `issue_id`
- **Functional Dependencies (FDs):**
  - $FD_1: \text{issue_id} \rightarrow \{\text{member_id, equipment_name, quantity, issue_date, due_date, return_date, status}\}$
- **Normalization Justification:**
  - **1NF / 2NF / 3NF:** Tracks discrete checkout transactions.

---

## 3. Summary of Normalization Conformance

| Table Name | Normal Form Achieved | Determinants are Superkeys? | Redundancy Elimination |
| :--- | :---: | :---: | :--- |
| `membership_plan` | **3NF / BCNF** | Yes | Tier fees and durations centralized |
| `member` | **3NF / BCNF** | Yes | Personal records separate from payments |
| `payment` | **3NF / BCNF** | Yes | Pure financial audit ledger |
| `sport` | **3NF / BCNF** | Yes | Disciplines cataloged independently |
| `coach` | **3NF / BCNF** | Yes | Coaching staff isolated from team lifecycle |
| `team` | **3NF / BCNF** | Yes | Club athletic franchises separate from rosters |
| `team_member` | **3NF / BCNF** | Yes | Normalized M:N relationship bridge |
| `facility` | **3NF / BCNF** | Yes | Venue inventory de-duplicated |
| `training_session` | **3NF / BCNF** | Yes | Atomic practice drills calendar |
| `tournament` | **3NF / BCNF** | Yes | Master sports event lifecycle |
| `fixture` | **3NF / BCNF** | Yes | Pure match scheduling |
| `participant` | **3NF / BCNF** | Yes | Normalized player-to-match lineups |
| `result` | **3NF / BCNF** | Yes | 1:1 post-match audit entity |
| `equipment_issue` | **3NF / BCNF** | Yes | Inventory custody tracking |

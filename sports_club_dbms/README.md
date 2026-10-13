# Sports Club Membership and Tournament Management DBMS

A comprehensive, production-grade academic database management system built with **MySQL 8.x**, **Python 3.10+ / 3.11+**, and **Flask**. Designed for professional athletic facilities and multi-sport clubs, this system orchestrates patron subscriptions, team rosters, coaching schedules, tournament fixtures, automated standings, fee accounting, and equipment custody.

---

## 🏛️ System Architecture

```
sports_club_dbms/
├── sql/
│   ├── 01_schema.sql          # 14 normalized tables, constraints, foreign keys, indexes
│   ├── 02_triggers.sql        # 8 business rule triggers (collision prevention, quotas)
│   ├── 03_procedures.sql      # Atomic stored procedures with transaction handling
│   ├── 04_sample_data.sql     # Realistic Indian club dataset satisfying all constraints
│   ├── 05_queries.sql         # 27 analytical queries (joins, aggregations, subqueries)
│   └── 06_views.sql           # 8 operational and analytical database views
├── app/
│   ├── app.py                 # Flask server implementing 10 end-to-end modules
│   ├── db.py                  # Database connection pooling & error sanitization
│   ├── validators.py          # Strict server-side payload and format validation
│   ├── static/
│   │   ├── css/style.css      # Bespoke modern dark & glassmorphism theme
│   │   └── js/main.js         # Interactive conflict checker & UI behaviors
│   └── templates/             # Jinja2 templates (Bootstrap 5 CDN + Icons)
│       ├── base.html
│       ├── index.html         # Module 1: Dashboard
│       ├── members.html       # Module 2: Membership Management
│       ├── member_renew.html  # Module 2: Renewal Form
│       ├── teams.html         # Module 3: Team Formation
│       ├── team_detail.html   # Module 3: Roster Management
│       ├── training.html      # Module 4: Training Scheduling
│       ├── facility_booking.html # Module 5: Facilities & Conflict Checker
│       ├── fixtures.html      # Module 6: Match Fixtures
│       ├── results.html       # Module 7: Result Entry
│       ├── payments.html      # Module 8: Fee Collection
│       ├── equipment.html     # Module 9: Equipment Checkout & Return
│       └── reports.html       # Module 10: Reports & CSV Export
├── tests/
│   ├── test_constraints.sql   # 26 automated SQL tests (13 Fail cases + 13 Pass cases)
│   └── test_app.py            # 21 pytest unit & integration tests
├── docs/
│   ├── normalization.md       # Functional dependencies & 3NF/BCNF proofs
│   ├── er_diagram.mmd         # Mermaid Entity-Relationship diagram
│   └── test_report.md         # Full test verification matrix (100% PASS)
├── requirements.txt
├── .env.example
├── .env
└── README.md
```

---

## 📋 Technology Stack

- **RDBMS:** MySQL 8.x (InnoDB engine, strict UTF-8 Unicode, Check constraints, Event scheduler)
- **Backend:** Python 3.10+ / 3.11+, Flask 3.x, `mysql-connector-python`
- **Frontend:** Jinja2, Vanilla CSS (Custom Design System), Bootstrap 5.3.3 (CDN), Bootstrap Icons
- **Testing:** `pytest`, MySQL stored test procedure harness

---

## ⚡ Quick Start & Setup Instructions

### 1. Database Setup in MySQL 8

Log into your local MySQL 8 server and create the database and user:

```sql
CREATE DATABASE IF NOT EXISTS sports_club_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'sports_user'@'localhost' IDENTIFIED BY 'sports_pass';
CREATE USER IF NOT EXISTS 'sports_user'@'%' IDENTIFIED BY 'sports_pass';
GRANT ALL PRIVILEGES ON sports_club_db.* TO 'sports_user'@'localhost', 'sports_user'@'%';
SET GLOBAL log_bin_trust_function_creators = 1;
FLUSH PRIVILEGES;
```

### 2. Run the SQL Scripts in Exact Numerical Order

Execute all 6 SQL scripts against the `sports_club_db` database:

```bash
# Windows PowerShell
$files = @("01_schema.sql", "02_triggers.sql", "03_procedures.sql", "04_sample_data.sql", "05_queries.sql", "06_views.sql")
foreach ($f in $files) {
    mysql -h 127.0.0.1 -P 3307 -u sports_user -psports_pass sports_club_db -e "source sql/$f"
}
```

*All 6 files execute in order with 0 errors!*

### 3. Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure Environment Variables

Create `.env` (or copy from `.env.example`):

```ini
DB_HOST=127.0.0.1
DB_PORT=3307
DB_USER=sports_user
DB_PASSWORD=sports_pass
DB_NAME=sports_club_db
SECRET_KEY=sports_club_super_secret_key_2026
PORT=5000
```

### 5. Start the Web Application

```bash
python app/app.py
```

Open your browser and navigate to:
**`http://127.0.0.1:5000`**

---

## 🧪 Running the Tests

### 1. Automated Database Constraints Test Harness (`test_constraints.sql`)

Runs 26 test assertions (13 failing constraint violation cases + 13 passing cases):

```bash
mysql -h 127.0.0.1 -P 3307 -u sports_user -psports_pass sports_club_db -e "source tests/test_constraints.sql"
```

**Expected Result:**
```
total_tests_executed: 26 | passed_tests: 26 | failed_tests: 0 | overall_verdict: 100% PASS
```

### 2. Python Flask & Validator Test Suite (`pytest`)

```bash
pytest tests/test_app.py -v
```

**Expected Result:**
```
============================= 21 passed in 0.63s ==============================
```

---

## 🔒 Business Rules & Integrity Constraints Enforced

1. **No Overlapping Facility Schedule:** Prevents double-booking any facility across training sessions and tournament matches simultaneously.
2. **No Overlapping Team Schedule:** A squad cannot be scheduled for two concurrent events across disparate venues.
3. **Active Membership Required:** Patrons must maintain `status = 'Active'` and non-expired validity to enroll in squads, participate in matches, or check out sports gear.
4. **Valid Result & Winner Consistency:** Scores must be $\ge 0$; winner must equal the higher-scoring team (or NULL for tie); results can only be recorded for `Scheduled` fixtures.
5. **Capacity Limits:** Squad sizes cannot exceed `sport.max_team_size`; attendees cannot exceed `facility.capacity`.
6. **Equipment Custody Limits:** Members may hold at most 3 unreturned items at once; checkout is blocked if any item is overdue.
7. **Facility Maintenance Protection:** Venues with status `Maintenance` cannot be reserved.
8. **Sport Consistency:** Coach specialization, team sport, and tournament discipline must match strictly.

---

## 📊 Analytical Views & Reporting

The system provides 8 live database views accessible via the interactive **Analytics & Reports** module (with one-click CSV export):

1. `v_active_memberships`: Current active club members with calculated days remaining.
2. `v_membership_expiring_30_days`: Proactive renewal alerts for subscriptions ending within 30 days.
3. `v_fixture_schedule`: Complete tournament match calendar with scores and winners.
4. `v_tournament_standings`: Dynamic league standings with 3-1-0 points, goal difference, and rankings.
5. `v_facility_utilization`: Venue utilization comparing training drills vs tournament bookings.
6. `v_player_performance`: Match appearances and team win tallies per player.
7. `v_fee_dues`: Members with unpaid subscriptions or lapsed memberships.
8. `v_equipment_status`: Loaned inventory counts (Issued, Returned, Overdue) per member.

---

## 📸 Screenshots & UI Showcase

| Module | Feature Highlight |
| :--- | :--- |
| **Dashboard** | Metric stat cards, upcoming match fixtures, overdue gear alerts |
| **Memberships** | Search, filter by plan and status, register modal calling `sp_register_member_with_payment` |
| **Team Rosters** | Squad progress meters, add/remove players with trigger validations |
| **Conflict Checker** | Live venue availability checker with conflict diagnostics |
| **Result Entry** | Score recorder with automated winner resolution via `sp_enter_result` |
| **Reports** | Tabbed dynamic view explorer with instant CSV data downloads |

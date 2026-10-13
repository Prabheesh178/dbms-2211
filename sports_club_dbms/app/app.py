"""Main Flask Web Application for Sports Club DBMS.
Exposes routes for all 10 modules: Dashboard, Members, Teams, Training,
Facilities, Fixtures, Results, Payments, Equipment, and Reports.
"""

import csv
import io
import os
from datetime import datetime, date
from flask import (
    Flask,
    render_template,
    request,
    redirect,
    url_for,
    flash,
    Response,
    jsonify,
)
from dotenv import load_dotenv

from db import query_all, query_one, execute_modify, call_procedure, clean_db_error
import validators

load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY", "sports_club_secret_key_2026")


# Custom template filter for date formatting
@app.template_filter("format_date")
def format_date_filter(value):
    if not value:
        return ""
    if isinstance(value, (datetime, date)):
        return value.strftime("%d %b %Y")
    try:
        dt = datetime.strptime(str(value), "%Y-%m-%d")
        return dt.strftime("%d %b %Y")
    except Exception:
        return str(value)


# ============================================================================
# MODULE 1: DASHBOARD
# ============================================================================
@app.route("/")
def dashboard():
    # Key counters
    stats = {
        "active_members": query_one("SELECT COUNT(*) AS c FROM member WHERE status = 'Active'")["c"],
        "total_teams": query_one("SELECT COUNT(*) AS c FROM team")["c"],
        "upcoming_fixtures": query_one("SELECT COUNT(*) AS c FROM fixture WHERE status = 'Scheduled' AND fixture_date >= CURDATE()")["c"],
        "overdue_equipment": query_one("SELECT COUNT(*) AS c FROM equipment_issue WHERE status = 'Overdue' OR (return_date IS NULL AND due_date < CURDATE())")["c"],
        "total_revenue": query_one("SELECT COALESCE(SUM(amount), 0) AS s FROM payment WHERE status = 'Paid'")["s"],
        "pending_dues_count": query_one("SELECT COUNT(*) AS c FROM member WHERE status = 'Expired'")["c"],
    }

    upcoming_fixtures = query_all("""
        SELECT fx.fixture_id, tr.tournament_name, t1.team_name AS team1, t2.team_name AS team2,
               f.facility_name, fx.fixture_date, fx.start_time
        FROM fixture fx
        JOIN tournament tr ON fx.tournament_id = tr.tournament_id
        JOIN team t1 ON fx.team1_id = t1.team_id
        JOIN team t2 ON fx.team2_id = t2.team_id
        JOIN facility f ON fx.facility_id = f.facility_id
        WHERE fx.status = 'Scheduled'
        ORDER BY fx.fixture_date ASC, fx.start_time ASC
        LIMIT 5
    """)

    overdue_gear = query_all("""
        SELECT eq.issue_id, m.name AS member_name, m.phone, eq.equipment_name,
               eq.quantity, eq.due_date, DATEDIFF(CURDATE(), eq.due_date) AS days_overdue
        FROM equipment_issue eq
        JOIN member m ON eq.member_id = m.member_id
        WHERE eq.status = 'Overdue' OR (eq.return_date IS NULL AND eq.due_date < CURDATE())
        ORDER BY eq.due_date ASC
        LIMIT 5
    """)

    return render_template(
        "index.html",
        stats=stats,
        upcoming_fixtures=upcoming_fixtures,
        overdue_gear=overdue_gear,
    )


# ============================================================================
# MODULE 2: MEMBERSHIP MANAGEMENT
# ============================================================================
@app.route("/members")
def members_list():
    search = request.args.get("search", "").strip()
    status_filter = request.args.get("status", "").strip()
    plan_filter = request.args.get("plan_id", "").strip()

    sql = """
        SELECT m.member_id, m.name, m.phone, m.email, m.dob, m.join_date,
               m.membership_start, m.membership_end, m.status, mp.plan_name, mp.fee
        FROM member m
        JOIN membership_plan mp ON m.plan_id = mp.plan_id
        WHERE 1=1
    """
    params = []

    if search:
        sql += " AND (m.name LIKE %s OR m.email LIKE %s OR m.phone LIKE %s)"
        pattern = f"%{search}%"
        params.extend([pattern, pattern, pattern])

    if status_filter:
        sql += " AND m.status = %s"
        params.append(status_filter)

    if plan_filter and plan_filter.isdigit():
        sql += " AND m.plan_id = %s"
        params.append(int(plan_filter))

    sql += " ORDER BY m.member_id DESC"
    members = query_all(sql, tuple(params))
    plans = query_all("SELECT plan_id, plan_name, fee, duration_months FROM membership_plan ORDER BY fee ASC")

    return render_template(
        "members.html",
        members=members,
        plans=plans,
        search=search,
        status_filter=status_filter,
        plan_filter=plan_filter,
    )


@app.route("/members/register", methods=["POST"])
def member_register():
    data = {
        "name": request.form.get("name", "").strip(),
        "phone": request.form.get("phone", "").strip(),
        "email": request.form.get("email", "").strip(),
        "dob": request.form.get("dob", "").strip(),
        "plan_id": request.form.get("plan_id", "").strip(),
        "mode": request.form.get("mode", "UPI").strip(),
    }

    errors = validators.validate_member_registration(data)
    if errors:
        for err in errors:
            flash(err, "danger")
        return redirect(url_for("members_list"))

    try:
        # Atomic stored procedure call
        out_args = call_procedure(
            "sp_register_member_with_payment",
            (
                data["name"],
                data["phone"],
                data["email"],
                data["dob"],
                int(data["plan_id"]),
                data["mode"],
                0,  # OUT p_member_id
                0,  # OUT p_payment_id
            ),
        )
        new_member_id = out_args[6]
        flash(f"Member successfully registered! Assigned Member ID: {new_member_id}", "success")
    except Exception as e:
        flash(f"Registration error: {clean_db_error(e)}", "danger")

    return redirect(url_for("members_list"))


@app.route("/members/renew/<int:member_id>", methods=["GET", "POST"])
def member_renew(member_id):
    member = query_one("""
        SELECT m.*, mp.plan_name, mp.fee, mp.duration_months
        FROM member m
        JOIN membership_plan mp ON m.plan_id = mp.plan_id
        WHERE m.member_id = %s
    """, (member_id,))

    if not member:
        flash("Member not found.", "warning")
        return redirect(url_for("members_list"))

    plans = query_all("SELECT plan_id, plan_name, fee, duration_months FROM membership_plan ORDER BY fee ASC")

    if request.method == "POST":
        plan_id = request.form.get("plan_id")
        mode = request.form.get("mode", "UPI")

        if not plan_id or not plan_id.isdigit():
            flash("Please choose a valid membership plan.", "danger")
            return render_template("member_renew.html", member=member, plans=plans)

        try:
            call_procedure("sp_renew_membership", (member_id, int(plan_id), mode, 0))
            flash(f"Membership successfully renewed for {member['name']}!", "success")
            return redirect(url_for("members_list"))
        except Exception as e:
            flash(f"Renewal failed: {clean_db_error(e)}", "danger")

    return render_template("member_renew.html", member=member, plans=plans)


# ============================================================================
# MODULE 3: TEAM FORMATION & ROSTERS
# ============================================================================
@app.route("/teams")
def teams_list():
    teams = query_all("""
        SELECT t.team_id, t.team_name, t.formed_on, s.sport_id, s.sport_name,
               s.max_team_size, c.name AS coach_name,
               COUNT(tm.team_member_id) AS current_members
        FROM team t
        JOIN sport s ON t.sport_id = s.sport_id
        LEFT JOIN coach c ON t.coach_id = c.coach_id
        LEFT JOIN team_member tm ON t.team_id = tm.team_id
        GROUP BY t.team_id, t.team_name, t.formed_on, s.sport_id, s.sport_name, s.max_team_size, c.name
        ORDER BY t.team_name ASC
    """)
    sports = query_all("SELECT * FROM sport ORDER BY sport_name")
    coaches = query_all("SELECT c.*, s.sport_name FROM coach c JOIN sport s ON c.sport_id = s.sport_id ORDER BY c.name")
    return render_template("teams.html", teams=teams, sports=sports, coaches=coaches)


@app.route("/teams/create", methods=["POST"])
def team_create():
    name = request.form.get("team_name", "").strip()
    sport_id = request.form.get("sport_id", "").strip()
    coach_id = request.form.get("coach_id", "").strip()

    if not name or not sport_id:
        flash("Team name and sport are required.", "danger")
        return redirect(url_for("teams_list"))

    coach_val = int(coach_id) if (coach_id and coach_id.isdigit()) else None

    try:
        execute_modify(
            "INSERT INTO team (team_name, sport_id, coach_id, formed_on) VALUES (%s, %s, %s, CURDATE())",
            (name, int(sport_id), coach_val),
        )
        flash(f"Team '{name}' formed successfully!", "success")
    except Exception as e:
        flash(f"Could not create team: {clean_db_error(e)}", "danger")

    return redirect(url_for("teams_list"))


@app.route("/teams/<int:team_id>")
def team_detail(team_id):
    team = query_one("""
        SELECT t.*, s.sport_name, s.max_team_size, c.name AS coach_name, c.phone AS coach_phone
        FROM team t
        JOIN sport s ON t.sport_id = s.sport_id
        LEFT JOIN coach c ON t.coach_id = c.coach_id
        WHERE t.team_id = %s
    """, (team_id,))

    if not team:
        flash("Team not found.", "warning")
        return redirect(url_for("teams_list"))

    roster = query_all("""
        SELECT tm.team_member_id, tm.role, tm.joined_on, m.member_id, m.name, m.phone, m.email, m.status
        FROM team_member tm
        JOIN member m ON tm.member_id = m.member_id
        WHERE tm.team_id = %s
        ORDER BY tm.role, m.name
    """, (team_id,))

    # Active members available to be added
    available_members = query_all("""
        SELECT member_id, name, phone, email
        FROM member
        WHERE status = 'Active' AND membership_end >= CURDATE()
          AND member_id NOT IN (SELECT member_id FROM team_member WHERE team_id = %s)
        ORDER BY name
    """, (team_id,))

    return render_template(
        "team_detail.html",
        team=team,
        roster=roster,
        available_members=available_members,
    )


@app.route("/teams/<int:team_id>/add_member", methods=["POST"])
def team_add_member(team_id):
    member_id = request.form.get("member_id")
    role = request.form.get("role", "Player").strip() or "Player"

    if not member_id or not member_id.isdigit():
        flash("Please select a valid member.", "danger")
        return redirect(url_for("team_detail", team_id=team_id))

    try:
        execute_modify(
            "INSERT INTO team_member (team_id, member_id, role, joined_on) VALUES (%s, %s, %s, CURDATE())",
            (team_id, int(member_id), role),
        )
        flash("Member successfully enrolled in team roster!", "success")
    except Exception as e:
        flash(f"Enrollment rejected: {clean_db_error(e)}", "danger")

    return redirect(url_for("team_detail", team_id=team_id))


@app.route("/teams/<int:team_id>/remove_member/<int:member_id>", methods=["POST"])
def team_remove_member(team_id, member_id):
    try:
        execute_modify("DELETE FROM team_member WHERE team_id = %s AND member_id = %s", (team_id, member_id))
        flash("Member removed from roster.", "info")
    except Exception as e:
        flash(f"Removal error: {clean_db_error(e)}", "danger")

    return redirect(url_for("team_detail", team_id=team_id))


# ============================================================================
# MODULE 4: TRAINING SCHEDULING
# ============================================================================
@app.route("/training")
def training_list():
    sessions = query_all("""
        SELECT ts.session_id, ts.session_date, ts.start_time, ts.end_time, ts.max_attendees,
               t.team_name, s.sport_name, c.name AS coach_name, f.facility_name
        FROM training_session ts
        JOIN team t ON ts.team_id = t.team_id
        JOIN sport s ON t.sport_id = s.sport_id
        JOIN coach c ON ts.coach_id = c.coach_id
        JOIN facility f ON ts.facility_id = f.facility_id
        ORDER BY ts.session_date DESC, ts.start_time ASC
    """)

    teams = query_all("SELECT team_id, team_name, sport_id, coach_id FROM team ORDER BY team_name")
    coaches = query_all("SELECT coach_id, name, sport_id FROM coach ORDER BY name")
    facilities = query_all("SELECT facility_id, facility_name, capacity, status FROM facility ORDER BY facility_name")

    return render_template(
        "training.html",
        sessions=sessions,
        teams=teams,
        coaches=coaches,
        facilities=facilities,
    )


@app.route("/training/schedule", methods=["POST"])
def training_schedule():
    data = {
        "team_id": request.form.get("team_id"),
        "coach_id": request.form.get("coach_id"),
        "facility_id": request.form.get("facility_id"),
        "session_date": request.form.get("session_date"),
        "start_time": request.form.get("start_time"),
        "end_time": request.form.get("end_time"),
        "max_attendees": request.form.get("max_attendees"),
    }

    errors = validators.validate_training_session(data)
    if errors:
        for err in errors:
            flash(err, "danger")
        return redirect(url_for("training_list"))

    try:
        execute_modify("""
            INSERT INTO training_session (team_id, coach_id, facility_id, session_date, start_time, end_time, max_attendees)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (
            int(data["team_id"]),
            int(data["coach_id"]),
            int(data["facility_id"]),
            data["session_date"],
            data["start_time"],
            data["end_time"],
            int(data["max_attendees"]),
        ))
        flash("Training session successfully scheduled!", "success")
    except Exception as e:
        flash(f"Scheduling rejected: {clean_db_error(e)}", "danger")

    return redirect(url_for("training_list"))


# ============================================================================
# MODULE 5: FACILITY BOOKINGS & CONFLICT CHECKER
# ============================================================================
@app.route("/facilities")
def facility_booking():
    facilities = query_all("SELECT * FROM facility ORDER BY facility_name")
    bookings = query_all("""
        SELECT 'Training Session' AS type, ts.session_date AS b_date, ts.start_time, ts.end_time,
               f.facility_name, t.team_name AS entity, ts.max_attendees AS attendees
        FROM training_session ts
        JOIN facility f ON ts.facility_id = f.facility_id
        JOIN team t ON ts.team_id = t.team_id
        WHERE ts.session_date >= CURDATE()
        UNION
        SELECT 'Tournament Match' AS type, fx.fixture_date AS b_date, fx.start_time, fx.end_time,
               f.facility_name, CONCAT(t1.team_name, ' vs ', t2.team_name) AS entity, f.capacity AS attendees
        FROM fixture fx
        JOIN facility f ON fx.facility_id = f.facility_id
        JOIN team t1 ON fx.team1_id = t1.team_id
        JOIN team t2 ON fx.team2_id = t2.team_id
        WHERE fx.fixture_date >= CURDATE() AND fx.status <> 'Cancelled'
        ORDER BY b_date ASC, start_time ASC
    """)
    return render_template("facility_booking.html", facilities=facilities, bookings=bookings)


@app.route("/facilities/check_conflict", methods=["POST"])
def check_facility_conflict():
    fac_id = request.form.get("facility_id")
    chk_date = request.form.get("booking_date")
    start = request.form.get("start_time")
    end = request.form.get("end_time")

    if not fac_id or not chk_date or not start or not end:
        return jsonify({"conflict": True, "message": "All fields required for checking conflict."}), 400

    facility = query_one("SELECT status, facility_name FROM facility WHERE facility_id = %s", (fac_id,))
    if not facility:
        return jsonify({"conflict": True, "message": "Facility not found."}), 404

    if facility["status"] != "Available":
        return jsonify({"conflict": True, "message": f"{facility['facility_name']} is currently under Maintenance."})

    # Check overlaps across training sessions
    ts_overlap = query_all("""
        SELECT ts.session_id, t.team_name, ts.start_time, ts.end_time
        FROM training_session ts
        JOIN team t ON ts.team_id = t.team_id
        WHERE ts.facility_id = %s AND ts.session_date = %s
          AND (%s < ts.end_time AND %s > ts.start_time)
    """, (fac_id, chk_date, start, end))

    # Check overlaps across fixtures
    fx_overlap = query_all("""
        SELECT fx.fixture_id, t1.team_name AS team1, t2.team_name AS team2, fx.start_time, fx.end_time
        FROM fixture fx
        JOIN team t1 ON fx.team1_id = t1.team_id
        JOIN team t2 ON fx.team2_id = t2.team_id
        WHERE fx.facility_id = %s AND fx.fixture_date = %s AND fx.status <> 'Cancelled'
          AND (%s < fx.end_time AND %s > fx.start_time)
    """, (fac_id, chk_date, start, end))

    conflicts = []
    for ts in ts_overlap:
        conflicts.append(f"Training session for '{ts['team_name']}' ({ts['start_time']} - {ts['end_time']})")
    for fx in fx_overlap:
        conflicts.append(f"Fixture '{fx['team1']} vs {fx['team2']}' ({fx['start_time']} - {fx['end_time']})")

    if conflicts:
        return jsonify({"conflict": True, "message": "Conflict detected: " + "; ".join(conflicts)})

    return jsonify({"conflict": False, "message": f"Slot is completely AVAILABLE at {facility['facility_name']}!"})


# ============================================================================
# MODULE 6: FIXTURE CREATION
# ============================================================================
@app.route("/fixtures")
def fixtures_list():
    fixtures = query_all("""
        SELECT fx.fixture_id, tr.tournament_name, sp.sport_name, f.facility_name,
               t1.team_name AS team1, t2.team_name AS team2, fx.fixture_date,
               fx.start_time, fx.end_time, fx.status, r.result_id, r.team1_score, r.team2_score
        FROM fixture fx
        JOIN tournament tr ON fx.tournament_id = tr.tournament_id
        JOIN sport sp ON tr.sport_id = sp.sport_id
        JOIN facility f ON fx.facility_id = f.facility_id
        JOIN team t1 ON fx.team1_id = t1.team_id
        JOIN team t2 ON fx.team2_id = t2.team_id
        LEFT JOIN result r ON fx.fixture_id = r.fixture_id
        ORDER BY fx.fixture_date DESC, fx.start_time ASC
    """)
    tournaments = query_all("SELECT * FROM tournament ORDER BY start_date DESC")
    facilities = query_all("SELECT * FROM facility WHERE status = 'Available' ORDER BY facility_name")
    teams = query_all("SELECT team_id, team_name, sport_id FROM team ORDER BY team_name")

    return render_template(
        "fixtures.html",
        fixtures=fixtures,
        tournaments=tournaments,
        facilities=facilities,
        teams=teams,
    )


@app.route("/fixtures/create", methods=["POST"])
def fixture_create():
    data = {
        "tournament_id": request.form.get("tournament_id"),
        "facility_id": request.form.get("facility_id"),
        "team1_id": request.form.get("team1_id"),
        "team2_id": request.form.get("team2_id"),
        "fixture_date": request.form.get("fixture_date"),
        "start_time": request.form.get("start_time"),
        "end_time": request.form.get("end_time"),
    }

    errors = validators.validate_fixture(data)
    if errors:
        for err in errors:
            flash(err, "danger")
        return redirect(url_for("fixtures_list"))

    try:
        execute_modify("""
            INSERT INTO fixture (tournament_id, facility_id, team1_id, team2_id, fixture_date, start_time, end_time, status)
            VALUES (%s, %s, %s, %s, %s, %s, %s, 'Scheduled')
        """, (
            int(data["tournament_id"]),
            int(data["facility_id"]),
            int(data["team1_id"]),
            int(data["team2_id"]),
            data["fixture_date"],
            data["start_time"],
            data["end_time"],
        ))
        flash("Tournament fixture scheduled successfully!", "success")
    except Exception as e:
        flash(f"Fixture scheduling rejected: {clean_db_error(e)}", "danger")

    return redirect(url_for("fixtures_list"))


# ============================================================================
# MODULE 7: RESULT ENTRY (sp_enter_result)
# ============================================================================
@app.route("/results")
def results_list():
    scheduled_fixtures = query_all("""
        SELECT fx.fixture_id, tr.tournament_name, sp.sport_name, f.facility_name,
               t1.team_name AS team1, t2.team_name AS team2, fx.fixture_date, fx.start_time
        FROM fixture fx
        JOIN tournament tr ON fx.tournament_id = tr.tournament_id
        JOIN sport sp ON tr.sport_id = sp.sport_id
        JOIN facility f ON fx.facility_id = f.facility_id
        JOIN team t1 ON fx.team1_id = t1.team_id
        JOIN team t2 ON fx.team2_id = t2.team_id
        WHERE fx.status = 'Scheduled'
        ORDER BY fx.fixture_date ASC, fx.start_time ASC
    """)

    completed_results = query_all("""
        SELECT r.result_id, fx.fixture_id, tr.tournament_name, sp.sport_name,
               t1.team_name AS team1, t2.team_name AS team2, r.team1_score, r.team2_score,
               COALESCE(w.team_name, 'Match Tied (Draw)') AS winner_name,
               r.remarks, fx.fixture_date
        FROM result r
        JOIN fixture fx ON r.fixture_id = fx.fixture_id
        JOIN tournament tr ON fx.tournament_id = tr.tournament_id
        JOIN sport sp ON tr.sport_id = sp.sport_id
        JOIN team t1 ON fx.team1_id = t1.team_id
        JOIN team t2 ON fx.team2_id = t2.team_id
        LEFT JOIN team w ON r.winner_team_id = w.team_id
        ORDER BY fx.fixture_date DESC
    """)

    return render_template(
        "results.html",
        scheduled_fixtures=scheduled_fixtures,
        completed_results=completed_results,
    )


@app.route("/results/enter", methods=["POST"])
def result_enter():
    data = {
        "fixture_id": request.form.get("fixture_id"),
        "team1_score": request.form.get("team1_score"),
        "team2_score": request.form.get("team2_score"),
        "remarks": request.form.get("remarks", "").strip(),
    }

    errors = validators.validate_result_entry(data)
    if errors:
        for err in errors:
            flash(err, "danger")
        return redirect(url_for("results_list"))

    try:
        call_procedure(
            "sp_enter_result",
            (
                int(data["fixture_id"]),
                int(data["team1_score"]),
                int(data["team2_score"]),
                data["remarks"] or "Match concluded cleanly.",
            ),
        )
        flash("Match result recorded and fixture status updated to Completed!", "success")
    except Exception as e:
        flash(f"Result entry error: {clean_db_error(e)}", "danger")

    return redirect(url_for("results_list"))


# ============================================================================
# MODULE 8: FEE COLLECTION
# ============================================================================
@app.route("/payments")
def payments_list():
    payments = query_all("""
        SELECT p.payment_id, m.name AS member_name, m.phone, mp.plan_name,
               p.amount, p.payment_date, p.mode, p.status
        FROM payment p
        JOIN member m ON p.member_id = m.member_id
        JOIN membership_plan mp ON p.plan_id = mp.plan_id
        ORDER BY p.payment_date DESC, p.payment_id DESC
    """)
    members = query_all("SELECT member_id, name, phone, plan_id FROM member ORDER BY name")
    plans = query_all("SELECT plan_id, plan_name, fee FROM membership_plan ORDER BY fee ASC")

    return render_template("payments.html", payments=payments, members=members, plans=plans)


@app.route("/payments/record", methods=["POST"])
def payment_record():
    member_id = request.form.get("member_id")
    plan_id = request.form.get("plan_id")
    amount = request.form.get("amount")
    mode = request.form.get("mode", "UPI")

    if not member_id or not plan_id or not amount:
        flash("Member, Plan, and Amount are required.", "danger")
        return redirect(url_for("payments_list"))

    try:
        execute_modify("""
            INSERT INTO payment (member_id, plan_id, amount, payment_date, mode, status)
            VALUES (%s, %s, %s, CURDATE(), %s, 'Paid')
        """, (int(member_id), int(plan_id), float(amount), mode))
        flash("Payment receipt generated successfully!", "success")
    except Exception as e:
        flash(f"Transaction failed: {clean_db_error(e)}", "danger")

    return redirect(url_for("payments_list"))


# ============================================================================
# MODULE 9: EQUIPMENT ISSUE & RETURN
# ============================================================================
@app.route("/equipment")
def equipment_list():
    status_filter = request.args.get("status", "")
    sql = """
        SELECT eq.issue_id, m.member_id, m.name AS member_name, m.phone,
               eq.equipment_name, eq.quantity, eq.issue_date, eq.due_date,
               eq.return_date, eq.status,
               DATEDIFF(CURDATE(), eq.due_date) AS days_overdue
        FROM equipment_issue eq
        JOIN member m ON eq.member_id = m.member_id
        WHERE 1=1
    """
    params = []
    if status_filter:
        sql += " AND eq.status = %s"
        params.append(status_filter)

    sql += " ORDER BY eq.issue_id DESC"
    issues = query_all(sql, tuple(params))
    active_members = query_all("SELECT member_id, name, phone FROM member WHERE status = 'Active' AND membership_end >= CURDATE() ORDER BY name")

    return render_template(
        "equipment.html",
        issues=issues,
        active_members=active_members,
        status_filter=status_filter,
    )


@app.route("/equipment/issue", methods=["POST"])
def equipment_issue():
    data = {
        "member_id": request.form.get("member_id"),
        "equipment_name": request.form.get("equipment_name", "").strip(),
        "quantity": request.form.get("quantity", "1"),
        "due_days": request.form.get("due_days", "7"),
    }

    errors = validators.validate_equipment_issue(data)
    if errors:
        for err in errors:
            flash(err, "danger")
        return redirect(url_for("equipment_list"))

    try:
        call_procedure(
            "sp_issue_equipment",
            (
                int(data["member_id"]),
                data["equipment_name"],
                int(data["quantity"]),
                int(data["due_days"]),
                0,
            ),
        )
        flash(f"Equipment '{data['equipment_name']}' issued successfully!", "success")
    except Exception as e:
        flash(f"Equipment checkout blocked: {clean_db_error(e)}", "danger")

    return redirect(url_for("equipment_list"))


@app.route("/equipment/return/<int:issue_id>", methods=["POST"])
def equipment_return(issue_id):
    try:
        call_procedure("sp_return_equipment", (issue_id,))
        flash("Equipment marked as Returned.", "success")
    except Exception as e:
        flash(f"Return check-in error: {clean_db_error(e)}", "danger")

    return redirect(url_for("equipment_list"))


# ============================================================================
# MODULE 10: REPORTS & CSV DOWNLOAD (All 8 SQL Views)
# ============================================================================
AVAILABLE_VIEWS = {
    "active_memberships": {
        "view": "v_active_memberships",
        "title": "Active Memberships",
        "desc": "Patrons with valid active club memberships and remaining days.",
    },
    "expiring_30_days": {
        "view": "v_membership_expiring_30_days",
        "title": "Subscriptions Expiring in 30 Days",
        "desc": "Members whose packages expire in the next 30 days.",
    },
    "fixture_schedule": {
        "view": "v_fixture_schedule",
        "title": "Master Fixture Schedule",
        "desc": "Tournament match calendar with venues, timings, and recorded outcomes.",
    },
    "tournament_standings": {
        "view": "v_tournament_standings",
        "title": "Tournament Standings",
        "desc": "League tables computed with 3-1-0 points, goal difference, and rankings.",
    },
    "facility_utilization": {
        "view": "v_facility_utilization",
        "title": "Facility Utilization",
        "desc": "Aggregate booking counts for practice sessions vs competitive matches.",
    },
    "player_performance": {
        "view": "v_player_performance",
        "title": "Player Performance",
        "desc": "Individual athlete tournament appearances and win/loss records.",
    },
    "fee_dues": {
        "view": "v_fee_dues",
        "title": "Fee Dues & Arrears",
        "desc": "Unpaid pending subscriptions and lapsed member fee dues.",
    },
    "equipment_status": {
        "view": "v_equipment_status",
        "title": "Equipment Inventory Status",
        "desc": "Patron borrowing accountability across issued, returned, and overdue gear.",
    },
}


@app.route("/reports")
def reports_page():
    active_report_key = request.args.get("report", "tournament_standings")
    if active_report_key not in AVAILABLE_VIEWS:
        active_report_key = "tournament_standings"

    meta = AVAILABLE_VIEWS[active_report_key]
    rows = query_all(f"SELECT * FROM {meta['view']}")
    columns = list(rows[0].keys()) if rows else []

    return render_template(
        "reports.html",
        views_dict=AVAILABLE_VIEWS,
        active_key=active_report_key,
        current_meta=meta,
        columns=columns,
        rows=rows,
    )


@app.route("/reports/export/<report_key>")
def report_export_csv(report_key):
    if report_key not in AVAILABLE_VIEWS:
        flash("Invalid report view requested for export.", "danger")
        return redirect(url_for("reports_page"))

    meta = AVAILABLE_VIEWS[report_key]
    rows = query_all(f"SELECT * FROM {meta['view']}")

    output = io.StringIO()
    writer = csv.writer(output)

    if rows:
        headers = list(rows[0].keys())
        writer.writerow(headers)
        for r in rows:
            writer.writerow([r[h] for h in headers])

    csv_data = output.getvalue()
    filename = f"{report_key}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"

    return Response(
        csv_data,
        mimetype="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=True)

-- ============================================================================
-- SPORTS CLUB MEMBERSHIP AND TOURNAMENT MANAGEMENT SYSTEM
-- File: 05_queries.sql
-- Description: 27 comprehensive analytical and operational queries demonstrating
--              filtering, sorting, multi-table joins, aggregations, subqueries,
--              set operations, window/top-N operations, and date-range logic.
-- ============================================================================

USE sports_club_db;

-- ============================================================================
-- SECTION 1: SIMPLE SELECTION, FILTERING & SORTING
-- ============================================================================

-- Query 1: Retrieve all active members sorted chronologically by registration date
SELECT member_id, name, email, phone, join_date, membership_end, status
FROM member
WHERE status = 'Active'
ORDER BY join_date ASC;

-- Query 2: Retrieve all facilities currently available for booking, ordered by capacity descending
SELECT facility_id, facility_name, type, capacity, status
FROM facility
WHERE status = 'Available'
ORDER BY capacity DESC;

-- Query 3: List membership plans offering mid-tier durations with fee between 4000 and 10000
SELECT plan_id, plan_name, duration_months, fee, benefits
FROM membership_plan
WHERE fee BETWEEN 4000.00 AND 10000.00
ORDER BY fee ASC;

-- ============================================================================
-- SECTION 2: MULTI-TABLE JOINS (INNER, LEFT, RIGHT across 3-4 tables)
-- ============================================================================

-- Query 4: 3-Table INNER JOIN: Comprehensive team roster with member and sport details
SELECT 
    tm.team_member_id,
    t.team_name,
    s.sport_name,
    m.name AS member_name,
    m.phone AS member_phone,
    tm.role,
    tm.joined_on
FROM team_member tm
INNER JOIN team t ON tm.team_id = t.team_id
INNER JOIN sport s ON t.sport_id = s.sport_id
INNER JOIN member m ON tm.member_id = m.member_id
ORDER BY t.team_name, tm.role;

-- Query 5: 4-Table INNER JOIN: Detailed training schedule with coach, facility, and sport metadata
SELECT 
    ts.session_id,
    ts.session_date,
    ts.start_time,
    ts.end_time,
    t.team_name,
    s.sport_name,
    c.name AS coach_name,
    f.facility_name,
    ts.max_attendees
FROM training_session ts
INNER JOIN team t ON ts.team_id = t.team_id
INNER JOIN sport s ON t.sport_id = s.sport_id
INNER JOIN coach c ON ts.coach_id = c.coach_id
INNER JOIN facility f ON ts.facility_id = f.facility_id
ORDER BY ts.session_date, ts.start_time;

-- Query 6: 4-Table INNER JOIN: Comprehensive tournament fixture list with venue and team names
SELECT 
    fx.fixture_id,
    tr.tournament_name,
    sp.sport_name,
    t1.team_name AS team_one,
    t2.team_name AS team_two,
    f.facility_name,
    fx.fixture_date,
    fx.start_time,
    fx.end_time,
    fx.status
FROM fixture fx
INNER JOIN tournament tr ON fx.tournament_id = tr.tournament_id
INNER JOIN sport sp ON tr.sport_id = sp.sport_id
INNER JOIN team t1 ON fx.team1_id = t1.team_id
INNER JOIN team t2 ON fx.team2_id = t2.team_id
INNER JOIN facility f ON fx.facility_id = f.facility_id
ORDER BY fx.fixture_date, fx.start_time;

-- Query 7: LEFT JOIN: All teams and their assigned coaches (including any team with NULL coach)
SELECT 
    t.team_id,
    t.team_name,
    s.sport_name,
    COALESCE(c.name, 'Unassigned') AS head_coach,
    COALESCE(c.phone, 'N/A') AS coach_contact,
    t.formed_on
FROM team t
INNER JOIN sport s ON t.sport_id = s.sport_id
LEFT JOIN coach c ON t.coach_id = c.coach_id
ORDER BY t.team_name;

-- Query 8: LEFT JOIN: Facility inventory utilization displaying scheduled sessions count
SELECT 
    f.facility_id,
    f.facility_name,
    f.type,
    f.capacity,
    f.status,
    COUNT(ts.session_id) AS total_training_sessions
FROM facility f
LEFT JOIN training_session ts ON f.facility_id = ts.facility_id
GROUP BY f.facility_id, f.facility_name, f.type, f.capacity, f.status
ORDER BY total_training_sessions DESC;

-- Query 9: RIGHT JOIN: All coaches and teams they oversee (highlighting coach assignment status)
SELECT 
    c.coach_id,
    c.name AS coach_name,
    c.specialization,
    s.sport_name,
    COALESCE(t.team_name, 'No Assigned Team') AS managed_team
FROM team t
RIGHT JOIN coach c ON t.coach_id = c.coach_id
INNER JOIN sport s ON c.sport_id = s.sport_id
ORDER BY c.name;

-- ============================================================================
-- SECTION 3: GROUP BY & HAVING AGGREGATIONS (COUNT, SUM, AVG, MAX, MIN)
-- ============================================================================

-- Query 10: Count active vs non-active members enrolled under each membership plan
SELECT 
    mp.plan_name,
    mp.fee,
    COUNT(m.member_id) AS total_enrolled_members,
    SUM(CASE WHEN m.status = 'Active' THEN 1 ELSE 0 END) AS active_members,
    SUM(CASE WHEN m.status <> 'Active' THEN 1 ELSE 0 END) AS inactive_or_expired
FROM membership_plan mp
LEFT JOIN member m ON mp.plan_id = m.plan_id
GROUP BY mp.plan_id, mp.plan_name, mp.fee
ORDER BY total_enrolled_members DESC;

-- Query 11: Total payment revenue collected and transaction volume grouped by payment mode
SELECT 
    mode,
    status,
    COUNT(payment_id) AS transaction_count,
    SUM(amount) AS total_amount,
    AVG(amount) AS average_transaction_value
FROM payment
GROUP BY mode, status
ORDER BY total_amount DESC;

-- Query 12: Aggregate average training session capacity grouped by sport, filtered by HAVING
SELECT 
    s.sport_name,
    COUNT(ts.session_id) AS total_sessions,
    AVG(ts.max_attendees) AS avg_max_attendees,
    MAX(ts.max_attendees) AS peak_attendees
FROM training_session ts
INNER JOIN team t ON ts.team_id = t.team_id
INNER JOIN sport s ON t.sport_id = s.sport_id
GROUP BY s.sport_id, s.sport_name
HAVING COUNT(ts.session_id) >= 2
ORDER BY avg_max_attendees DESC;

-- Query 13: Maximum, minimum, and average scores per tournament
SELECT 
    tr.tournament_name,
    COUNT(r.result_id) AS completed_fixtures,
    MAX(GREATEST(r.team1_score, r.team2_score)) AS highest_score,
    MIN(LEAST(r.team1_score, r.team2_score)) AS lowest_score,
    AVG(r.team1_score + r.team2_score) AS avg_total_score
FROM result r
INNER JOIN fixture fx ON r.fixture_id = fx.fixture_id
INNER JOIN tournament tr ON fx.tournament_id = tr.tournament_id
GROUP BY tr.tournament_id, tr.tournament_name;

-- ============================================================================
-- SECTION 4: SUBQUERIES (IN, NOT IN, EXISTS, NOT EXISTS, CORRELATED, SCALAR)
-- ============================================================================

-- Query 14: Subquery with IN: Find members who currently serve as Team Captains
SELECT member_id, name, email, phone, status
FROM member
WHERE member_id IN (
    SELECT DISTINCT member_id
    FROM team_member
    WHERE role LIKE '%Captain%'
)
ORDER BY name;

-- Query 15: Subquery with NOT IN: Active members who have NEVER borrowed any club equipment
SELECT member_id, name, email, join_date
FROM member
WHERE status = 'Active'
  AND member_id NOT IN (
      SELECT DISTINCT member_id
      FROM equipment_issue
  )
ORDER BY name;

-- Query 16: Subquery with EXISTS: Tournaments that have at least one recorded match result
SELECT tr.tournament_id, tr.tournament_name, tr.start_date, tr.end_date
FROM tournament tr
WHERE EXISTS (
    SELECT 1
    FROM fixture fx
    INNER JOIN result r ON fx.fixture_id = r.fixture_id
    WHERE fx.tournament_id = tr.tournament_id
)
ORDER BY tr.start_date;

-- Query 17: Subquery with NOT EXISTS: Members who have made only successful (non-pending) payments
SELECT m.member_id, m.name, m.email
FROM member m
WHERE NOT EXISTS (
    SELECT 1
    FROM payment p
    WHERE p.member_id = m.member_id
      AND p.status = 'Pending'
)
ORDER BY m.member_id;

-- Query 18: Correlated Subquery: Members along with their count of currently unreturned equipment items
SELECT 
    m.member_id,
    m.name,
    m.phone,
    (
        SELECT COALESCE(SUM(eq.quantity), 0)
        FROM equipment_issue eq
        WHERE eq.member_id = m.member_id
          AND eq.return_date IS NULL
    ) AS currently_issued_equipment_count
FROM member m
WHERE m.status = 'Active'
HAVING currently_issued_equipment_count > 0
ORDER BY currently_issued_equipment_count DESC;

-- Query 19: Scalar Subquery: Facilities whose spectator/player capacity is strictly above the club average
SELECT facility_id, facility_name, type, capacity
FROM facility
WHERE capacity > (
    SELECT AVG(capacity) FROM facility
)
ORDER BY capacity DESC;

-- ============================================================================
-- SECTION 5: SET OPERATIONS (UNION & UNION ALL)
-- ============================================================================

-- Query 20: Set Operation (UNION): Unified club events schedule combining training sessions and matches
SELECT 
    'Training Session' AS event_type,
    ts.session_date AS event_date,
    ts.start_time,
    ts.end_time,
    f.facility_name,
    t.team_name AS primary_party
FROM training_session ts
INNER JOIN facility f ON ts.facility_id = f.facility_id
INNER JOIN team t ON ts.team_id = t.team_id
UNION
SELECT 
    'Tournament Match' AS event_type,
    fx.fixture_date AS event_date,
    fx.start_time,
    fx.end_time,
    f.facility_name,
    CONCAT(t1.team_name, ' vs ', t2.team_name) AS primary_party
FROM fixture fx
INNER JOIN facility f ON fx.facility_id = f.facility_id
INNER JOIN team t1 ON fx.team1_id = t1.team_id
INNER JOIN team t2 ON fx.team2_id = t2.team_id
ORDER BY event_date, start_time;

-- Query 21: Set Operation (UNION ALL): Activity ledger combining member joins and payment receipts
SELECT 
    join_date AS activity_date,
    CONCAT('Member Joined: ', name) AS activity_description,
    0.00 AS credit_amount
FROM member
UNION ALL
SELECT 
    payment_date AS activity_date,
    CONCAT('Fee Payment Received (Mode: ', mode, ')') AS activity_description,
    amount AS credit_amount
FROM payment
WHERE status = 'Paid'
ORDER BY activity_date DESC, credit_amount DESC;

-- ============================================================================
-- SECTION 6: TOP-N (LIMIT) QUERIES
-- ============================================================================

-- Query 22: Top 3 most booked facilities across all scheduled fixtures and training sessions
SELECT 
    f.facility_id,
    f.facility_name,
    f.type,
    (COUNT(DISTINCT ts.session_id) + COUNT(DISTINCT fx.fixture_id)) AS total_events_booked
FROM facility f
LEFT JOIN training_session ts ON f.facility_id = ts.facility_id
LEFT JOIN fixture fx ON f.facility_id = fx.facility_id
GROUP BY f.facility_id, f.facility_name, f.type
ORDER BY total_events_booked DESC
LIMIT 3;

-- Query 23: Top 5 single largest payment transactions recorded
SELECT 
    p.payment_id,
    m.name AS member_name,
    mp.plan_name,
    p.amount,
    p.payment_date,
    p.mode
FROM payment p
INNER JOIN member m ON p.member_id = m.member_id
INNER JOIN membership_plan mp ON p.plan_id = mp.plan_id
WHERE p.status = 'Paid'
ORDER BY p.amount DESC, p.payment_date DESC
LIMIT 5;

-- ============================================================================
-- SECTION 7: DATE-RANGE & TEMPORAL QUERIES
-- ============================================================================

-- Query 24: Fixtures scheduled within October 2026
SELECT 
    fx.fixture_id,
    fx.fixture_date,
    fx.start_time,
    t1.team_name AS home_team,
    t2.team_name AS away_team,
    f.facility_name,
    fx.status
FROM fixture fx
INNER JOIN team t1 ON fx.team1_id = t1.team_id
INNER JOIN team t2 ON fx.team2_id = t2.team_id
INNER JOIN facility f ON fx.facility_id = f.facility_id
WHERE fx.fixture_date BETWEEN '2026-10-01' AND '2026-10-31'
ORDER BY fx.fixture_date;

-- Query 25: Equipment due within the next 14 days or currently overdue
SELECT 
    eq.issue_id,
    m.name AS member_name,
    m.phone,
    eq.equipment_name,
    eq.quantity,
    eq.issue_date,
    eq.due_date,
    eq.status,
    DATEDIFF(eq.due_date, '2026-10-12') AS days_until_due
FROM equipment_issue eq
INNER JOIN member m ON eq.member_id = m.member_id
WHERE eq.return_date IS NULL
ORDER BY eq.due_date ASC;

-- Query 26: Team match performance statistics in completed fixtures
SELECT 
    t.team_name,
    COUNT(fx.fixture_id) AS total_matches_played,
    SUM(CASE WHEN r.winner_team_id = t.team_id THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN r.winner_team_id IS NULL AND r.result_id IS NOT NULL THEN 1 ELSE 0 END) AS draws,
    SUM(CASE WHEN r.winner_team_id IS NOT NULL AND r.winner_team_id <> t.team_id THEN 1 ELSE 0 END) AS losses
FROM team t
INNER JOIN fixture fx ON (fx.team1_id = t.team_id OR fx.team2_id = t.team_id)
INNER JOIN result r ON fx.fixture_id = r.fixture_id
GROUP BY t.team_id, t.team_name
ORDER BY wins DESC, draws DESC;

-- Query 27: Average payment collected per plan from a nested derived table
SELECT 
    plan_summary.plan_name,
    plan_summary.plan_fee,
    plan_summary.total_collected,
    ROUND(plan_summary.total_collected / plan_summary.paid_transactions, 2) AS avg_receipt_size
FROM (
    SELECT 
        mp.plan_name,
        mp.fee AS plan_fee,
        COUNT(p.payment_id) AS paid_transactions,
        SUM(p.amount) AS total_collected
    FROM membership_plan mp
    INNER JOIN payment p ON mp.plan_id = p.plan_id
    WHERE p.status = 'Paid'
    GROUP BY mp.plan_id, mp.plan_name, mp.fee
) AS plan_summary
ORDER BY plan_summary.total_collected DESC;

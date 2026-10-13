-- ============================================================================
-- SPORTS CLUB MEMBERSHIP AND TOURNAMENT MANAGEMENT SYSTEM
-- File: 06_views.sql
-- Description: Analytical and operational reports encapsulated as SQL views.
--              Includes membership lifecycle, fixture schedules, tournament standings,
--              facility utilization, player performance, fee dues, and equipment status.
-- ============================================================================

USE sports_club_db;

-- ----------------------------------------------------------------------------
-- 1. VIEW: v_active_memberships
-- Description: Overview of current active club members, tier, and days remaining.
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_active_memberships;
CREATE VIEW v_active_memberships AS
SELECT 
    m.member_id,
    m.name AS member_name,
    m.phone,
    m.email,
    mp.plan_name,
    mp.fee,
    m.membership_start,
    m.membership_end,
    DATEDIFF(m.membership_end, CURDATE()) AS days_remaining,
    m.status
FROM member m
INNER JOIN membership_plan mp ON m.plan_id = mp.plan_id
WHERE m.status = 'Active' AND m.membership_end >= CURDATE();

-- ----------------------------------------------------------------------------
-- 2. VIEW: v_membership_expiring_30_days
-- Description: Proactive renewal alert view for subscriptions expiring within 30 days.
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_membership_expiring_30_days;
CREATE VIEW v_membership_expiring_30_days AS
SELECT 
    m.member_id,
    m.name AS member_name,
    m.phone,
    m.email,
    mp.plan_name,
    m.membership_end,
    DATEDIFF(m.membership_end, CURDATE()) AS days_until_expiration,
    m.status
FROM member m
INNER JOIN membership_plan mp ON m.plan_id = mp.plan_id
WHERE m.status = 'Active'
  AND m.membership_end BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY);

-- ----------------------------------------------------------------------------
-- 3. VIEW: v_fixture_schedule
-- Description: Master tournament match calendar with scores and winners.
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_fixture_schedule;
CREATE VIEW v_fixture_schedule AS
SELECT 
    fx.fixture_id,
    tr.tournament_name,
    sp.sport_name,
    f.facility_name,
    t1.team_name AS team_one,
    t2.team_name AS team_two,
    fx.fixture_date,
    fx.start_time,
    fx.end_time,
    fx.status,
    r.team1_score,
    r.team2_score,
    COALESCE(w.team_name, CASE WHEN r.result_id IS NOT NULL THEN 'Draw' ELSE 'Pending' END) AS winner_or_outcome,
    r.remarks
FROM fixture fx
INNER JOIN tournament tr ON fx.tournament_id = tr.tournament_id
INNER JOIN sport sp ON tr.sport_id = sp.sport_id
INNER JOIN facility f ON fx.facility_id = f.facility_id
INNER JOIN team t1 ON fx.team1_id = t1.team_id
INNER JOIN team t2 ON fx.team2_id = t2.team_id
LEFT JOIN result r ON fx.fixture_id = r.fixture_id
LEFT JOIN team w ON r.winner_team_id = w.team_id;

-- ----------------------------------------------------------------------------
-- 4. VIEW: v_tournament_standings
-- Description: League tables (3 pts win, 1 pt draw, 0 pt loss; played, W/D/L, GF/GA/GD/points/rank).
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_tournament_standings;
CREATE VIEW v_tournament_standings AS
SELECT 
    fx.tournament_id,
    tr.tournament_name,
    sp.sport_name,
    t.team_id,
    t.team_name,
    COUNT(r.result_id) AS played,
    SUM(CASE WHEN r.winner_team_id = t.team_id THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN r.winner_team_id IS NULL AND r.result_id IS NOT NULL THEN 1 ELSE 0 END) AS draws,
    SUM(CASE WHEN r.winner_team_id IS NOT NULL AND r.winner_team_id <> t.team_id THEN 1 ELSE 0 END) AS losses,
    SUM(CASE 
        WHEN fx.team1_id = t.team_id THEN r.team1_score 
        ELSE r.team2_score 
    END) AS goals_for,
    SUM(CASE 
        WHEN fx.team1_id = t.team_id THEN r.team2_score 
        ELSE r.team1_score 
    END) AS goals_against,
    SUM(CASE 
        WHEN fx.team1_id = t.team_id THEN r.team1_score - r.team2_score 
        ELSE r.team2_score - r.team1_score 
    END) AS goal_difference,
    SUM(CASE 
        WHEN r.winner_team_id = t.team_id THEN 3
        WHEN r.winner_team_id IS NULL AND r.result_id IS NOT NULL THEN 1
        ELSE 0 
    END) AS points,
    RANK() OVER (
        PARTITION BY fx.tournament_id 
        ORDER BY 
            SUM(CASE WHEN r.winner_team_id = t.team_id THEN 3 WHEN r.winner_team_id IS NULL AND r.result_id IS NOT NULL THEN 1 ELSE 0 END) DESC,
            SUM(CASE WHEN fx.team1_id = t.team_id THEN r.team1_score - r.team2_score ELSE r.team2_score - r.team1_score END) DESC,
            SUM(CASE WHEN fx.team1_id = t.team_id THEN r.team1_score ELSE r.team2_score END) DESC
    ) AS standings_rank
FROM fixture fx
INNER JOIN tournament tr ON fx.tournament_id = tr.tournament_id
INNER JOIN sport sp ON tr.sport_id = sp.sport_id
INNER JOIN result r ON fx.fixture_id = r.fixture_id
INNER JOIN team t ON (t.team_id = fx.team1_id OR t.team_id = fx.team2_id)
GROUP BY fx.tournament_id, tr.tournament_name, sp.sport_name, t.team_id, t.team_name;

-- ----------------------------------------------------------------------------
-- 5. VIEW: v_facility_utilization
-- Description: Aggregate usage counts comparing training sessions vs matches booked.
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_facility_utilization;
CREATE VIEW v_facility_utilization AS
SELECT 
    f.facility_id,
    f.facility_name,
    f.type AS facility_type,
    f.capacity,
    f.status,
    COALESCE(ts_sub.training_count, 0) AS total_training_sessions,
    COALESCE(fx_sub.fixture_count, 0) AS total_fixtures_booked,
    (COALESCE(ts_sub.training_count, 0) + COALESCE(fx_sub.fixture_count, 0)) AS total_bookings
FROM facility f
LEFT JOIN (
    SELECT facility_id, COUNT(*) AS training_count
    FROM training_session
    GROUP BY facility_id
) ts_sub ON f.facility_id = ts_sub.facility_id
LEFT JOIN (
    SELECT facility_id, COUNT(*) AS fixture_count
    FROM fixture
    WHERE status <> 'Cancelled'
    GROUP BY facility_id
) fx_sub ON f.facility_id = fx_sub.facility_id;

-- ----------------------------------------------------------------------------
-- 6. VIEW: v_player_performance
-- Description: Individual athlete match participation and winning records.
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_player_performance;
CREATE VIEW v_player_performance AS
SELECT 
    m.member_id,
    m.name AS player_name,
    t.team_name,
    s.sport_name,
    COUNT(p.participant_id) AS total_appearances,
    SUM(CASE WHEN r.winner_team_id = p.team_id THEN 1 ELSE 0 END) AS team_wins,
    SUM(CASE WHEN r.winner_team_id IS NULL AND r.result_id IS NOT NULL THEN 1 ELSE 0 END) AS team_draws,
    SUM(CASE WHEN r.winner_team_id IS NOT NULL AND r.winner_team_id <> p.team_id THEN 1 ELSE 0 END) AS team_losses
FROM participant p
INNER JOIN member m ON p.member_id = m.member_id
INNER JOIN team t ON p.team_id = t.team_id
INNER JOIN sport s ON t.sport_id = s.sport_id
INNER JOIN fixture fx ON p.fixture_id = fx.fixture_id
LEFT JOIN result r ON fx.fixture_id = r.fixture_id
GROUP BY m.member_id, m.name, t.team_name, s.sport_name;

-- ----------------------------------------------------------------------------
-- 7. VIEW: v_fee_dues
-- Description: Members with pending payments or expired memberships.
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_fee_dues;
CREATE VIEW v_fee_dues AS
SELECT 
    m.member_id,
    m.name AS member_name,
    m.phone,
    m.email,
    mp.plan_name,
    mp.fee AS current_plan_fee,
    m.membership_end,
    m.status AS membership_status,
    COALESCE(p.pending_amount, 0.00) AS pending_amount,
    CASE 
        WHEN m.status = 'Expired' AND COALESCE(p.pending_amount, 0) > 0 THEN 'Expired & Pending Fee'
        WHEN m.status = 'Expired' THEN 'Subscription Expired'
        WHEN COALESCE(p.pending_amount, 0) > 0 THEN 'Pending Unsettled Payment'
        ELSE 'Current'
    END AS dues_category
FROM member m
INNER JOIN membership_plan mp ON m.plan_id = mp.plan_id
LEFT JOIN (
    SELECT member_id, SUM(amount) AS pending_amount
    FROM payment
    WHERE status = 'Pending'
    GROUP BY member_id
) p ON m.member_id = p.member_id
WHERE m.status = 'Expired' OR COALESCE(p.pending_amount, 0) > 0;

-- ----------------------------------------------------------------------------
-- 8. VIEW: v_equipment_status
-- Description: Equipment borrowing accountability per member (issued, returned, overdue).
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_equipment_status;
CREATE VIEW v_equipment_status AS
SELECT 
    m.member_id,
    m.name AS member_name,
    m.phone,
    COUNT(eq.issue_id) AS total_lifetime_issues,
    SUM(CASE WHEN eq.status = 'Returned' THEN eq.quantity ELSE 0 END) AS total_returned_qty,
    SUM(CASE WHEN eq.status = 'Issued' THEN eq.quantity ELSE 0 END) AS currently_issued_qty,
    SUM(CASE WHEN eq.status = 'Overdue' THEN eq.quantity ELSE 0 END) AS overdue_qty
FROM member m
LEFT JOIN equipment_issue eq ON m.member_id = eq.member_id
GROUP BY m.member_id, m.name, m.phone
HAVING total_lifetime_issues > 0;

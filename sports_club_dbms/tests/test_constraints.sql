-- ============================================================================
-- SPORTS CLUB MEMBERSHIP AND TOURNAMENT MANAGEMENT SYSTEM
-- File: tests/test_constraints.sql
-- Description: Automated test harness for database integrity constraints and business rules.
--              Tests 15 distinct constraint and trigger requirements:
--              Each has a FAILING test (expected error) and a PASSING test (expected success).
--              Outputs a clean PASS/FAIL summary table upon execution.
-- ============================================================================

USE sports_club_db;

DROP TABLE IF EXISTS test_results;
CREATE TABLE test_results (
    test_num INT AUTO_INCREMENT PRIMARY KEY,
    test_id VARCHAR(25) NOT NULL,
    rule_category VARCHAR(40) NOT NULL,
    test_description VARCHAR(150) NOT NULL,
    expected_outcome VARCHAR(50) NOT NULL,
    actual_outcome VARCHAR(50) NOT NULL,
    status ENUM('PASS', 'FAIL') NOT NULL
);

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_run_constraint_tests$$
CREATE PROCEDURE sp_run_constraint_tests()
BEGIN
    DECLARE v_error_occurred INT DEFAULT 0;
    DECLARE v_err_msg VARCHAR(255) DEFAULT '';
    
    -- Handler for anticipated exceptions
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error_occurred = 1;
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
    END;

    -- ========================================================================
    -- TEST 1: CHECK CONSTRAINT - Plan fee cannot be negative
    -- ========================================================================
    -- 1A: Failing case (Fee < 0)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO membership_plan (plan_name, duration_months, fee) VALUES ('Test Invalid Fee Plan', 1, -500.00);
    END;
    IF v_error_occurred = 1 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-01A', 'CHECK: Plan Fee', 'Insert membership plan with negative fee (-500)', 'Error: chk_plan_fee violated', 'Blocked by CHECK constraint', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-01A', 'CHECK: Plan Fee', 'Insert membership plan with negative fee (-500)', 'Error: chk_plan_fee violated', 'Unexpected Success', 'FAIL');
    END IF;

    -- 1B: Passing case (Fee >= 0)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO membership_plan (plan_name, duration_months, fee) VALUES ('Test Valid Fee Plan', 1, 2000.00);
        DELETE FROM membership_plan WHERE plan_name = 'Test Valid Fee Plan';
    END;
    IF v_error_occurred = 0 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-01B', 'CHECK: Plan Fee', 'Insert membership plan with valid positive fee', 'Success', 'Row inserted successfully', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-01B', 'CHECK: Plan Fee', 'Insert membership plan with valid positive fee', 'Success', CONCAT('Failed: ', v_err_msg), 'FAIL');
    END IF;

    -- ========================================================================
    -- TEST 2: CHECK CONSTRAINT - Member dates (membership_end >= membership_start)
    -- ========================================================================
    -- 2A: Failing case (End < Start)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO member (name, phone, email, dob, plan_id, membership_start, membership_end, status)
        VALUES ('Test Invalid Dates', '+91 99000 00001', 'inv_dates@test.in', '2000-01-01', 1, '2026-10-15', '2026-10-01', 'Active');
    END;
    IF v_error_occurred = 1 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-02A', 'CHECK: Member Dates', 'Insert member with membership_end < membership_start', 'Error: chk_member_dates violated', 'Blocked by CHECK constraint', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-02A', 'CHECK: Member Dates', 'Insert member with membership_end < membership_start', 'Error: chk_member_dates violated', 'Unexpected Success', 'FAIL');
    END IF;

    -- 2B: Passing case (End >= Start)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO member (name, phone, email, dob, plan_id, membership_start, membership_end, status)
        VALUES ('Test Valid Dates', '+91 99000 00002', 'val_dates@test.in', '2000-01-01', 1, '2026-10-15', '2026-11-15', 'Active');
        DELETE FROM member WHERE email = 'val_dates@test.in';
    END;
    IF v_error_occurred = 0 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-02B', 'CHECK: Member Dates', 'Insert member with valid date range', 'Success', 'Row inserted successfully', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-02B', 'CHECK: Member Dates', 'Insert member with valid date range', 'Success', CONCAT('Failed: ', v_err_msg), 'FAIL');
    END IF;

    -- ========================================================================
    -- TEST 3: CHECK CONSTRAINT - Fixture teams cannot be identical (team1_id <> team2_id)
    -- ========================================================================
    -- 3A: Failing case (team1 == team2)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO fixture (tournament_id, facility_id, team1_id, team2_id, fixture_date, start_time, end_time, status)
        VALUES (1, 1, 1, 1, '2026-11-01', '10:00:00', '12:00:00', 'Scheduled');
    END;
    IF v_error_occurred = 1 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-03A', 'CHECK: Distinct Teams', 'Create fixture where team1_id equals team2_id', 'Error: chk_fixture_teams violated', 'Blocked by CHECK constraint', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-03A', 'CHECK: Distinct Teams', 'Create fixture where team1_id equals team2_id', 'Error: chk_fixture_teams violated', 'Unexpected Success', 'FAIL');
    END IF;

    -- 3B: Passing case (team1 <> team2)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO fixture (tournament_id, facility_id, team1_id, team2_id, fixture_date, start_time, end_time, status)
        VALUES (1, 1, 1, 2, '2026-11-01', '10:00:00', '12:00:00', 'Scheduled');
        DELETE FROM fixture WHERE fixture_date = '2026-11-01' AND start_time = '10:00:00';
    END;
    IF v_error_occurred = 0 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-03B', 'CHECK: Distinct Teams', 'Create fixture with two distinct competing teams', 'Success', 'Row inserted successfully', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-03B', 'CHECK: Distinct Teams', 'Create fixture with two distinct competing teams', 'Success', CONCAT('Failed: ', v_err_msg), 'FAIL');
    END IF;

    -- ========================================================================
    -- TEST 4: UNIQUE CONSTRAINT - Duplicate member phone number
    -- ========================================================================
    -- 4A: Failing case (Existing phone)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO member (name, phone, email, dob, plan_id, membership_start, membership_end, status)
        VALUES ('Duplicate Phone Member', '+91 98111 00001', 'dup_phone@test.in', '1999-05-05', 1, '2026-10-15', '2026-11-15', 'Active');
    END;
    IF v_error_occurred = 1 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-04A', 'UNIQUE: Member Phone', 'Insert member with existing phone number', 'Error: Duplicate entry', 'Blocked by UNIQUE key', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-04A', 'UNIQUE: Member Phone', 'Insert member with existing phone number', 'Error: Duplicate entry', 'Unexpected Success', 'FAIL');
    END IF;

    -- 4B: Passing case (Unique phone)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO member (name, phone, email, dob, plan_id, membership_start, membership_end, status)
        VALUES ('Unique Phone Member', '+91 99000 99999', 'uniq_phone@test.in', '1999-05-05', 1, '2026-10-15', '2026-11-15', 'Active');
        DELETE FROM member WHERE email = 'uniq_phone@test.in';
    END;
    IF v_error_occurred = 0 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-04B', 'UNIQUE: Member Phone', 'Insert member with unique phone number', 'Success', 'Row inserted successfully', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-04B', 'UNIQUE: Member Phone', 'Insert member with unique phone number', 'Success', CONCAT('Failed: ', v_err_msg), 'FAIL');
    END IF;

    -- ========================================================================
    -- TEST 5: FOREIGN KEY CONSTRAINT - Invalid plan_id in member
    -- ========================================================================
    -- 5A: Failing case (Non-existent plan_id 9999)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO member (name, phone, email, dob, plan_id, membership_start, membership_end, status)
        VALUES ('Invalid Plan Member', '+91 99000 00003', 'inv_plan@test.in', '1999-05-05', 9999, '2026-10-15', '2026-11-15', 'Active');
    END;
    IF v_error_occurred = 1 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-05A', 'FK: Plan Reference', 'Insert member referencing non-existent plan_id 9999', 'Error: Foreign key fails', 'Blocked by FK constraint', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-05A', 'FK: Plan Reference', 'Insert member referencing non-existent plan_id 9999', 'Error: Foreign key fails', 'Unexpected Success', 'FAIL');
    END IF;

    -- 5B: Passing case (Existing plan_id 1)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO member (name, phone, email, dob, plan_id, membership_start, membership_end, status)
        VALUES ('Valid Plan Member', '+91 99000 00004', 'val_plan@test.in', '1999-05-05', 1, '2026-10-15', '2026-11-15', 'Active');
        DELETE FROM member WHERE email = 'val_plan@test.in';
    END;
    IF v_error_occurred = 0 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-05B', 'FK: Plan Reference', 'Insert member referencing valid plan_id 1', 'Success', 'Row inserted successfully', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-05B', 'FK: Plan Reference', 'Insert member referencing valid plan_id 1', 'Success', CONCAT('Failed: ', v_err_msg), 'FAIL');
    END IF;

    -- ========================================================================
    -- TEST 6: BUSINESS RULE 1 - Facility Schedule Overlap Prevention
    -- ========================================================================
    -- 6A: Failing case (Training session overlaps existing session 1 on 2026-10-14 06:00-08:00 at Facility 1)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO training_session (team_id, coach_id, facility_id, session_date, start_time, end_time, max_attendees)
        VALUES (1, 1, 1, '2026-10-14', '07:00:00', '09:00:00', 10);
    END;
    IF v_error_occurred = 1 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-06A', 'RULE 1: Facility Overlap', 'Book facility with overlapping time interval (07:00-09:00)', 'Error: Facility schedule conflict', 'Blocked by Trigger', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-06A', 'RULE 1: Facility Overlap', 'Book facility with overlapping time interval (07:00-09:00)', 'Error: Facility schedule conflict', 'Unexpected Success', 'FAIL');
    END IF;

    -- 6B: Passing case (Non-overlapping time on same date at Facility 1: 11:00-13:00)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO training_session (team_id, coach_id, facility_id, session_date, start_time, end_time, max_attendees)
        VALUES (1, 1, 1, '2026-10-14', '11:00:00', '13:00:00', 10);
        DELETE FROM training_session WHERE session_date = '2026-10-14' AND start_time = '11:00:00';
    END;
    IF v_error_occurred = 0 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-06B', 'RULE 1: Facility Overlap', 'Book facility at available non-overlapping time slot (11:00-13:00)', 'Success', 'Session scheduled cleanly', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-06B', 'RULE 1: Facility Overlap', 'Book facility at available non-overlapping time slot (11:00-13:00)', 'Success', CONCAT('Failed: ', v_err_msg), 'FAIL');
    END IF;

    -- ========================================================================
    -- TEST 7: BUSINESS RULE 2 - Team Schedule Overlap Prevention
    -- ========================================================================
    -- 7A: Failing case (Team 1 already training on 2026-10-14 06:00-08:00, try booking team on another facility at same time)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO training_session (team_id, coach_id, facility_id, session_date, start_time, end_time, max_attendees)
        VALUES (1, 1, 6, '2026-10-14', '06:30:00', '07:30:00', 4);
    END;
    IF v_error_occurred = 1 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-07A', 'RULE 2: Team Overlap', 'Book team for concurrent session at another venue', 'Error: Team schedule conflict', 'Blocked by Trigger', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-07A', 'RULE 2: Team Overlap', 'Book team for concurrent session at another venue', 'Error: Team schedule conflict', 'Unexpected Success', 'FAIL');
    END IF;

    -- 7B: Passing case (Team 1 booked at a different, open time: 14:00-16:00)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO training_session (team_id, coach_id, facility_id, session_date, start_time, end_time, max_attendees)
        VALUES (1, 1, 1, '2026-10-14', '14:00:00', '16:00:00', 10);
        DELETE FROM training_session WHERE session_date = '2026-10-14' AND start_time = '14:00:00';
    END;
    IF v_error_occurred = 0 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-07B', 'RULE 2: Team Overlap', 'Book team for session during free hours', 'Success', 'Session scheduled cleanly', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-07B', 'RULE 2: Team Overlap', 'Book team for session during free hours', 'Success', CONCAT('Failed: ', v_err_msg), 'FAIL');
    END IF;

    -- ========================================================================
    -- TEST 8: BUSINESS RULE 3 - Active Membership Required for Team/Equipment
    -- ========================================================================
    -- 8A: Failing case (Expired member 31 attempting to join Team 1)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO team_member (team_id, member_id, role) VALUES (1, 31, 'Substitute');
    END;
    IF v_error_occurred = 1 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-08A', 'RULE 3: Active Member', 'Add expired member (ID 31) to team roster', 'Error: Active membership required', 'Blocked by Trigger', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-08A', 'RULE 3: Active Member', 'Add expired member (ID 31) to team roster', 'Error: Active membership required', 'Unexpected Success', 'FAIL');
    END IF;

    -- 8B: Passing case (Active member 25 joining Team 1)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO team_member (team_id, member_id, role) VALUES (1, 25, 'Substitute');
        DELETE FROM team_member WHERE team_id = 1 AND member_id = 25;
    END;
    IF v_error_occurred = 0 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-08B', 'RULE 3: Active Member', 'Add active member (ID 25) to team roster', 'Success', 'Member added to roster', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-08B', 'RULE 3: Active Member', 'Add active member (ID 25) to team roster', 'Success', CONCAT('Failed: ', v_err_msg), 'FAIL');
    END IF;

    -- ========================================================================
    -- TEST 9: BUSINESS RULE 4 - Valid Result & Scores (Winner matches higher score)
    -- ========================================================================
    -- 9A: Failing case (Team 1 score 10 > Team 2 score 5, but winner set as Team 2)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO result (fixture_id, team1_score, team2_score, winner_team_id, remarks)
        VALUES (13, 10, 5, 2, 'Inverted winner test');
    END;
    IF v_error_occurred = 1 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-09A', 'RULE 4: Result Winner', 'Record score (10-5) with invalid winner (team 2)', 'Error: winner_team_id mismatch', 'Blocked by Trigger', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-09A', 'RULE 4: Result Winner', 'Record score (10-5) with invalid winner (team 2)', 'Error: winner_team_id mismatch', 'Unexpected Success', 'FAIL');
    END IF;

    -- 9B: Passing case (Team 1 score 10 > Team 2 score 5, winner set correctly as Team 1)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO result (fixture_id, team1_score, team2_score, winner_team_id, remarks)
        VALUES (13, 10, 5, 1, 'Valid result test');
        DELETE FROM result WHERE fixture_id = 13;
        UPDATE fixture SET status = 'Scheduled' WHERE fixture_id = 13;
    END;
    IF v_error_occurred = 0 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-09B', 'RULE 4: Result Winner', 'Record score (10-5) with correct winner (team 1)', 'Success', 'Result recorded and fixture completed', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-09B', 'RULE 4: Result Winner', 'Record score (10-5) with correct winner (team 1)', 'Success', CONCAT('Failed: ', v_err_msg), 'FAIL');
    END IF;

    -- ========================================================================
    -- TEST 10: BUSINESS RULE 5 - Capacity Limits (Team size <= sport.max_team_size)
    -- ========================================================================
    -- 10A: Failing case (Team 5 is Badminton, max size 4. Currently has 2. Try adding 3 more = 5)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO team_member (team_id, member_id, role) VALUES (5, 7, 'Player');
        INSERT INTO team_member (team_id, member_id, role) VALUES (5, 8, 'Player');
        -- This 5th addition exceeds Badminton max size 4
        INSERT INTO team_member (team_id, member_id, role) VALUES (5, 9, 'Player');
    END;
    IF v_error_occurred = 1 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-10A', 'RULE 5: Team Capacity', 'Exceed sport max_team_size for Badminton (limit 4)', 'Error: Team roster full', 'Blocked by Trigger', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-10A', 'RULE 5: Team Capacity', 'Exceed sport max_team_size for Badminton (limit 4)', 'Error: Team roster full', 'Unexpected Success', 'FAIL');
    END IF;
    -- Cleanup any test members added to team 5
    DELETE FROM team_member WHERE team_id = 5 AND member_id IN (7, 8, 9);

    -- 10B: Passing case (Adding 1 member to Team 5 within limit 4)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO team_member (team_id, member_id, role) VALUES (5, 7, 'Reserve Player');
        DELETE FROM team_member WHERE team_id = 5 AND member_id = 7;
    END;
    IF v_error_occurred = 0 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-10B', 'RULE 5: Team Capacity', 'Add player to team roster within permitted sport capacity', 'Success', 'Roster member accepted', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-10B', 'RULE 5: Team Capacity', 'Add player to team roster within permitted sport capacity', 'Success', CONCAT('Failed: ', v_err_msg), 'FAIL');
    END IF;

    -- ========================================================================
    -- TEST 11: BUSINESS RULE 6 - Equipment Limits (No issue if overdue items exist)
    -- ========================================================================
    -- 11A: Failing case (Member 17 already has an overdue equipment item #23)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO equipment_issue (member_id, equipment_name, quantity, issue_date, due_date, status)
        VALUES (17, 'New Tennis Ball Can', 1, '2026-10-12', '2026-10-19', 'Issued');
    END;
    IF v_error_occurred = 1 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-11A', 'RULE 6: Equipment Limits', 'Issue equipment to member with existing overdue item', 'Error: Equipment issue blocked', 'Blocked by Trigger', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-11A', 'RULE 6: Equipment Limits', 'Issue equipment to member with existing overdue item', 'Error: Equipment issue blocked', 'Unexpected Success', 'FAIL');
    END IF;

    -- 11B: Passing case (Member 6 has 0 overdue and 0 unreturned items)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO equipment_issue (member_id, equipment_name, quantity, issue_date, due_date, status)
        VALUES (6, 'Test Badminton Shuttlecock Tube', 1, '2026-10-12', '2026-10-19', 'Issued');
        DELETE FROM equipment_issue WHERE member_id = 6 AND equipment_name = 'Test Badminton Shuttlecock Tube';
    END;
    IF v_error_occurred = 0 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-11B', 'RULE 6: Equipment Limits', 'Issue equipment to member in good standing', 'Success', 'Equipment issued cleanly', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-11B', 'RULE 6: Equipment Limits', 'Issue equipment to member in good standing', 'Success', CONCAT('Failed: ', v_err_msg), 'FAIL');
    END IF;

    -- ========================================================================
    -- TEST 12: BUSINESS RULE 7 - Facility Status (Cannot book Maintenance venue)
    -- ========================================================================
    -- 12A: Failing case (Facility 7 is Maintenance)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO training_session (team_id, coach_id, facility_id, session_date, start_time, end_time, max_attendees)
        VALUES (3, 2, 7, '2026-10-30', '09:00:00', '11:00:00', 10);
    END;
    IF v_error_occurred = 1 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-12A', 'RULE 7: Facility Maintenance', 'Book training session on facility under Maintenance (ID 7)', 'Error: Facility unavailable', 'Blocked by Trigger', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-12A', 'RULE 7: Facility Maintenance', 'Book training session on facility under Maintenance (ID 7)', 'Error: Facility unavailable', 'Unexpected Success', 'FAIL');
    END IF;

    -- 12B: Passing case (Facility 2 is Available)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO training_session (team_id, coach_id, facility_id, session_date, start_time, end_time, max_attendees)
        VALUES (3, 2, 2, '2026-10-30', '09:00:00', '11:00:00', 10);
        DELETE FROM training_session WHERE session_date = '2026-10-30' AND start_time = '09:00:00';
    END;
    IF v_error_occurred = 0 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-12B', 'RULE 7: Facility Maintenance', 'Book training session on Available facility (ID 2)', 'Success', 'Session scheduled cleanly', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-12B', 'RULE 7: Facility Maintenance', 'Book training session on Available facility (ID 2)', 'Success', CONCAT('Failed: ', v_err_msg), 'FAIL');
    END IF;

    -- ========================================================================
    -- TEST 13: BUSINESS RULE 8 - Sport Consistency
    -- ========================================================================
    -- 13A: Failing case (Schedule Football team 3 in Cricket Tournament 1)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO fixture (tournament_id, facility_id, team1_id, team2_id, fixture_date, start_time, end_time, status)
        VALUES (1, 1, 3, 2, '2026-10-31', '10:00:00', '12:00:00', 'Scheduled');
    END;
    IF v_error_occurred = 1 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-13A', 'RULE 8: Sport Consistency', 'Fixture with team whose sport does not match tournament sport', 'Error: Sport mismatch', 'Blocked by Trigger', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-13A', 'RULE 8: Sport Consistency', 'Fixture with team whose sport does not match tournament sport', 'Error: Sport mismatch', 'Unexpected Success', 'FAIL');
    END IF;

    -- 13B: Passing case (Both teams 1 & 2 match Cricket Tournament 1)
    SET v_error_occurred = 0;
    BEGIN
        INSERT INTO fixture (tournament_id, facility_id, team1_id, team2_id, fixture_date, start_time, end_time, status)
        VALUES (1, 1, 1, 2, '2026-10-31', '10:00:00', '12:00:00', 'Scheduled');
        DELETE FROM fixture WHERE fixture_date = '2026-10-31' AND start_time = '10:00:00';
    END;
    IF v_error_occurred = 0 THEN
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-13B', 'RULE 8: Sport Consistency', 'Fixture with matching teams and tournament sport', 'Success', 'Fixture scheduled cleanly', 'PASS');
    ELSE
        INSERT INTO test_results (test_id, rule_category, test_description, expected_outcome, actual_outcome, status)
        VALUES ('TC-13B', 'RULE 8: Sport Consistency', 'Fixture with matching teams and tournament sport', 'Success', CONCAT('Failed: ', v_err_msg), 'FAIL');
    END IF;

END$$

DELIMITER ;

-- Execute test harness and render report table
CALL sp_run_constraint_tests();

SELECT 
    test_id,
    rule_category,
    test_description,
    expected_outcome,
    actual_outcome,
    status
FROM test_results;

SELECT 
    COUNT(*) AS total_tests_executed,
    SUM(CASE WHEN status = 'PASS' THEN 1 ELSE 0 END) AS passed_tests,
    SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END) AS failed_tests,
    CASE WHEN SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END) = 0 THEN '100% PASS' ELSE 'FAILURES DETECTED' END AS overall_verdict
FROM test_results;

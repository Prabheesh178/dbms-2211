-- ============================================================================
-- SPORTS CLUB MEMBERSHIP AND TOURNAMENT MANAGEMENT SYSTEM
-- File: 03_procedures.sql
-- Description: Transactional stored procedures with exception handling
--              (COMMIT/ROLLBACK), atomic workflows, and maintenance routines.
-- ============================================================================

USE sports_club_db;

DELIMITER $$

-- ============================================================================
-- 1. PROCEDURE: sp_register_member_with_payment
-- Description: Registers a member and creates an initial paid payment record atomically.
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_register_member_with_payment$$
CREATE PROCEDURE sp_register_member_with_payment(
    IN p_name VARCHAR(100),
    IN p_phone VARCHAR(20),
    IN p_email VARCHAR(120),
    IN p_dob DATE,
    IN p_plan_id INT,
    IN p_payment_mode ENUM('Cash', 'UPI', 'Card', 'Bank'),
    OUT p_member_id INT,
    OUT p_payment_id INT
)
proc_body: BEGIN
    DECLARE v_duration INT;
    DECLARE v_fee DECIMAL(10,2);
    DECLARE v_start DATE;
    DECLARE v_end DATE;

    -- Exit handler to rollback transaction on failure
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Validate Plan
    SELECT duration_months, fee INTO v_duration, v_fee
    FROM membership_plan
    WHERE plan_id = p_plan_id;

    IF v_duration IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Registration failed: Selected membership plan does not exist.';
    END IF;

    SET v_start = CURDATE();
    SET v_end = DATE_ADD(v_start, INTERVAL v_duration MONTH);

    START TRANSACTION;

    INSERT INTO member (name, phone, email, dob, join_date, plan_id, membership_start, membership_end, status)
    VALUES (p_name, p_phone, p_email, p_dob, CURDATE(), p_plan_id, v_start, v_end, 'Active');

    SET p_member_id = LAST_INSERT_ID();

    INSERT INTO payment (member_id, plan_id, amount, payment_date, mode, status)
    VALUES (p_member_id, p_plan_id, v_fee, CURDATE(), p_payment_mode, 'Paid');

    SET p_payment_id = LAST_INSERT_ID();

    COMMIT;
END proc_body$$

-- ============================================================================
-- 2. PROCEDURE: sp_renew_membership
-- Description: Renews member subscription, extends membership_end, and records payment.
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_renew_membership$$
CREATE PROCEDURE sp_renew_membership(
    IN p_member_id INT,
    IN p_plan_id INT,
    IN p_payment_mode ENUM('Cash', 'UPI', 'Card', 'Bank'),
    OUT p_payment_id INT
)
proc_body: BEGIN
    DECLARE v_current_end DATE;
    DECLARE v_duration INT;
    DECLARE v_fee DECIMAL(10,2);
    DECLARE v_new_end DATE;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Verify Member
    SELECT membership_end INTO v_current_end
    FROM member
    WHERE member_id = p_member_id;

    IF v_current_end IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Renewal failed: Member ID not found.';
    END IF;

    -- Verify Plan
    SELECT duration_months, fee INTO v_duration, v_fee
    FROM membership_plan
    WHERE plan_id = p_plan_id;

    IF v_duration IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Renewal failed: Membership plan not found.';
    END IF;

    -- If existing membership has already expired, renewal starts from today.
    -- Otherwise, extension starts from existing membership_end.
    IF v_current_end < CURDATE() THEN
        SET v_new_end = DATE_ADD(CURDATE(), INTERVAL v_duration MONTH);
    ELSE
        SET v_new_end = DATE_ADD(v_current_end, INTERVAL v_duration MONTH);
    END IF;

    START TRANSACTION;

    UPDATE member
    SET plan_id = p_plan_id,
        membership_end = v_new_end,
        status = 'Active'
    WHERE member_id = p_member_id;

    INSERT INTO payment (member_id, plan_id, amount, payment_date, mode, status)
    VALUES (p_member_id, p_plan_id, v_fee, CURDATE(), p_payment_mode, 'Paid');

    SET p_payment_id = LAST_INSERT_ID();

    COMMIT;
END proc_body$$

-- ============================================================================
-- 3. PROCEDURE: sp_enter_result
-- Description: Records fixture result, computes winner, and marks fixture Completed.
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_enter_result$$
CREATE PROCEDURE sp_enter_result(
    IN p_fixture_id INT,
    IN p_team1_score INT,
    IN p_team2_score INT,
    IN p_remarks TEXT
)
proc_body: BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_team1_id INT;
    DECLARE v_team2_id INT;
    DECLARE v_winner_id INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Check fixture existence and status
    SELECT status, team1_id, team2_id
    INTO v_status, v_team1_id, v_team2_id
    FROM fixture
    WHERE fixture_id = p_fixture_id;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Result entry failed: Fixture not found.';
    END IF;

    IF v_status <> 'Scheduled' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Result entry failed: Result can only be entered for Scheduled fixtures.';
    END IF;

    IF p_team1_score < 0 OR p_team2_score < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Result entry failed: Scores cannot be negative.';
    END IF;

    -- Determine winner
    IF p_team1_score > p_team2_score THEN
        SET v_winner_id = v_team1_id;
    ELSEIF p_team2_score > p_team1_score THEN
        SET v_winner_id = v_team2_id;
    ELSE
        SET v_winner_id = NULL; -- Draw
    END IF;

    START TRANSACTION;

    -- Insert into result (triggers will validate and update fixture status)
    INSERT INTO result (fixture_id, team1_score, team2_score, winner_team_id, remarks)
    VALUES (p_fixture_id, p_team1_score, p_team2_score, v_winner_id, p_remarks);

    -- Ensure fixture status updated
    UPDATE fixture
    SET status = 'Completed'
    WHERE fixture_id = p_fixture_id;

    COMMIT;
END proc_body$$

-- ============================================================================
-- 4. PROCEDURE: sp_issue_equipment
-- Description: Issues sports equipment to an active member with due date validation.
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_issue_equipment$$
CREATE PROCEDURE sp_issue_equipment(
    IN p_member_id INT,
    IN p_equipment_name VARCHAR(100),
    IN p_quantity INT,
    IN p_due_days INT,
    OUT p_issue_id INT
)
proc_body: BEGIN
    DECLARE v_due_date DATE;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Issue failed: Quantity must be at least 1.';
    END IF;

    IF p_due_days <= 0 THEN
        SET p_due_days = 7; -- Default to 7 days
    END IF;

    SET v_due_date = DATE_ADD(CURDATE(), INTERVAL p_due_days DAY);

    START TRANSACTION;

    INSERT INTO equipment_issue (member_id, equipment_name, quantity, issue_date, due_date, status)
    VALUES (p_member_id, p_equipment_name, p_quantity, CURDATE(), v_due_date, 'Issued');

    SET p_issue_id = LAST_INSERT_ID();

    COMMIT;
END proc_body$$

-- ============================================================================
-- 5. PROCEDURE: sp_return_equipment
-- Description: Processes equipment check-in and updates status to Returned.
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_return_equipment$$
CREATE PROCEDURE sp_return_equipment(
    IN p_issue_id INT
)
proc_body: BEGIN
    DECLARE v_current_status VARCHAR(20);
    DECLARE v_ret_date DATE;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT status, return_date INTO v_current_status, v_ret_date
    FROM equipment_issue
    WHERE issue_id = p_issue_id;

    IF v_current_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Equipment return failed: Issue ID not found.';
    END IF;

    IF v_ret_date IS NOT NULL OR v_current_status = 'Returned' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Equipment return failed: This item has already been marked Returned.';
    END IF;

    START TRANSACTION;

    UPDATE equipment_issue
    SET return_date = CURDATE(),
        status = 'Returned'
    WHERE issue_id = p_issue_id;

    COMMIT;
END proc_body$$

-- ============================================================================
-- 6. PROCEDURE & EVENT: sp_maintenance_check
-- Description: Daily automated batch job marking expired memberships and overdue gear.
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_maintenance_check$$
CREATE PROCEDURE sp_maintenance_check()
BEGIN
    DECLARE v_expired_count INT DEFAULT 0;
    DECLARE v_overdue_count INT DEFAULT 0;

    -- Update expired memberships
    UPDATE member
    SET status = 'Expired'
    WHERE membership_end < CURDATE()
      AND status = 'Active';

    -- Update overdue equipment issues
    UPDATE equipment_issue
    SET status = 'Overdue'
    WHERE return_date IS NULL
      AND due_date < CURDATE()
      AND status = 'Issued';

    SELECT ROW_COUNT() AS updated_records;
END$$

-- Optional scheduled event (fires daily at 00:01 AM)
SET GLOBAL event_scheduler = ON$$

DROP EVENT IF EXISTS ev_daily_maintenance$$
CREATE EVENT ev_daily_maintenance
ON SCHEDULE EVERY 1 DAY
STARTS (TIMESTAMP(CURRENT_DATE) + INTERVAL 1 DAY + INTERVAL 1 MINUTE)
DO
BEGIN
    CALL sp_maintenance_check();
END$$

DELIMITER ;

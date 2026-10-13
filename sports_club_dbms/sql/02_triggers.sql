-- ============================================================================
-- SPORTS CLUB MEMBERSHIP AND TOURNAMENT MANAGEMENT SYSTEM
-- File: 02_triggers.sql
-- Description: Business rules enforcement via database triggers.
--              Enforces facility scheduling, team scheduling, active membership,
--              score validation, capacity limits, equipment limits, and sport consistency.
-- ============================================================================

USE sports_club_db;

DELIMITER $$

-- ============================================================================
-- RULE 1, 2, 5, 7, 8: TRAINING SESSION VALIDATION TRIGGERS
-- ============================================================================

DROP TRIGGER IF EXISTS trg_training_session_before_insert$$
CREATE TRIGGER trg_training_session_before_insert
BEFORE INSERT ON training_session
FOR EACH ROW
BEGIN
    DECLARE v_fac_status VARCHAR(20);
    DECLARE v_fac_capacity INT;
    DECLARE v_team_sport INT;
    DECLARE v_coach_sport INT;
    DECLARE v_conflict_count INT DEFAULT 0;

    -- 1. Facility Status & Capacity Checks (Rule 7 & 5)
    SELECT status, capacity INTO v_fac_status, v_fac_capacity
    FROM facility WHERE facility_id = NEW.facility_id;

    IF v_fac_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Validation error: Facility not found.';
    END IF;

    IF v_fac_status <> 'Available' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Facility unavailable: Selected facility is under maintenance.';
    END IF;

    IF NEW.max_attendees > v_fac_capacity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Capacity exceeded: Max training attendees exceeds facility capacity.';
    END IF;

    -- 2. Sport Consistency Check (Rule 8)
    SELECT sport_id INTO v_team_sport FROM team WHERE team_id = NEW.team_id;
    SELECT sport_id INTO v_coach_sport FROM coach WHERE coach_id = NEW.coach_id;

    IF v_team_sport <> v_coach_sport THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sport mismatch: Coach sport does not match the team sport for training session.';
    END IF;

    -- 3. Facility Overlap Check (Rule 1: across training_session and fixture)
    SELECT COUNT(*) INTO v_conflict_count
    FROM training_session
    WHERE facility_id = NEW.facility_id
      AND session_date = NEW.session_date
      AND (NEW.start_time < end_time AND NEW.end_time > start_time);

    IF v_conflict_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Facility schedule conflict: Facility is already booked by another training session during this time interval.';
    END IF;

    SELECT COUNT(*) INTO v_conflict_count
    FROM fixture
    WHERE facility_id = NEW.facility_id
      AND fixture_date = NEW.session_date
      AND status <> 'Cancelled'
      AND (NEW.start_time < end_time AND NEW.end_time > start_time);

    IF v_conflict_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Facility schedule conflict: Facility is already booked by a tournament fixture during this time interval.';
    END IF;

    -- 4. Team Schedule Overlap Check (Rule 2: across training_session and fixture)
    SELECT COUNT(*) INTO v_conflict_count
    FROM training_session
    WHERE team_id = NEW.team_id
      AND session_date = NEW.session_date
      AND (NEW.start_time < end_time AND NEW.end_time > start_time);

    IF v_conflict_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Team schedule conflict: Team has another training session during this time interval.';
    END IF;

    SELECT COUNT(*) INTO v_conflict_count
    FROM fixture
    WHERE (team1_id = NEW.team_id OR team2_id = NEW.team_id)
      AND fixture_date = NEW.session_date
      AND status <> 'Cancelled'
      AND (NEW.start_time < end_time AND NEW.end_time > start_time);

    IF v_conflict_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Team schedule conflict: Team has a scheduled fixture during this time interval.';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_training_session_before_update$$
CREATE TRIGGER trg_training_session_before_update
BEFORE UPDATE ON training_session
FOR EACH ROW
BEGIN
    DECLARE v_fac_status VARCHAR(20);
    DECLARE v_fac_capacity INT;
    DECLARE v_team_sport INT;
    DECLARE v_coach_sport INT;
    DECLARE v_conflict_count INT DEFAULT 0;

    -- 1. Facility Status & Capacity Checks (Rule 7 & 5)
    SELECT status, capacity INTO v_fac_status, v_fac_capacity
    FROM facility WHERE facility_id = NEW.facility_id;

    IF v_fac_status <> 'Available' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Facility unavailable: Selected facility is under maintenance.';
    END IF;

    IF NEW.max_attendees > v_fac_capacity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Capacity exceeded: Max training attendees exceeds facility capacity.';
    END IF;

    -- 2. Sport Consistency Check (Rule 8)
    SELECT sport_id INTO v_team_sport FROM team WHERE team_id = NEW.team_id;
    SELECT sport_id INTO v_coach_sport FROM coach WHERE coach_id = NEW.coach_id;

    IF v_team_sport <> v_coach_sport THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sport mismatch: Coach sport does not match the team sport for training session.';
    END IF;

    -- 3. Facility Overlap Check (Rule 1)
    SELECT COUNT(*) INTO v_conflict_count
    FROM training_session
    WHERE facility_id = NEW.facility_id
      AND session_date = NEW.session_date
      AND session_id <> NEW.session_id
      AND (NEW.start_time < end_time AND NEW.end_time > start_time);

    IF v_conflict_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Facility schedule conflict: Facility is already booked by another training session during this time interval.';
    END IF;

    SELECT COUNT(*) INTO v_conflict_count
    FROM fixture
    WHERE facility_id = NEW.facility_id
      AND fixture_date = NEW.session_date
      AND status <> 'Cancelled'
      AND (NEW.start_time < end_time AND NEW.end_time > start_time);

    IF v_conflict_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Facility schedule conflict: Facility is already booked by a tournament fixture during this time interval.';
    END IF;

    -- 4. Team Schedule Overlap Check (Rule 2)
    SELECT COUNT(*) INTO v_conflict_count
    FROM training_session
    WHERE team_id = NEW.team_id
      AND session_date = NEW.session_date
      AND session_id <> NEW.session_id
      AND (NEW.start_time < end_time AND NEW.end_time > start_time);

    IF v_conflict_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Team schedule conflict: Team has another training session during this time interval.';
    END IF;

    SELECT COUNT(*) INTO v_conflict_count
    FROM fixture
    WHERE (team1_id = NEW.team_id OR team2_id = NEW.team_id)
      AND fixture_date = NEW.session_date
      AND status <> 'Cancelled'
      AND (NEW.start_time < end_time AND NEW.end_time > start_time);

    IF v_conflict_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Team schedule conflict: Team has a scheduled fixture during this time interval.';
    END IF;
END$$

-- ============================================================================
-- RULE 1, 2, 7, 8: FIXTURE VALIDATION TRIGGERS
-- ============================================================================

DROP TRIGGER IF EXISTS trg_fixture_before_insert$$
CREATE TRIGGER trg_fixture_before_insert
BEFORE INSERT ON fixture
FOR EACH ROW
BEGIN
    DECLARE v_fac_status VARCHAR(20);
    DECLARE v_tourn_sport INT;
    DECLARE v_team1_sport INT;
    DECLARE v_team2_sport INT;
    DECLARE v_conflict_count INT DEFAULT 0;

    -- Only check active/scheduled fixtures
    IF NEW.status <> 'Cancelled' THEN
        -- 1. Facility Status (Rule 7)
        SELECT status INTO v_fac_status FROM facility WHERE facility_id = NEW.facility_id;
        IF v_fac_status <> 'Available' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Facility unavailable: Selected facility is under maintenance.';
        END IF;

        -- 2. Sport Consistency (Rule 8)
        SELECT sport_id INTO v_tourn_sport FROM tournament WHERE tournament_id = NEW.tournament_id;
        SELECT sport_id INTO v_team1_sport FROM team WHERE team_id = NEW.team1_id;
        SELECT sport_id INTO v_team2_sport FROM team WHERE team_id = NEW.team2_id;

        IF (v_team1_sport <> v_tourn_sport) OR (v_team2_sport <> v_tourn_sport) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sport mismatch: Teams must belong to the same sport as the tournament.';
        END IF;

        -- 3. Facility Overlap Check (Rule 1)
        SELECT COUNT(*) INTO v_conflict_count
        FROM fixture
        WHERE facility_id = NEW.facility_id
          AND fixture_date = NEW.fixture_date
          AND status <> 'Cancelled'
          AND (NEW.start_time < end_time AND NEW.end_time > start_time);

        IF v_conflict_count > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Facility schedule conflict: Facility is already booked by another fixture during this time interval.';
        END IF;

        SELECT COUNT(*) INTO v_conflict_count
        FROM training_session
        WHERE facility_id = NEW.facility_id
          AND session_date = NEW.fixture_date
          AND (NEW.start_time < end_time AND NEW.end_time > start_time);

        IF v_conflict_count > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Facility schedule conflict: Facility is already booked by a training session during this time interval.';
        END IF;

        -- 4. Team Schedule Overlap Check (Rule 2)
        -- Check team1 and team2 against other fixtures
        SELECT COUNT(*) INTO v_conflict_count
        FROM fixture
        WHERE (team1_id IN (NEW.team1_id, NEW.team2_id) OR team2_id IN (NEW.team1_id, NEW.team2_id))
          AND fixture_date = NEW.fixture_date
          AND status <> 'Cancelled'
          AND (NEW.start_time < end_time AND NEW.end_time > start_time);

        IF v_conflict_count > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Team schedule conflict: One of the teams has another fixture during this time interval.';
        END IF;

        -- Check team1 and team2 against training sessions
        SELECT COUNT(*) INTO v_conflict_count
        FROM training_session
        WHERE team_id IN (NEW.team1_id, NEW.team2_id)
          AND session_date = NEW.fixture_date
          AND (NEW.start_time < end_time AND NEW.end_time > start_time);

        IF v_conflict_count > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Team schedule conflict: One of the teams has a training session during this time interval.';
        END IF;
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_fixture_before_update$$
CREATE TRIGGER trg_fixture_before_update
BEFORE UPDATE ON fixture
FOR EACH ROW
BEGIN
    DECLARE v_fac_status VARCHAR(20);
    DECLARE v_tourn_sport INT;
    DECLARE v_team1_sport INT;
    DECLARE v_team2_sport INT;
    DECLARE v_conflict_count INT DEFAULT 0;

    -- Only check active/scheduled fixtures
    IF NEW.status <> 'Cancelled' THEN
        -- 1. Facility Status (Rule 7)
        SELECT status INTO v_fac_status FROM facility WHERE facility_id = NEW.facility_id;
        IF v_fac_status <> 'Available' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Facility unavailable: Selected facility is under maintenance.';
        END IF;

        -- 2. Sport Consistency (Rule 8)
        SELECT sport_id INTO v_tourn_sport FROM tournament WHERE tournament_id = NEW.tournament_id;
        SELECT sport_id INTO v_team1_sport FROM team WHERE team_id = NEW.team1_id;
        SELECT sport_id INTO v_team2_sport FROM team WHERE team_id = NEW.team2_id;

        IF (v_team1_sport <> v_tourn_sport) OR (v_team2_sport <> v_tourn_sport) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sport mismatch: Teams must belong to the same sport as the tournament.';
        END IF;

        -- 3. Facility Overlap Check (Rule 1)
        SELECT COUNT(*) INTO v_conflict_count
        FROM fixture
        WHERE facility_id = NEW.facility_id
          AND fixture_date = NEW.fixture_date
          AND fixture_id <> NEW.fixture_id
          AND status <> 'Cancelled'
          AND (NEW.start_time < end_time AND NEW.end_time > start_time);

        IF v_conflict_count > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Facility schedule conflict: Facility is already booked by another fixture during this time interval.';
        END IF;

        SELECT COUNT(*) INTO v_conflict_count
        FROM training_session
        WHERE facility_id = NEW.facility_id
          AND session_date = NEW.fixture_date
          AND (NEW.start_time < end_time AND NEW.end_time > start_time);

        IF v_conflict_count > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Facility schedule conflict: Facility is already booked by a training session during this time interval.';
        END IF;

        -- 4. Team Schedule Overlap Check (Rule 2)
        SELECT COUNT(*) INTO v_conflict_count
        FROM fixture
        WHERE (team1_id IN (NEW.team1_id, NEW.team2_id) OR team2_id IN (NEW.team1_id, NEW.team2_id))
          AND fixture_date = NEW.fixture_date
          AND fixture_id <> NEW.fixture_id
          AND status <> 'Cancelled'
          AND (NEW.start_time < end_time AND NEW.end_time > start_time);

        IF v_conflict_count > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Team schedule conflict: One of the teams has another fixture during this time interval.';
        END IF;

        SELECT COUNT(*) INTO v_conflict_count
        FROM training_session
        WHERE team_id IN (NEW.team1_id, NEW.team2_id)
          AND session_date = NEW.fixture_date
          AND (NEW.start_time < end_time AND NEW.end_time > start_time);

        IF v_conflict_count > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Team schedule conflict: One of the teams has a training session during this time interval.';
        END IF;
    END IF;
END$$

-- ============================================================================
-- RULE 8: TEAM COACH SPORT CONSISTENCY
-- ============================================================================

DROP TRIGGER IF EXISTS trg_team_before_insert$$
CREATE TRIGGER trg_team_before_insert
BEFORE INSERT ON team
FOR EACH ROW
BEGIN
    DECLARE v_coach_sport INT;

    IF NEW.coach_id IS NOT NULL THEN
        SELECT sport_id INTO v_coach_sport FROM coach WHERE coach_id = NEW.coach_id;
        IF v_coach_sport <> NEW.sport_id THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sport mismatch: Coach specialization does not match team sport.';
        END IF;
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_team_before_update$$
CREATE TRIGGER trg_team_before_update
BEFORE UPDATE ON team
FOR EACH ROW
BEGIN
    DECLARE v_coach_sport INT;

    IF NEW.coach_id IS NOT NULL THEN
        SELECT sport_id INTO v_coach_sport FROM coach WHERE coach_id = NEW.coach_id;
        IF v_coach_sport <> NEW.sport_id THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sport mismatch: Coach specialization does not match team sport.';
        END IF;
    END IF;
END$$

-- ============================================================================
-- RULE 3 & 5: TEAM MEMBER VALIDATION (Active member & team capacity)
-- ============================================================================

DROP TRIGGER IF EXISTS trg_team_member_before_insert$$
CREATE TRIGGER trg_team_member_before_insert
BEFORE INSERT ON team_member
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_end_date DATE;
    DECLARE v_max_size INT;
    DECLARE v_current_size INT;

    -- 1. Active membership check (Rule 3)
    SELECT status, membership_end INTO v_status, v_end_date
    FROM member WHERE member_id = NEW.member_id;

    IF v_status <> 'Active' OR v_end_date < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Active membership required: Member is not Active or membership has expired.';
    END IF;

    -- 2. Team Capacity Limit Check (Rule 5)
    SELECT s.max_team_size INTO v_max_size
    FROM team t
    JOIN sport s ON t.sport_id = s.sport_id
    WHERE t.team_id = NEW.team_id;

    SELECT COUNT(*) INTO v_current_size
    FROM team_member
    WHERE team_id = NEW.team_id;

    IF v_current_size >= v_max_size THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Capacity exceeded: Team roster has reached the maximum size for this sport.';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_team_member_before_update$$
CREATE TRIGGER trg_team_member_before_update
BEFORE UPDATE ON team_member
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_end_date DATE;

    SELECT status, membership_end INTO v_status, v_end_date
    FROM member WHERE member_id = NEW.member_id;

    IF v_status <> 'Active' OR v_end_date < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Active membership required: Member is not Active or membership has expired.';
    END IF;
END$$

-- ============================================================================
-- RULE 3 & 5: PARTICIPANT VALIDATION (Active member & facility capacity)
-- ============================================================================

DROP TRIGGER IF EXISTS trg_participant_before_insert$$
CREATE TRIGGER trg_participant_before_insert
BEFORE INSERT ON participant
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_end_date DATE;
    DECLARE v_fix_team1 INT;
    DECLARE v_fix_team2 INT;
    DECLARE v_facility_id INT;
    DECLARE v_fac_capacity INT;
    DECLARE v_current_participants INT;
    DECLARE v_in_roster INT DEFAULT 0;

    -- 1. Active membership check (Rule 3)
    SELECT status, membership_end INTO v_status, v_end_date
    FROM member WHERE member_id = NEW.member_id;

    IF v_status <> 'Active' OR v_end_date < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Active membership required: Member is not Active or membership has expired.';
    END IF;

    -- 2. Check team belongs to fixture
    SELECT team1_id, team2_id, facility_id
    INTO v_fix_team1, v_fix_team2, v_facility_id
    FROM fixture WHERE fixture_id = NEW.fixture_id;

    IF NEW.team_id <> v_fix_team1 AND NEW.team_id <> v_fix_team2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Validation error: Team is not a competitor in this fixture.';
    END IF;

    -- 3. Check member is part of the team roster
    SELECT COUNT(*) INTO v_in_roster
    FROM team_member
    WHERE team_id = NEW.team_id AND member_id = NEW.member_id;

    IF v_in_roster = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Validation error: Member is not registered in the team roster.';
    END IF;

    -- 4. Check facility capacity limit (Rule 5)
    SELECT capacity INTO v_fac_capacity
    FROM facility WHERE facility_id = v_facility_id;

    SELECT COUNT(*) INTO v_current_participants
    FROM participant WHERE fixture_id = NEW.fixture_id;

    IF v_current_participants >= v_fac_capacity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Capacity exceeded: Fixture participants exceed facility capacity.';
    END IF;
END$$

-- ============================================================================
-- RULE 4: RESULT ENTRY VALIDATION & AUTO-COMPLETION
-- ============================================================================

DROP TRIGGER IF EXISTS trg_result_before_insert$$
CREATE TRIGGER trg_result_before_insert
BEFORE INSERT ON result
FOR EACH ROW
BEGIN
    DECLARE v_fix_status VARCHAR(20);
    DECLARE v_team1_id INT;
    DECLARE v_team2_id INT;

    -- 1. Verify fixture exists and status is Scheduled
    SELECT status, team1_id, team2_id
    INTO v_fix_status, v_team1_id, v_team2_id
    FROM fixture WHERE fixture_id = NEW.fixture_id;

    IF v_fix_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Validation error: Fixture not found.';
    END IF;

    IF v_fix_status <> 'Scheduled' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Result entry error: Result can only be entered for Scheduled fixtures.';
    END IF;

    -- 2. Validate scores and winner_team_id
    IF NEW.team1_score < 0 OR NEW.team2_score < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Result entry error: Scores must be greater than or equal to zero.';
    END IF;

    IF NEW.team1_score > NEW.team2_score THEN
        IF NEW.winner_team_id IS NULL OR NEW.winner_team_id <> v_team1_id THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Result validation error: winner_team_id must match the higher scoring team (team 1).';
        END IF;
    ELSEIF NEW.team2_score > NEW.team1_score THEN
        IF NEW.winner_team_id IS NULL OR NEW.winner_team_id <> v_team2_id THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Result validation error: winner_team_id must match the higher scoring team (team 2).';
        END IF;
    ELSE
        -- Draw: winner_team_id must be NULL
        IF NEW.winner_team_id IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Result validation error: Tied match must have winner_team_id as NULL (Draw).';
        END IF;
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_result_after_insert$$
CREATE TRIGGER trg_result_after_insert
AFTER INSERT ON result
FOR EACH ROW
BEGIN
    -- Atomically mark fixture as Completed
    UPDATE fixture
    SET status = 'Completed'
    WHERE fixture_id = NEW.fixture_id;
END$$

-- ============================================================================
-- RULE 3 & 6: EQUIPMENT ISSUE & RETURN VALIDATION
-- ============================================================================

DROP TRIGGER IF EXISTS trg_equipment_issue_before_insert$$
CREATE TRIGGER trg_equipment_issue_before_insert
BEFORE INSERT ON equipment_issue
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_end_date DATE;
    DECLARE v_unreturned_count INT DEFAULT 0;
    DECLARE v_overdue_count INT DEFAULT 0;

    -- 1. Active membership check (Rule 3)
    SELECT status, membership_end INTO v_status, v_end_date
    FROM member WHERE member_id = NEW.member_id;

    IF v_status <> 'Active' OR v_end_date < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Active membership required: Member is not Active or membership has expired.';
    END IF;

    -- 2. Check for any overdue items (Rule 6)
    SELECT COUNT(*) INTO v_overdue_count
    FROM equipment_issue
    WHERE member_id = NEW.member_id
      AND (status = 'Overdue' OR (return_date IS NULL AND due_date < CURDATE()));

    IF v_overdue_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Equipment issue blocked: Member has overdue equipment items.';
    END IF;

    -- 3. Check unreturned item limit (max 3 items at once) (Rule 6)
    SELECT COALESCE(SUM(quantity), 0) INTO v_unreturned_count
    FROM equipment_issue
    WHERE member_id = NEW.member_id
      AND return_date IS NULL;

    IF (v_unreturned_count + NEW.quantity) > 3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Equipment limit exceeded: Member cannot hold more than 3 unreturned equipment items at once.';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_equipment_issue_before_update$$
CREATE TRIGGER trg_equipment_issue_before_update
BEFORE UPDATE ON equipment_issue
FOR EACH ROW
BEGIN
    -- Ensure return date is not prior to issue date
    IF NEW.return_date IS NOT NULL AND NEW.return_date < NEW.issue_date THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid return date: Return date cannot be earlier than issue date.';
    END IF;

    -- Auto-adjust status when returned
    IF NEW.return_date IS NOT NULL THEN
        SET NEW.status = 'Returned';
    END IF;
END$$

DELIMITER ;

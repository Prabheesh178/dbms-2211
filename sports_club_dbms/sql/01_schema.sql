-- ============================================================================
-- SPORTS CLUB MEMBERSHIP AND TOURNAMENT MANAGEMENT SYSTEM
-- File: 01_schema.sql
-- Description: Database creation, table definitions, integrity constraints,
--              foreign keys with cascade/restrict semantics, and performance indexes.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS sports_club_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE sports_club_db;

-- Disable foreign key checks during clean rebuild
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS equipment_issue;
DROP TABLE IF EXISTS result;
DROP TABLE IF EXISTS participant;
DROP TABLE IF EXISTS fixture;
DROP TABLE IF EXISTS tournament;
DROP TABLE IF EXISTS training_session;
DROP TABLE IF EXISTS facility;
DROP TABLE IF EXISTS team_member;
DROP TABLE IF EXISTS team;
DROP TABLE IF EXISTS coach;
DROP TABLE IF EXISTS sport;
DROP TABLE IF EXISTS payment;
DROP TABLE IF EXISTS member;
DROP TABLE IF EXISTS membership_plan;

SET FOREIGN_KEY_CHECKS = 1;

-- ----------------------------------------------------------------------------
-- 1. Table: membership_plan
-- Description: Defines subscription tiers, validity, pricing, and perks.
-- ----------------------------------------------------------------------------
CREATE TABLE membership_plan (
    plan_id INT AUTO_INCREMENT PRIMARY KEY,
    plan_name VARCHAR(100) NOT NULL UNIQUE,
    duration_months INT NOT NULL,
    fee DECIMAL(10,2) NOT NULL,
    benefits TEXT,
    CONSTRAINT chk_plan_duration CHECK (duration_months > 0),
    CONSTRAINT chk_plan_fee CHECK (fee >= 0.00)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 2. Table: member
-- Description: Stores registered club patrons and their subscription status.
-- ON DELETE RESTRICT on plan_id preserves plan history while active members exist.
-- ----------------------------------------------------------------------------
CREATE TABLE member (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(120) NOT NULL UNIQUE,
    dob DATE NOT NULL,
    join_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    plan_id INT NOT NULL,
    membership_start DATE NOT NULL,
    membership_end DATE NOT NULL,
    status ENUM('Active', 'Expired', 'Suspended') NOT NULL DEFAULT 'Active',
    CONSTRAINT chk_member_dates CHECK (membership_end >= membership_start),
    CONSTRAINT fk_member_plan FOREIGN KEY (plan_id)
        REFERENCES membership_plan(plan_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 3. Table: payment
-- Description: Financial transactions for memberships and renewals.
-- ON DELETE RESTRICT ensures strict accounting audit trails cannot be deleted.
-- ----------------------------------------------------------------------------
CREATE TABLE payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    plan_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    mode ENUM('Cash', 'UPI', 'Card', 'Bank') NOT NULL,
    status ENUM('Paid', 'Pending') NOT NULL DEFAULT 'Paid',
    CONSTRAINT chk_payment_amount CHECK (amount > 0.00),
    CONSTRAINT fk_payment_member FOREIGN KEY (member_id)
        REFERENCES member(member_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_payment_plan FOREIGN KEY (plan_id)
        REFERENCES membership_plan(plan_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 4. Table: sport
-- Description: Sports offered by the club with squad constraints.
-- ----------------------------------------------------------------------------
CREATE TABLE sport (
    sport_id INT AUTO_INCREMENT PRIMARY KEY,
    sport_name VARCHAR(80) NOT NULL UNIQUE,
    category ENUM('Team', 'Individual') NOT NULL,
    max_team_size INT NOT NULL,
    CONSTRAINT chk_sport_max_team CHECK (max_team_size > 0)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 5. Table: coach
-- Description: Certified trainers linked to specialized sports disciplines.
-- ON DELETE RESTRICT on sport_id prevents orphaning coaching staff.
-- ----------------------------------------------------------------------------
CREATE TABLE coach (
    coach_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    specialization VARCHAR(100),
    sport_id INT NOT NULL,
    CONSTRAINT fk_coach_sport FOREIGN KEY (sport_id)
        REFERENCES sport(sport_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 6. Table: team
-- Description: Club squads affiliated with a sport and assigned head coach.
-- ON DELETE SET NULL on coach_id allows coach reassignment without losing team record.
-- ON DELETE RESTRICT on sport_id protects athletic identity integrity.
-- ----------------------------------------------------------------------------
CREATE TABLE team (
    team_id INT AUTO_INCREMENT PRIMARY KEY,
    team_name VARCHAR(100) NOT NULL UNIQUE,
    sport_id INT NOT NULL,
    coach_id INT NULL,
    formed_on DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT fk_team_sport FOREIGN KEY (sport_id)
        REFERENCES sport(sport_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_team_coach FOREIGN KEY (coach_id)
        REFERENCES coach(coach_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 7. Table: team_member
-- Description: Roster membership linking members to teams.
-- ON DELETE CASCADE on team_id cleanly cleans up roster when team is disbanded.
-- ON DELETE RESTRICT on member_id prevents dropping members who have roster history.
-- ----------------------------------------------------------------------------
CREATE TABLE team_member (
    team_member_id INT AUTO_INCREMENT PRIMARY KEY,
    team_id INT NOT NULL,
    member_id INT NOT NULL,
    role VARCHAR(50) DEFAULT 'Player',
    joined_on DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT uq_team_member UNIQUE (team_id, member_id),
    CONSTRAINT fk_tm_team FOREIGN KEY (team_id)
        REFERENCES team(team_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_tm_member FOREIGN KEY (member_id)
        REFERENCES member(member_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 8. Table: facility
-- Description: Physical club venues, courts, turfs, and tracks.
-- ----------------------------------------------------------------------------
CREATE TABLE facility (
    facility_id INT AUTO_INCREMENT PRIMARY KEY,
    facility_name VARCHAR(100) NOT NULL UNIQUE,
    type VARCHAR(60) NOT NULL,
    capacity INT NOT NULL,
    status ENUM('Available', 'Maintenance') NOT NULL DEFAULT 'Available',
    CONSTRAINT chk_facility_capacity CHECK (capacity > 0)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 9. Table: training_session
-- Description: Scheduled practice sessions utilizing a facility and coach.
-- Time constraint ensures end_time is strictly after start_time.
-- ON DELETE RESTRICT prevents loss of scheduled operational history.
-- ----------------------------------------------------------------------------
CREATE TABLE training_session (
    session_id INT AUTO_INCREMENT PRIMARY KEY,
    team_id INT NOT NULL,
    coach_id INT NOT NULL,
    facility_id INT NOT NULL,
    session_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    max_attendees INT NOT NULL,
    CONSTRAINT chk_training_time CHECK (end_time > start_time),
    CONSTRAINT chk_training_attendees CHECK (max_attendees > 0),
    CONSTRAINT fk_ts_team FOREIGN KEY (team_id)
        REFERENCES team(team_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_ts_coach FOREIGN KEY (coach_id)
        REFERENCES coach(coach_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_ts_facility FOREIGN KEY (facility_id)
        REFERENCES facility(facility_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 10. Table: tournament
-- Description: Competitive sporting events spanning a calendar date range.
-- ----------------------------------------------------------------------------
CREATE TABLE tournament (
    tournament_id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_name VARCHAR(120) NOT NULL,
    sport_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    CONSTRAINT chk_tourn_dates CHECK (end_date >= start_date),
    CONSTRAINT fk_tourn_sport FOREIGN KEY (sport_id)
        REFERENCES sport(sport_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 11. Table: fixture
-- Description: Specific match between two distinct teams at a venue.
-- ON DELETE CASCADE on tournament_id removes fixtures if tournament is deleted.
-- ON DELETE RESTRICT on teams and facility prevents accidental deletion of active venue/teams.
-- ----------------------------------------------------------------------------
CREATE TABLE fixture (
    fixture_id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_id INT NOT NULL,
    facility_id INT NOT NULL,
    team1_id INT NOT NULL,
    team2_id INT NOT NULL,
    fixture_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status ENUM('Scheduled', 'Completed', 'Cancelled') NOT NULL DEFAULT 'Scheduled',
    CONSTRAINT chk_fixture_teams CHECK (team1_id <> team2_id),
    CONSTRAINT chk_fixture_time CHECK (end_time > start_time),
    CONSTRAINT fk_fix_tourn FOREIGN KEY (tournament_id)
        REFERENCES tournament(tournament_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_fix_facility FOREIGN KEY (facility_id)
        REFERENCES facility(facility_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_fix_team1 FOREIGN KEY (team1_id)
        REFERENCES team(team_id)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_fix_team2 FOREIGN KEY (team2_id)
        REFERENCES team(team_id)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 12. Table: participant
-- Description: Individual player line-ups submitted for a specific fixture match.
-- ON DELETE CASCADE on fixture_id cleans up match rosters when fixture is removed.
-- ----------------------------------------------------------------------------
CREATE TABLE participant (
    participant_id INT AUTO_INCREMENT PRIMARY KEY,
    fixture_id INT NOT NULL,
    team_id INT NOT NULL,
    member_id INT NOT NULL,
    role VARCHAR(50) DEFAULT 'Starter',
    CONSTRAINT uq_fixture_member UNIQUE (fixture_id, member_id),
    CONSTRAINT fk_part_fixture FOREIGN KEY (fixture_id)
        REFERENCES fixture(fixture_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_part_team FOREIGN KEY (team_id)
        REFERENCES team(team_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_part_member FOREIGN KEY (member_id)
        REFERENCES member(member_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 13. Table: result
-- Description: Final outcome and scores for completed tournament fixtures.
-- UNIQUE constraint on fixture_id guarantees 1-to-1 relationship with fixture.
-- ON DELETE CASCADE on fixture_id ensures result is purged if match record is dropped.
-- ----------------------------------------------------------------------------
CREATE TABLE result (
    result_id INT AUTO_INCREMENT PRIMARY KEY,
    fixture_id INT NOT NULL UNIQUE,
    team1_score INT NOT NULL,
    team2_score INT NOT NULL,
    winner_team_id INT NULL,
    remarks TEXT,
    CONSTRAINT chk_res_score1 CHECK (team1_score >= 0),
    CONSTRAINT chk_res_score2 CHECK (team2_score >= 0),
    CONSTRAINT fk_res_fixture FOREIGN KEY (fixture_id)
        REFERENCES fixture(fixture_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_res_winner FOREIGN KEY (winner_team_id)
        REFERENCES team(team_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 14. Table: equipment_issue
-- Description: Tracks gear checkout, due dates, returns, and inventory accountability.
-- ----------------------------------------------------------------------------
CREATE TABLE equipment_issue (
    issue_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    equipment_name VARCHAR(100) NOT NULL,
    quantity INT NOT NULL,
    issue_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    due_date DATE NOT NULL,
    return_date DATE NULL,
    status ENUM('Issued', 'Returned', 'Overdue') NOT NULL DEFAULT 'Issued',
    CONSTRAINT chk_equip_qty CHECK (quantity > 0),
    CONSTRAINT chk_equip_dates CHECK (due_date >= issue_date),
    CONSTRAINT fk_eq_member FOREIGN KEY (member_id)
        REFERENCES member(member_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================================
-- PERFORMANCE INDEXES
-- Purpose: Speed up foreign key lookups, frequent filters, date-range checks,
--          and scheduling collision queries.
-- ============================================================================

-- Fast lookup for membership verification and authentication by email/phone/status
CREATE INDEX idx_member_email ON member(email);
CREATE INDEX idx_member_phone ON member(phone);
CREATE INDEX idx_member_status ON member(status);

-- Accelerates team roster membership filtering and joins
CREATE INDEX idx_team_member_fks ON team_member(team_id, member_id);

-- Critical composite index for collision detection and schedule calendar queries
CREATE INDEX idx_fixture_date_facility ON fixture(fixture_date, facility_id);
CREATE INDEX idx_training_date_facility ON training_session(session_date, facility_id);

-- Optimized lookup for member payment history and financial auditing
CREATE INDEX idx_payment_member_date ON payment(member_id, payment_date);

-- Speeds up equipment borrowing limits checking (counting active and overdue items per member)
CREATE INDEX idx_equipment_member_status ON equipment_issue(member_id, status);

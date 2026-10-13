-- ============================================================================
-- SPORTS CLUB MEMBERSHIP AND TOURNAMENT MANAGEMENT SYSTEM
-- File: 04_sample_data.sql
-- Description: Realistic Indian sports club sample dataset.
--              Fully validates against all constraints, triggers, and procedures.
-- ============================================================================

USE sports_club_db;

-- ----------------------------------------------------------------------------
-- 1. MEMBERSHIP PLANS (5 tiers)
-- ----------------------------------------------------------------------------
INSERT INTO membership_plan (plan_id, plan_name, duration_months, fee, benefits) VALUES
(1, 'Bronze Monthly', 1, 1500.00, 'Standard access to gym and general practice nets.'),
(2, 'Silver Quarterly', 3, 4000.00, 'Gym, practice facilities, plus 2 monthly coach clinic passes.'),
(3, 'Gold Half-Yearly', 6, 7500.00, 'Unlimited sports access, priority court reservations, 5 guest passes.'),
(4, 'Platinum Annual', 12, 14000.00, 'All-inclusive premium access, all tournament registrations included, dedicated locker.'),
(5, 'Student Special', 6, 4500.00, 'Subsidized pass for students under 23, valid during off-peak hours.');

-- ----------------------------------------------------------------------------
-- 2. SPORTS (6 disciplines)
-- ----------------------------------------------------------------------------
INSERT INTO sport (sport_id, sport_name, category, max_team_size) VALUES
(1, 'Cricket', 'Team', 15),
(2, 'Football', 'Team', 18),
(3, 'Badminton', 'Individual', 4),
(4, 'Basketball', 'Team', 12),
(5, 'Tennis', 'Individual', 4),
(6, 'Volleyball', 'Team', 10);

-- ----------------------------------------------------------------------------
-- 3. FACILITIES (6 venues + 1 under maintenance)
-- ----------------------------------------------------------------------------
INSERT INTO facility (facility_id, facility_name, type, capacity, status) VALUES
(1, 'Wankhede Practice Oval', 'Cricket Ground', 50, 'Available'),
(2, 'Shivaji Football Arena', 'Turf Ground', 40, 'Available'),
(3, 'Padukone Badminton Arena 1', 'Indoor Wooden Court', 12, 'Available'),
(4, 'Padukone Badminton Arena 2', 'Indoor Synthetic Court', 12, 'Available'),
(5, 'Deccan Basketball Arena', 'Hardwood Indoor Court', 30, 'Available'),
(6, 'Centre Court Tennis Complex', 'Clay Court', 16, 'Available'),
(7, 'Shivaji Annexe Turf', 'Mini Turf', 20, 'Maintenance');

-- ----------------------------------------------------------------------------
-- 4. COACHES (8 certified coaches)
-- ----------------------------------------------------------------------------
INSERT INTO coach (coach_id, name, phone, specialization, sport_id) VALUES
(1, 'Rahul Dravid', '+91 98201 11001', 'Batting & Tactical Play', 1),
(2, 'Bhaichung Bhutia', '+91 98201 11002', 'Forward Attacking & Conditioning', 2),
(3, 'Pullela Gopichand', '+91 98201 11003', 'Singles & Footwork Technique', 3),
(4, 'Satnam Singh', '+91 98201 11004', 'Post Play & Defense Drills', 4),
(5, 'Mahesh Bhupathi', '+91 98201 11005', 'Doubles Strategy & Serve-Volley', 5),
(6, 'Jimmy George', '+91 98201 11006', 'Spiking Mechanics & Rotations', 6),
(7, 'VVS Laxman', '+91 98201 11007', 'Middle Order & Fielding Drills', 1),
(8, 'Sunil Chhetri', '+91 98201 11008', 'Finishing & Set Pieces', 2);

-- ----------------------------------------------------------------------------
-- 5. TEAMS (10 teams affiliated with matching coach specialization)
-- ----------------------------------------------------------------------------
INSERT INTO team (team_id, team_name, sport_id, coach_id, formed_on) VALUES
(1, 'Mumbai Super Kings', 1, 1, '2026-01-10'),
(2, 'Delhi Daredevils', 1, 7, '2026-01-12'),
(3, 'Bengaluru FC Strikers', 2, 2, '2026-01-15'),
(4, 'Goa Mariners', 2, 8, '2026-01-20'),
(5, 'Hyderabad Smashers', 3, 3, '2026-02-01'),
(6, 'Chennai Shuttlers', 3, 3, '2026-02-05'),
(7, 'Punjab Hoopers', 4, 4, '2026-02-10'),
(8, 'Pune Cagers', 4, 4, '2026-02-15'),
(9, 'Kolkata Aces', 5, 5, '2026-03-01'),
(10, 'Ahmedabad Spikers', 6, 6, '2026-03-05');

-- ----------------------------------------------------------------------------
-- 6. MEMBERS (35 members: 30 Active, 3 Expired, 2 Suspended)
-- Current reference date in environment: October 2026
-- Active: membership_end in Nov 2026 - Dec 2027
-- Expired: membership_end in July-Sept 2026
-- ----------------------------------------------------------------------------
INSERT INTO member (member_id, name, phone, email, dob, join_date, plan_id, membership_start, membership_end, status) VALUES
(1, 'Aarav Sharma', '+91 98111 00001', 'aarav.sharma@example.in', '2001-04-12', '2026-01-05', 4, '2026-01-05', '2027-01-05', 'Active'),
(2, 'Priya Patel', '+91 98111 00002', 'priya.patel@example.in', '2002-08-20', '2026-01-10', 3, '2026-07-10', '2027-01-10', 'Active'),
(3, 'Rohan Verma', '+91 98111 00003', 'rohan.verma@example.in', '1999-11-03', '2026-01-15', 3, '2026-06-15', '2026-12-15', 'Active'),
(4, 'Ananya Iyer', '+91 98111 00004', 'ananya.iyer@example.in', '2003-02-18', '2026-02-01', 5, '2026-05-01', '2026-11-01', 'Active'),
(5, 'Vikram Singh', '+91 98111 00005', 'vikram.singh@example.in', '1998-06-25', '2026-02-10', 4, '2026-02-10', '2027-02-10', 'Active'),
(6, 'Neha Nair', '+91 98111 00006', 'neha.nair@example.in', '2000-09-14', '2026-02-15', 3, '2026-08-15', '2027-02-15', 'Active'),
(7, 'Aditya Rao', '+91 98111 00007', 'aditya.rao@example.in', '1997-12-30', '2026-03-01', 4, '2026-03-01', '2027-03-01', 'Active'),
(8, 'Kavya Reddy', '+91 98111 00008', 'kavya.reddy@example.in', '2002-05-19', '2026-03-05', 2, '2026-09-05', '2026-12-05', 'Active'),
(9, 'Kabir Malhotra', '+91 98111 00009', 'kabir.m@example.in', '2001-07-08', '2026-03-10', 3, '2026-07-10', '2027-01-10', 'Active'),
(10, 'Ishita Sengupta', '+91 98111 00010', 'ishita.s@example.in', '2003-03-22', '2026-03-15', 5, '2026-06-15', '2026-12-15', 'Active'),
(11, 'Manish Tiwari', '+91 98111 00011', 'manish.t@example.in', '1996-10-10', '2026-04-01', 4, '2026-04-01', '2027-04-01', 'Active'),
(12, 'Pooja Joshi', '+91 98111 00012', 'pooja.j@example.in', '2000-01-17', '2026-04-05', 2, '2026-08-05', '2026-11-05', 'Active'),
(13, 'Siddharth Deshmukh', '+91 98111 00013', 'sid.deshmukh@example.in', '1999-04-04', '2026-04-10', 3, '2026-07-10', '2027-01-10', 'Active'),
(14, 'Tanvi Kapoor', '+91 98111 00014', 'tanvi.k@example.in', '2002-12-12', '2026-04-15', 3, '2026-08-15', '2027-02-15', 'Active'),
(15, 'Arjun Menon', '+91 98111 00015', 'arjun.menon@example.in', '1998-03-09', '2026-05-01', 4, '2026-05-01', '2027-05-01', 'Active'),
(16, 'Diya Mukherjee', '+91 98111 00016', 'diya.m@example.in', '2001-10-27', '2026-05-05', 2, '2026-09-05', '2026-12-05', 'Active'),
(17, 'Harsh Vardhan', '+91 98111 00017', 'harsh.v@example.in', '2000-06-06', '2026-05-10', 4, '2026-05-10', '2027-05-10', 'Active'),
(18, 'Ritu Agarwal', '+91 98111 00018', 'ritu.a@example.in', '2002-09-01', '2026-05-15', 3, '2026-07-15', '2027-01-15', 'Active'),
(19, 'Varun Chopra', '+91 98111 00019', 'varun.c@example.in', '1997-08-14', '2026-06-01', 4, '2026-06-01', '2027-06-01', 'Active'),
(20, 'Meera Nambiar', '+91 98111 00020', 'meera.n@example.in', '2003-07-23', '2026-06-05', 5, '2026-07-05', '2027-01-05', 'Active'),
(21, 'Kunal Shah', '+91 98111 00021', 'kunal.shah@example.in', '1999-05-11', '2026-06-10', 3, '2026-06-10', '2026-12-10', 'Active'),
(22, 'Shreya Kulkarni', '+91 98111 00022', 'shreya.k@example.in', '2001-01-30', '2026-06-15', 2, '2026-09-15', '2026-12-15', 'Active'),
(23, 'Gaurav Bhatia', '+91 98111 00023', 'gaurav.b@example.in', '1998-11-20', '2026-07-01', 4, '2026-07-01', '2027-07-01', 'Active'),
(24, 'Sneha Pillai', '+91 98111 00024', 'sneha.p@example.in', '2000-04-18', '2026-07-05', 3, '2026-07-05', '2027-01-05', 'Active'),
(25, 'Abhishek Chatterjee', '+91 98111 00025', 'abhi.c@example.in', '1999-09-09', '2026-07-10', 4, '2026-07-10', '2027-07-10', 'Active'),
(26, 'Deepika Goswami', '+91 98111 00026', 'deepika.g@example.in', '2002-03-14', '2026-07-15', 2, '2026-08-15', '2026-11-15', 'Active'),
(27, 'Naveen Kumar', '+91 98111 00027', 'naveen.k@example.in', '1997-02-28', '2026-08-01', 4, '2026-08-01', '2027-08-01', 'Active'),
(28, 'Prerna Mathur', '+91 98111 00028', 'prerna.m@example.in', '2001-12-05', '2026-08-05', 3, '2026-08-05', '2027-02-05', 'Active'),
(29, 'Sameer Saxena', '+91 98111 00029', 'sameer.s@example.in', '1998-08-08', '2026-08-10', 4, '2026-08-10', '2027-08-10', 'Active'),
(30, 'Bhavna Chauhan', '+91 98111 00030', 'bhavna.c@example.in', '2000-02-16', '2026-08-15', 3, '2026-08-15', '2027-02-15', 'Active'),
-- Expired Members (useful for dues/expiration reporting)
(31, 'Rajesh Khanna', '+91 98111 00031', 'rajesh.khanna@example.in', '1995-05-15', '2025-06-01', 1, '2026-07-01', '2026-08-01', 'Expired'),
(32, 'Sunita Hegde', '+91 98111 00032', 'sunita.h@example.in', '1996-09-21', '2025-07-10', 2, '2026-06-10', '2026-09-10', 'Expired'),
(33, 'Devendra Yadav', '+91 98111 00033', 'devendra.y@example.in', '1994-01-11', '2025-08-01', 1, '2026-08-01', '2026-09-01', 'Expired'),
-- Suspended Members
(34, 'Mohit Suri', '+91 98111 00034', 'mohit.suri@example.in', '1997-04-19', '2026-01-20', 3, '2026-01-20', '2026-07-20', 'Suspended'),
(35, 'Tanya Singhania', '+91 98111 00035', 'tanya.s@example.in', '2001-11-11', '2026-02-25', 2, '2026-02-25', '2026-05-25', 'Suspended');

-- ----------------------------------------------------------------------------
-- 7. PAYMENTS (35 payments, mix of Paid and Pending for dues report)
-- ----------------------------------------------------------------------------
INSERT INTO payment (payment_id, member_id, plan_id, amount, payment_date, mode, status) VALUES
(1, 1, 4, 14000.00, '2026-01-05', 'UPI', 'Paid'),
(2, 2, 3, 7500.00, '2026-07-10', 'Card', 'Paid'),
(3, 3, 3, 7500.00, '2026-06-15', 'Bank', 'Paid'),
(4, 4, 5, 4500.00, '2026-05-01', 'UPI', 'Paid'),
(5, 5, 4, 14000.00, '2026-02-10', 'Card', 'Paid'),
(6, 6, 3, 7500.00, '2026-08-15', 'Cash', 'Paid'),
(7, 7, 4, 14000.00, '2026-03-01', 'Bank', 'Paid'),
(8, 8, 2, 4000.00, '2026-09-05', 'UPI', 'Paid'),
(9, 9, 3, 7500.00, '2026-07-10', 'Card', 'Paid'),
(10, 10, 5, 4500.00, '2026-06-15', 'UPI', 'Paid'),
(11, 11, 4, 14000.00, '2026-04-01', 'Card', 'Paid'),
(12, 12, 2, 4000.00, '2026-08-05', 'Cash', 'Paid'),
(13, 13, 3, 7500.00, '2026-07-10', 'Bank', 'Paid'),
(14, 14, 3, 7500.00, '2026-08-15', 'UPI', 'Paid'),
(15, 15, 4, 14000.00, '2026-05-01', 'Card', 'Paid'),
(16, 16, 2, 4000.00, '2026-09-05', 'UPI', 'Paid'),
(17, 17, 4, 14000.00, '2026-05-10', 'Bank', 'Paid'),
(18, 18, 3, 7500.00, '2026-07-15', 'Cash', 'Paid'),
(19, 19, 4, 14000.00, '2026-06-01', 'Card', 'Paid'),
(20, 20, 5, 4500.00, '2026-07-05', 'UPI', 'Paid'),
(21, 21, 3, 7500.00, '2026-06-10', 'Bank', 'Paid'),
(22, 22, 2, 4000.00, '2026-09-15', 'Card', 'Paid'),
(23, 23, 4, 14000.00, '2026-07-01', 'UPI', 'Paid'),
(24, 24, 3, 7500.00, '2026-07-05', 'Cash', 'Paid'),
(25, 25, 4, 14000.00, '2026-07-10', 'Card', 'Paid'),
(26, 26, 2, 4000.00, '2026-08-15', 'UPI', 'Paid'),
(27, 27, 4, 14000.00, '2026-08-01', 'Bank', 'Paid'),
(28, 28, 3, 7500.00, '2026-08-05', 'Card', 'Paid'),
(29, 29, 4, 14000.00, '2026-08-10', 'UPI', 'Paid'),
(30, 30, 3, 7500.00, '2026-08-15', 'Cash', 'Paid'),
-- Historical & Pending records
(31, 31, 1, 1500.00, '2026-07-01', 'Cash', 'Paid'),
(32, 32, 2, 4000.00, '2026-06-10', 'UPI', 'Paid'),
(33, 33, 1, 1500.00, '2026-08-01', 'Cash', 'Paid'),
(34, 12, 1, 1500.00, '2026-10-01', 'UPI', 'Pending'),
(35, 16, 1, 1500.00, '2026-10-02', 'Card', 'Pending');

-- ----------------------------------------------------------------------------
-- 8. TEAM MEMBERS (42 roster entries, all using Active members 1-30)
-- ----------------------------------------------------------------------------
INSERT INTO team_member (team_member_id, team_id, member_id, role, joined_on) VALUES
-- Team 1: Mumbai Super Kings (Cricket) - 6 members
(1, 1, 1, 'Captain', '2026-01-15'),
(2, 1, 2, 'Vice-Captain', '2026-01-15'),
(3, 1, 3, 'Wicketkeeper', '2026-01-16'),
(4, 1, 4, 'Bowler', '2026-01-16'),
(5, 1, 5, 'All-Rounder', '2026-01-17'),
(6, 1, 6, 'Batsman', '2026-01-17'),
-- Team 2: Delhi Daredevils (Cricket) - 6 members
(7, 2, 7, 'Captain', '2026-01-20'),
(8, 2, 8, 'Batsman', '2026-01-20'),
(9, 2, 9, 'Fast Bowler', '2026-01-21'),
(10, 2, 10, 'Spin Bowler', '2026-01-21'),
(11, 2, 11, 'All-Rounder', '2026-01-22'),
(12, 2, 12, 'Wicketkeeper', '2026-01-22'),
-- Team 3: Bengaluru FC Strikers (Football) - 6 members
(13, 3, 13, 'Forward / Captain', '2026-01-25'),
(14, 3, 14, 'Midfielder', '2026-01-25'),
(15, 3, 15, 'Defender', '2026-01-26'),
(16, 3, 16, 'Goalkeeper', '2026-01-26'),
(17, 3, 17, 'Winger', '2026-01-27'),
(18, 3, 18, 'Centre-Back', '2026-01-27'),
-- Team 4: Goa Mariners (Football) - 6 members
(19, 4, 19, 'Captain / Striker', '2026-02-01'),
(20, 4, 20, 'Midfielder', '2026-02-01'),
(21, 4, 21, 'Defender', '2026-02-02'),
(22, 4, 22, 'Goalkeeper', '2026-02-02'),
(23, 4, 23, 'Full-Back', '2026-02-03'),
(24, 4, 24, 'Playmaker', '2026-02-03'),
-- Team 5: Hyderabad Smashers (Badminton) - 2 members
(25, 5, 1, 'Singles Lead', '2026-02-10'),
(26, 5, 2, 'Doubles Lead', '2026-02-10'),
-- Team 6: Chennai Shuttlers (Badminton) - 2 members
(27, 6, 3, 'Singles Lead', '2026-02-12'),
(28, 6, 4, 'Doubles Lead', '2026-02-12'),
-- Team 7: Punjab Hoopers (Basketball) - 4 members
(29, 7, 5, 'Point Guard', '2026-02-15'),
(30, 7, 6, 'Shooting Guard', '2026-02-15'),
(31, 7, 7, 'Center', '2026-02-16'),
(32, 7, 8, 'Power Forward', '2026-02-16'),
-- Team 8: Pune Cagers (Basketball) - 4 members
(33, 8, 9, 'Point Guard', '2026-02-20'),
(34, 8, 10, 'Small Forward', '2026-02-20'),
(35, 8, 11, 'Center', '2026-02-21'),
(36, 8, 12, 'Shooting Guard', '2026-02-21'),
-- Team 9: Kolkata Aces (Tennis) - 3 members
(37, 9, 15, 'Singles Player', '2026-03-05'),
(38, 9, 16, 'Doubles Player', '2026-03-05'),
(39, 9, 25, 'Doubles Player', '2026-03-06'),
-- Team 10: Ahmedabad Spikers (Volleyball) - 3 members
(40, 10, 27, 'Setter', '2026-03-10'),
(41, 10, 28, 'Spiker', '2026-03-10'),
(42, 10, 29, 'Libero', '2026-03-11');

-- ----------------------------------------------------------------------------
-- 9. TOURNAMENTS (3 competitive tournaments)
-- ----------------------------------------------------------------------------
INSERT INTO tournament (tournament_id, tournament_name, sport_id, start_date, end_date) VALUES
(1, 'All-India Inter-Club Cricket Championship 2026', 1, '2026-10-01', '2026-10-31'),
(2, 'Indian Club Football League Trophy 2026', 2, '2026-10-05', '2026-11-05'),
(3, 'National Club Badminton Open 2026', 3, '2026-10-10', '2026-10-25');

-- ----------------------------------------------------------------------------
-- 10. TRAINING SESSIONS (25 non-overlapping sessions across October 2026)
-- ----------------------------------------------------------------------------
INSERT INTO training_session (session_id, team_id, coach_id, facility_id, session_date, start_time, end_time, max_attendees) VALUES
-- Cricket Training (Facility 1 - Wankhede Oval, capacity 50)
(1, 1, 1, 1, '2026-10-14', '06:00:00', '08:00:00', 15),
(2, 2, 7, 1, '2026-10-14', '08:30:00', '10:30:00', 15),
(3, 1, 1, 1, '2026-10-15', '06:00:00', '08:00:00', 15),
(4, 2, 7, 1, '2026-10-15', '08:30:00', '10:30:00', 15),
(5, 1, 1, 1, '2026-10-16', '06:00:00', '08:00:00', 15),
-- Football Training (Facility 2 - Shivaji Football Arena, capacity 40)
(6, 3, 2, 2, '2026-10-14', '06:30:00', '08:30:00', 18),
(7, 4, 8, 2, '2026-10-14', '09:00:00', '11:00:00', 18),
(8, 3, 2, 2, '2026-10-15', '06:30:00', '08:30:00', 18),
(9, 4, 8, 2, '2026-10-15', '09:00:00', '11:00:00', 18),
(10, 3, 2, 2, '2026-10-16', '06:30:00', '08:30:00', 18),
-- Badminton Training (Facility 3 & 4 - Padukone Arenas, capacity 12)
(11, 5, 3, 3, '2026-10-14', '07:00:00', '09:00:00', 4),
(12, 6, 3, 4, '2026-10-14', '07:00:00', '09:00:00', 4),
(13, 5, 3, 3, '2026-10-15', '07:00:00', '09:00:00', 4),
(14, 6, 3, 4, '2026-10-15', '07:00:00', '09:00:00', 4),
(15, 5, 3, 3, '2026-10-16', '07:00:00', '09:00:00', 4),
-- Basketball Training (Facility 5 - Deccan Basketball Arena, capacity 30)
(16, 7, 4, 5, '2026-10-14', '16:00:00', '18:00:00', 12),
(17, 8, 4, 5, '2026-10-14', '18:30:00', '20:30:00', 12),
(18, 7, 4, 5, '2026-10-15', '16:00:00', '18:00:00', 12),
(19, 8, 4, 5, '2026-10-15', '18:30:00', '20:30:00', 12),
(20, 7, 4, 5, '2026-10-16', '16:00:00', '18:00:00', 12),
-- Tennis Training (Facility 6 - Centre Court, capacity 16)
(21, 9, 5, 6, '2026-10-14', '06:00:00', '08:00:00', 4),
(22, 9, 5, 6, '2026-10-15', '06:00:00', '08:00:00', 4),
(23, 9, 5, 6, '2026-10-16', '06:00:00', '08:00:00', 4),
-- Additional Cricket & Football Evening Sessions
(24, 1, 1, 1, '2026-10-17', '16:00:00', '18:00:00', 15),
(25, 3, 2, 2, '2026-10-17', '16:00:00', '18:00:00', 18);

-- ----------------------------------------------------------------------------
-- 11. FIXTURES (20 fixtures: 12 Completed, 8 Scheduled)
-- Fixture dates and hours strictly avoided collision with training sessions.
-- Training occurs early morning/late afternoon on 14-17 Oct.
-- Fixtures are placed in afternoon slots or on dates 01-13 Oct and 18-28 Oct.
-- Note: All fixtures start as Scheduled. For fixtures 1-12, inserting into
-- `result` below triggers automatic completion and winner updates!
-- ----------------------------------------------------------------------------
INSERT INTO fixture (fixture_id, tournament_id, facility_id, team1_id, team2_id, fixture_date, start_time, end_time, status) VALUES
-- Tournament 1: Cricket (Facility 1)
(1, 1, 1, 1, 2, '2026-10-02', '14:00:00', '18:00:00', 'Scheduled'),
(2, 1, 1, 2, 1, '2026-10-04', '14:00:00', '18:00:00', 'Scheduled'),
(3, 1, 1, 1, 2, '2026-10-06', '14:00:00', '18:00:00', 'Scheduled'),
(4, 1, 1, 2, 1, '2026-10-08', '14:00:00', '18:00:00', 'Scheduled'),
-- Tournament 2: Football (Facility 2)
(5, 2, 2, 3, 4, '2026-10-06', '15:30:00', '17:30:00', 'Scheduled'),
(6, 2, 2, 4, 3, '2026-10-08', '15:30:00', '17:30:00', 'Scheduled'),
(7, 2, 2, 3, 4, '2026-10-10', '15:30:00', '17:30:00', 'Scheduled'),
(8, 2, 2, 4, 3, '2026-10-12', '15:30:00', '17:30:00', 'Scheduled'),
-- Tournament 3: Badminton (Facility 3 & 4)
(9, 3, 3, 5, 6, '2026-10-11', '10:00:00', '12:00:00', 'Scheduled'),
(10, 3, 4, 6, 5, '2026-10-12', '10:00:00', '12:00:00', 'Scheduled'),
(11, 3, 3, 5, 6, '2026-10-13', '10:00:00', '12:00:00', 'Scheduled'),
(12, 3, 4, 6, 5, '2026-10-13', '14:00:00', '16:00:00', 'Scheduled'),
-- Future / Upcoming Scheduled Fixtures (13 to 20)
(13, 1, 1, 1, 2, '2026-10-20', '14:00:00', '18:00:00', 'Scheduled'),
(14, 1, 1, 2, 1, '2026-10-22', '14:00:00', '18:00:00', 'Scheduled'),
(15, 2, 2, 3, 4, '2026-10-21', '15:30:00', '17:30:00', 'Scheduled'),
(16, 2, 2, 4, 3, '2026-10-23', '15:30:00', '17:30:00', 'Scheduled'),
(17, 3, 3, 5, 6, '2026-10-20', '10:00:00', '12:00:00', 'Scheduled'),
(18, 3, 4, 6, 5, '2026-10-22', '10:00:00', '12:00:00', 'Scheduled'),
(19, 1, 1, 1, 2, '2026-10-26', '14:00:00', '18:00:00', 'Scheduled'),
(20, 2, 2, 3, 4, '2026-10-28', '15:30:00', '17:30:00', 'Scheduled');

-- ----------------------------------------------------------------------------
-- 12. PARTICIPANTS (42 participant line-up entries for fixtures 1, 5, 9)
-- ----------------------------------------------------------------------------
-- Fixture 1: Team 1 (Mumbai) vs Team 2 (Delhi)
INSERT INTO participant (fixture_id, team_id, member_id, role) VALUES
(1, 1, 1, 'Captain / Opener'),
(1, 1, 2, 'Vice-Captain'),
(1, 1, 3, 'Wicketkeeper'),
(1, 1, 4, 'Pace Bowler'),
(1, 1, 5, 'All-Rounder'),
(1, 1, 6, 'Batsman'),
(1, 2, 7, 'Captain / Opener'),
(1, 2, 8, 'Top Order'),
(1, 2, 9, 'Strike Bowler'),
(1, 2, 10, 'Spinner'),
(1, 2, 11, 'All-Rounder'),
(1, 2, 12, 'Wicketkeeper');

-- Fixture 5: Team 3 (Bengaluru) vs Team 4 (Goa)
INSERT INTO participant (fixture_id, team_id, member_id, role) VALUES
(5, 3, 13, 'Striker'),
(5, 3, 14, 'Central Midfielder'),
(5, 3, 15, 'Centre Back'),
(5, 3, 16, 'Goalkeeper'),
(5, 3, 17, 'Right Winger'),
(5, 3, 18, 'Left Back'),
(5, 4, 19, 'Centre Forward'),
(5, 4, 20, 'Attacking Midfielder'),
(5, 4, 21, 'Centre Back'),
(5, 4, 22, 'Goalkeeper'),
(5, 4, 23, 'Right Back'),
(5, 4, 24, 'Playmaker');

-- Fixture 9: Team 5 (Hyderabad) vs Team 6 (Chennai)
INSERT INTO participant (fixture_id, team_id, member_id, role) VALUES
(9, 5, 1, 'Lead Singles Player'),
(9, 5, 2, 'Doubles Partner'),
(9, 6, 3, 'Lead Singles Player'),
(9, 6, 4, 'Doubles Partner');

-- Additional Match Rosters (Fixture 2, 6, 10)
INSERT INTO participant (fixture_id, team_id, member_id, role) VALUES
(2, 2, 7, 'Captain'),
(2, 2, 8, 'Batsman'),
(2, 2, 9, 'Bowler'),
(2, 1, 1, 'Captain'),
(2, 1, 2, 'Batsman'),
(2, 1, 3, 'Wicketkeeper'),
(6, 4, 19, 'Captain'),
(6, 4, 20, 'Midfielder'),
(6, 3, 13, 'Captain'),
(6, 3, 14, 'Midfielder'),
(10, 6, 3, 'Singles Lead'),
(10, 5, 1, 'Singles Lead');

-- ----------------------------------------------------------------------------
-- 13. RESULTS (12 results for Completed fixtures 1-12)
-- Note: Trigger trg_result_after_insert updates fixture status to Completed!
-- Winner team ID matches higher score, or NULL for tie.
-- ----------------------------------------------------------------------------
INSERT INTO result (result_id, fixture_id, team1_score, team2_score, winner_team_id, remarks) VALUES
-- Cricket Results (runs)
(1, 1, 185, 160, 1, 'Mumbai Super Kings won by 25 runs. Outstanding opening partnership.'),
(2, 2, 172, 174, 1, 'Mumbai Super Kings won by 4 wickets in a last-over thriller.'),
(3, 3, 150, 150, NULL, 'Match Tied after 20 overs. Super over omitted by tournament rules.'),
(4, 4, 190, 145, 2, 'Delhi Daredevils bounced back with disciplined bowling attack.'),
-- Football Results (goals)
(5, 5, 3, 1, 3, 'Bengaluru FC dominated possession with clinical finishing.'),
(6, 6, 2, 2, NULL, 'Thrilling 2-2 draw with stoppage time equalizer by Goa.'),
(7, 7, 0, 1, 4, 'Goa Mariners secured defensive away clean sheet win.'),
(8, 8, 3, 2, 4, 'End-to-end derby ending with Goa scoring decisive goal.'),
-- Badminton Results (game points)
(9, 9, 21, 18, 5, 'Hyderabad won first rubber in high tempo baseline rallies.'),
(10, 10, 22, 20, 6, 'Chennai took nail-biting deuce set.'),
(11, 11, 21, 15, 5, 'Comprehensive straight-set victory for Hyderabad Smashers.'),
(12, 12, 19, 21, 5, 'Hyderabad secured away win with sharp net smashes.');

-- ----------------------------------------------------------------------------
-- 14. EQUIPMENT ISSUES (25 issues: 16 Returned, 6 Active Issued, 3 Overdue)
-- Active members only, respecting limit of <= 3 unreturned items per member.
-- ----------------------------------------------------------------------------
INSERT INTO equipment_issue (issue_id, member_id, equipment_name, quantity, issue_date, due_date, return_date, status) VALUES
-- Returned items (Past issues returned on time)
(1, 1, 'SG Cricket Bat (English Willow)', 1, '2026-09-01', '2026-09-08', '2026-09-07', 'Returned'),
(2, 1, 'Kookaburra Batting Pads', 1, '2026-09-10', '2026-09-17', '2026-09-16', 'Returned'),
(3, 2, 'Yonex Astrox 99 Badminton Racket', 1, '2026-09-05', '2026-09-12', '2026-09-11', 'Returned'),
(4, 3, 'Nivia Premier League Football', 1, '2026-09-08', '2026-09-15', '2026-09-14', 'Returned'),
(5, 4, 'Wilson US Open Tennis Racket', 1, '2026-09-12', '2026-09-19', '2026-09-18', 'Returned'),
(6, 5, 'Spalding NBA Official Basketball', 1, '2026-09-15', '2026-09-22', '2026-09-21', 'Returned'),
(7, 6, 'SG Leather Match Ball (Red)', 2, '2026-09-18', '2026-09-25', '2026-09-24', 'Returned'),
(8, 7, 'Kookaburra Helmet (Titanium)', 1, '2026-09-20', '2026-09-27', '2026-09-26', 'Returned'),
(9, 8, 'Yonex Shuttlecock Tube (Mavis 350)', 1, '2026-09-22', '2026-09-29', '2026-09-28', 'Returned'),
(10, 9, 'Mikasa V200W Volleyball', 1, '2026-09-25', '2026-10-02', '2026-10-01', 'Returned'),
(11, 10, 'Adidas Shin Guards (Pair)', 1, '2026-09-28', '2026-10-05', '2026-10-04', 'Returned'),
(12, 11, 'SS Wicket Keeping Gloves', 1, '2026-10-01', '2026-10-08', '2026-10-07', 'Returned'),
(13, 12, 'Cosco Championship Tennis Balls Can', 1, '2026-10-02', '2026-10-09', '2026-10-08', 'Returned'),
(14, 13, 'Agility Cones & Ladder Set', 1, '2026-10-03', '2026-10-10', '2026-10-09', 'Returned'),
(15, 14, 'Nivia Football Goalkeeper Gloves', 1, '2026-10-04', '2026-10-11', '2026-10-10', 'Returned'),
(16, 15, 'Yonex Badminton Net & Posts', 1, '2026-10-05', '2026-10-12', '2026-10-11', 'Returned'),

-- Currently Active Issued Gear (Due in future, return_date NULL)
(17, 1, 'SG Cricket Helmet', 1, '2026-10-10', '2026-10-24', NULL, 'Issued'),
(18, 2, 'Yonex Nanoflare Racket', 1, '2026-10-10', '2026-10-24', NULL, 'Issued'),
(19, 3, 'Kipsta Training Football Size 5', 1, '2026-10-11', '2026-10-25', NULL, 'Issued'),
(20, 5, 'Molten Basketball Size 7', 1, '2026-10-11', '2026-10-25', NULL, 'Issued'),
(21, 7, 'SS Master 500 Batting Gloves', 1, '2026-10-12', '2026-10-26', NULL, 'Issued'),
(22, 13, 'Football Tactical Whiteboard', 1, '2026-10-12', '2026-10-26', NULL, 'Issued'),

-- Overdue Gear (Due date prior to Oct 12 2026, return_date NULL)
(23, 17, 'Head Speed Tennis Racket', 1, '2026-09-20', '2026-09-27', NULL, 'Overdue'),
(24, 18, 'Cricket Stumps & Bails Wooden Set', 1, '2026-09-22', '2026-09-29', NULL, 'Overdue'),
(25, 23, 'Spalding Precision Basketball', 1, '2026-09-25', '2026-10-02', NULL, 'Overdue');

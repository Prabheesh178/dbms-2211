"""Unit and integration test suite for Sports Club DBMS application.
Tests validator functions and key Flask web routes.
"""

import os
import sys
import pytest

# Ensure app directory is on Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "app")))

from app import app
import validators


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


# ============================================================================
# 1. VALIDATOR UNIT TESTS
# ============================================================================
class TestValidators:
    def test_email_validation(self):
        assert validators.validate_email("aarav.sharma@example.in") is None
        assert validators.validate_email("user@club.org") is None
        assert validators.validate_email("invalid-email") is not None
        assert validators.validate_email("") is not None
        assert validators.validate_email("missing@domain") is not None

    def test_phone_validation(self):
        assert validators.validate_phone("+91 98111 00001") is None
        assert validators.validate_phone("9876543210") is None
        assert validators.validate_phone("123") is not None
        assert validators.validate_phone("invalid_phone_string") is not None
        assert validators.validate_phone("") is not None

    def test_date_validation(self):
        d, err = validators.validate_date("2026-10-15", "Event date")
        assert err is None
        assert d is not None and d.year == 2026

        d, err = validators.validate_date("not-a-date", "Event date")
        assert err is not None
        assert "YYYY-MM-DD" in err

    def test_date_range_validation(self):
        assert validators.validate_date_range("2026-10-01", "2026-10-31") is None
        assert validators.validate_date_range("2026-10-15", "2026-10-15", allow_equal=True) is None
        assert validators.validate_date_range("2026-10-31", "2026-10-01") is not None

    def test_time_range_validation(self):
        assert validators.validate_time_range("06:00", "08:00") is None
        assert validators.validate_time_range("14:30:00", "16:30:00") is None
        assert validators.validate_time_range("08:00", "06:00") is not None
        assert validators.validate_time_range("10:00", "10:00") is not None

    def test_positive_numbers(self):
        v, err = validators.validate_positive_int(10, "Count")
        assert err is None and v == 10

        v, err = validators.validate_positive_int(-5, "Count")
        assert err is not None

        v, err = validators.validate_positive_decimal(1500.50, "Fee")
        assert err is None and v == 1500.50

        v, err = validators.validate_positive_decimal(-10.0, "Fee")
        assert err is not None

    def test_member_payload_validator(self):
        valid_payload = {
            "name": "Virat Kohli",
            "phone": "+91 98200 12345",
            "email": "virat@cricket.in",
            "dob": "1988-11-05",
            "plan_id": "4",
            "mode": "UPI",
        }
        assert validators.validate_member_registration(valid_payload) == []

        invalid_payload = {
            "name": "",
            "phone": "bad_phone",
            "email": "bad_email",
            "dob": "invalid",
            "plan_id": "-1",
            "mode": "Bitcoin",
        }
        errors = validators.validate_member_registration(invalid_payload)
        assert len(errors) >= 5

    def test_fixture_payload_validator(self):
        valid_fix = {
            "tournament_id": "1",
            "facility_id": "1",
            "team1_id": "1",
            "team2_id": "2",
            "fixture_date": "2026-10-25",
            "start_time": "14:00",
            "end_time": "18:00",
        }
        assert validators.validate_fixture(valid_fix) == []

        # Duplicate team test
        invalid_fix = dict(valid_fix, team2_id="1")
        errors = validators.validate_fixture(invalid_fix)
        assert any("distinct" in e for e in errors)


# ============================================================================
# 2. FLASK ROUTE INTEGRATION TESTS
# ============================================================================
class TestFlaskRoutes:
    def test_dashboard_route(self, client):
        response = client.get("/")
        assert response.status_code == 200
        assert b"Club Operations Dashboard" in response.data
        assert b"Active Members" in response.data

    def test_members_route(self, client):
        response = client.get("/members")
        assert response.status_code == 200
        assert b"Club Memberships" in response.data
        assert b"Aarav Sharma" in response.data

    def test_teams_route(self, client):
        response = client.get("/teams")
        assert response.status_code == 200
        assert b"Teams &amp; Athletic Squads" in response.data or b"Teams & Squads" in response.data
        assert b"Mumbai Super Kings" in response.data

    def test_team_detail_route(self, client):
        response = client.get("/teams/1")
        assert response.status_code == 200
        assert b"Mumbai Super Kings" in response.data
        assert b"Official Team Roster" in response.data

    def test_training_route(self, client):
        response = client.get("/training")
        assert response.status_code == 200
        assert b"Training Sessions" in response.data

    def test_facilities_route(self, client):
        response = client.get("/facilities")
        assert response.status_code == 200
        assert b"Facilities &amp; Venue Bookings" in response.data or b"Facilities & Venue Bookings" in response.data
        assert b"Wankhede Practice Oval" in response.data

    def test_facility_conflict_checker_api(self, client):
        # Test conflict check on facility 1 during existing training session (2026-10-14 06:00-08:00)
        response = client.post("/facilities/check_conflict", data={
            "facility_id": "1",
            "booking_date": "2026-10-14",
            "start_time": "06:30",
            "end_time": "07:30"
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data["conflict"] is True

        # Test free slot on facility 1 (2026-10-14 11:00-13:00)
        response = client.post("/facilities/check_conflict", data={
            "facility_id": "1",
            "booking_date": "2026-10-14",
            "start_time": "11:00",
            "end_time": "13:00"
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data["conflict"] is False

    def test_fixtures_route(self, client):
        response = client.get("/fixtures")
        assert response.status_code == 200
        assert b"Match Fixtures" in response.data

    def test_results_route(self, client):
        response = client.get("/results")
        assert response.status_code == 200
        assert b"Match Results &amp; Outcomes" in response.data or b"Match Results & Outcomes" in response.data

    def test_payments_route(self, client):
        response = client.get("/payments")
        assert response.status_code == 200
        assert b"Fee Collection" in response.data

    def test_equipment_route(self, client):
        response = client.get("/equipment")
        assert response.status_code == 200
        assert b"Equipment Issue &amp; Inventory" in response.data or b"Equipment Issue & Inventory" in response.data

    def test_reports_route(self, client):
        response = client.get("/reports?report=tournament_standings")
        assert response.status_code == 200
        assert b"Tournament Standings" in response.data

    def test_reports_csv_export(self, client):
        response = client.get("/reports/export/tournament_standings")
        assert response.status_code == 200
        assert response.content_type == "text/csv; charset=utf-8"
        assert b"tournament_name" in response.data

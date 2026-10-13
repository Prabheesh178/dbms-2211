"""Server-side form and parameter validation layer for Sports Club DBMS.
Ensures strong typing, format integrity, and business logic conformance
prior to database query execution.
"""

import re
from datetime import datetime, date, time
from typing import Any, Dict, List, Optional, Tuple


def validate_required(data: Dict[str, Any], required_fields: List[str]) -> List[str]:
    """Checks that all specified fields are present and non-empty."""
    errors = []
    for field in required_fields:
        val = data.get(field)
        if val is None or (isinstance(val, str) and not val.strip()):
            readable_name = field.replace("_", " ").capitalize()
            errors.append(f"{readable_name} is required.")
    return errors


def validate_email(email: Optional[str]) -> Optional[str]:
    """Validates email format."""
    if not email or not email.strip():
        return "Email address is required."
    email_regex = r"^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$"
    if not re.match(email_regex, email.strip()):
        return "Invalid email format (e.g., user@example.com)."
    return None


def validate_phone(phone: Optional[str]) -> Optional[str]:
    """Validates contact phone number format."""
    if not phone or not phone.strip():
        return "Phone number is required."
    # Allow digits, optional leading +, spaces, hyphens
    cleaned = re.sub(r"[\s\-\(\)]", "", phone.strip())
    if not re.match(r"^\+?[0-9]{7,15}$", cleaned):
        return "Invalid phone number format (must contain 7 to 15 digits)."
    return None


def validate_date(date_str: Optional[str], field_name: str = "Date") -> Tuple[Optional[date], Optional[str]]:
    """Parses and validates ISO YYYY-MM-DD date."""
    if not date_str or not date_str.strip():
        return None, f"{field_name} is required."
    try:
        dt = datetime.strptime(date_str.strip(), "%Y-%m-%d").date()
        return dt, None
    except ValueError:
        return None, f"{field_name} must follow YYYY-MM-DD format."


def validate_time(time_str: Optional[str], field_name: str = "Time") -> Tuple[Optional[time], Optional[str]]:
    """Parses and validates HH:MM or HH:MM:SS time."""
    if not time_str or not time_str.strip():
        return None, f"{field_name} is required."
    raw = time_str.strip()
    for fmt in ("%H:%M:%S", "%H:%M"):
        try:
            t = datetime.strptime(raw, fmt).time()
            return t, None
        except ValueError:
            pass
    return None, f"{field_name} must follow HH:MM (24-hour) format."


def validate_date_range(start_str: str, end_str: str, allow_equal: bool = True) -> Optional[str]:
    """Validates that end_date >= start_date (or strictly > if allow_equal=False)."""
    d_start, err1 = validate_date(start_str, "Start date")
    d_end, err2 = validate_date(end_str, "End date")
    if err1 or err2:
        return err1 or err2
    if d_start and d_end:
        if allow_equal and d_end < d_start:
            return "End date cannot be prior to start date."
        if not allow_equal and d_end <= d_start:
            return "End date must be strictly after start date."
    return None


def validate_time_range(start_time_str: str, end_time_str: str) -> Optional[str]:
    """Validates that end_time is strictly after start_time."""
    t_start, err1 = validate_time(start_time_str, "Start time")
    t_end, err2 = validate_time(end_time_str, "End time")
    if err1 or err2:
        return err1 or err2
    if t_start and t_end and t_end <= t_start:
        return "End time must be strictly later than start time."
    return None


def validate_positive_int(value: Any, field_name: str, min_val: int = 1) -> Tuple[Optional[int], Optional[str]]:
    """Validates integer and checks minimum threshold."""
    try:
        val = int(value)
        if val < min_val:
            return None, f"{field_name} must be at least {min_val}."
        return val, None
    except (ValueError, TypeError):
        return None, f"{field_name} must be a valid integer."


def validate_positive_decimal(value: Any, field_name: str, min_val: float = 0.0) -> Tuple[Optional[float], Optional[str]]:
    """Validates decimal number and checks minimum threshold."""
    try:
        val = float(value)
        if val < min_val:
            return None, f"{field_name} cannot be less than {min_val}."
        return val, None
    except (ValueError, TypeError):
        return None, f"{field_name} must be a valid number."


def validate_member_registration(data: Dict[str, Any]) -> List[str]:
    """Validates member registration input payload."""
    errors = validate_required(data, ["name", "phone", "email", "dob", "plan_id", "mode"])
    err = validate_email(data.get("email"))
    if err:
        errors.append(err)
    err = validate_phone(data.get("phone"))
    if err:
        errors.append(err)
    _, err = validate_date(data.get("dob"), "Date of birth")
    if err:
        errors.append(err)
    _, err = validate_positive_int(data.get("plan_id"), "Membership plan", min_val=1)
    if err:
        errors.append(err)
    valid_modes = {"Cash", "UPI", "Card", "Bank"}
    if data.get("mode") not in valid_modes:
        errors.append("Invalid payment mode selected.")
    return errors


def validate_training_session(data: Dict[str, Any]) -> List[str]:
    """Validates training session scheduling inputs."""
    errors = validate_required(data, ["team_id", "coach_id", "facility_id", "session_date", "start_time", "end_time", "max_attendees"])
    _, err = validate_date(data.get("session_date"), "Session date")
    if err:
        errors.append(err)
    err = validate_time_range(data.get("start_time", ""), data.get("end_time", ""))
    if err:
        errors.append(err)
    _, err = validate_positive_int(data.get("max_attendees"), "Max attendees", min_val=1)
    if err:
        errors.append(err)
    return errors


def validate_fixture(data: Dict[str, Any]) -> List[str]:
    """Validates match fixture creation payload."""
    errors = validate_required(data, ["tournament_id", "facility_id", "team1_id", "team2_id", "fixture_date", "start_time", "end_time"])
    if data.get("team1_id") and data.get("team2_id") and str(data.get("team1_id")) == str(data.get("team2_id")):
        errors.append("Competing teams must be distinct (Team 1 cannot equal Team 2).")
    _, err = validate_date(data.get("fixture_date"), "Fixture date")
    if err:
        errors.append(err)
    err = validate_time_range(data.get("start_time", ""), data.get("end_time", ""))
    if err:
        errors.append(err)
    return errors


def validate_result_entry(data: Dict[str, Any]) -> List[str]:
    """Validates scores submitted for completed matches."""
    errors = validate_required(data, ["fixture_id", "team1_score", "team2_score"])
    s1, err1 = validate_positive_int(data.get("team1_score"), "Team 1 score", min_val=0)
    s2, err2 = validate_positive_int(data.get("team2_score"), "Team 2 score", min_val=0)
    if err1:
        errors.append(err1)
    if err2:
        errors.append(err2)
    return errors


def validate_equipment_issue(data: Dict[str, Any]) -> List[str]:
    """Validates equipment issue payload."""
    errors = validate_required(data, ["member_id", "equipment_name", "quantity", "due_days"])
    _, err = validate_positive_int(data.get("quantity"), "Quantity", min_val=1)
    if err:
        errors.append(err)
    _, err = validate_positive_int(data.get("due_days"), "Due period (days)", min_val=1)
    if err:
        errors.append(err)
    return errors

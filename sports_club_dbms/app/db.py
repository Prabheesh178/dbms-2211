"""Database utility layer for Sports Club DBMS.
Provides connection management, parameterized query execution,
stored procedure invocation, and clean error sanitization.
"""

import os
import re
from typing import Any, Dict, List, Optional, Tuple
import mysql.connector
from mysql.connector import Error, pooling
from dotenv import load_dotenv

# Load environment configuration
load_dotenv()

DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
DB_PORT = int(os.getenv("DB_PORT", "3307"))
DB_USER = os.getenv("DB_USER", "sports_user")
DB_PASSWORD = os.getenv("DB_PASSWORD", "sports_pass")
DB_NAME = os.getenv("DB_NAME", "sports_club_db")

# Connection pool setup
_connection_pool: Optional[pooling.MySQLConnectionPool] = None


def get_db_config() -> Dict[str, Any]:
    """Returns database connection parameters dictionary."""
    return {
        "host": DB_HOST,
        "port": DB_PORT,
        "user": DB_USER,
        "password": DB_PASSWORD,
        "database": DB_NAME,
        "autocommit": False,
        "consume_results": True,
    }


def init_pool(pool_size: int = 5) -> pooling.MySQLConnectionPool:
    """Initializes or returns singleton connection pool."""
    global _connection_pool
    if _connection_pool is None:
        cfg = get_db_config()
        _connection_pool = pooling.MySQLConnectionPool(
            pool_name="sports_club_pool",
            pool_size=pool_size,
            pool_reset_session=True,
            **cfg,
        )
    return _connection_pool


def get_connection():
    """Acquires a database connection, fallback to direct connection if pool exhausted."""
    try:
        pool = init_pool()
        return pool.get_connection()
    except Exception:
        return mysql.connector.connect(**get_db_config())


def clean_db_error(e: Exception) -> str:
    """Extracts user-friendly error message from MySQL exceptions and triggers."""
    msg = str(e)
    # Check for SIGNAL SQLSTATE '45000' custom message
    match = re.search(r"\d+\s*\([A-Z0-9]+\):\s*(.*)", msg)
    if match:
        msg = match.group(1).strip()
    # Check for Duplicate entry
    if "Duplicate entry" in msg:
        dup_match = re.search(r"Duplicate entry '([^']+)' for key '([^']+)'", msg)
        if dup_match:
            return f"Duplicate entry '{dup_match.group(1)}': A record with this value already exists."
        return "Duplicate entry detected: Record already exists."
    # Check for foreign key violation
    if "foreign key constraint fails" in msg.lower():
        return "Invalid reference: Selected item does not exist or cannot be modified due to dependent records."
    # Check for check constraint violation
    if "check constraint" in msg.lower():
        chk_match = re.search(r"Check constraint '([^']+)' is violated", msg)
        if chk_match:
            return f"Data constraint error: Constraint '{chk_match.group(1)}' violated."
        return "Data integrity constraint violated."
    return msg


def query_all(sql: str, params: Optional[Tuple[Any, ...]] = None) -> List[Dict[str, Any]]:
    """Executes a SELECT query returning all matching rows as dictionaries."""
    conn = get_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(sql, params or ())
        rows = cursor.fetchall()
        cursor.close()
        return rows
    finally:
        conn.close()


def query_one(sql: str, params: Optional[Tuple[Any, ...]] = None) -> Optional[Dict[str, Any]]:
    """Executes a SELECT query returning a single row as dictionary, or None."""
    conn = get_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(sql, params or ())
        row = cursor.fetchone()
        cursor.close()
        return row
    finally:
        conn.close()


def execute_modify(sql: str, params: Optional[Tuple[Any, ...]] = None) -> int:
    """Executes an INSERT/UPDATE/DELETE query with transaction commit. Returns lastrowid or affected rows."""
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(sql, params or ())
        conn.commit()
        last_id = cursor.lastrowid
        row_count = cursor.rowcount
        cursor.close()
        return last_id if last_id > 0 else row_count
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def call_procedure(proc_name: str, args: Tuple[Any, ...]) -> Tuple[Any, ...]:
    """Calls a stored procedure with in/out arguments and returns the modified args tuple."""
    conn = get_connection()
    try:
        cursor = conn.cursor()
        res = cursor.callproc(proc_name, list(args))
        conn.commit()
        cursor.close()
        return res
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

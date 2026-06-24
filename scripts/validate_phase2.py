from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SQL_DIR = ROOT / "supabase" / "migrations"


def executable_sql() -> str:
    text = "\n".join(path.read_text(encoding="utf-8") for path in sorted(SQL_DIR.glob("*.sql")))
    text = re.sub(r"--[^\n]*", "", text)
    return re.sub(r"/\*.*?\*/", "", text, flags=re.S).lower()


def main() -> int:
    all_text = "\n".join(
        path.read_text(encoding="utf-8", errors="ignore")
        for path in ROOT.rglob("*")
        if path.is_file()
    ).lower()
    code = executable_sql()

    checks = {
        "required tables": all(
            f"public.{name}" in all_text
            for name in (
                "profiles",
                "tickets",
                "comments",
                "ticket_history",
                "notifications",
                "device_tokens",
                "app_settings",
                "ticket_attachments",
            )
        ),
        "canonical statuses": all(
            status in all_text
            for status in ("open", "pending", "in_progress", "resolved", "closed", "reopened")
        ),
        "required RPCs": all(
            rpc in all_text
            for rpc in (
                "assign_ticket",
                "update_ticket_status",
                "admin_override_ticket_status",
                "soft_delete_ticket",
                "restore_ticket",
                "admin_update_user_role",
                "admin_set_user_active",
                "register_device_token",
                "unregister_device_token",
                "register_ticket_attachment",
                "get_ticket_stats",
            )
        ),
        "no DROP TABLE": re.search(r"\bdrop\s+table\b", code) is None,
        "no DROP COLUMN": re.search(r"\bdrop\s+column\b", code) is None,
        "no TRUNCATE": re.search(r"\btruncate\b", code) is None,
        "private ticket bucket": "'tickets', 'tickets', false" in all_text,
        "notification owner policy": "notifications_select_own" in all_text,
        "storage owner policy": "ticket_objects_select_scope" in all_text,
        "inactive-user gate": "is_active_user" in all_text,
        "policy test": (ROOT / "supabase" / "tests" / "phase_2_policy_test.sql").exists(),
    }

    failed = [name for name, passed in checks.items() if not passed]
    for name, passed in checks.items():
        print(f"[{'PASS' if passed else 'FAIL'}] {name}")

    if failed:
        print("\nStatic validation failed: " + ", ".join(failed), file=sys.stderr)
        return 1

    print("\nStatic Phase 2 validation passed.")
    print("Runtime validation still requires Supabase CLI + Docker: supabase db reset && supabase test db")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

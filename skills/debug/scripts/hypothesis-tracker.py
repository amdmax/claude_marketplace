#!/usr/bin/env python3
"""
Hypothesis Tracker - State management for /debug skill

Manages debug session state in .claude/active-debug.json with deterministic operations.
Provides CLI interface for hypothesis tracking, evidence collection, and session management.

Usage:
    hypothesis-tracker.py init <issue-number> "<title>" [<url>]
    hypothesis-tracker.py status
    hypothesis-tracker.py archive
    hypothesis-tracker.py add-hypothesis "<desc>" "<type>" "<confidence>"
    hypothesis-tracker.py update-status <h-id> <status>
    hypothesis-tracker.py add-evidence <h-id> "<file>" <line> "<note>"
    hypothesis-tracker.py mark-confirmed <h-id>
    hypothesis-tracker.py get-next-hypothesis
    hypothesis-tracker.py set-fix "<files>" "<description>"
    hypothesis-tracker.py set-tests "<files>" "<description>" <count>
    hypothesis-tracker.py list-hypotheses [<status>]
"""

import json
import sys
from pathlib import Path
from datetime import datetime
from typing import Optional, Dict, Any, List

# Constants
STATE_FILE = Path(".claude/active-debug.json")
ARCHIVE_DIR = Path(".claude/debug-sessions")
VALID_HYPOTHESIS_TYPES = ["logic_error", "missing_validation", "race_condition", "configuration", "dependency"]
VALID_CONFIDENCES = ["high", "medium", "low"]
VALID_STATUSES = ["pending", "investigating", "confirmed", "rejected", "needs_info"]


def load_state() -> Optional[Dict[str, Any]]:
    """Load current debug session state."""
    if not STATE_FILE.exists():
        return None

    with open(STATE_FILE, 'r') as f:
        return json.load(f)


def save_state(state: Dict[str, Any]) -> None:
    """Save debug session state."""
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(STATE_FILE, 'w') as f:
        json.dump(state, f, indent=2)


def generate_session_id(issue_number: int) -> str:
    """Generate unique session ID."""
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    return f"debug-{issue_number}-{timestamp}"


def cmd_init(issue_number: str, title: str, url: str = "") -> int:
    """Initialize new debug session."""
    if STATE_FILE.exists():
        print("Error: Active debug session already exists", file=sys.stderr)
        print("Run 'hypothesis-tracker.py archive' first", file=sys.stderr)
        return 1

    try:
        issue_num = int(issue_number)
    except ValueError:
        print(f"Error: Invalid issue number '{issue_number}'", file=sys.stderr)
        return 1

    state = {
        "issueNumber": issue_num,
        "title": title,
        "url": url,
        "sessionId": generate_session_id(issue_num),
        "status": "investigating",
        "currentPhase": "hypothesis_generation",
        "hypotheses": [],
        "fix": None,
        "tests": None,
        "createdAt": datetime.now().isoformat(),
        "updatedAt": datetime.now().isoformat()
    }

    save_state(state)
    print(f"Initialized debug session for issue #{issue_num}")
    print(f"Session ID: {state['sessionId']}")
    return 0


def cmd_status() -> int:
    """Display current session status."""
    state = load_state()
    if not state:
        print("No active debug session")
        return 1

    print(f"Issue #{state['issueNumber']}: {state['title']}")
    print(f"Session: {state['sessionId']}")
    print(f"Phase: {state['currentPhase']}")
    print(f"Status: {state['status']}")
    print(f"\nHypotheses: {len(state['hypotheses'])}")

    for h in state['hypotheses']:
        status_icon = {
            'pending': '⏳',
            'investigating': '🔍',
            'confirmed': '✅',
            'rejected': '❌',
            'needs_info': '❓'
        }.get(h['status'], '?')

        print(f"  {status_icon} [{h['id']}] {h['description']}")
        print(f"      Type: {h['type']}, Confidence: {h['confidence']}")
        if h['evidence']:
            print(f"      Evidence: {len(h['evidence'])} item(s)")

    if state['fix']:
        print(f"\nFix: {state['fix']['description']}")
        print(f"     Files: {state['fix']['files']}")

    if state['tests']:
        print(f"\nTests: {state['tests']['description']}")
        print(f"       Files: {state['tests']['files']}")
        print(f"       Count: {state['tests']['count']}")
        print(f"       Validated: {state['tests'].get('validated', False)}")

    return 0


def cmd_archive() -> int:
    """Archive current session."""
    state = load_state()
    if not state:
        print("No active debug session to archive")
        return 1

    ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)
    archive_file = ARCHIVE_DIR / f"{state['sessionId']}.json"

    state['archivedAt'] = datetime.now().isoformat()

    with open(archive_file, 'w') as f:
        json.dump(state, f, indent=2)

    STATE_FILE.unlink()

    print(f"Archived session to {archive_file}")
    return 0


def cmd_add_hypothesis(description: str, hyp_type: str, confidence: str) -> int:
    """Add new hypothesis."""
    state = load_state()
    if not state:
        print("Error: No active debug session", file=sys.stderr)
        return 1

    if hyp_type not in VALID_HYPOTHESIS_TYPES:
        print(f"Error: Invalid type '{hyp_type}'", file=sys.stderr)
        print(f"Valid types: {', '.join(VALID_HYPOTHESIS_TYPES)}", file=sys.stderr)
        return 1

    if confidence not in VALID_CONFIDENCES:
        print(f"Error: Invalid confidence '{confidence}'", file=sys.stderr)
        print(f"Valid confidences: {', '.join(VALID_CONFIDENCES)}", file=sys.stderr)
        return 1

    # Generate new hypothesis ID
    existing_ids = [h['id'] for h in state['hypotheses']]
    h_num = 1
    while f"h{h_num}" in existing_ids:
        h_num += 1
    h_id = f"h{h_num}"

    hypothesis = {
        "id": h_id,
        "description": description,
        "type": hyp_type,
        "confidence": confidence,
        "status": "pending",
        "evidence": [],
        "researchNotes": "",
        "createdAt": datetime.now().isoformat()
    }

    state['hypotheses'].append(hypothesis)
    state['updatedAt'] = datetime.now().isoformat()
    save_state(state)

    print(f"Added hypothesis {h_id}: {description}")
    return 0


def cmd_update_status(h_id: str, status: str) -> int:
    """Update hypothesis status."""
    state = load_state()
    if not state:
        print("Error: No active debug session", file=sys.stderr)
        return 1

    if status not in VALID_STATUSES:
        print(f"Error: Invalid status '{status}'", file=sys.stderr)
        print(f"Valid statuses: {', '.join(VALID_STATUSES)}", file=sys.stderr)
        return 1

    hypothesis = next((h for h in state['hypotheses'] if h['id'] == h_id), None)
    if not hypothesis:
        print(f"Error: Hypothesis '{h_id}' not found", file=sys.stderr)
        return 1

    hypothesis['status'] = status
    hypothesis['updatedAt'] = datetime.now().isoformat()
    state['updatedAt'] = datetime.now().isoformat()
    save_state(state)

    print(f"Updated {h_id} status to '{status}'")
    return 0


def cmd_add_evidence(h_id: str, file_path: str, line: str, note: str) -> int:
    """Add evidence to hypothesis."""
    state = load_state()
    if not state:
        print("Error: No active debug session", file=sys.stderr)
        return 1

    hypothesis = next((h for h in state['hypotheses'] if h['id'] == h_id), None)
    if not hypothesis:
        print(f"Error: Hypothesis '{h_id}' not found", file=sys.stderr)
        return 1

    try:
        line_num = int(line)
    except ValueError:
        print(f"Error: Invalid line number '{line}'", file=sys.stderr)
        return 1

    evidence = {
        "file": file_path,
        "line": line_num,
        "note": note,
        "timestamp": datetime.now().isoformat()
    }

    hypothesis['evidence'].append(evidence)
    hypothesis['updatedAt'] = datetime.now().isoformat()
    state['updatedAt'] = datetime.now().isoformat()
    save_state(state)

    print(f"Added evidence to {h_id}: {file_path}:{line_num}")
    return 0


def cmd_mark_confirmed(h_id: str) -> int:
    """Mark hypothesis as confirmed and reject others."""
    state = load_state()
    if not state:
        print("Error: No active debug session", file=sys.stderr)
        return 1

    hypothesis = next((h for h in state['hypotheses'] if h['id'] == h_id), None)
    if not hypothesis:
        print(f"Error: Hypothesis '{h_id}' not found", file=sys.stderr)
        return 1

    # Mark this hypothesis as confirmed
    hypothesis['status'] = 'confirmed'
    hypothesis['confirmedAt'] = datetime.now().isoformat()

    # Mark all other non-confirmed hypotheses as rejected
    for h in state['hypotheses']:
        if h['id'] != h_id and h['status'] not in ['confirmed', 'rejected']:
            h['status'] = 'rejected'
            h['rejectedAt'] = datetime.now().isoformat()

    state['currentPhase'] = 'fix_implementation'
    state['updatedAt'] = datetime.now().isoformat()
    save_state(state)

    print(f"Confirmed {h_id}, rejected others")
    print(f"Phase updated to: fix_implementation")
    return 0


def cmd_get_next_hypothesis() -> int:
    """Get next hypothesis to investigate (highest confidence pending)."""
    state = load_state()
    if not state:
        print("Error: No active debug session", file=sys.stderr)
        return 1

    # Get pending hypotheses sorted by confidence
    confidence_order = {"high": 3, "medium": 2, "low": 1}
    pending = [h for h in state['hypotheses'] if h['status'] == 'pending']

    if not pending:
        print("No pending hypotheses")
        return 1

    next_hyp = max(pending, key=lambda h: confidence_order.get(h['confidence'], 0))

    print(json.dumps({
        "id": next_hyp['id'],
        "description": next_hyp['description'],
        "type": next_hyp['type'],
        "confidence": next_hyp['confidence']
    }))

    return 0


def cmd_set_fix(files: str, description: str) -> int:
    """Record fix implementation."""
    state = load_state()
    if not state:
        print("Error: No active debug session", file=sys.stderr)
        return 1

    state['fix'] = {
        "files": files,
        "description": description,
        "implementedAt": datetime.now().isoformat()
    }

    state['currentPhase'] = 'test_generation'
    state['updatedAt'] = datetime.now().isoformat()
    save_state(state)

    print(f"Recorded fix: {description}")
    print(f"Phase updated to: test_generation")
    return 0


def cmd_set_tests(files: str, description: str, count: str) -> int:
    """Record test implementation."""
    state = load_state()
    if not state:
        print("Error: No active debug session", file=sys.stderr)
        return 1

    try:
        test_count = int(count)
    except ValueError:
        print(f"Error: Invalid test count '{count}'", file=sys.stderr)
        return 1

    state['tests'] = {
        "files": files,
        "description": description,
        "count": test_count,
        "validated": False,
        "createdAt": datetime.now().isoformat()
    }

    state['updatedAt'] = datetime.now().isoformat()
    save_state(state)

    print(f"Recorded tests: {description}")
    print(f"Test count: {test_count}")
    print("⚠️  Tests not yet validated - run validation process")
    return 0


def cmd_mark_tests_validated() -> int:
    """Mark tests as validated (fail-before/pass-after)."""
    state = load_state()
    if not state:
        print("Error: No active debug session", file=sys.stderr)
        return 1

    if not state.get('tests'):
        print("Error: No tests recorded yet", file=sys.stderr)
        return 1

    state['tests']['validated'] = True
    state['tests']['validatedAt'] = datetime.now().isoformat()
    state['currentPhase'] = 'commit_and_pr'
    state['status'] = 'fixed'
    state['updatedAt'] = datetime.now().isoformat()
    save_state(state)

    print("✅ Tests validated successfully")
    print(f"Phase updated to: commit_and_pr")
    return 0


def cmd_list_hypotheses(status_filter: Optional[str] = None) -> int:
    """List hypotheses with optional status filter."""
    state = load_state()
    if not state:
        print("Error: No active debug session", file=sys.stderr)
        return 1

    hypotheses = state['hypotheses']

    if status_filter:
        if status_filter not in VALID_STATUSES:
            print(f"Error: Invalid status filter '{status_filter}'", file=sys.stderr)
            print(f"Valid statuses: {', '.join(VALID_STATUSES)}", file=sys.stderr)
            return 1
        hypotheses = [h for h in hypotheses if h['status'] == status_filter]

    if not hypotheses:
        print(f"No hypotheses{' with status ' + status_filter if status_filter else ''}")
        return 0

    result = []
    for h in hypotheses:
        result.append({
            "id": h['id'],
            "description": h['description'],
            "type": h['type'],
            "confidence": h['confidence'],
            "status": h['status'],
            "evidenceCount": len(h['evidence'])
        })

    print(json.dumps(result, indent=2))
    return 0


def main():
    """Main CLI entry point."""
    if len(sys.argv) < 2:
        print(__doc__)
        return 1

    command = sys.argv[1]

    try:
        if command == "init":
            if len(sys.argv) < 4:
                print("Usage: hypothesis-tracker.py init <issue-number> \"<title>\" [<url>]", file=sys.stderr)
                return 1
            issue_number = sys.argv[2]
            title = sys.argv[3]
            url = sys.argv[4] if len(sys.argv) > 4 else ""
            return cmd_init(issue_number, title, url)

        elif command == "status":
            return cmd_status()

        elif command == "archive":
            return cmd_archive()

        elif command == "add-hypothesis":
            if len(sys.argv) != 5:
                print("Usage: hypothesis-tracker.py add-hypothesis \"<desc>\" \"<type>\" \"<confidence>\"", file=sys.stderr)
                return 1
            return cmd_add_hypothesis(sys.argv[2], sys.argv[3], sys.argv[4])

        elif command == "update-status":
            if len(sys.argv) != 4:
                print("Usage: hypothesis-tracker.py update-status <h-id> <status>", file=sys.stderr)
                return 1
            return cmd_update_status(sys.argv[2], sys.argv[3])

        elif command == "add-evidence":
            if len(sys.argv) != 6:
                print("Usage: hypothesis-tracker.py add-evidence <h-id> \"<file>\" <line> \"<note>\"", file=sys.stderr)
                return 1
            return cmd_add_evidence(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])

        elif command == "mark-confirmed":
            if len(sys.argv) != 3:
                print("Usage: hypothesis-tracker.py mark-confirmed <h-id>", file=sys.stderr)
                return 1
            return cmd_mark_confirmed(sys.argv[2])

        elif command == "get-next-hypothesis":
            return cmd_get_next_hypothesis()

        elif command == "set-fix":
            if len(sys.argv) != 4:
                print("Usage: hypothesis-tracker.py set-fix \"<files>\" \"<description>\"", file=sys.stderr)
                return 1
            return cmd_set_fix(sys.argv[2], sys.argv[3])

        elif command == "set-tests":
            if len(sys.argv) != 5:
                print("Usage: hypothesis-tracker.py set-tests \"<files>\" \"<description>\" <count>", file=sys.stderr)
                return 1
            return cmd_set_tests(sys.argv[2], sys.argv[3], sys.argv[4])

        elif command == "mark-tests-validated":
            return cmd_mark_tests_validated()

        elif command == "list-hypotheses":
            status_filter = sys.argv[2] if len(sys.argv) > 2 else None
            return cmd_list_hypotheses(status_filter)

        else:
            print(f"Error: Unknown command '{command}'", file=sys.stderr)
            print(__doc__)
            return 1

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())

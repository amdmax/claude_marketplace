#!/usr/bin/env python3
"""
Remote Jupyter kernel execution tool.

Executes Python code on a Jupyter kernel via REST API + WebSocket.
When JUPYTER_SSH_HOST is set, opens an SSH tunnel automatically.
When JUPYTER_SSH_HOST is empty or unset, connects to a local Jupyter server.

CLI usage:
    python scripts/jupyter_remote.py "import torch; print(torch.cuda.get_device_name(0))"
    python scripts/jupyter_remote.py --list-kernels
    python scripts/jupyter_remote.py --kernel-id <id> "code..."
    python scripts/jupyter_remote.py --timeout 120 "long_running_code()"
    cat script.py | python scripts/jupyter_remote.py -

Config (env vars with defaults):
    JUPYTER_TOKEN    → aigensa
    JUPYTER_HOST     → localhost
    JUPYTER_PORT     → 8888
    JUPYTER_SSH_HOST → (unset = local mode; set to e.g. cuda-dev for remote)
"""

import json
import os
import sys
import time
import uuid
from typing import Optional
import urllib.request
import urllib.error

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ssh_tunnel import ensure_tunnel, is_reachable


# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

TOKEN = os.environ.get("JUPYTER_TOKEN", "aigensa")
HOST = os.environ.get("JUPYTER_HOST", "localhost")
PORT = int(os.environ.get("JUPYTER_PORT", "8888"))
SSH_HOST: Optional[str] = os.environ.get("JUPYTER_SSH_HOST") or None

BASE_URL = f"http://{HOST}:{PORT}"
BASE_WS = f"ws://{HOST}:{PORT}"


# ---------------------------------------------------------------------------
# Kernel management
# ---------------------------------------------------------------------------

def _api_get(path: str) -> object:
    req = urllib.request.Request(
        f"{BASE_URL}{path}",
        headers={"Authorization": f"token {TOKEN}"},
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


def _api_post(path: str, body: dict) -> object:
    data = json.dumps(body).encode()
    req = urllib.request.Request(
        f"{BASE_URL}{path}",
        data=data,
        headers={
            "Authorization": f"token {TOKEN}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


def list_kernels() -> list:
    """Return the list of kernel dicts from /api/kernels."""
    return _api_get("/api/kernels")


def get_or_create_kernel(kernel_id: Optional[str] = None) -> str:
    """
    Return a kernel ID to use.

    Priority:
    1. Explicit --kernel-id argument
    2. First kernel in 'busy' or 'idle' state
    3. Create a new python3 kernel
    """
    if kernel_id:
        return kernel_id

    kernels = list_kernels()
    if kernels:
        # Prefer an already-running kernel
        for k in kernels:
            if k.get("execution_state") in ("idle", "busy"):
                return k["id"]
        return kernels[0]["id"]

    # No kernels — start one
    print("[kernel] No running kernels found — starting a new python3 kernel...",
          file=sys.stderr)
    result = _api_post("/api/kernels", {"name": "python3"})
    kid = result["id"]
    print(f"[kernel] Started kernel {kid}", file=sys.stderr)
    return kid


# ---------------------------------------------------------------------------
# WebSocket execution
# ---------------------------------------------------------------------------

def execute(code: str, kernel_id: str, timeout: float = 60) -> dict:
    """
    Execute *code* on the given kernel via WebSocket.

    Returns a dict:
        {
            "stdout": str,
            "stderr": str,
            "result": str | None,   # execute_result text/plain
            "error":  str | None,   # formatted traceback
            "displays": [str],      # display_data text/plain values
        }
    """
    try:
        import websocket  # websocket-client
    except ImportError:
        raise ImportError(
            "websocket-client is required: pip install websocket-client"
        )

    msg_id = str(uuid.uuid4())
    session_id = str(uuid.uuid4())

    execute_request = {
        "header": {
            "msg_id": msg_id,
            "username": "claude",
            "session": session_id,
            "msg_type": "execute_request",
            "version": "5.3",
        },
        "parent_header": {},
        "metadata": {},
        "content": {
            "code": code,
            "silent": False,
            "store_history": True,
            "user_expressions": {},
            "allow_stdin": False,
        },
        "buffers": [],
    }

    ws_url = f"{BASE_WS}/api/kernels/{kernel_id}/channels?token={TOKEN}"
    ws = websocket.create_connection(ws_url, timeout=timeout)

    output = {
        "stdout": "",
        "stderr": "",
        "result": None,
        "error": None,
        "displays": [],
    }

    try:
        ws.send(json.dumps(execute_request))

        got_reply = False
        got_idle = False
        deadline = time.monotonic() + timeout

        while not (got_reply and got_idle):
            if time.monotonic() > deadline:
                raise TimeoutError(
                    f"Kernel did not finish within {timeout} s. "
                    "Use --timeout to increase the limit."
                )

            raw = ws.recv()
            msg = json.loads(raw)
            mtype = msg.get("header", {}).get("msg_type", "")
            parent_id = msg.get("parent_header", {}).get("msg_id", "")
            content = msg.get("content", {})

            if mtype == "stream" and parent_id == msg_id:
                text = content.get("text", "")
                if content.get("name") == "stderr":
                    output["stderr"] += text
                else:
                    output["stdout"] += text

            elif mtype == "execute_result" and parent_id == msg_id:
                output["result"] = content.get("data", {}).get("text/plain", "")

            elif mtype == "display_data" and parent_id == msg_id:
                val = content.get("data", {}).get("text/plain", "")
                if val:
                    output["displays"].append(val)

            elif mtype == "error" and parent_id == msg_id:
                ename = content.get("ename", "Error")
                evalue = content.get("evalue", "")
                tb = content.get("traceback", [])
                # Strip ANSI escape codes for clean output
                import re
                ansi_escape = re.compile(r"\x1b\[[0-9;]*m")
                clean_tb = [ansi_escape.sub("", line) for line in tb]
                output["error"] = f"{ename}: {evalue}\n" + "\n".join(clean_tb)

            elif mtype == "execute_reply" and parent_id == msg_id:
                got_reply = True

            elif mtype == "status" and parent_id == msg_id:
                if content.get("execution_state") == "idle":
                    got_idle = True

    finally:
        ws.close()

    return output


# ---------------------------------------------------------------------------
# Formatting
# ---------------------------------------------------------------------------

def format_output(out: dict) -> str:
    """Format an execute() result dict into a human-readable string."""
    parts = []

    if out["stdout"]:
        parts.append(out["stdout"].rstrip())

    if out["displays"]:
        parts.extend(d.rstrip() for d in out["displays"])

    if out["result"] is not None:
        parts.append(out["result"].rstrip())

    if out["stderr"]:
        parts.append("--- stderr ---")
        parts.append(out["stderr"].rstrip())

    if out["error"]:
        parts.append("--- error ---")
        parts.append(out["error"].rstrip())

    return "\n".join(parts)


# ---------------------------------------------------------------------------
# Notebook execution
# ---------------------------------------------------------------------------

def read_notebook(path: str) -> list:
    """
    Fetch a notebook from the Jupyter server via the contents API.
    *path* is relative to the Jupyter root (e.g. 'notebooks/foo.ipynb').
    Returns a list of dicts: [{"id": cell_id, "source": "..."}] for code cells.
    """
    import urllib.parse
    encoded = urllib.parse.quote(path, safe="/")
    nb = _api_get(f"/api/contents/{encoded}")
    cells = []
    for cell in nb["content"]["cells"]:
        if cell["cell_type"] != "code":
            continue
        source = "".join(cell["source"])
        if not source.strip():
            continue
        cells.append({
            "id": cell.get("id", ""),
            "source": source,
        })
    return cells


def run_notebook(
    path: str,
    kernel_id: Optional[str] = None,
    timeout: float = 300,
    stop_on_error: bool = True,
    start_cell: Optional[str] = None,
    stop_cell: Optional[str] = None,
) -> None:
    """
    Execute all code cells in a notebook on the remote kernel, printing output
    as each cell completes.

    *path*       — notebook path relative to Jupyter root
    *start_cell* — cell id to start from (skip earlier cells)
    *stop_cell*  — cell id to stop BEFORE (exclusive)
    """
    cells = read_notebook(path)
    kernel_id = get_or_create_kernel(kernel_id)

    skipping = start_cell is not None
    errors = 0

    for i, cell in enumerate(cells, 1):
        if skipping:
            if cell["id"] == start_cell:
                skipping = False
            else:
                continue

        if stop_cell and cell["id"] == stop_cell:
            print(f"\n[stopped before cell {stop_cell}]")
            break

        preview = cell["source"].split("\n")[0][:60]
        print(f"\n{'─'*60}")
        print(f"Cell {i}/{len(cells)}  [{cell['id']}]  {preview}")
        print('─'*60)

        out = execute(cell["source"], kernel_id, timeout=timeout)
        result_str = format_output(out)
        if result_str:
            print(result_str)

        if out["error"]:
            errors += 1
            if stop_on_error:
                print(f"\n[stopped after error in cell {cell['id']}]", file=sys.stderr)
                sys.exit(1)

    print(f"\n{'='*60}")
    print(f"Notebook complete. {len(cells)} cells run, {errors} error(s).")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(
        description="Execute Python code on a remote Jupyter kernel.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "code",
        nargs="?",
        help="Python code to execute (use '-' to read from stdin)",
    )
    parser.add_argument(
        "--list-kernels",
        action="store_true",
        help="List running kernels and exit",
    )
    parser.add_argument(
        "--run-notebook",
        metavar="PATH",
        help="Run all code cells in a notebook (path relative to Jupyter root)",
    )
    parser.add_argument(
        "--start-cell",
        metavar="CELL_ID",
        help="When using --run-notebook, skip cells before this cell id",
    )
    parser.add_argument(
        "--stop-cell",
        metavar="CELL_ID",
        help="When using --run-notebook, stop BEFORE this cell id (exclusive)",
    )
    parser.add_argument(
        "--no-stop-on-error",
        action="store_true",
        help="When using --run-notebook, continue past errors",
    )
    parser.add_argument(
        "--kernel-id",
        metavar="ID",
        help="Use this specific kernel ID",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=60,
        metavar="SECONDS",
        help="Execution timeout in seconds (default: 60)",
    )
    parser.add_argument(
        "--no-tunnel",
        action="store_true",
        help="Skip tunnel setup (assume port is already reachable)",
    )

    args = parser.parse_args()

    # Ensure connectivity
    if not args.no_tunnel:
        if SSH_HOST:
            ensure_tunnel(ssh_host=SSH_HOST, local_port=PORT, token=TOKEN)
        else:
            if not is_reachable(host=HOST, port=PORT, token=TOKEN):
                raise SystemExit(
                    f"[jupyter] Cannot reach Jupyter at {HOST}:{PORT}. "
                    "Start JupyterLab locally or set JUPYTER_SSH_HOST to use a remote box."
                )

    if args.list_kernels:
        kernels = list_kernels()
        if not kernels:
            print("No kernels running.")
        else:
            print(f"{'ID':<40}  {'Name':<20}  State")
            print("-" * 72)
            for k in kernels:
                print(
                    f"{k['id']:<40}  {k.get('name','?'):<20}  "
                    f"{k.get('execution_state','?')}"
                )
        return

    if args.run_notebook:
        run_notebook(
            args.run_notebook,
            kernel_id=args.kernel_id,
            timeout=args.timeout,
            stop_on_error=not args.no_stop_on_error,
            start_cell=args.start_cell,
            stop_cell=args.stop_cell,
        )
        return

    # Resolve code
    if args.code is None:
        parser.error("Provide code as an argument, use '-' to read from stdin, or use --run-notebook.")

    if args.code == "-":
        code = sys.stdin.read()
    else:
        code = args.code

    kernel_id = get_or_create_kernel(args.kernel_id)
    out = execute(code, kernel_id, timeout=args.timeout)
    result_str = format_output(out)

    if result_str:
        print(result_str)

    # Exit with non-zero status on kernel error
    if out["error"]:
        sys.exit(1)


if __name__ == "__main__":
    main()

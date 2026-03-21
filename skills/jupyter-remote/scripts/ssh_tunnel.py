"""
SSH tunnel utility for remote Jupyter (and other) services.

This module is SSH-transport-only — no Jupyter-specific logic.
All configuration is passed as explicit parameters; env-var defaults
are exposed as module-level constants for convenience.

Env vars:
    JUPYTER_SSH_HOST  — default remote host (empty/unset = local mode)
"""

import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from typing import Optional


# ---------------------------------------------------------------------------
# Module-level defaults (read env at import time)
# ---------------------------------------------------------------------------

DEFAULT_SSH_HOST: Optional[str] = os.environ.get("JUPYTER_SSH_HOST") or None


# ---------------------------------------------------------------------------
# Connectivity probe
# ---------------------------------------------------------------------------

def is_reachable(host: str, port: int, token: str, timeout: float = 3.0) -> bool:
    """HTTP probe to http://<host>:<port>/api. Returns False on any error."""
    try:
        req = urllib.request.Request(
            f"http://{host}:{port}/api",
            headers={"Authorization": f"token {token}"},
        )
        with urllib.request.urlopen(req, timeout=timeout):
            return True
    except Exception:
        return False


# ---------------------------------------------------------------------------
# Tunnel management
# ---------------------------------------------------------------------------

def open_tunnel(
    ssh_host: str,
    local_port: int,
    remote_port: int,
    remote_host: str = "localhost",
    wait_seconds: float = 10.0,
    check_host: str = "localhost",
    check_token: str = "",
) -> None:
    """Run `ssh -L <local_port>:<remote_host>:<remote_port> <ssh_host> -fN`.

    Polls is_reachable() for up to wait_seconds. Raises RuntimeError on timeout.
    Idempotent — returns immediately if port is already reachable.
    """
    if is_reachable(host=check_host, port=local_port, token=check_token):
        return

    print(
        f"[tunnel] {check_host}:{local_port} unreachable — opening SSH tunnel to {ssh_host}...",
        file=sys.stderr,
    )
    subprocess.Popen(
        ["ssh", "-L", f"{local_port}:{remote_host}:{remote_port}", ssh_host, "-fN"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    deadline = time.monotonic() + wait_seconds
    while time.monotonic() < deadline:
        time.sleep(0.5)
        if is_reachable(host=check_host, port=local_port, token=check_token):
            print("[tunnel] tunnel up.", file=sys.stderr)
            return

    raise RuntimeError(
        f"SSH tunnel to {ssh_host} did not come up within {wait_seconds:.0f} s. "
        "Check that the host is reachable and the remote service is running."
    )


def ensure_tunnel(
    ssh_host: str,
    local_port: int,
    token: str,
    remote_port: Optional[int] = None,
    wait_seconds: float = 10.0,
) -> None:
    """Convenience wrapper: open tunnel if not already reachable.

    remote_port defaults to local_port.
    """
    open_tunnel(
        ssh_host=ssh_host,
        local_port=local_port,
        remote_port=remote_port if remote_port is not None else local_port,
        wait_seconds=wait_seconds,
        check_host="localhost",
        check_token=token,
    )

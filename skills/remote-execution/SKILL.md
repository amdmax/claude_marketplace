---
name: remote-execution
description: Routing pattern for SSH-dispatched compute. Use as a reference skill when building tools that need to run code either on a remote box (via SSH tunnel) or locally.
user-invocable: false
---

# remote-execution

Behavioral contract for any skill that routes compute to either a remote host (via SSH tunnel) or a local service.

## Routing Rule

| `*_SSH_HOST` env var | Mode |
|---|---|
| Set (e.g. `cuda-dev`) | **Remote** — open SSH tunnel, then connect |
| Unset or empty | **Local** — probe once, fail immediately if unreachable |

The env var name follows the `*_SSH_HOST` suffix convention (e.g. `JUPYTER_SSH_HOST`).

## Remote Mode

1. Call `scripts/ssh_tunnel.py` `ensure_tunnel(ssh_host, local_port, token)`.
2. `ensure_tunnel` is idempotent — safe to call on every invocation.
3. Tunnel maps `localhost:<local_port>` → `<ssh_host>:<remote_port>`.

## Local Mode

1. Probe once with `is_reachable(host, port, token)`.
2. If not reachable, exit immediately with the error message template below.
3. **Never auto-start** the local service — that is the user's responsibility.

## Error Message Template

```
Cannot reach <service> at <host>:<port>.
Start <service> locally or set <ENV_VAR> to use a remote box.
```

Example:
```
[jupyter] Cannot reach Jupyter at localhost:8888.
Start JupyterLab locally or set JUPYTER_SSH_HOST to use a remote box.
```

## Composing This Pattern

Skills that follow this pattern should:
1. Document their own `*_SSH_HOST` env var in their SKILL.md.
2. Add `metadata.requires-skill: remote-execution` as a documentation signal.
3. Import from `scripts/ssh_tunnel.py` for the actual tunnel logic — do not duplicate it.
4. Default the env var to `None` (not a hardcoded hostname) so local mode works out of the box.

## Implementation Reference

```python
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ssh_tunnel import ensure_tunnel, is_reachable

SSH_HOST = os.environ.get("MY_SSH_HOST") or None

if not args.no_tunnel:
    if SSH_HOST:
        ensure_tunnel(ssh_host=SSH_HOST, local_port=PORT, token=TOKEN)
    else:
        if not is_reachable(host=HOST, port=PORT, token=TOKEN):
            raise SystemExit(
                f"Cannot reach <service> at {HOST}:{PORT}. "
                "Start <service> locally or set MY_SSH_HOST to use a remote box."
            )
```

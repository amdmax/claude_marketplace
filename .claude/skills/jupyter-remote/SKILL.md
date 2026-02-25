---
name: jupyter-remote
description: "Run Python code and notebooks on a Jupyter kernel, remote or local. Use when running GPU-intensive or training code on a remote box, or when running experiments locally via Jupyter."
user-invocable: true
hooks:
  PostToolUse:
    - matcher: "Write"
      hooks:
        - type: command
          command: "bash ~/.claude/hooks/ruff-format-remote.sh"
metadata:
  author: aigensa
  version: "2.0.0"
  requires-skill: remote-execution
---

# jupyter-remote

Executes Python code on a Jupyter kernel via `scripts/jupyter_remote.py`.

## Routing

Routing is controlled by the `JUPYTER_SSH_HOST` env var (see `remote-execution` skill):

| `JUPYTER_SSH_HOST` | Behavior |
|---|---|
| Set (e.g. `cuda-dev`) | SSH tunnel opened automatically; runs on remote box |
| Unset or empty | Connects to local Jupyter server; fails immediately if not running |

Set `JUPYTER_SSH_HOST` in `.claude/settings.local.json` to use a remote GPU box.

## Usage

```bash
# Run inline code
python scripts/jupyter_remote.py "<python code>"

# Run a notebook end-to-end
python scripts/jupyter_remote.py --run-notebook notebooks/train.ipynb --timeout 300

# List active kernels
python scripts/jupyter_remote.py --list-kernels

# Resume a specific kernel
python scripts/jupyter_remote.py --kernel-id <id> "<code>"

# Set timeout (default 60s)
python scripts/jupyter_remote.py --timeout 300 "<code>"

# Read code from stdin
cat train.py | python scripts/jupyter_remote.py -
```

## Flags

| Flag | Purpose |
|------|---------|
| `code` | Positional. Inline Python string to execute. |
| `--run-notebook PATH` | Run a local `.ipynb` file cell by cell. |
| `--list-kernels` | Print all running kernels and exit. |
| `--kernel-id ID` | Use a specific kernel instead of the default. |
| `--timeout SECONDS` | Max wait for execution (default 60). |
| `--start-cell CELL_ID` | Start execution from this cell (skip earlier cells). |
| `--stop-cell CELL_ID` | Stop BEFORE this cell id (exclusive). |
| `--no-stop-on-error` | Continue running cells after an error. |
| `--no-tunnel` | Skip connectivity check entirely (port already reachable). |

## Notes

- Token defaults to `aigensa` (`JUPYTER_TOKEN` env var overrides it).
- `JUPYTER_HOST` defaults to `localhost`, `JUPYTER_PORT` to `8888`.
- `websocket-client` must be installed: `pip install websocket-client`.
- Local mode probes once and fails immediately if Jupyter is not running — it does not auto-start it.

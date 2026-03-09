#!/bin/bash
#
# Check if actionlint is installed and provide installation instructions
#
# Exit codes:
#   0 - actionlint is installed
#   1 - actionlint is not installed

set -euo pipefail

# Check if actionlint is in PATH
if command -v actionlint >/dev/null 2>&1; then
  exit 0
fi

# actionlint not found - print installation instructions
cat >&2 <<'EOF'
⚠️  actionlint not found

GitHub Actions workflow validation requires actionlint.

Installation:
  macOS:     brew install actionlint
  Linux:     Download from https://github.com/rhysd/actionlint/releases

After installation, workflow validation will run automatically.
EOF

exit 1

#!/bin/bash
set -euo pipefail

# Validate all skills in .claude/skills/
# Runs from Stop hook or manually

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${CLAUDE_PROJECT_DIR}/.claude/skills"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Validating skills...${NC}"

TOTAL=0
VALID=0
INVALID=0
SKIPPED=0

# Find all SKILL.md files
while IFS= read -r SKILL_FILE; do
  ((TOTAL++))

  # Skip validation skill itself and documentation files
  if [[ "$SKILL_FILE" =~ claude:validate-skills ]] || \
     [[ "$SKILL_FILE" =~ /references/ ]] || \
     [[ "$SKILL_FILE" =~ ^[A-Z] ]]; then
    ((SKIPPED++))
    continue
  fi

  # Run validation
  if bash "$SCRIPT_DIR/validate-skill.sh" "$SKILL_FILE" 2>&1; then
    ((VALID++))
  else
    ((INVALID++))
  fi
done < <(find "$SKILLS_DIR" -name "SKILL.md" -type f)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Validation Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total files:    $TOTAL"
echo -e "${GREEN}Valid:${NC}          $VALID"
if [[ $INVALID -gt 0 ]]; then
  echo -e "${RED}Invalid:${NC}        $INVALID"
fi
if [[ $SKIPPED -gt 0 ]]; then
  echo -e "${YELLOW}Skipped:${NC}        $SKIPPED"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $INVALID -gt 0 ]]; then
  echo -e "${RED}✗ Skill validation failed${NC}"
  exit 1
else
  echo -e "${GREEN}✓ All skills valid${NC}"
  exit 0
fi

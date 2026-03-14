#!/bin/bash
# GitHub Issue Creation Script with Validation
#
# Creates GitHub issues with quality validation and error handling
#
# Usage:
#   ./create_issue.sh <title> <body> [labels] [assignees]
#
# Input:
#   $1: Issue title (required)
#   $2: Issue body (required)
#   $3: Comma-separated labels (optional)
#   $4: Comma-separated assignees (optional)
#
# Environment Variables:
#   REPO_SLUG: GitHub repository (e.g., "owner/repo")
#              If not set, uses current repo from git config
#
# Exit Codes:
#   0 - Success
#   1 - Validation error (missing required fields)
#   2 - Authentication error (gh not authenticated)
#   3 - GitHub API error
#   4 - Configuration error (no repo found)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Input parameters
TITLE="${1:-}"
BODY="${2:-}"
LABELS="${3:-}"
ASSIGNEES="${4:-}"

# ============================================================================
# Validation Functions
# ============================================================================

validate_required_fields() {
    local errors=0

    if [[ -z "$TITLE" ]]; then
        echo -e "${RED}❌ Error: Issue title is required${NC}" >&2
        errors=$((errors + 1))
    fi

    if [[ -z "$BODY" ]]; then
        echo -e "${RED}❌ Error: Issue body is required${NC}" >&2
        errors=$((errors + 1))
    fi

    return $errors
}

validate_title_quality() {
    local title="$1"
    local warnings=0

    # Check title length (too short or too long)
    local title_length=${#title}
    if [[ $title_length -lt 10 ]]; then
        echo -e "${YELLOW}⚠️  Warning: Title is very short ($title_length chars). Consider adding more context.${NC}" >&2
        warnings=$((warnings + 1))
    fi

    if [[ $title_length -gt 100 ]]; then
        echo -e "${YELLOW}⚠️  Warning: Title is long ($title_length chars). Consider shortening.${NC}" >&2
        warnings=$((warnings + 1))
    fi

    # Check for vague words
    if echo "$title" | grep -iqE '\b(fix|update|change)\s+(it|this|that|stuff|things?)\b'; then
        echo -e "${YELLOW}⚠️  Warning: Title contains vague words (it/this/that/stuff). Be more specific.${NC}" >&2
        warnings=$((warnings + 1))
    fi

    # Check for generic titles
    if echo "$title" | grep -iqE '^\s*(bug|issue|problem|error)\s*$'; then
        echo -e "${YELLOW}⚠️  Warning: Title is too generic. Describe what specifically needs to be fixed.${NC}" >&2
        warnings=$((warnings + 1))
    fi

    return 0  # Warnings don't fail validation
}

validate_body_quality() {
    local body="$1"
    local warnings=0

    # Check body length (too short)
    local body_length=${#body}
    if [[ $body_length -lt 20 ]]; then
        echo -e "${YELLOW}⚠️  Warning: Issue body is very short ($body_length chars). Consider adding more context.${NC}" >&2
        warnings=$((warnings + 1))
    fi

    # Check for task checkboxes
    if ! echo "$body" | grep -q '\- \[ \]'; then
        echo -e "${YELLOW}⚠️  Warning: No task checkboxes found. Consider adding actionable tasks.${NC}" >&2
        warnings=$((warnings + 1))
    fi

    return 0  # Warnings don't fail validation
}

# ============================================================================
# Authentication and Configuration
# ============================================================================

check_gh_auth() {
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}❌ Error: GitHub CLI (gh) is not installed${NC}" >&2
        echo -e "   Install from: https://cli.github.com/" >&2
        return 2
    fi

    if ! gh auth status &>/dev/null; then
        echo -e "${RED}❌ Error: GitHub CLI not authenticated${NC}" >&2
        echo -e "   Run: ${GREEN}gh auth login${NC}" >&2
        return 2
    fi

    return 0
}

get_repo_slug() {
    # Use environment variable if set
    if [[ -n "${REPO_SLUG:-}" ]]; then
        echo "$REPO_SLUG"
        return 0
    fi

    # Try to detect from current git repository
    if git rev-parse --git-dir &>/dev/null; then
        local remote_url
        remote_url=$(git config --get remote.origin.url 2>/dev/null || echo "")

        if [[ -n "$remote_url" ]]; then
            # Extract owner/repo from various URL formats
            # https://github.com/owner/repo.git
            # git@github.com:owner/repo.git
            # owner/repo
            local slug
            slug=$(echo "$remote_url" | sed -E 's#.*/([^/]+/[^/]+)\.git$#\1#' | sed -E 's#.*:([^/]+/[^/]+)\.git$#\1#')

            if [[ "$slug" =~ ^[^/]+/[^/]+$ ]]; then
                echo "$slug"
                return 0
            fi
        fi
    fi

    # Could not determine repository
    echo -e "${RED}❌ Error: Could not determine repository${NC}" >&2
    echo -e "   Set REPO_SLUG environment variable or run from a git repository with remote origin" >&2
    return 4
}

# ============================================================================
# Issue Creation
# ============================================================================

create_github_issue() {
    local title="$1"
    local body="$2"
    local labels="$3"
    local assignees="$4"
    local repo="$5"

    # Build gh command
    local gh_cmd=(gh issue create --repo "$repo" --title "$title" --body "$body")

    # Add optional parameters
    if [[ -n "$labels" ]]; then
        gh_cmd+=(--label "$labels")
    fi

    if [[ -n "$assignees" ]]; then
        gh_cmd+=(--assignee "$assignees")
    fi

    # Execute command and capture output
    local issue_url
    if ! issue_url=$("${gh_cmd[@]}" 2>&1); then
        echo -e "${RED}❌ Failed to create GitHub issue${NC}" >&2
        echo -e "${RED}   $issue_url${NC}" >&2
        return 3
    fi

    echo "$issue_url"
    return 0
}

extract_issue_number() {
    local url="$1"

    # Extract issue number from URL
    # Format: https://github.com/owner/repo/issues/NUMBER
    local number
    number=$(echo "$url" | grep -oE '[0-9]+$' || echo "")

    if [[ -z "$number" ]]; then
        echo -e "${YELLOW}⚠️  Warning: Could not extract issue number from URL: $url${NC}" >&2
        echo "unknown"
        return 0
    fi

    echo "$number"
    return 0
}

# ============================================================================
# Output Formatting
# ============================================================================

output_json_result() {
    local number="$1"
    local url="$2"
    local title="$3"

    # Output JSON result
    cat <<EOF
{
  "number": "${number}",
  "url": "${url}",
  "title": $(echo "$title" | jq -Rs .)
}
EOF
}

# ============================================================================
# Main Script
# ============================================================================

main() {
    # Validate required fields first
    if ! validate_required_fields; then
        echo -e "\n${RED}Usage: $0 <title> <body> [labels] [assignees]${NC}" >&2
        exit 1
    fi

    # Run quality validations (warnings only)
    validate_title_quality "$TITLE"
    validate_body_quality "$BODY"

    # Check authentication
    if ! check_gh_auth; then
        exit 2
    fi

    # Get repository slug
    local repo
    if ! repo=$(get_repo_slug); then
        exit 4
    fi

    echo -e "${GREEN}Creating issue in ${repo}...${NC}"

    # Create the issue
    local issue_url
    if ! issue_url=$(create_github_issue "$TITLE" "$BODY" "$LABELS" "$ASSIGNEES" "$repo"); then
        exit 3
    fi

    # Extract issue number
    local issue_number
    issue_number=$(extract_issue_number "$issue_url")

    # Output results
    echo -e "\n${GREEN}✅ Successfully created issue #${issue_number}${NC}"
    echo -e "   ${issue_url}"
    echo ""

    # Output JSON for programmatic use
    output_json_result "$issue_number" "$issue_url" "$TITLE"

    exit 0
}

# Run main function
main "$@"

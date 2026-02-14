#!/bin/bash

# LiteLLM Proxy Configuration for Claude Code
# This script configures Claude Code to use the local LiteLLM proxy

# Default configuration
DEFAULT_PROXY_URL="http://localhost:4000"
# NOTE: Set your own API key via -k/--key or by modifying this value
DEFAULT_API_KEY=""
USE_PROVIDER_ENDPOINT=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -u|--url)
      PROXY_URL="$2"
      shift 2
      ;;
    -k|--key)
      API_KEY="$2"
      shift 2
      ;;
    -p|--provider-endpoint)
      USE_PROVIDER_ENDPOINT=true
      shift
      ;;
    -c|--config)
      SHOW_CONFIG=true
      shift
      ;;
    -h|--help)
      cat << EOF
LiteLLM Proxy Launcher for Claude Code

Usage: $0 [OPTIONS] [CLAUDE_ARGS...]

Options:
  -u, --url URL              Set proxy URL (default: $DEFAULT_PROXY_URL)
  -k, --key KEY              Set API key (default: $DEFAULT_API_KEY)
  -p, --provider-endpoint    Use provider-specific endpoint (/anthropic)
  -c, --config               Show configuration and exit
  -h, --help                 Show this help message

Examples:
  $0                         # Use default configuration
  $0 -u http://localhost:8000 -k sk-custom
  $0 -p                      # Use /anthropic endpoint
  $0 --config                # Show current configuration

Any additional arguments are passed to the claude command.

EOF
      exit 0
      ;;
    *)
      # All other arguments are passed to claude
      break
      ;;
  esac
done

# Use defaults if not specified
PROXY_URL="${PROXY_URL:-$DEFAULT_PROXY_URL}"
API_KEY="${API_KEY:-$DEFAULT_API_KEY}"

# Add provider endpoint if requested
if [ "$USE_PROVIDER_ENDPOINT" = true ]; then
  PROXY_URL="${PROXY_URL}/anthropic"
fi

# Set environment variables
export ANTHROPIC_BASE_URL="$PROXY_URL"
export ANTHROPIC_AUTH_TOKEN="$API_KEY"

# Show configuration if requested
if [ "$SHOW_CONFIG" = true ]; then
  echo "Current Configuration:"
  echo "  Proxy URL: $ANTHROPIC_BASE_URL"
  echo "  API Key: ${ANTHROPIC_AUTH_TOKEN:0:8}..."
  echo "  Provider Endpoint: $USE_PROVIDER_ENDPOINT"
  exit 0
fi

# Start Claude Code
echo "🚀 Starting Claude Code with LiteLLM Proxy..."
echo "   Proxy URL: $ANTHROPIC_BASE_URL"
echo "   Master Key: ${ANTHROPIC_AUTH_TOKEN:0:8}..."
echo ""

claude "$@"

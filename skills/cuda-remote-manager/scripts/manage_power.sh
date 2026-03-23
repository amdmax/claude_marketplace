#!/bin/bash
# Manage power state of cuda-dev machine

ACTION="${1:-status}"

case "$ACTION" in
    shutdown)
        echo "Shutting down cuda-dev..."
        ssh cuda-dev 'sudo shutdown -h now'
        sleep 3
        if ssh cuda-dev 'echo still up' 2>&1 | grep -q "timed out\|Connection refused"; then
            echo "✓ cuda-dev is shutting down"
        else
            echo "⚠ cuda-dev may still be running"
        fi
        ;;
    reboot)
        echo "Rebooting cuda-dev..."
        ssh cuda-dev 'sudo reboot'
        ;;
    status)
        if ssh cuda-dev 'echo online' 2>&1 | grep -q "online"; then
            echo "✓ cuda-dev is online"
            ssh cuda-dev 'uptime'
        else
            echo "✗ cuda-dev is offline"
        fi
        ;;
    *)
        echo "Usage: $0 {shutdown|reboot|status}"
        exit 1
        ;;
esac

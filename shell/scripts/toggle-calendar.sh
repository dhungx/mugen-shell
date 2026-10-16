#!/usr/bin/env bash
# Toggle the floating calendar (--open raises an open one instead of closing it); a separate quickshell process keeps the bar responsive.

set -uo pipefail

# Resolved from this script's own location, so it cannot disagree with whoever launched it.
SHELL_PATH="$(dirname "$0")/../calendar-shell.qml"

if pgrep -f "calendar-shell\.qml" >/dev/null 2>&1; then
    if [[ "${1:-}" == "--open" ]]; then
        "$(dirname "$0")/raise-window.sh" "Mugen Calendar"
    else
        pkill -f "calendar-shell\.qml"
    fi
    exit 0
fi

setsid nohup quickshell -p "$SHELL_PATH" -d >/dev/null 2>&1 &
disown 2>/dev/null || true

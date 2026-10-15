#!/usr/bin/env bash
# Toggle the Yura settings window; --open never closes it.

set -uo pipefail

# Resolved from this script's own location, so it cannot disagree with whoever launched it.
SHELL_PATH="$(dirname "$0")/../yura-settings-shell.qml"
open_only=0
if [[ "${1:-}" == "--open" ]]; then
    open_only=1
fi

if pgrep -f "yura-settings-shell\.qml" >/dev/null 2>&1; then
    [[ $open_only -eq 0 ]] && pkill -f "yura-settings-shell\.qml"
    exit 0
fi

setsid nohup quickshell -p "$SHELL_PATH" -d >/dev/null 2>&1 &
disown 2>/dev/null || true

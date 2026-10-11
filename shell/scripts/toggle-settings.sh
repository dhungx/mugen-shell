#!/usr/bin/env bash
# Toggle the floating settings window; a category switches an open one over ipc, and --open never closes it.

set -uo pipefail

# Resolved from this script's own location, so it cannot disagree with whoever launched it.
SHELL_PATH="$(dirname "$0")/../settings-shell.qml"
open_only=0
if [[ "${1:-}" == "--open" ]]; then
    open_only=1
    shift
fi
category="${1:-}"

if pgrep -f "/settings-shell\.qml" >/dev/null 2>&1; then
    if [[ -n "$category" ]]; then
        qs -p "$SHELL_PATH" ipc call settings openCategory "$category"
    elif [[ $open_only -eq 0 ]]; then
        pkill -f "/settings-shell\.qml"
    fi
    exit 0
fi

if [[ -n "$category" ]]; then
    MUGEN_SETTINGS_CATEGORY="$category" setsid nohup quickshell -p "$SHELL_PATH" -d >/dev/null 2>&1 &
else
    setsid nohup quickshell -p "$SHELL_PATH" -d >/dev/null 2>&1 &
fi
disown 2>/dev/null || true

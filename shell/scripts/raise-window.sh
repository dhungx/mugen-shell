#!/usr/bin/env bash
# Bring an open window to the front by its exact title; focusing a floating window does not raise it.

set -uo pipefail

selector="title:^($1)\$"

# A Lua Hyprland config evaluates `hyprctl dispatch` args as Lua and rejects the legacy string form.
if [[ "${HYPR_CONFIG_LUA:-}" == "1" ]] || hyprctl systeminfo 2>/dev/null | grep -qE '^configProvider:\s*lua\s*$'; then
    hyprctl dispatch "hl.dsp.window.alter_zorder({ mode = \"top\", window = \"${selector}\" })" >/dev/null 2>&1
    hyprctl dispatch "hl.dsp.focus({ window = \"${selector}\" })" >/dev/null 2>&1
else
    hyprctl dispatch alterzorder "top,${selector}" >/dev/null 2>&1
    hyprctl dispatch focuswindow "$selector" >/dev/null 2>&1
fi

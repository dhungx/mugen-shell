#!/usr/bin/env bash
set -euo pipefail

CFG="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hypridle.conf"
KIND="${1:?usage: idle-timer.sh <suspend|dpms> <minutes>}"
MINUTES="${2:-0}"

if [[ ! -f "$CFG" ]]; then
    echo "hypridle.conf not found: $CFG" >&2
    exit 1
fi

# A Lua Hyprland config rejects the legacy dispatch string, so probe and use hl.dsp.*.
IS_LUA=0
if [[ "${HYPR_CONFIG_LUA:-}" == "1" ]]; then
    IS_LUA=1
elif command -v hyprctl >/dev/null 2>&1 && hyprctl systeminfo 2>/dev/null | grep -qE '^configProvider:\s*lua\s*$'; then
    IS_LUA=1
fi

case "$KIND" in
    suspend)
        TIMEOUT_CMD="systemctl suspend"
        RESUME_CMD=""
        ;;
    dpms)
        if [[ "$IS_LUA" == "1" ]]; then
            TIMEOUT_CMD='hyprctl dispatch '\''hl.dsp.dpms({ action = "disable" })'\'''
            RESUME_CMD='hyprctl dispatch '\''hl.dsp.dpms({ action = "enable" })'\'''
        else
            TIMEOUT_CMD="hyprctl dispatch dpms off"
            RESUME_CMD="hyprctl dispatch dpms on"
        fi
        ;;
    *)
        echo "unknown kind: $KIND (expected suspend or dpms)" >&2
        exit 1
        ;;
esac

# Exact match, not substring: a loose check would claim hand-written listeners that merely mention "dpms".
case "$KIND" in
    suspend)
        KNOWN_LINES=("on-timeout = systemctl suspend")
        ;;
    dpms)
        KNOWN_LINES=(
            "on-timeout = hyprctl dispatch dpms off"
            "on-resume = hyprctl dispatch dpms on"
            'on-timeout = hyprctl dispatch '"'"'hl.dsp.dpms({ action = "disable" })'"'"''
            'on-resume = hyprctl dispatch '"'"'hl.dsp.dpms({ action = "enable" })'"'"''
        )
        ;;
esac
KNOWN_LINES_JSON=$(printf '%s\n' "${KNOWN_LINES[@]}")

SECONDS_VAL=$((MINUTES * 60))

# 0 minutes removes the block entirely, so hypridle.conf stays a truthful description of what's active.
python3 - "$CFG" "$SECONDS_VAL" "$TIMEOUT_CMD" "$RESUME_CMD" "$KNOWN_LINES_JSON" <<'PY'
import os, re, sys, tempfile

# Writing in place truncates first, and the replace lives here because closing Settings kills the bash above.
def write_atomic(path, text):
    dest = os.path.realpath(path)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(dest), prefix=os.path.basename(dest) + ".")
    try:
        with os.fdopen(fd, "w") as f:
            f.write(text)
        os.chmod(tmp, os.stat(dest).st_mode & 0o7777)
        os.replace(tmp, dest)
    except BaseException:
        os.unlink(tmp)
        raise

cfg, seconds = sys.argv[1], int(sys.argv[2])
timeout_cmd, resume_cmd = sys.argv[3], sys.argv[4]
known_lines = set(sys.argv[5].splitlines())
with open(cfg) as f:
    lines = f.readlines()

# Brace depth, not a regex: the Lua dpms command contains its own `{ ... }`.
def find_blocks(lns):
    blocks, i, n = [], 0, len(lns)
    while i < n:
        if re.match(r"\s*listener\s*\{", lns[i]):
            depth = lns[i].count("{") - lns[i].count("}")
            start, j = i, i
            while depth > 0 and j + 1 < n:
                j += 1
                depth += lns[j].count("{") - lns[j].count("}")
            blocks.append((start, j))
            i = j + 1
        else:
            i += 1
    return blocks

existing = None
for (s, e) in find_blocks(lines):
    if any(ln.strip() in known_lines for ln in lines[s:e + 1]):
        existing = (s, e)
        break

def build_block():
    b = ["listener {\n", "    timeout = %d\n" % seconds, "    on-timeout = %s\n" % timeout_cmd]
    if resume_cmd:
        b.append("    on-resume = %s\n" % resume_cmd)
    b.append("}\n")
    return b

if seconds <= 0:
    if existing:
        s, e = existing
        end = e + 1
        if end < len(lines) and lines[end].strip() == "":
            end += 1  # drop one trailing blank line so gaps don't accumulate
        del lines[s:end]
else:
    if existing:
        s, e = existing
        lines[s:e + 1] = build_block()
    else:
        if lines and not lines[-1].endswith("\n"):
            lines[-1] += "\n"
        lines.append("\n")
        lines.extend(build_block())

write_atomic(cfg, "".join(lines))
PY

if command -v systemctl >/dev/null 2>&1; then
    # Inactive means the user has an idle inhibitor on, and restarting would flip it back.
    if systemctl --user is-active --quiet hypridle.service; then
        systemctl --user restart hypridle.service >/dev/null 2>&1 || true
    fi
fi

echo "idle ${KIND} timer set to ${MINUTES} min (${SECONDS_VAL}s, 0=disabled, lua=${IS_LUA})"

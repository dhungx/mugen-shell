#!/usr/bin/env bash
set -euo pipefail

CFG="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hypridle.conf"
MINUTES="${1:-10}"
SECONDS_VAL=$((MINUTES * 60))

if [[ ! -f "$CFG" ]]; then
    echo "hypridle.conf not found: $CFG" >&2
    exit 1
fi

python3 - "$CFG" "$SECONDS_VAL" <<'PY'
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
with open(cfg) as f:
    content = f.read()

def replace(match):
    block = match.group(0)
    # The lockscreen listener runs the lock directly (without `before_sleep`).
    if re.search(r"on-timeout\s*=\s*\S*mugen-lock\.sh\b", block):
        block = re.sub(r"timeout\s*=\s*\d+", f"timeout = {seconds}", block, count=1)
    return block

new = re.sub(r"listener\s*\{[^}]+\}", replace, content)
if new == content:
    sys.stderr.write("warning: no lockscreen listener matched; nothing changed\n")

write_atomic(cfg, new)
PY

if command -v systemctl >/dev/null 2>&1; then
    # Inactive means the user has an idle inhibitor on, and restarting would flip it back.
    if systemctl --user is-active --quiet hypridle.service; then
        systemctl --user restart hypridle.service >/dev/null 2>&1 || true
    fi
fi

echo "lock timer set to ${MINUTES} min (${SECONDS_VAL}s)"

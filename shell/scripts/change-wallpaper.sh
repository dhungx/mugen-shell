#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
THUMB_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/mugen-shell/wallp"
mkdir -p "$THUMB_DIR"
source "$SCRIPT_DIR/wallpaper-opts.sh"

DEBUG_LOG="$THUMB_DIR/debug.log"
DEBUG_LOG_MAX_BYTES=1048576

# The log is the only trace a detached run leaves, so it is rotated rather than switched off.
if [[ -f "$DEBUG_LOG" ]] && (( $(wc -c < "$DEBUG_LOG") > DEBUG_LOG_MAX_BYTES )); then
  mv -f "$DEBUG_LOG" "$DEBUG_LOG.1" 2>/dev/null || true
fi

debug_log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$DEBUG_LOG"
}

debug_log "========== NEW EXECUTION =========="
debug_log "Called with: $*"
debug_log "PWD: $PWD"
debug_log "USER: ${USER:-unknown}"
debug_log "WAYLAND_DISPLAY: ${WAYLAND_DISPLAY:-not set}"
debug_log "XDG_RUNTIME_DIR: ${XDG_RUNTIME_DIR:-not set}"
debug_log "PATH: $PATH"

# The shell fires this detached and never sees the exit code, so a rejection must announce itself.
notify_failure() {
  command -v notify-send >/dev/null 2>&1 && notify-send -a mugen-shell "Wallpaper" "$1" >/dev/null 2>&1 || true
}

abort_daemon_unavailable() {
  debug_log "ensure_swww failed, aborting"
  notify_failure "Wallpaper daemon (awww) is not responding"
  exit 1
}

CURRENT_WALLPAPER_FILE="$THUMB_DIR/current_wallpaper_path.txt"

read_current_wallpaper() {
  if [[ -r "$CURRENT_WALLPAPER_FILE" ]]; then tr -d '\n' < "$CURRENT_WALLPAPER_FILE" || true; fi
}

absolute_path() {
  printf '%s' "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

REAPPLY=false
if [[ "${1:-}" == "--reapply" ]]; then REAPPLY=true; shift; fi

if [[ $REAPPLY == true ]]; then
  WALLPAPER="$(read_current_wallpaper)"
  [[ -f "$WALLPAPER" ]] || exit 0
else
  WALLPAPER="${1:-}"
fi
[[ -z "${WALLPAPER:-}" ]] && { echo "Usage: $0 [--reapply] <wallpaper-path>" >&2; exit 1; }
[[ ! -f "$WALLPAPER" ]] && {
  echo "File not found: $WALLPAPER" >&2
  notify_failure "File not found: ${WALLPAPER##*/}"
  exit 1
}

WALLPAPER_ABS="$(absolute_path "$WALLPAPER")"

THUMB_FILE="$THUMB_DIR/current_wallpaper_thumb.png"
LOCK="$THUMB_DIR/.wallp.lock"
THEME_MODE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/mugen-shell/theme-mode"

# Hyprland draws a closing layer's fade-out on top of the stack, so it bleeds through for this long.
LAYER_FADE_SEC=0.5

# awww paces even a zero-duration set by --transition-fps, so 1 fps would stall the commit.
STILL_SET_FPS=60
STILL_COMMIT_SEC=0.35

# A mapped layer stays off screen until its first frame, so this hides mpvpaper's start-up.
MPV_WARMUP_SEC=0.4

# awww-daemon and mpvpaper are spawned with 9>&-: an inherited fd holds the flock for their whole life.
exec 9>"$LOCK"
if [[ $REAPPLY == true ]]; then
  flock -w 10 9 || exit 0
  # A switch that held the lock may have replaced the wallpaper while this waited.
  WALLPAPER="$(read_current_wallpaper)"
  [[ -f "$WALLPAPER" ]] || exit 0
  WALLPAPER_ABS="$(absolute_path "$WALLPAPER")"
  source "$SCRIPT_DIR/wallpaper-opts.sh"
elif ! flock -n 9; then
  echo "Already running" >&2
  notify_failure "Another wallpaper change is still running"
  exit 1
fi
cleanup() {
  debug_log "Cleanup: releasing lock"
  exec 9>&-
  find "$THUMB_DIR" -name 'wprev.*.png' -mmin +5 -delete 2>/dev/null || true
  debug_log "========== EXECUTION COMPLETED =========="
}
trap cleanup EXIT

# Nix wraps these in scripts, so comm becomes ".mpvpaper-wrapped" and pgrep -x misses them.

is_image() {
  case "${1,,}" in
    *.png|*.jpg|*.jpeg|*.webp) return 0 ;;
    *) return 1 ;;
  esac
}

is_video() {
  case "${1,,}" in
    *.mp4|*.webm|*.mkv|*.gif) return 0 ;;
    *) return 1 ;;
  esac
}

if ! is_image "$WALLPAPER_ABS" && ! is_video "$WALLPAPER_ABS"; then
  echo "Unsupported file format: $WALLPAPER_ABS" >&2
  notify_failure "Unsupported file format: ${WALLPAPER_ABS##*/}"
  exit 1
fi

theme_mode() {
  local mode=""
  [[ -f "$THEME_MODE_FILE" ]] && mode="$(tr -d '\n' < "$THEME_MODE_FILE")"
  if [[ "$mode" == "light" ]]; then printf 'light'; else printf 'dark'; fi
}

run_matugen() {
  # Without the mode, changing wallpaper in light mode silently drops every app back to dark.
  local args=(matugen image "$1" --mode "$(theme_mode)")
  # matugen >= 4 aborts headless when several source colors qualify
  if matugen image --help 2>/dev/null | grep -q -- '--prefer'; then
    args+=(--prefer saturation)
  fi
  "${args[@]}" 2>&1 || return
  # config.toml is reverted at every login, so a user's own templates live beside it.
  local user_config="${XDG_CONFIG_HOME:-$HOME/.config}/matugen/user.toml"
  if [[ -f "$user_config" ]]; then
    "${args[@]}" --config "$user_config" 2>&1 || true
  fi
}

swww_ready() {
  awww query >/dev/null 2>&1
}

# A service restart kills the shell's whole cgroup, so the daemons get a scope of their own.
spawn_daemon() {
  setsid nohup systemd-run --user --scope --quiet -- "$@" 9>&- &
}

start_swww() {
  spawn_daemon awww-daemon --format xrgb --no-cache >/dev/null 2>&1
}

ensure_swww() {
  debug_log "ensure_swww: checking awww-daemon status"
  if ! swww_ready; then
    debug_log "ensure_swww: awww-daemon not ready, starting..."
    pkill awww-daemon >/dev/null 2>&1 || true
    start_swww
  fi

  for _ in {1..60}; do
    swww_ready && { debug_log "ensure_swww: awww-daemon ready"; return 0; }
    sleep 0.05
  done

  echo "awww-daemon not ready" >&2
  debug_log "ensure_swww: FAILED - awww-daemon not ready"
  return 1
}

swww_set_no_transition() {
  ensure_swww || return 1

  if awww img --help 2>/dev/null | grep -q -- '--transition-type'; then
    awww img --resize "$AWWW_RESIZE" --fill-color "$AWWW_FILL" "$1" --transition-type none --transition-duration 0 --transition-fps "$STILL_SET_FPS" 2>/dev/null \
    || awww img --resize "$AWWW_RESIZE" --fill-color "$AWWW_FILL" "$1" --transition-duration 0 --transition-fps "$STILL_SET_FPS"
  else
    awww img --resize "$AWWW_RESIZE" --fill-color "$AWWW_FILL" "$1" --transition-duration 0 --transition-fps "$STILL_SET_FPS"
  fi
}

# mpvpaper covers this frame once it maps, so a failed set must not keep the video from starting.
show_bridge_frame() {
  awww img --resize "$AWWW_RESIZE" --fill-color "$AWWW_FILL" "$1" "${TRANS_OPTS[@]}" \
    || debug_log "awww img: FAILED with exit code $?"
}

mpv_ipc_send() {
  local payload="$1"
  if command -v socat >/dev/null 2>&1; then
    printf '%s\n' "$payload" | socat - UNIX-CONNECT:"$MPV_SOCKET" 2>/dev/null
  elif command -v nc >/dev/null 2>&1; then
    printf '%s\n' "$payload" | nc -U "$MPV_SOCKET" 2>/dev/null
  else
    return 1
  fi
}

stop_mpvpaper() {
  if [[ -S "$MPV_SOCKET" ]]; then
    mpv_ipc_send '{"command":["quit"]}' >/dev/null 2>&1 || true
    sleep 0.2
  fi

  if pgrep mpvpaper >/dev/null 2>&1; then
    pkill mpvpaper 2>/dev/null || true
    for _ in {1..10}; do
      pgrep mpvpaper >/dev/null 2>&1 || break
      sleep 0.1
    done
  fi

  if pgrep mpvpaper >/dev/null 2>&1; then
    pkill -9 mpvpaper 2>/dev/null || true
  fi

  [[ -S "$MPV_SOCKET" ]] && rm -f "$MPV_SOCKET" || true
}

freeze_and_shot_current_frame() {
  [[ -S "$MPV_SOCKET" ]] || return 1

  mpv_ipc_send '{"command":["set_property","pause",true]}' >/dev/null 2>&1 || true

  local out
  out="$(mktemp "$THUMB_DIR/wprev.XXXXXX.png")"
  mpv_ipc_send "{\"command\":[\"screenshot-to-file\",\"${out}\",\"video\"]}" >/dev/null 2>&1 || true

  for _ in {1..40}; do
    [[ -s "$out" ]] && { printf '%s' "$out"; return 0; }
    sleep 0.01
  done

  return 1
}

grab_current_video_frame_via_ipc() {
  [[ -S "$MPV_SOCKET" ]] || return 1
  command -v ffmpeg >/dev/null 2>&1 || return 1

  local json path curtime tries=0 out

  json="$(mpv_ipc_send '{"command":["get_property","path"]}')" || true
  path="$(printf '%s' "$json" | sed -n 's/.*"data"\s*:\s*"\([^"]\+\)".*/\1/p')" || true
  [[ -n "${path:-}" && -f "$path" ]] || return 1

  while :; do
    json="$(mpv_ipc_send '{"command":["get_property","time-pos"]}')" || true
    curtime="$(printf '%s' "$json" | sed -n 's/.*"data"\s*:\s*\([0-9]\+\(\.[0-9]\+\)\?\).*/\1/p')" || true
    [[ -n "${curtime:-}" ]] && break
    ((tries++>=2)) && curtime=0 && break
    sleep 0.02
  done

  out="$(mktemp "$THUMB_DIR/wprev.XXXXXX.png")"
  ffmpeg -nostdin -y -v error -i "$path" -ss "$curtime" \
    -frames:v 1 -update 1 \
    "$out" >/dev/null 2>&1 || return 1

  [[ -s "$out" ]] || return 1
  printf '%s' "$out"
}

if [[ $REAPPLY == true ]]; then
  if is_video "$WALLPAPER_ABS"; then
    debug_log "Reapply skipped: a video wallpaper is updated live"
    exit 0
  fi
  ensure_swww || abort_daemon_unavailable
  if ! awww img --resize "$AWWW_RESIZE" --fill-color "$AWWW_FILL" "$(wallpaper_adjusted_still "$WALLPAPER_ABS" "$THUMB_DIR/still.png")" \
    --transition-type none --transition-duration 0 --transition-fps "$STILL_SET_FPS"; then
    debug_log "Reapply: awww img FAILED"
    notify_failure "Could not redraw the wallpaper with the new settings"
    exit 1
  fi
  exit 0
fi

# Tear the video layer down while awww already holds the same frame, so the flash shows nothing new.
if pgrep mpvpaper >/dev/null 2>&1; then
  echo "Capturing current video frame for smooth transition..."

  prev_png="$(freeze_and_shot_current_frame 2>/dev/null || true)"
  [[ -z "${prev_png:-}" ]] && prev_png="$(grab_current_video_frame_via_ipc 2>/dev/null || true)"

  if [[ -n "${prev_png:-}" && -s "$prev_png" ]]; then
    # mpv's screenshot leaves out its brightness and saturation (measured), so the frame gets them like a still.
    shown_png="$(wallpaper_adjusted_still "$prev_png" "${prev_png%.png}.adjusted.png")"
    if ! ensure_swww; then
      mpv_ipc_send '{"command":["set_property","pause",false]}' >/dev/null 2>&1 || true
      rm -f "$prev_png" "${prev_png%.png}.adjusted.png"
      abort_daemon_unavailable
    fi
    if swww_set_no_transition "$shown_png"; then
      sleep "$STILL_COMMIT_SEC"
      echo "Current frame captured and displayed"
    fi
    rm -f "$prev_png" "${prev_png%.png}.adjusted.png"
  fi

  stop_mpvpaper
  sleep "$LAYER_FADE_SEC"
fi

if is_image "$WALLPAPER_ABS"; then
  echo "Setting image wallpaper: $WALLPAPER_ABS"
  debug_log "Setting image wallpaper: $WALLPAPER_ABS"

  if command -v matugen >/dev/null 2>&1; then
    echo "Generating color palette with matugen..."
    debug_log "Running matugen..."
    if matugen_output=$(run_matugen "$WALLPAPER_ABS"); then
      echo "$matugen_output" >> "$DEBUG_LOG"
      echo "Color palette generated successfully"
      debug_log "matugen: success"
    else
      matugen_rc=$?
      echo "$matugen_output" >> "$DEBUG_LOG"
      echo "matugen failed with exit code $matugen_rc"
      debug_log "matugen: FAILED"
    fi
  fi

  ensure_swww || abort_daemon_unavailable
  debug_log "Running awww img with TRANS_OPTS"
  if swww_output=$(awww img --resize "$AWWW_RESIZE" --fill-color "$AWWW_FILL" "$(wallpaper_adjusted_still "$WALLPAPER_ABS" "$THUMB_DIR/still.png")" "${TRANS_OPTS[@]}" 2>&1); then
    echo "$swww_output" >> "$DEBUG_LOG"
    debug_log "awww img: success"
  else
    swww_rc=$?
    echo "$swww_output" >> "$DEBUG_LOG"
    debug_log "awww img: FAILED with exit code $swww_rc"
    notify_failure "Could not set ${WALLPAPER_ABS##*/} as the wallpaper"
    exit 1
  fi

  echo "$WALLPAPER_ABS" > "$CURRENT_WALLPAPER_FILE"
  echo "Image wallpaper set successfully"
  debug_log "Image wallpaper set successfully"

elif is_video "$WALLPAPER_ABS"; then
  echo "Setting video wallpaper: $WALLPAPER_ABS"
  debug_log "Setting video wallpaper: $WALLPAPER_ABS"

  FIRST_FRAME="$THUMB_DIR/video-first.png"
  # apply-theme-mode.sh repaints from whatever thumb is here, so a stale one would outlive this video.
  rm -f "$FIRST_FRAME" "$THUMB_FILE"
  if command -v ffmpeg >/dev/null 2>&1; then
    first_frame_vf="$(wallpaper_adjust_filter)"
    # The transition waits on this: decoding and PNG-compressing a 4K frame twice takes about a second.
    ffmpeg -nostdin -y -v error -i "$WALLPAPER_ABS" -filter_complex \
      "[0:v]split=2[t][f];[t]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=0x00000000[thumb];[f]${first_frame_vf:-null}[first]" \
      -map '[thumb]' -frames:v 1 -compression_level 1 -update 1 "$THUMB_FILE" \
      -map '[first]' -frames:v 1 -compression_level 1 -update 1 "$FIRST_FRAME" >/dev/null 2>&1 || rm -f "$FIRST_FRAME" "$THUMB_FILE"
  fi

  if command -v matugen >/dev/null 2>&1 && [[ -f "$THUMB_FILE" ]]; then
    echo "Generating color palette with matugen..."
    debug_log "Running matugen..."
    if matugen_output=$(run_matugen "$THUMB_FILE"); then
      echo "$matugen_output" >> "$DEBUG_LOG"
      echo "Color palette generated successfully"
      debug_log "matugen: success"
    else
      matugen_rc=$?
      echo "$matugen_output" >> "$DEBUG_LOG"
      echo "matugen failed with exit code $matugen_rc"
      debug_log "matugen: FAILED"
    fi
  fi

  ensure_swww || abort_daemon_unavailable
  if [[ -s "$FIRST_FRAME" ]]; then
    show_bridge_frame "$FIRST_FRAME"
  elif [[ -f "$THUMB_FILE" ]]; then
    show_bridge_frame "$THUMB_FILE"
  else
    if command -v ffmpeg >/dev/null 2>&1; then
      placeholder="$THUMB_DIR/video-placeholder.png"
      ffmpeg -nostdin -v error -f lavfi -i color=c=#222222:s=1920x1080 -frames:v 1 -y "$placeholder" >/dev/null 2>&1 || true
      [[ -f "$placeholder" ]] && show_bridge_frame "$placeholder"
    fi
  fi

  sleep "$(awk "BEGIN { d = $TRANS_DURATION - $MPV_WARMUP_SEC; print (d > 0) ? d : 0 }")"

  echo "Starting mpvpaper..."
  debug_log "Starting mpvpaper with: $WALLPAPER_ABS"
  spawn_daemon mpvpaper "${MPVPAPER_FLAGS[@]}" -o "$MPV_OPTS" '*' "$WALLPAPER_ABS" >"$THUMB_DIR/mpvpaper.log" 2>&1

  for i in {1..20}; do
    if pgrep mpvpaper >/dev/null 2>&1; then
      echo "$WALLPAPER_ABS" > "$CURRENT_WALLPAPER_FILE"
      echo "Video wallpaper is playing"
      debug_log "mpvpaper: started successfully"
      exit 0
    fi
    sleep 0.1
  done

  echo "mpvpaper failed to start, check $THUMB_DIR/mpvpaper.log" >&2
  debug_log "mpvpaper: FAILED to start"
  cat "$THUMB_DIR/mpvpaper.log" >> "$DEBUG_LOG" 2>/dev/null || true
  notify_failure "Could not start the video wallpaper"
  exit 1
fi

#!/usr/bin/env bash
# Usage: pictures-dir.sh  (prints the user's Pictures directory)

set -euo pipefail

dirs_file="${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs"
dir=""
if [[ -r "$dirs_file" ]]; then
  # Read the way GLib's g_get_user_special_dir does, so the file manager and the gallery agree.
  line=$(grep -E '^[[:space:]]*XDG_PICTURES_DIR[[:space:]]*=' "$dirs_file" | tail -n 1 || true)
  value=${line#*=}
  value=${value#"${value%%[![:space:]]*}"}
  if [[ "$value" == \"* ]]; then
    value=${value#\"}
    value=${value%\"*}
  else
    value=${value%"${value##*[![:space:]]}"}
  fi
  case "$value" in
  '$HOME' | '$HOME/'*) dir="$HOME${value#\$HOME}" ;;
  /*) dir="$value" ;;
  esac
fi

dir="${dir:-$HOME/Pictures}"
[[ "$dir" == "/" ]] || dir="${dir%/}"
printf '%s\n' "$dir"

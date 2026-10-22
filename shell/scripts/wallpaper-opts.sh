# -p only: WallpaperPlayback owns mpv's pause over IPC; mpvpaper's -a writes the same pause and falls out of step.
MPVPAPER_FLAGS=(-p)
MPV_SOCKET="${XDG_CACHE_HOME:-$HOME/.cache}/mugen-shell/wallp/mpvpaper.sock"

WALLPAPER_SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/mugen-shell/settings.json"
_wp_line=$(jq -r '
  def pick($allowed; $d): . as $v | if ($v | type) == "string" and ($allowed | any(. == $v)) then $v else $d end;
  def finite: type == "number" and (isinfinite | not);
  def clampnum($lo; $hi; $d): if finite then ([$lo, ([$hi, .] | min)] | max) else $d end;
  ((.wallpaper | objects) // {}) as $w
  | [ ($w.speed | if finite then (. * 4 | round / 4) else null end | clampnum(0.25; 2; 1)),
      ($w.sound | if type == "boolean" then . else false end),
      ($w.volume | if finite then round else null end | clampnum(0; 100; 50)),
      ($w.fit | pick(["fill", "fit", "stretch"]; "fill")),
      ($w.brightness | if finite then round else null end | clampnum(-50; 50; 0)),
      ($w.saturation | if finite then round else null end | clampnum(-100; 100; 0)),
      ($w.transition | pick(["wave", "fade", "wipe", "grow", "random", "none"]; "wave")),
      ($w.transitionSeconds | if finite then (. * 10 | round / 10) else null end | clampnum(0.3; 3; 1.3)) ]
  | @tsv' "$WALLPAPER_SETTINGS" 2>/dev/null) || _wp_line=""
IFS=$'\t' read -r WP_SPEED WP_SOUND WP_VOLUME WP_FIT WP_BRIGHTNESS WP_SATURATION WP_TRANSITION WP_TRANSITION_SECONDS <<< "$_wp_line" || true
: "${WP_SPEED:=1}" "${WP_SOUND:=false}" "${WP_VOLUME:=50}" "${WP_FIT:=fill}" "${WP_BRIGHTNESS:=0}" \
  "${WP_SATURATION:=0}" "${WP_TRANSITION:=wave}" "${WP_TRANSITION_SECONDS:=1.3}"
# jq prints a rounded -0.4 as -0; normalise so the mpv options read 0.
WP_VOLUME=$((WP_VOLUME)) WP_BRIGHTNESS=$((WP_BRIGHTNESS)) WP_SATURATION=$((WP_SATURATION))

_wp_noaudio="no-audio "
if [[ $WP_SOUND == true ]]; then _wp_noaudio=""; fi

case $WP_FIT in
  fit)     AWWW_RESIZE=fit;     _wp_panscan=0.0; _wp_keepaspect=yes ;;
  stretch) AWWW_RESIZE=stretch; _wp_panscan=0.0; _wp_keepaspect=no ;;
  *)       AWWW_RESIZE=crop;    _wp_panscan=1.0; _wp_keepaspect=yes ;;
esac
AWWW_FILL=000000

# vaapi surfaces can't be read back, failing every mpv screenshot; auto-copy lands frames in memory.
MPV_OPTS="no-config ${_wp_noaudio}loop cache=yes profile=low-latency \
vo=gpu-next gpu-context=wayland \
hwdec=auto-copy \
keep-open=yes \
input-ipc-server=${MPV_SOCKET} \
screenshot-format=png screenshot-high-bit-depth=no screenshot-png-compression=1 \
speed=${WP_SPEED} volume=${WP_VOLUME} panscan=${_wp_panscan} keepaspect=${_wp_keepaspect} brightness=${WP_BRIGHTNESS} saturation=${WP_SATURATION}"

if [[ $WP_TRANSITION == random ]]; then
  _wp_kinds=(wave fade wipe grow)
  WP_TRANSITION=${_wp_kinds[RANDOM % 4]}
fi

TRANS_DURATION=$WP_TRANSITION_SECONDS
if [[ $WP_TRANSITION == none ]]; then TRANS_DURATION=0; fi
_wp_bezier=0.25,0.1,0.25,1.0
case $WP_TRANSITION in
  none) TRANS_OPTS=(--transition-type none --transition-fps 60 --transition-duration 0) ;;
  fade) TRANS_OPTS=(--transition-type fade --transition-fps 144 --transition-duration "$TRANS_DURATION"
    --transition-step 90 --transition-bezier "$_wp_bezier") ;;
  wipe) TRANS_OPTS=(--transition-type wipe --transition-fps 144 --transition-duration "$TRANS_DURATION"
    --transition-angle 30 --transition-step 90 --transition-bezier "$_wp_bezier") ;;
  grow) TRANS_OPTS=(--transition-type center --transition-fps 144 --transition-duration "$TRANS_DURATION"
    --transition-step 90 --transition-bezier "$_wp_bezier") ;;
  *) TRANS_OPTS=(--transition-type wave --transition-fps 144 --transition-duration "$TRANS_DURATION"
    --transition-angle 30 --transition-wave 40,40 --transition-step 20 --transition-bezier "$_wp_bezier") ;;
esac

unset _wp_line _wp_noaudio _wp_panscan _wp_keepaspect _wp_kinds _wp_bezier

wallpaper_adjust_filter() {
  local chain="" sat k sign=+
  if (( WP_SATURATION != 0 )); then
    sat=$((100 + WP_SATURATION))
    printf -v chain 'hue=s=%d.%02d' $((sat / 100)) $((sat % 100))
  fi
  if (( WP_BRIGHTNESS != 0 )); then
    k=$WP_BRIGHTNESS
    if (( k < 0 )); then k=$((-k)); sign=-; fi
    k=$(((k * 255 + 50) / 100))
    chain+="${chain:+,}lutrgb=r=val$sign$k:g=val$sign$k:b=val$sign$k"
  fi
  if [[ -n $chain ]]; then printf '%s\n' "$chain"; fi
  return 0
}

# Prints the path to show for still <src>: <out> when adjusted, <src> when nothing is set or ffmpeg fails.
wallpaper_adjusted_still() {
  local src=$1 out=$2 vf
  vf=$(wallpaper_adjust_filter)
  if [[ -z $vf ]]; then
    printf '%s\n' "$src"
  elif ffmpeg -nostdin -y -v error -i "$src" -vf "$vf" -frames:v 1 -compression_level 1 -update 1 "$out.tmp.png" >&2 && mv -f "$out.tmp.png" "$out"; then
    printf '%s\n' "$out"
  else
    rm -f "$out.tmp.png"
    printf '%s\n' "$src"
  fi
  return 0
}

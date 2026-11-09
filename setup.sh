#!/usr/bin/env bash
# Installe sur une TCL Google TV: menage des apps inutiles + lanceur "liquid glass" + thème.
# Usage: ./setup.sh <IP de la télé> [-y]
#   Variables facultatives: LAT=43.30 LON=5.37 (ta ville, pour que le fond change avec le soleil)
set -euo pipefail
. "$(dirname "$0")/lib.sh"
[ "${2:-}" = "-y" ] && ASSUME_YES=1
need_ip_pre() { TV_IP="${1:-}"; [ -n "$TV_IP" ] || { echo "Usage: ./setup.sh <IP de la télé> [-y]"; exit 2; }; }
need_ip_pre "${1:-}"

echo "== 1/7 Outils sur l'ordinateur (macOS, Homebrew)"
if ! command -v brew >/dev/null; then echo "Installe Homebrew d'abord: https://brew.sh"; exit 1; fi
command -v adb >/dev/null || { ask "Installer android-platform-tools (adb)?" && brew install android-platform-tools; }
[ -d /opt/homebrew/opt/openjdk@17 ] || [ -d /usr/local/opt/openjdk@17 ] || { ask "Installer Java 17 (openjdk@17)?" && brew install openjdk@17; }
SDK="$(brew --prefix)/share/android-commandlinetools"
if [ ! -d "$SDK" ]; then ask "Installer les outils Android (commandlinetools)?" && brew install --cask android-commandlinetools; fi
export JAVA_HOME="$(brew --prefix openjdk@17)" ANDROID_HOME="$SDK" ANDROID_SDK_ROOT="$SDK"
if [ ! -d "$SDK/platforms/android-34" ]; then
  yes | "$SDK/cmdline-tools/latest/bin/sdkmanager" --licenses >/dev/null 2>&1 || true
  "$SDK/cmdline-tools/latest/bin/sdkmanager" "platforms;android-34" "build-tools;34.0.0" "platform-tools"
fi
need_ip "$TV_IP"; connect_tv
echo "Connecté à $TV ($(a getprop ro.product.model))"

echo "== 2/7 Sauvegarde"
BACKUP_DIR="" "$KIT_DIR/backup.sh" "$TV_IP"
BK="$(cat "$KIT_DIR/.dernier-backup")"

echo "== 3/7 Code du lanceur (projet open source Gathin23/cleanyourtv)"
cd "$KIT_DIR"
if [ ! -d cleanyourtv ]; then git clone -q "$UPSTREAM_URL" cleanyourtv; fi
cd cleanyourtv && git checkout -q -- . 2>/dev/null || true
git fetch -q origin && git checkout -q "$UPSTREAM_COMMIT"
if [ ! -x tools/venv/bin/python ]; then python3 -m venv tools/venv; tools/venv/bin/pip install -q -r tools/requirements.txt; fi
tools/venv/bin/pip install -q pillow numpy

echo "== 4/7 Désactivation des apps inutiles (réversible)"
: > "$BK/disabled_by_us.txt"
while read -r pkg _; do
  case "$pkg" in ''|\#*) continue ;; esac
  grep -qx "$pkg" "$BK/packages_enabled_before.txt" && echo "$pkg" >> "$BK/disabled_by_us.txt"
done < "$KIT_DIR/debloat-tcl.txt"
echo "Apps qui seront désactivées:"; sed 's/^/  - /' "$BK/disabled_by_us.txt"
if ask "Continuer?"; then
  TV_HOST="$TV_IP" tools/disable.sh "$KIT_DIR/debloat-tcl.txt"
  # l'assistant de configuration prendrait la main sur l'accueil
  if grep -qx com.google.android.tungsten.setupwraith "$BK/packages_enabled_before.txt"; then
    echo com.google.android.tungsten.setupwraith >> "$BK/disabled_by_us.txt"
    echo com.google.android.tungsten.setupwraith > /tmp/_sw.txt
    TV_HOST="$TV_IP" tools/disable.sh /tmp/_sw.txt
  fi
fi

echo "== 5/7 Lanceur"
CFG=launcher/app/src/main/res/values/config.xml
python3 - "$CFG" "${LAT:-}" "${LON:-}" <<'PY'
import re, sys
p, lat, lon = sys.argv[1:4]
s = open(p).read()
dock = ["com.netflix.ninja", "com.google.android.youtube.tv", "com.disney.disneyplus", "com.amazon.amazonvideo.livingroom"]
s = re.sub(r'(<string-array name="dock_apps">).*?(</string-array>)',
           lambda m: m.group(1) + "".join(f"\n        <item>{d}</item>" for d in dock) + "\n    " + m.group(2), s, count=1, flags=re.S)
s = re.sub(r'(<string name="live_tv_package" translatable="false">).*?(</string>)', r'\1com.tcl.tv\2', s, count=1)
if lat and lon:
    s = re.sub(r'(<string name="latitude" translatable="false">).*?(</string>)', rf'\g<1>{lat}\2', s, count=1)
    s = re.sub(r'(<string name="longitude" translatable="false">).*?(</string>)', rf'\g<1>{lon}\2', s, count=1)
open(p, "w").write(s)
PY
sed -i.bak 's/networkTimeout=[0-9]*/networkTimeout=180000/' launcher/gradle/wrapper/gradle-wrapper.properties && rm -f launcher/gradle/wrapper/gradle-wrapper.properties.bak
git apply "$KIT_DIR/patches/horloge-centree.patch"
if ask "Compiler et installer le lanceur (quelques minutes)?"; then
  (cd launcher && TV_HOST="$TV_IP" ./build-and-install.sh)
  echo "$LAUNCHER_PKG" > "$BK/launcher_installed.txt"
fi

echo "== 6/7 Thème et fonds d'écran"
THEME="$KIT_DIR/theme-prêt"; rm -rf "$THEME"; mkdir -p "$THEME/wallpapers"
cp "$KIT_DIR/theme/config.json" "$THEME/config.json"
if [ -d "$KIT_DIR/theme/wallpapers" ] && ls "$KIT_DIR/theme/wallpapers"/*.jpg >/dev/null 2>&1; then
  cp "$KIT_DIR/theme/wallpapers/"*.jpg "$THEME/wallpapers/"
else
  tools/venv/bin/python "$KIT_DIR/make_wallpapers.py" "$THEME/wallpapers"
fi
TV_HOST="$TV_IP" tools/theme.sh "$THEME"

echo "== 7/7 Écran de veille (horloge sur le fond) et animations"
a "settings put secure screensaver_components $LAUNCHER_PKG/$LAUNCHER_PKG.ClockDream"
for s in window_animation_scale transition_animation_scale animator_duration_scale; do a "settings put global $s 0.5"; done
a "input keyevent KEYCODE_HOME"
echo
echo "Terminé. Pour tout remettre comme avant: ./restore.sh $TV_IP"

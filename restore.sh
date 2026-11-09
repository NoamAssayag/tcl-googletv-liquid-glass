#!/usr/bin/env bash
# Remet la télé comme avant (apps réactivées, ancien accueil, thème retiré, animations et veille d'origine).
# Usage: ./restore.sh <IP de la télé> [dossier de sauvegarde]
set -u
. "$(dirname "$0")/lib.sh"
need_ip "${1:-}"; connect_tv
BK="${2:-$(cat "$KIT_DIR/.dernier-backup" 2>/dev/null || true)}"
[ -d "$BK" ] || { echo "Dossier de sauvegarde introuvable. Donne-le en 2e argument: ./restore.sh $TV_IP backup-..."; exit 1; }

# thème (retire les fichiers du thème sur la télé)
if [ -x "$KIT_DIR/cleanyourtv/tools/theme.sh" ]; then (cd "$KIT_DIR/cleanyourtv" && TV_HOST="$TV_IP" tools/theme.sh --reset) || true; fi

# réactive les apps
if [ -f "$BK/disabled_by_us.txt" ]; then
  while read -r pkg _; do case "$pkg" in ''|\#*) continue ;; esac; echo "réactive $pkg"; a "pm enable $pkg" >/dev/null 2>&1; done < "$BK/disabled_by_us.txt"
fi
a "pm enable $STOCK_LAUNCHER" >/dev/null 2>&1
a "cmd package set-home-activity $STOCK_HOME" >/dev/null 2>&1
# retire le lanceur ajouté
a "pm uninstall --user 0 $LAUNCHER_PKG" >/dev/null 2>&1 && echo "lanceur retiré"
# animations et écran de veille d'origine
for s in window_animation_scale transition_animation_scale animator_duration_scale; do a "settings put global $s 1.0"; done
v="$(cat "$BK/screensaver_before.txt" 2>/dev/null)"
if [ -n "$v" ] && [ "$v" != null ]; then a "settings put secure screensaver_components $v"; else a "settings delete secure screensaver_components"; fi
echo "Terminé. Redémarre la télé (Réglages > Système > Redémarrer)."
echo "Avant une revente, fais aussi: Réglages > Système > À propos > Réinitialiser."

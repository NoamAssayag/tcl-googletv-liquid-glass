#!/usr/bin/env bash
# Sauvegarde l'état de la télé AVANT toute modification (lecture seule, rien n'est changé).
# Usage: ./backup.sh <IP de la télé>
set -u
. "$(dirname "$0")/lib.sh"
need_ip "${1:-}"; connect_tv
BK="${BACKUP_DIR:-$KIT_DIR/backup-$(echo "$TV_IP" | tr . -)-$(date +%Y%m%d)}"
mkdir -p "$BK"
a "pm list packages -f" | sort > "$BK/packages_all.txt"
a "pm list packages -e" | sed 's/package://' | sort > "$BK/packages_enabled_before.txt"
a "pm list packages -d" | sed 's/package://' | sort > "$BK/packages_disabled_before.txt"
for ns in system secure global; do a "settings list $ns" > "$BK/settings_$ns.txt"; done
a "settings get secure screensaver_components" > "$BK/screensaver_before.txt"
a "cmd package resolve-activity --brief -c android.intent.category.HOME -a android.intent.action.MAIN | tail -1" > "$BK/default_home.txt"
a getprop > "$BK/getprop.txt"
echo "Sauvegarde dans: $BK"
echo "Garde ce dossier: restore.sh en a besoin. Il contient des infos propres à ta télé, ne le publie pas."
echo "$BK" > "$KIT_DIR/.dernier-backup"

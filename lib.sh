# Fonctions communes (chargé par les autres scripts)
UPSTREAM_URL="https://github.com/Gathin23/cleanyourtv"
UPSTREAM_COMMIT="6e8615eb0be0e843ceeebedae246d69f3e0a88d7"   # version testée avec les correctifs de ce kit
LAUNCHER_PKG="com.gathin.tvhome"
STOCK_LAUNCHER="com.google.android.apps.tv.launcherx"
STOCK_HOME="$STOCK_LAUNCHER/.home.HomeActivity"
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

need_ip() {
  TV_IP="${1:-${TV_HOST:-}}"
  [ -n "$TV_IP" ] || { echo "Il manque l'adresse IP de la télé (Réglages > Réseau). Exemple: $0 192.168.1.50"; exit 2; }
  TV="$TV_IP:5555"
  command -v adb >/dev/null || { echo "adb est introuvable. Lance d'abord ./setup.sh (il l'installe)."; exit 2; }
}
connect_tv() {
  adb connect "$TV" >/dev/null 2>&1 || true
  if ! adb -s "$TV" get-state >/dev/null 2>&1; then
    echo "Connexion impossible à $TV."
    echo "Vérifie: télé allumée, même Wi-Fi que l'ordinateur, Options pour les développeurs > Débogage réseau activé."
    exit 1
  fi
  if adb -s "$TV" shell true 2>&1 | grep -qi unauthorized; then
    echo "Accepte la fenêtre « Autoriser le débogage » affichée sur la télé, puis relance."; exit 1
  fi
}
a() { adb -s "$TV" shell "$@" | tr -d '\r'; }
ask() { # ask "question" -> 0 si oui ; avec -y / ASSUME_YES=1, répond oui
  [ "${ASSUME_YES:-}" = 1 ] && return 0
  read -r -p "$1 [o/N] " r; [ "$r" = o ] || [ "$r" = O ] || [ "$r" = y ] || [ "$r" = Y ]
}

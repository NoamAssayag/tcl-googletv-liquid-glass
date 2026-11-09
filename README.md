# TCL Google TV: moins de pubs, plus fluide, accueil « liquid glass »

Un kit en 1 commande pour une télé **TCL sous Google TV** (testé sur une TCL 65C845, Android 12), depuis un **Mac**, en **Wi-Fi**.

Ce que ça fait:
- **Désactive** les apps de suivi, de pubs et de démo préinstallées par TCL (rien n'est désinstallé).
- Installe un **accueil épuré** (projet open source [Gathin23/cleanyourtv](https://github.com/Gathin23/cleanyourtv)) avec Netflix, YouTube, Disney+ et Prime Video dans le dock.
- Thème **verre dépoli**: boutons du haut en icônes seules, fond d'écran qui change **jour / nuit** selon le soleil.
- **Écran de veille**: grande horloge + date centrées sur le fond.
- **Sauvegarde automatique** avant toute modification, et un script pour **tout remettre comme avant**.

Le **Play Store**, Chromecast et AirPlay restent disponibles.

## Avant de commencer
1. L'ordinateur (Mac) et la télé sont sur le **même Wi-Fi**.
2. Sur la télé: Réglages > Système > À propos > clique 7 fois sur **Build** pour activer le mode développeur. Puis Réglages > Système > Options pour les développeurs > active le **Débogage réseau** (ou Débogage USB).
3. Note l'**adresse IP** de la télé: Réglages > Réseau > ton Wi-Fi > Adresse IP.
4. Installe [Homebrew](https://brew.sh) si tu ne l'as pas.

## Installation
```bash
git clone https://github.com/NoamAssayag/tcl-googletv-liquid-glass.git
cd tcl-googletv-liquid-glass
./setup.sh 192.168.1.50          # remplace par l'IP de ta télé
```
- Une fenêtre « Autoriser le débogage » apparaît sur la télé: accepte (coche « toujours autoriser »).
- Le script demande confirmation avant les étapes importantes (`-y` pour tout accepter).
- Pour que le fond change avec le **lever et le coucher du soleil de ta ville**, ajoute ta position:
  ```bash
  LAT=48.85 LON=2.35 ./setup.sh 192.168.1.50      # exemple: Paris
  ```
  Sans position, le lanceur utilise 7 h et 18 h 30.
- La première compilation prend quelques minutes.

## Personnaliser
- **Apps du dock**: modifie la liste `dock_apps` dans `theme/config.json` (et dans `setup.sh`), puis relance.
- **Fonds d'écran**: dépose tes propres `jour.jpg` et `nuit.jpg` (1920×1080, plutôt sombres) dans `theme/wallpapers/`. Sinon, des fonds dégradés sont générés.
- **Apps à désactiver**: édite `debloat-tcl.txt` (un `#` devant une ligne = on la garde).
- Autres options du thème: voir la [documentation du thème](https://github.com/Gathin23/cleanyourtv/blob/main/themes/README.md).

## Tout remettre comme avant
```bash
./restore.sh 192.168.1.50
```
Il réactive les apps, remet l'ancien accueil, retire le thème et le lanceur, et rétablit les animations et l'écran de veille d'origine. Redémarre ensuite la télé.
Avant une **revente**, fais en plus une réinitialisation d'usine (Réglages > Système > À propos > Réinitialiser).

Les sauvegardes sont dans `backup-…/`: **garde-les et ne les publie jamais** (infos propres à ta télé).

## Limites à connaître
- Liste d'apps établie pour un **TCL 65C845**; d'autres modèles ont d'autres noms de paquets: les absents sont ignorés, mais vérifie `debloat-tcl.txt`.
- La télé a peu de RAM (≈ 2,4 Go): les apps restent lentes à s'ouvrir si le Wi-Fi est en **2,4 GHz**; préfère le **5 GHz** ou l'Ethernet.
- Le fond de nuit n'est pas progressif: l'image change d'un coup.
- Un navigateur ou xCloud ne sont pas installés par ce kit.

## Sécurité
- Les paquets sont désactivés pour l'utilisateur 0 seulement (`pm disable-user`), jamais supprimés.
- Pense à **désactiver le débogage réseau** sur la télé une fois terminé.
- Le kit récupère le code du lanceur sur le dépôt d'origine, à une version précise (voir `lib.sh`).

Licence MIT (voir `LICENSE`). Le lanceur est © Gathin, licence MIT.

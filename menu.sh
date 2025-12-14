#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

games=(
  "1|Mastermind|mastermind.sh"
  "2|Le Pendu|pendu.sh"
  "3|Le Puissance 4|puissance4.sh"
  "4|Snake|snake.sh"
  "5|Labyrinth|labyrinthe.sh"
  "6|Simon|simon.sh"
  "7|Memory|memory.sh"
)

cleanup() {
  # restore cursor on exit
  tput cnorm 2>/dev/null || true
}
trap cleanup EXIT

draw_header() {
  clear
  # hide cursor
  tput civis 2>/dev/null || true

  # ASCII art title (simple)
  printf "\e[1;36m"
  cat <<'EOF'
   ___    ____   ____   ____   ____   _____
  / _ \  / ___| / ___| / ___| / ___| | ____|
 | | | || |     \___ \| |     \___ \ |  _|
 | |_| || |___   ___) | |___   ___) || |___
  \__\_\ \____| |____/ \____| |____/ |_____|
EOF
  printf "\e[0m"
  echo "==============================================="
  printf "   \e[1;33mMenu jeux d'arcade\e[0m   -   Dossier: %s\n" "$script_dir"
  echo "==============================================="
}

run_game() {
  local file="$1"
  local path="$script_dir/$file"
  if [[ -f "$path" ]]; then
    # clear screen before launching the game (requirement)
    clear
    echo "Lancement de $(basename "$file")..."
    if [[ -x "$path" ]]; then
      "$path"
    else
      bash "$path"
    fi
    return $?
  else
    echo "Fichier '$file' introuvable dans $script_dir."
    return 2
  fi
}

while true; do
  draw_header

  # list games with presence indicator
  for g in "${games[@]}"; do
    IFS='|' read -r num name file <<< "$g"
    if [[ -f "$script_dir/$file" ]]; then
      printf "  %s) %s\n" "$num" "$name"
    else
      printf "  %s) %s \e[1;31m(ABSENT)\e[0m\n" "$num" "$name"
    fi
  done
  echo "  q) Quitter"
  echo
  read -r -p $'Votre choix : ' choice

  case "$choice" in
    q|Q) echo "Au revoir."; exit 0 ;;
    1|2|3|4|5|6|7)
      for g in "${games[@]}"; do
        IFS='|' read -r num name file <<< "$g"
        if [[ "$num" == "$choice" ]]; then
          # if missing, inform and return to menu
          if [[ ! -f "$script_dir/$file" ]]; then
            echo
            echo "Le jeu '$name' est introuvable. Appuyez sur Entrée pour revenir au menu."
            read -r _
            break
          fi

          while true; do
            run_game "$file"
            echo
            read -r -p $'Rejouer (r), Retour au menu (m) ou Quitter (q) ? [r/m/q] : ' ans
            case "$ans" in
              r|R) continue ;;
              m|M) break ;;
              q|Q) exit 0 ;;
              *) echo "Réponse invalide." ;;
            esac
          done
          break
        fi
      done
      ;;
    *) echo "Choix invalide. Appuyez sur Entrée pour continuer."; read -r _ ;;
  esac
done

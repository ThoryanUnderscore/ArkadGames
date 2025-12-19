#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCOREFILE="$script_dir/simon_scores.txt"

declare -A COLORS
COLORS[1]='\033[31m' # Red
COLORS[2]='\033[32m' # Green
COLORS[3]='\033[34m' # Blue
COLORS[4]='\033[33m' # Yellow
COLORS[5]='\033[35m' # Magenta
COLORS[6]='\033[36m' # Cyan
COLORS[7]='\033[91m' # Bright Red
COLORS[8]='\033[92m' # Bright Green
COLORS[9]='\033[94m' # Bright Blue
RESET='\033[0m'

usage() {
  echo "Usage: $0 [--delay N]" >&2
  echo "  --delay N   seconds to show each digit (default 1.0)" >&2
  exit 1
}

DELAY=1.0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --delay) shift; [[ $# -eq 0 ]] && usage; DELAY=$1; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option $1" >&2; usage ;;
  esac
done

clear_screen() { clear; }

print_intro() {
  printf "\e[1;36m"
  cat <<EOF
 #####  ### #     # ####### #     # 
#     #  #  ##   ## #     # ##    # 
#        #  # # # # #     # # #   # 
 #####   #  #  #  # #     # #  #  # 
      #  #  #     # #     # #   # # 
#     #  #  #     # #     # #    ## 
 #####  ### #     # ####### #     # 
EOF
  printf "\e[0m\n"
  echo "Simon - Memory Game (Bash)"
  echo "Digits: 1..9. Type 'q' to quit."
  echo "Press Enter to start..."
  read -r
}

show_sequence() {
  local -n _seq=$1
  for d in "${_seq[@]}"; do
    clear_screen
    printf "%b%s%b\n" "${COLORS[$d]}" "$d" "$RESET"
    sleep "$DELAY"
  done
  clear_screen
}

save_score_and_show_top3() {
  local name=$1 score=$2
  touch "$SCOREFILE"
  echo "$name $score" >> "$SCOREFILE"
  sort -k2 -nr "$SCOREFILE" | awk '!seen[$0]++' | head -n 3 > "$SCOREFILE.tmp"
  mv "$SCOREFILE.tmp" "$SCOREFILE"
  echo -e "\n--- Classement Top 3 ---"
  nl -w1 -s") " -ba "$SCOREFILE"
}

# --- Main ---
print_intro
seq=()
round=0

while true; do
  d=$((RANDOM % 9 + 1))
  seq+=("$d")
  round=$((round + 1))

  echo "Round $round - Watch!"
  sleep 0.5
  show_sequence seq

  echo "Round $round - Your turn"
  read -r -p "Sequence: " input
  
  if [[ "${input,,}" == 'q' ]]; then
    echo "Goodbye!"; exit 0
  fi

  # Nettoyage de l'entrée (garde uniquement les chiffres)
  user_val=$(echo "$input" | tr -cd '0-9')
  
  # Construction de la chaîne attendue
  seq_str=$(printf "%s" "${seq[@]}")

  # VERIFICATION : Longueur et Contenu
  if [[ "$user_val" == "$seq_str" ]]; then
    echo "Correct! Next round."
    sleep 0.7
    clear_screen
  else
    # ECHEC : On calcule le score et on propose l'enregistrement
    final_score=$((round - 1))
    echo -e "\nDommage !"
    
    if [[ ${#user_val} -ne $round ]]; then
      echo "Erreur de longueur (Attendu: $round, Reçu: ${#user_val})"
    fi
    
    echo "Attendu : $seq_str"
    echo "Reçu    : $user_val"
    echo "Score final : $final_score"

    read -r -p "Votre nom (max 10 char) pour le top 3: " pname
    if [[ -n "$pname" ]]; then
      pname=$(echo "$pname" | tr -cd '[:alnum:]' | cut -c1-10)
      save_score_and_show_top3 "$pname" "$final_score"
    fi
    echo "Merci d'avoir joué !"
    exit 0
  fi
done

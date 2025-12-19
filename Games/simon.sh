#!/usr/bin/env bash
set -euo pipefail

# Simon game in Bash: digits 1..9, show colored digits, record Top-3 scores

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

# default delay
DELAY=1.0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --delay)
      shift
      if [[ $# -eq 0 ]]; then usage; fi
      DELAY=$1
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option $1" >&2; usage
      ;;
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
  echo "Digits: 1..9 (colors). Type 'q' to quit at any prompt."
  echo "Delay between flashes: $DELAY seconds."
  echo "Press Enter to start..."
  read -r
}

print_colored_digit() {
  local d=$1
  printf "%b%s%b" "${COLORS[$d]}" "$d" "$RESET"
}

show_sequence() {
  local -n seq=$1
  local delay=${2:-$DELAY}
  for d in "${seq[@]}"; do
    clear_screen
    print_colored_digit "$d"
    echo
    sleep "$delay"
  done
  clear_screen
}

read_user_input() {
  local expected_len=$1
  read -r -p "Repeat the sequence ($expected_len numbers), or 'q' to quit: " input || return 1
  if [[ "${input,,}" == 'q' ]]; then
    return 2
  fi
  # compact digits only
  compact=$(echo "$input" | tr -cd '0-9')
  if [[ ${#compact} -ne $expected_len ]]; then
    echo "Please enter exactly $expected_len digits (1..9). Example: 1 2 3 or 123"
    return 1
  fi
  if [[ ! "$compact" =~ ^[1-9]+$ ]]; then
    echo "Digits must be 1..9."
    return 1
  fi
  REPLY="$compact"
  return 0
}

save_score_and_show_top3() {
  local name=$1
  local score=$2
  # Ensure file exists
  touch "$SCOREFILE"
  # append name and score
  echo "$name $score" >> "$SCOREFILE"
  # sort desc by score (second column), keep top 3
  sort -k2 -nr "$SCOREFILE" | awk '!seen[$0]++' | head -n 3 > "$SCOREFILE.tmp"
  mv "$SCOREFILE.tmp" "$SCOREFILE"
  echo
  echo "Classement Top 3:"
  nl -w1 -s") " -ba "$SCOREFILE"
}

# Main
print_intro

seq=()
round=0
while true; do
  # add digit 1..9
  d=$((RANDOM % 9 + 1))
  seq+=("$d")
  round=$((round + 1))

  clear_screen
  echo "Round $round - Watch!"
  sleep 0.5
  show_sequence seq "$DELAY"

  # prompt user
  echo "Round $round - Your turn"
  while true; do
    read_user_input $round
    res=$?
    if [[ $res -eq 2 ]]; then
      echo "Goodbye!"
      exit 0
    elif [[ $res -eq 1 ]]; then
      # invalid entry; re-prompt
      continue
    else
      # REPLY contains compact digits
      break
    fi
  done

  user=$REPLY
  # join seq into a string
  seq_str=""
  for x in "${seq[@]}"; do seq_str+="$x"; done

  if [[ "$user" == "$seq_str" ]]; then
    echo "Correct! Next round."
    sleep 0.7
    clear_screen
    continue
  else
    final_score=$((round - 1))
    echo "Incorrect."
    # print expected with spaces
    expected=""
    for x in "${seq[@]}"; do expected+="$x "; done
    echo "Expected: $expected"
    # print what user wrote spaced
    user_spaced=$(echo "$user" | sed 's/./& /g')
    echo "You wrote: $user_spaced"
    echo "Final score: $final_score"

    read -r -p "Entrez votre nom (max 5 char) pour le classement, ou vide pour ignorer: " pname
    if [[ -n "$pname" ]]; then
      # sanitize to alnum and truncate
      pname=$(echo "$pname" | tr -cd '[:alnum:]' | cut -c1-5)
      save_score_and_show_top3 "$pname" "$final_score"
    fi

    echo "Merci d'avoir joué !"
    exit 0
  fi

done

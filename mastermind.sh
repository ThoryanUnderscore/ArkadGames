#!/usr/bin/env bash
# Mastermind en Bash
# Couleurs disponibles (initiales) :
# B = bleu, J = jaune, V = vert, R = rouge, G = gris, W = blanc,
# N = noir, M = marron, C = cyan, O = orange
# Usage: bash ./mastermind.sh

ROWS=1  # pas utilisé mais conservé pour clarté
COLS=1

# configuration
MAX_ATTEMPTS=10
SIZE=4

declare -a COLORS_INITS=(B J V R C O)
declare -A COLOR_NAMES
COLOR_NAMES=(
  [B]="Bleu" [J]="Jaune" [V]="Vert" [R]="Rouge" [C]="Cyan" [O]="Orange"
)

# ANSI color codes (may require terminal supporting ANSI / 256 colors)
declare -A COLOR_CODE
COLOR_CODE=(
  [B]="\e[34m"        # blue
  [J]="\e[33m"        # yellow
  [V]="\e[32m"        # green
  [R]="\e[31m"        # red
  [C]="\e[36m"        # cyan
  [O]="\e[38;5;208m"  # orange (256 color code; may fallback to default if unsupported)
)
RESET="\e[0m"

# pick a random combination (with duplicates)
pick_secret() {
  SECRET=()
  for ((i=0;i<SIZE;i++)); do
    idx=$((RANDOM % ${#COLORS_INITS[@]}))
    SECRET+=("${COLORS_INITS[idx]}")
  done
}

# print a guess as colored stars according to initials
print_colored_guess() {
  local -n arr=$1
  local out=""
  for ch in "${arr[@]}"; do
    local code="${COLOR_CODE[$ch]}"
    if [[ -z "$code" ]]; then code="$RESET"; fi
    out+="${code}★${RESET} "
  done
  echo -e "$out"
}

# validate input, accept either "B J V R" or "BJV R" or "BJV R" etc.
normalize_and_validate() {
  local raw="$1"
  # remove spaces and non letters, uppercase
  raw="${raw//[^a-zA-Z]/}"
  raw="${raw^^}"
  if [[ ${#raw} -ne $SIZE ]]; then
    return 1
  fi
  # split into array of chars
  guess=()
  for ((i=0;i<SIZE;i++)); do
    guess+=("${raw:i:1}")
  done
  # validate initials
  for ch in "${guess[@]}"; do
    if [[ -z "${COLOR_NAMES[$ch]}" ]]; then
      return 1
    fi
  done
  return 0
}

# compute feedback: blacks = right color+position, whites = right color wrong position
feedback() {
  local -n secret=$1
  local -n guessarr=$2

  # count exact matches
  blacks=0
  for ((i=0;i<SIZE;i++)); do
    if [[ "${guessarr[i]}" == "${secret[i]}" ]]; then
      ((blacks++))
    fi
  done

  # count occurrences per color in secret and guess
  declare -A count_secret
  declare -A count_guess
  for ch in "${COLORS_INITS[@]}"; do
    count_secret[$ch]=0
    count_guess[$ch]=0
  done
  for ((i=0;i<SIZE;i++)); do
    ((count_secret[${secret[i]}]++))
    ((count_guess[${guessarr[i]}]++))
  done

  # total matches (color regardless of position) = sum min(count_secret[color], count_guess[color])
  total_matches=0
  for ch in "${COLORS_INITS[@]}"; do
    a=${count_secret[$ch]}
    b=${count_guess[$ch]}
    if ((a < b)); then
      ((total_matches += a))
    else
      ((total_matches += b))
    fi
  done

  whites=$((total_matches - blacks))
}

# reveal secret as colored stars plus initials
reveal_secret() {
  local -n s=$1
  local out=""
  for ch in "${s[@]}"; do
    local code="${COLOR_CODE[$ch]}"
    out+="${code}★${RESET}(${ch}) "
  done
  echo -e "$out"
}

# start game

printf "\e[1;36m"
cat <<'EOF'
#     #    #     #####  ####### ####### ######  #     # ### #     # ######  
##   ##   # #   #     #    #    #       #     # ##   ##  #  ##    # #     # 
# # # #  #   #  #          #    #       #     # # # # #  #  # #   # #     # 
#  #  # #     #  #####     #    #####   ######  #  #  #  #  #  #  # #     # 
#     # #######       #    #    #       #   #   #     #  #  #   # # #     # 
#     # #     # #     #    #    #       #    #  #     #  #  #    ## #     # 
#     # #     #  #####     #    ####### #     # #     # ### #     # ######                                                                      
EOF  
  printf "\e[0m\n"
echo "Mastermind - Devinez la combinaison de 4 couleurs (doublons autorisés)."
echo "Initiales disponibles:"
for ch in "${COLORS_INITS[@]}"; do
  printf " %s:%s%s%s" "$ch" "${COLOR_NAMES[$ch]}"
done
echo
echo
echo "Entrez 4 initiales (ex: B J V R ou BJV R ou BJVR). Tapez 'q' pour abandonner."

pick_secret
# Uncomment to debug reveal secret:
# echo "DEBUG secret: ${SECRET[*]}"

attempt=1
while (( attempt <= MAX_ATTEMPTS )); do
  echo
  echo "Essai $attempt / $MAX_ATTEMPTS - Entrez votre proposition :"
  read -r raw_input
  if [[ "${raw_input,,}" == "q" ]]; then
    echo "Abandon. La combinaison était :"
    reveal_secret SECRET
    exit 0
  fi

  if ! normalize_and_validate "$raw_input"; then
    echo "Entrée invalide. Fournissez exactement 4 initiales valides (ex: BJVR)."
    continue
  fi

  # show colored guess
  echo -n "Votre proposition : "
  print_colored_guess guess
  feedback SECRET guess

  # show feedback (black and white pegs)
  echo -n "Résultat : "
  # print blacks as filled circles in black, whites as empty circles
  for ((i=0;i<blacks;i++)); do printf "● "; done
  for ((i=0;i<whites;i++)); do printf "○ "; done
  if (( blacks == 0 && whites == 0 )); then printf "(aucune correspondance)"; fi
  echo

  if (( blacks == SIZE )); then
    echo
    echo "Félicitations ! Vous avez trouvé la combinaison en $attempt essais."
    echo -n "Combinaison : "
    reveal_secret SECRET
    exit 0
  fi

  ((attempt++))
done

echo
echo "Désolé, vous avez utilisé tous vos essais. La combinaison était :"
reveal_secret SECRET
exit 0

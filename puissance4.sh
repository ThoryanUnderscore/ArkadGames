#!/usr/bin/env bash
set -euo pipefail

# Simple Puissance 4 jouable en terminal : Vous (X) vs Ordinateur (O)
# Ecran effacé au lancement, interface simple et utilisable.

ROWS=6
COLS=7
EMPTY='.'
PLAYER='X'
CPU='O'
board=()

init_board() {
  board=()
  for ((r=0; r<ROWS; r++)); do
    for ((c=0; c<COLS; c++)); do
      board+=("$EMPTY")
    done
  done
}

idx() { echo $(( $1 * COLS + $2 )); }

cell() {
  local r=$1 c=$2
  echo "${board[$(idx "$r" "$c")]}"
}

set_cell() {
  local r=$1 c=$2 v=$3
  board[$(idx "$r" "$c")]="$v"
}

clear_screen() { clear; }

draw_header() {
  printf "\e[1;36m"
  cat <<EOF
######  #     # ###  #####   #####     #    #     #  #####  #######    #       
#     # #     #  #  #     # #     #   # #   ##    # #     # #          #    #  
#     # #     #  #  #       #        #   #  # #   # #       #          #    #  
######  #     #  #   #####   #####  #     # #  #  # #       #####      #    #  
#       #     #  #        #       # ####### #   # # #       #          ####### 
#       #     #  #  #     # #     # #     # #    ## #     # #               #  
#        #####  ###  #####   #####  #     # #     #  #####  #######         #  
                                                                             
EOF
  printf "\e[0m\n"
}

draw_board() {
  clear_screen
  draw_header
  printf "  Vous: %s    Ordinateur: %s\n\n" "$PLAYER" "$CPU"
  # Affiche numéros de colonne alignés avec les cellules
  for ((c=1;c<=COLS;c++)); do printf " [%d]" "$c"; done
  echo
  for ((r=0;r<ROWS;r++)); do
    for ((c=0;c<COLS;c++)); do
      printf " [%s]" "$(cell "$r" "$c")"
    done
    echo
  done
  echo
}

drop_piece() {
  local col=$1 sym=$2
  for ((r=ROWS-1;r>=0;r--)); do
    if [[ "$(cell $r $col)" == "$EMPTY" ]]; then
      set_cell $r $col "$sym"
      echo $r
      return 0
    fi
  done
  return 1
}

undo_drop() {
  local col=$1
  for ((r=0;r<ROWS;r++)); do
    if [[ "$(cell $r $col)" != "$EMPTY" ]]; then
      set_cell $r $col "$EMPTY"
      return 0
    fi
  done
  return 1
}

check_win_for() {
  local sym=$1 r c k
  # horizontal
  for ((r=0;r<ROWS;r++)); do
    for ((c=0;c<=COLS-4;c++)); do
      local ok=1
      for ((k=0;k<4;k++)); do
        [[ "$(cell $r $((c+k)))" == "$sym" ]] || { ok=0; break; }
      done
      (( ok )) && return 0
    done
  done
  # vertical
  for ((c=0;c<COLS;c++)); do
    for ((r=0;r<=ROWS-4;r++)); do
      local ok=1
      for ((k=0;k<4;k++)); do
        [[ "$(cell $((r+k)) $c)" == "$sym" ]] || { ok=0; break; }
      done
      (( ok )) && return 0
    done
  done
  # diag down-right
  for ((r=0;r<=ROWS-4;r++)); do
    for ((c=0;c<=COLS-4;c++)); do
      local ok=1
      for ((k=0;k<4;k++)); do
        [[ "$(cell $((r+k)) $((c+k)))" == "$sym" ]] || { ok=0; break; }
      done
      (( ok )) && return 0
    done
  done
  # diag up-right
  for ((r=3;r<ROWS;r++)); do
    for ((c=0;c<=COLS-4;c++)); do
      local ok=1
      for ((k=0;k<4;k++)); do
        [[ "$(cell $((r-k)) $((c+k)))" == "$sym" ]] || { ok=0; break; }
      done
      (( ok )) && return 0
    done
  done
  return 1
}

# Corrigée : retourne 0 (vrai) seulement si toutes les colonnes sont pleines.
is_full() {
  for ((c=0;c<COLS;c++)); do
    if [[ "$(cell 0 $c)" == "$EMPTY" ]]; then
      return 1  # pas plein
    fi
  done
  return 0  # plein
}

# IA basique : victoire immédiate, bloquer joueur, sinon centre/aleatoire
ai_move() {
  local col r valid=()
  for ((col=0;col<COLS;col++)); do
    if [[ "$(cell 0 $col)" == "$EMPTY" ]]; then
      valid+=("$col")
    fi
  done

  # 1) victoire immédiate
  for col in "${valid[@]}"; do
    drop_piece "$col" "$CPU" >/dev/null || continue
    if check_win_for "$CPU"; then
      return 0
    fi
    undo_drop "$col"
  done

  # 2) bloquer victoire du joueur
  for col in "${valid[@]}"; do
    drop_piece "$col" "$PLAYER" >/dev/null || continue
    if check_win_for "$PLAYER"; then
      undo_drop "$col"
      drop_piece "$col" "$CPU" >/dev/null
      return 0
    fi
    undo_drop "$col"
  done

  # 3) centre, puis voisins, sinon aléatoire
  local order=(3 2 4 1 5 0 6)
  for c in "${order[@]}"; do
    for v in "${valid[@]}"; do
      if [[ "$v" -eq "$c" ]]; then
        drop_piece "$v" "$CPU" >/dev/null
        return 0
      fi
    done
  done

  if [[ ${#valid[@]} -gt 0 ]]; then
    drop_piece "${valid[RANDOM % ${#valid[@]}]}" "$CPU" >/dev/null
    return 0
  fi
  return 1
}

player_move() {
  local input col
  while true; do
    read -r -p $'Votre colonne (1-7) ou q pour abandonner : ' input
    if [[ "$input" =~ ^[Qq]$ ]]; then return 2; fi
    if ! [[ "$input" =~ ^[1-7]$ ]]; then
      echo "Entrée invalide."
      continue
    fi
    col=$((input-1))
    if [[ "$(cell 0 $col)" != "$EMPTY" ]]; then
      echo "Colonne pleine."
      continue
    fi
    drop_piece "$col" "$PLAYER" >/dev/null
    return 0
  done
}

main_loop() {
  init_board
  clear_screen
  local turn=0  # 0 = joueur, 1 = cpu
  while true; do
    draw_board
    if (( turn == 0 )); then
      player_move
      local res=$?
      if [[ $res -eq 2 ]]; then echo "Vous avez ragequit."; return 0; fi
      if check_win_for "$PLAYER"; then
        draw_board
        printf "\e[1;32mVous gagnez !\e[0m\n"
        return 0
      fi
    else
      echo "Ordinateur joue..."
      sleep 0.3
      ai_move
      if check_win_for "$CPU"; then
        draw_board
        printf "\e[1;31mL'ordinateur gagne.\e[0m\n"
        return 0
      fi
    fi

    if is_full; then
      draw_board
      printf "\e[1;33mMatch nul.\e[0m\n"
      return 0
    fi

    turn=$((1-turn))
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main_loop
fi

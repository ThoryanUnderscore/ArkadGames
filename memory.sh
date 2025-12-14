#!/usr/bin/env bash
set -euo pipefail

# memory.sh - Bash port of memory.py
# Controls: a (left), z (right), e (flip), r (restart), q (quit)

SCOREFILE="memory_scores.txt"

# Couleurs ANSI (use $'...' so variables contain real escape bytes)
GREEN=$'\033[0;32m'
CYAN=$'\033[0;36m'
RESET=$'\033[0m'


clear_screen() {
    # Use printf with format string to interpret \033 escapes
    printf "\033[2J\033[H"
}

make_deck() {
    local pairs=${1:-8}
    if (( pairs > 26 )); then
        echo "pairs must be <= 26" >&2
        exit 1
    fi
    deck=()
    for ((i=0;i<pairs;i++)); do
        ch=$(printf "\x$(printf "%x" $((65 + i)))")
        deck+=("$ch")
        deck+=("$ch")
    done
    # shuffle
    for ((i=${#deck[@]}-1;i>0;i--)); do
        j=$((RANDOM % (i+1)))
        tmp=${deck[i]}
        deck[i]=${deck[j]}
        deck[j]=$tmp
    done
}

draw_board() {
    local cols=${1:-8}
    local status=${2:-}
    clear_screen
    local n=${#deck[@]}
    local rows=$(((n + cols - 1) / cols))
    for ((r=0;r<rows;r++)); do
        line=""
        for ((c=0;c<cols;c++)); do
            idx=$((r*cols+c))
            if (( idx >= n )); then
                break
            fi
            if [[ ${matched[idx]:-0} -eq 1 || ${revealed[idx]:-0} -eq 1 ]]; then
                face=${deck[idx]}
            else
                face='?'
            fi
            # Use fixed-width tokens [A] or [?]
            token_body="[${face}]"
            if (( idx == cursor )); then
                token="${CYAN}${token_body}${RESET}"  # curseur en cyan
            elif [[ ${matched[idx]:-0} -eq 1 ]]; then
                token="${GREEN}${token_body}${RESET}" # cartes déjà trouvées en vert
            else
                token="$token_body"                    # cartes fermées normales
            fi

            line+="$token"
        done
        # Use %b so any escape sequences are interpreted
        printf "%b\n" "$line"
    done
    printf "\nUse a (left), z (right), e (flip), r (restart), q (quit)\n"
    printf "Matched: %d/%d\n" ${#matched[@]} ${#deck[@]}
    if [[ -n "$status" ]]; then
        printf "%s\n" "$status"
    fi
}

save_score() {
    local name="$1"
    local seconds="$2"
    name=${name^^}
    name=${name:0:5}
    printf "%s %.2f\n" "$name" "$seconds" >> "$SCOREFILE"
}

top_scores() {
    if [[ ! -f "$SCOREFILE" ]]; then
        return
    fi
    sort -n -k2 "$SCOREFILE" | head -n 3
}

play() {
    local pairs=${1:-8}
    local cols=${2:-8}
    make_deck "$pairs"
    revealed=()
    matched=()
    cursor=0
    first=-1
    start_time=0
    status=""
    while true; do
        draw_board "$cols" "$status"
        # check matched count
        local matched_count=0
        for idx in "${!matched[@]}"; do
            ((matched_count++))
        done
        if (( matched_count == ${#deck[@]} )); then
            now=$(date +%s.%N)
            elapsed=$(awk "BEGIN{print $now - $start_time}")
            draw_board "$cols" "All matched! Time: $(printf "%.2f" "$elapsed")s"
            printf "Enter name (max 5 chars): "
            read -r name
            save_score "$name" "$elapsed"
            echo
            echo "Top 3 fastest times:"
            top_scores
            echo
            break
        fi
        # read one key
        read -r -n1 ch
        ch=${ch,,}
        if [[ -z "$ch" ]]; then
            continue
        fi
        if [[ $ch == 'q' ]]; then
            return 1
        fi
        if [[ $ch == 'r' ]]; then
            return 0
        fi
        if [[ $ch == 'a' ]]; then
            cursor=$(( (cursor - 1 + ${#deck[@]}) % ${#deck[@]} ))
            continue
        fi
        if [[ $ch == 'z' ]]; then
            cursor=$(( (cursor + 1) % ${#deck[@]} ))
            continue
        fi
        if [[ $ch == 'e' ]]; then
            if [[ ${matched[cursor]:-0} -eq 1 || ${revealed[cursor]:-0} -eq 1 ]]; then
                continue
            fi
            revealed[cursor]=1
            if [[ $first -lt 0 ]]; then
                first=$cursor
                if (( start_time == 0 )); then
                    start_time=$(date +%s.%N)
                fi
                status=""
                continue
            else
                second=$cursor
                if [[ ${deck[first]} == ${deck[second]} ]]; then
                    matched[$first]=1
                    matched[$second]=1
                    status="Match!"
                    draw_board "$cols" "$status"
                    sleep 0.5
                else
                    status="No match"
                    draw_board "$cols" "$status"
                    sleep 0.8
                    unset revealed[$first]
                    unset revealed[$second]
                fi
                first=-1
                continue
            fi
        fi
    done
}

main() {
    local pairs=8
    local cols=8
    while true; do
        if play "$pairs" "$cols"; then
            continue
        else
            break
        fi
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi

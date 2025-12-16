#!/usr/bin/env bash

RESET="\033[0m"
CYAN="\033[36m"
GREEN="\033[32m"
WHITE="\033[37m"

COLS=6
TOTAL=24

symbols=(A A B B C C D D E E F F G G H H I I J J K K L L)
shuf -e "${symbols[@]}" -o symbols

revealed=()
found=()
for i in $(seq 0 $((TOTAL-1))); do
    revealed[$i]=0
    found[$i]=0
done

cursor=0
first=-1
found_count=0

move_cursor() {
    local dir=$1
    local next=$cursor

    while true; do
        if [[ $dir == "left" ]]; then
            ((next--))
            ((next<0)) && next=$((TOTAL-1))
        else
            ((next++))
            ((next>=TOTAL)) && next=0
        fi

        [[ ${found[$next]} -eq 0 ]] && break
    done

    cursor=$next
}

draw() {
    clear
    echo "Memory | a/z = déplacer | e = retourner | q = quitter"
    echo

    for i in $(seq 0 $((TOTAL-1))); do
        if [[ ${found[$i]} -eq 1 ]]; then
            printf "${GREEN}[ %s ]${RESET} " "${symbols[$i]}"
        elif [[ $i -eq $cursor ]]; then
            if [[ ${revealed[$i]} -eq 1 ]]; then
                printf "${CYAN}[ %s ]${RESET} " "${symbols[$i]}"
            else
                printf "${CYAN}[ ? ]${RESET} "
            fi
        else
            if [[ ${revealed[$i]} -eq 1 ]]; then
                printf "${WHITE}[ %s ]${RESET} " "${symbols[$i]}"
            else
                printf "[ ? ] "
            fi
        fi

        (( (i+1) % COLS == 0 )) && echo
    done
}

# placer le curseur sur une carte non trouvée au départ
for i in $(seq 0 $((TOTAL-1))); do
    if [[ ${found[$i]} -eq 0 ]]; then
        cursor=$i
        break
    fi
done

while true; do
    draw
    IFS= read -rsn1 key

    [[ $key == "q" ]] && clear && exit 0

    if [[ $key == "a" ]]; then
        move_cursor "left"

    elif [[ $key == "z" ]]; then
        move_cursor "right"

    elif [[ $key == "e" ]]; then
        [[ ${found[$cursor]} -eq 1 || ${revealed[$cursor]} -eq 1 ]] && continue

        revealed[$cursor]=1

        if [[ $first -eq -1 ]]; then
            first=$cursor
        else
            draw
            sleep 1

            if [[ ${symbols[$first]} == "${symbols[$cursor]}" ]]; then
                found[$first]=1
                found[$cursor]=1
                ((found_count+=2))
            else
                revealed[$first]=0
                revealed[$cursor]=0
            fi

            first=-1

            # auto-skip vers la prochaine carte valide
            if [[ $found_count -lt $TOTAL ]]; then
                for i in $(seq 0 $((TOTAL-1))); do
                    if [[ ${found[$i]} -eq 0 ]]; then
                        cursor=$i
                        break
                    fi
                done
            fi
        fi
    fi

    # Fin automatique du jeu
    if [[ $found_count -eq $TOTAL ]]; then
        clear
        echo "Toutes les paires ont été trouvées 🎉"
        sleep 1
        clear
        exit 0
    fi
done

#!/bin/bash

# Dimensions
WIDTH=20
HEIGHT=10

# Snake
snake_x=(5 4 3)
snake_y=(5 5 5)
dir="RIGHT"

# Food
food_x=0
food_y=0

game_over=0

place_food() {
    food_x=$(( RANDOM % WIDTH ))
    food_y=$(( RANDOM % HEIGHT ))
}

draw() {
    clear
    # top border
    printf "+"
    for ((i=0; i<WIDTH; i++)); do printf "-"; done
    printf "+\n"

    for ((y=0; y<HEIGHT; y++)); do
        printf "|"
        for ((x=0; x<WIDTH; x++)); do
            char=" "
            # food
            if [[ $x -eq $food_x && $y -eq $food_y ]]; then
                char="*"
            fi
            # snake
            for ((i=0; i<${#snake_x[@]}; i++)); do
                if [[ ${snake_x[$i]} -eq $x && ${snake_y[$i]} -eq $y ]]; then
                    char="O"
                fi
            done
            printf "%s" "$char"
        done
        printf "|\n"
    done

    # bottom border
    printf "+"
    for ((i=0; i<WIDTH; i++)); do printf "-"; done
    printf "+\n"
}

move_snake() {
    local head_x=${snake_x[0]}
    local head_y=${snake_y[0]}

    case $dir in
        UP)    ((head_y--));;
        DOWN)  ((head_y++));;
        LEFT)  ((head_x--));;
        RIGHT) ((head_x++));;
    esac

    # Collision mur
    if (( head_x < 0 || head_x >= WIDTH || head_y < 0 || head_y >= HEIGHT )); then
        game_over=1
        return
    fi

    # Collision avec soi-même
    for ((i=0; i<${#snake_x[@]}; i++)); do
        if [[ ${snake_x[$i]} -eq $head_x && ${snake_y[$i]} -eq $head_y ]]; then
            game_over=1
            return
        fi
    done

    # Insert new head
    snake_x=("$head_x" "${snake_x[@]}")
    snake_y=("$head_y" "${snake_y[@]}")

    # Food eaten?
    if [[ $head_x -eq $food_x && $head_y -eq $food_y ]]; then
        place_food
    else
        # Remove tail
        snake_x=("${snake_x[@]:0:${#snake_x[@]}-1}")
        snake_y=("${snake_y[@]:0:${#snake_y[@]}-1}")
    fi
}

read_input() {
    read -rsn1 -t 0.05 key
    case $key in
        z) [[ $dir != "DOWN" ]]  && dir="UP" ;;
        s) [[ $dir != "UP" ]]    && dir="DOWN" ;;
        q) [[ $dir != "RIGHT" ]] && dir="LEFT" ;;
        d) [[ $dir != "LEFT" ]]  && dir="RIGHT" ;;
    esac
}
draw_header() {
  printf "\e[1;36m"
  cat <<'EOF'
 #####  #     #    #    #    # #######     #####     #    #     # ####### 
#     # ##    #   # #   #   #  #          #     #   # #   ##   ## #       
#       # #   #  #   #  #  #   #          #        #   #  # # # # #       
 #####  #  #  # #     # ###    #####      #  #### #     # #  #  # #####   
      # #   # # ####### #  #   #          #     # ####### #     # #       
#     # #    ## #     # #   #  #          #     # #     # #     # #       
 #####  #     # #     # #    # #######     #####  #     # #     # #######                                                                          
EOF  
  printf "\e[0m\n"
}

main() {
    draw_header
    place_food

    while (( game_over == 0 )); do
        draw
        read_input
        move_snake
        sleep 0.1
    done

    clear
    echo "Game Over !"
}

main

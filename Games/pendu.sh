#!/usr/bin/env bash

# ====== Chargement du fichier de mots ======
WORDS_FILE="words.txt"
if [[ ! -f "$WORDS_FILE" ]]; then
    echo "Erreur : fichier '$WORDS_FILE' introuvable."
    exit 1
fi

mapfile -t WORDS < "$WORDS_FILE"
if [[ ${#WORDS[@]} -eq 0 ]]; then
    echo "Erreur : '$WORDS_FILE' est vide."
    exit 1
fi

# ====== Sélection du mot secret ======
SECRET="${WORDS[$((RANDOM % ${#WORDS[@]}))]}"
SECRET="${SECRET,,}"     # minuscules
LEN=${#SECRET}

# ====== Initialisation ======
MAX_WRONG=6
wrong=0
guessed=()
display=()

for ((i=0; i<LEN; i++)); do
    display+=("_")
done

# ====== Hangman ASCII ======
HANGMAN=()
HANGMAN[0]="
  _______
 |/      
 |       
 |       
 |       
 |      
_|___
"
HANGMAN[1]="
  _______
 |/      |
 |      ( )
 |       
 |       
 |      
_|___
"
HANGMAN[2]="
  _______
 |/      |
 |      ( )
 |       |
 |       
 |      
_|___
"
HANGMAN[3]="
  _______
 |/      |
 |      ( )
 |      /|
 |       
 |      
_|___
"
HANGMAN[4]="
  _______
 |/      |
 |      ( )
 |      /|\\
 |       
 |      
_|___
"
HANGMAN[5]="
  _______
 |/      |
 |      ( )
 |      /|\\
 |      / 
 |      
_|___
"
HANGMAN[6]="
  _______
 |/      |
 |      ( )
 |      /|\\
 |      / \\
 |      
_|___
"

# ====== DISPLAY FUNCTION ======
show_game() {
    clear
    echo "${HANGMAN[$wrong]}"
    # Affiche le mot avec un espace entre chaque caractère (plus lisible)
    echo -n "Mot : "
    for ch in "${display[@]}"; do printf "%s " "$ch"; done
    echo ""
    # Lettres tentées (séparées par des espaces)
    if [[ ${#guessed[@]} -gt 0 ]]; then
        echo "Lettres tentées : ${guessed[*]}"
    else
        echo "Lettres tentées : (aucune)"
    fi
    echo "Erreurs : $wrong / $MAX_WRONG"
}

# ====== GAME LOOP ======
while (( wrong < MAX_WRONG )); do
    echo ""
    show_game

    echo -n "Lettre : "
    read -r guess

    # Normalisation
    guess="${guess,,}"
    guess="${guess:0:1}"

    # validation
    if [[ ! "$guess" =~ [a-z] ]]; then
        echo "Entre une lettre valide (a-z)."
        continue
    fi

    # vérifier si déjà tentée (pure Bash, safe)
    already=false
    for x in "${guessed[@]}"; do
        if [[ "$x" == "$guess" ]]; then
            already=true
            break
        fi
    done

    if [[ "$already" == true ]]; then
        echo "Lettre déjà tentée."
        continue
    fi

    guessed+=("$guess")

    # vérifier présence dans le mot
    found=false
    for ((i=0; i<LEN; i++)); do
        if [[ "${SECRET:$i:1}" == "$guess" ]]; then
            display[$i]="$guess"
            found=true
        fi
    done

    if [[ "$found" == false ]]; then
        ((wrong++))
    fi

    # === VICTOIRE (fix) ===
    # Si display ne contient plus de "_" => toutes les lettres trouvées
    if [[ "${display[*]}" != *"_"* ]]; then
        echo ""
        show_game
        echo "✨ Bravo ! Tu as trouvé le mot : $SECRET"
        exit 0
    fi
done

# ====== DEFAITE ======
echo ""
show_game
echo "💀 Perdu... Le mot était : $SECRET"

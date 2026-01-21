CURSOR=2
sorting=0
draw() {
    # clear
    stty -raw echo
    COLUMNS=$(tput cols)
    ROWS=$(tput lines)
    sabs=$(($sorting % 4))
    if [ $(($sorting % 4)) == 0 ]; then sortword="";
    elif [ $(($sorting % 4)) == 1 ]; then sortword="--sort=width";
    elif [ $(($sorting % 4)) == 2 ]; then sortword=-S;
    elif [ $(($sorting % 4)) == 3 ]; then sortword=-t;
    fi
    selected=$(ls -a1 $sortword | sed -n "$((CURSOR+1))"p)
    echo "Selected file: $selected"
    dirorf=$(ls -al $sortword | sed -n "$((CURSOR+2))"p | cut -c1)
    echo "Is a dir: $dirorf"
    # pwd
    # printf ┌; printf '─%.0s' $(seq 1 $((COLUMNS - 2))); printf ┐; printf "\n"
    printf ┌; printf $PWD; printf '─%.0s' $(seq 1 $((COLUMNS - 2 - $(printf $PWD | wc -c)))); printf ┐; printf "\n"
    FILES=$(ls -lha $sortword | cut -d ' ' -f 5-)  # -Gghl
    for i in $(seq 1 $((ROWS - 3))); do
          # [ $i == $CURSOR ]
        if [ $((CURSOR + i)) -lt 1 ]; then printf │; if [ $i == 2 ]; then printf "\033[7m"; fi; printf ' %.0s' $(seq 1 $((COLUMNS - 2))); if [ $i == 2 ]; then printf "\033[0m"; fi; printf │; printf "\n"; continue; fi
        L=$(printf "$FILES" | sed -n "$((CURSOR+i))p")
        printf │; 
        if [ $i == 2 ]; then printf "\033[7m"; fi  # [ $i == $CURSOR ]
        printf "$FILES" | sed -n "$((CURSOR+i))p" | tr -d '\n'; printf ' %.0s' $(seq 1 $((COLUMNS - 2 - ${#L}))); printf "│\n"
        if [ $i == 2 ]; then printf "\033[0m"; fi
    done
    # searchline=🔎︎$searchq
    searchline=${searchq:+🔎︎$searchq}; searchline=${searchline:-─}
    printf └; printf $searchline; printf '─%.0s' $(seq 1 $((COLUMNS -2 - $(printf $searchline | wc -m)))); printf ┘; printf "\n"
    printf " \033[7mF1\033[0m Help  \033[7mF2\033[0m Menu  \033[7mF3\033[0m View  \033[7mF4\033[0m Edit  \033[7mF5\033[0m Copy  \033[7mF6\033[0m Move  \033[7mF7\033[0m New  \033[7mF8\033[0m Delete  \033[7mF9\033[0m Pull  \033[7mF10\033[0m Quit"

    stty raw -echo
    key=''
    # echo q | read
    # echo awarting read
    read -r -n 1 -s -p "" key
    printf ">$key<\n\r"
    # printf $key | hexdump -C
    # echo TTT
    # Special cases:
    if [ "$key" = '' ]; then
        # echo "ENTER"
        notify-send "ENT"
    elif [ "$key" = '~' ]; then
        # getting rid of a weird bug that causes 
        # `read` being activated with remainants
        # of last key press instead of waitng.
        draw
    elif [[ ${#key} == 1 && "$key" =~ ^[[:graph:]]$ ]]; then
        # Is a single char for 🔎︎
        :
    elif [ $key = $'\x7f' ]; then
        # notify-send "BACKSPACE"
        # label-01
        searchq="${searchq%?}"
        draw
    # elif [ $key == $'\x1b' ]; then
    #     notify-send "ESC"
    #     stty -raw echo
    #     exit
    else
        key=$(dd bs=1 count=2 2>/dev/null)
    fi
    # printf ">>$key<<\n\r"
    if [ "$key" = '[B' ]; then
        printf "DOWN\n\r"
        CURSOR=$((CURSOR + 1))
        draw
        notify-send "continued"
    elif [ "$key" = '[A' ]; then
        echo "UP"
        CURSOR=$((CURSOR - 1))
        draw
    elif [ "$key" == '[C' ]; then
        echo "RIGHT"
        ((sorting++))
        draw
    elif [ "$key" == '[D' ]; then
        echo "LEFT"
        ((sorting--))
        draw
    elif [ "$key" == '[5' ]; then
        echo "PGUP"
        CURSOR=$((CURSOR - ROWS + 5))
        draw
    elif [ "$key" == '[6' ]; then
        echo "PGDN"
        notify-send "PGDN"
        CURSOR=$((CURSOR + ROWS - 5))
        draw
        notify-send "continued???"
    elif [ "$key" = '' ]; then
        # echo "ENTER"
        # notify-send "$dirorf"
        if [ "$dirorf" = 'd' ]; then
            cd "$selected"
            draw
        else
            # echo "-----"
            showmenu
        fi
    elif [ $key == $'\x1b[2~' ]; then
        echo "F2"
    elif [ $key == 'OR' ]; then
        echo "F3"
        if [[ $string =~ [tT]ext ]]; then
            less --prompt="🭪 Press q to exit, arrows to scroll 🭨🭪 %l / %L 🭨" -N "$selected"
        else
            hexdump -C "$selected" | less --prompt="🭪 Press q to exit, arrows to scroll 🭨🭪 %l / %L 🭨" -N
        fi
        draw
    elif [ $key == $'\x1b[4~' ]; then
        echo "F4"
    elif [ $key == $'\x1b[5~' ]; then
        echo "F5"
    elif [ $key == $'\x1b[6~' ]; then
        echo "F6"
    elif [ $key == $'\x1b[7~' ]; then
        echo "F7"
    elif [ $key == $'\x1b[8~' ]; then
        echo "F8"
    elif [ $key == $'\x1b[9~' ]; then
        echo "F9"
    elif [ $key == $'\x1b[10~' ]; then
        echo "F10"
    elif [ $key == $'' ]; then
        echo "ESC"
        exit
    else
        # Input was a search query
            # bs
            # handled in label-01
        searchq=$searchq$key
        files1c="$(ls -a1 $sortword)"
        # echo "$files1c" | less
        line_number=$(awk "/^${searchq}/{print NR; exit}" <<< "$files1c")
        # [ -z "$line_number" ] && echo "No line starts with '${searchq}'" || echo "First line starting with 'xyz': $line_number"
        CURSOR=$((line_number-1))
        # notify-send "$searchq; $key"
        draw
    fi
    stty -raw echo
}

showmenu() {
    stty -raw echo
    clear
    selected=$(echo "$FILES" | sed -n "$((CURSOR+1))p")
    printf ┌; printf '─%.0s' $(seq 1 $((COLUMNS - 2))); printf ┐; printf "\n"
    printf │; printf "Open with..."; printf ' %.0s' $(seq 1 $((COLUMNS - 14))); printf │; printf "\n"
    printf │; printf "Move to..."; printf ' %.0s' $(seq 1 $((COLUMNS - 12))); printf │; printf "\n"
    printf │; printf "Copy to..."; printf ' %.0s' $(seq 1 $((COLUMNS - 12))); printf │; printf "\n"
    printf │; printf "Rename"; printf ' %.0s' $(seq 1 $((COLUMNS - 8))); printf │; printf "\n"
    printf │; printf "Create link"; printf ' %.0s' $(seq 1 $((COLUMNS - 13))); printf │; printf "\n"
    printf │; printf "Compress"; printf ' %.0s' $(seq 1 $((COLUMNS - 10))); printf │; printf "\n"
    printf │; printf "Delete"; printf ' %.0s' $(seq 1 $((COLUMNS - 8))); printf │; printf "\n"
    printf └; printf '─%.0s' $(seq 1 $((COLUMNS - 2))); printf ┘; printf "\n"
}

draw
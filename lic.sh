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
    elif [ $(($sorting % 4)) == 2 ]; then sortword=-S;  # size
    elif [ $(($sorting % 4)) == 3 ]; then sortword=-t;  # time
    fi
    # overwrite list w/ passed
    if [ -z "$1" ]; then
        notify-send "qwf$1"
        list=$(ls -hal $sortword)
        list1=$(ls -a1 $sortword)
    else
        list="$1"
        list1="$1"
        draw_overwritten="$1"
    fi
    echo "list: $list, list1: $list1"
    selected=$(printf "$list1" | sed -n "$((CURSOR+1))"p)
    # selected=$(ls -a1 $sortword | sed -n "$((CURSOR+1))"p)
    echo "Selected file: $selected"
    dirorf=$(printf "$list" | sed -n "$((CURSOR+2))"p | cut -c1)
    echo "Is a dir: $dirorf"
    # pwd
    # printf ┌; printf '─%.0s' $(seq 1 $((COLUMNS - 2))); printf ┐; printf "\n"
    printf ┌; printf $PWD; printf '─%.0s' $(seq 1 $((COLUMNS - 2 - $(printf $PWD | wc -c)))); printf ┐; printf "\n"
    FILES=$(printf "$list" | cut -d ' ' -f 5-)  # -Gghl
    for i in $(seq 1 $((ROWS - 3))); do
          # [ $i == $CURSOR ]
        if [ $((CURSOR + i)) -lt 1 ]; then printf │; if [ $i == 2 ]; then printf "\033[7m"; fi; printf ' %.0s' $(seq 1 $((COLUMNS - 2))); if [ $i == 2 ]; then printf "\033[0m"; fi; printf │; printf "\n"; continue; fi
        L=$(printf "$FILES" | sed -n "$((CURSOR+i))p")
        printf │; 
        if [ $i == 2 ]; then printf "\033[7m"; fi  # [ $i == $CURSOR ]
        printf "$L" | tr -d '\n'; printf ' %.0s' $(seq 1 $((COLUMNS - 2 - ${#L}))); printf "│\n"
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
    # read -r -n 1 -s -p "" key

    saved_tty_settings=$(stty -g)
    stty -icanon -echo -isig min 100 time 1 -istrip
    set -- $(dd bs=100 count=1 2> /dev/null | od -vAn -to1)
    stty "$saved_tty_settings" # restore

    printf "| $1, $2, $3, $4, $5, $6 |"
    printf ">$1<\n\r"
    # printf $key | hexdump -C

    if [ "$1" = '015' ] || [ "$1$2$3" = '033117121' ]; then
        # ENTER / F2
        echo "ENTER; CURSOR: $CURSOR"

        if [ -z "$draw_overwritten" ]; then
            # file or dir is selected
            if [ "$dirorf" = 'd' ] && [ "$selected" != "." ]; then
                cd "$selected"
                # notify-send "III"
                draw
            else

                # Are we selecting a file for an action?
                if [ -n "$moving" ]; then
                    echo "moving: $moving"
                    mv "$moving" "$PWD"
                    unset moving
                    draw
                elif [ -n "$copying" ]; then
                    cp "$copying" "$PWD"
                    unset copying
                    draw
                fi

                # if not, display menu:
                CURSOR=0
                echo "CURSOR: $CURSOR"
                unset draw_overwritten
                actions_done_with=$selected
                draw "
Open-with...
Move-to...
Copy-to...
Rename
Create-link
Compress
Delete"
            # showmenu
            fi
        else
            # item in F2 menu is selected
            echo 3
            unset draw_overwritten
            # selection being done in F2 menu
            if [ $CURSOR == 0 ]; then
                echo "OPENWITH"
                draw
            elif [ $CURSOR == 1 ]; then
                echo "MOVETO"
                moving="$PWD/$actions_done_with"
                draw
            elif [ $CURSOR == 2 ]; then
                echo "COPYTO"
                copying="$PWD/$actions_done_with"
                draw
            elif [ $CURSOR == 3 ]; then
                echo "RENAME"
                stty echo -raw
                printf "\n\r"
                read -p "New name: " newname
                mv "$PWD/$actions_done_with" "$PWD/$newname"
                draw
            elif [ $CURSOR == 4 ]; then
                echo "CREATELINK"
                draw
            elif [ $CURSOR == 5 ]; then
                echo "COMPRESS"
                draw
            elif [ $CURSOR == 6 ]; then
                echo "DELETE"
                draw
            fi
        fi
    elif [ "$1$2" = '033' ] || [ "$1$2$3$4" = '033133062061' ] || [ "$1" = '021' ]; then
        # ESC / F10 / ^q
        stty echo
        exit
    elif [ "$3" = '101' ]; then
        # UP
        echo "UP"
        CURSOR=$((CURSOR - 1))
        draw
    elif [ "$3" = '102' ]; then
        printf "DOWN\n\r"
        CURSOR=$((CURSOR + 1))
        draw "$draw_overwritten"
        notify-send "continued"
    elif [ "$3" == '103' ]; then
        echo "RIGHT"
        ((sorting++))
        draw
    elif [ "$3" == '104' ]; then
        echo "LEFT"
        ((sorting--))
        draw

    elif [ "$3$4" == '065176' ]; then
        echo "PGUP"
        CURSOR=$((CURSOR - ROWS + 5))
        draw
    elif [ "$3$4" == '066176' ]; then
        echo "PGDN"
        notify-send "PGDN"
        CURSOR=$((CURSOR + ROWS - 5))
        draw
        notify-send "continued???"

    # elif [ "$1" == '012' ]; then
    #     if [ "$dirorf" = 'd' ]; then
    #         cd "$selected"
    #         draw
    #     else
    #         showmenu
    #     fi

    elif [ "$3" == '121' ]; then
        echo "F2"
    elif [ "$3" == '122' ]; then
        echo "F3"
        if [[ $(file "$selected") =~ [tT]ext ]]; then
            less --prompt="🭪 Press q to exit, arrows to scroll 🭨🭪 %l / %L 🭨" -N "$selected"
        else
            hexdump -C "$selected" | less --prompt="🭪 Press q to exit, arrows to scroll 🭨🭪 %l / %L 🭨" -N
        fi
        draw
    elif [ "$3" == '123' ]; then
        echo "F4"
        vi -y "$selected"
        draw

    elif [ "$1" == '177' ]; then
        notify-send "BACKSPACE"
        # label-01
        searchq="${searchq%?}"
        draw
    else
        echo "e: $1 $2 $3 $4 $5 $6"
        # Input was a search query
        # bs
        # handled in label-01
        searchq=$searchq$(printf "\\$1")
        files1c="$list1"
        # echo "$files1c" | less
        line_number=$(awk "/^${searchq}/{print NR; exit}" <<< "$files1c")
        # [ -z "$line_number" ] && echo "No line starts with '${searchq}'" || echo "First line starting with 'xyz': $line_number"
        CURSOR=$((line_number-1))
        notify-send "$searchq; $1"
        draw
    fi

    # IMPLEMENTED:
    # F1 2 3 4 5 6 7 8 9 10 ↑ ↓ ← → ↳ ␠ | F2: OW MV CP RN LINK COMP DL
    #      ✔ ✔            ✔ ✔ ✔ ✔ ✔ ✔             ✔     ✔







    # if [ "$key" = '' ]; then
    #     # echo "ENTER"
    #     notify-send "ENT"
    # elif [ "$key" = '~' ]; then
    #     # getting rid of a weird bug that causes 
    #     # `read` being activated with remainants
    #     # of last key press instead of waitng.
    #     draw
    # elif [[ ${#key} == 1 && "$key" =~ ^[[:graph:]]$ ]]; then
    #     # Is a single char for 🔎︎
    #     :
    # elif [ $key = $'\x7f' ]; then
    #     # notify-send "BACKSPACE"
    #     # label-01
    #     searchq="${searchq%?}"
    #     draw
    # # elif [ $key == $'\x1b' ]; then
    # #     notify-send "ESC"
    # #     stty -raw echo
    # #     exit
    # else
    #     key=$(dd bs=1 count=2 2>/dev/null)
    # fi
    # # printf ">>$key<<\n\r"


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
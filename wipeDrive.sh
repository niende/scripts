#!/bin/bash
# Script Name:  wipe-drive.sh
# Beschreibung: Cli to securely erase a specific drive
# Aufruf:       ./wipe-drive.sh [<param 1>] [<param 2>]
#               [<description of param 1>]
#               [<description of param 2>]
# Autor:        Nico Enderlein
# Version:      0.1
# Datum:        2023-01-05 08:38
version="0.1"
date="2023-01-05"

nl=$'\n'

# /dev/sda --> USE /dev/null to test dd command
selected_drive="UNDEFINED"

wipe_types=("/dev/zero" "/dev/urandom")
wipe_type_index=0

status_options=("yes" "no")
status_index=0

dd_bytes=1024

wipe_command="sudo dd if=${wipe_types[$wipe_type_index]} of=${selected_drive} bs=${dd_bytes} status=progress"

UpdateWipeCommand () {
    local wipe_command_base="sudo dd if=${wipe_types[$wipe_type_index]} of=${selected_drive}"
    wipe_command="${wipe_command_base} bs=${dd_bytes}"

    if [ "${status_options[$status_index]}" = "yes" ]; then
        wipe_command="${wipe_command} status=progress"
    fi
}

PromptForDrive () {
    read -p "${nl}Enter drive (path) to wipe (ex. /dev/sda): " selected_drive

    # check if entered drive is valid (block special)
    while [ ! -b $selected_drive ]; do
        echo "Entered drive (${selected_drive}) is not valid!"
        read -p 'Please enter a valid drive (path): ' selected_drive
    done

    UpdateWipeCommand
}

PromptForBytes () {
    read -p "${nl}Enter bytes to read and write at a time: " dd_bytes
    # reprompt if entered bytes contains nondigits
    until [[ -z ${dd_bytes//[[:digit:]]} ]]
    do
        echo "Bytes (${dd_bytes}) contains nondigits but only digits are allow!"
        read -p 'Please enter bytes digits only: ' dd_bytes
    done

    UpdateWipeCommand
}

CycleWipeType () {
    if [ $wipe_type_index -lt $((${#wipe_types[@]} - 1)) ]; then
        wipe_type_index=$((wipe_type_index + 1))
    else
        wipe_type_index=0
    fi

    UpdateWipeCommand
}

CycleDisplayStatus () {
    if [ $status_index -lt $((${#status_options[@]} - 1)) ]; then
        status_index=$((status_index + 1))
    else
        status_index=0
    fi

    UpdateWipeCommand
}

while :
do
# the following cat block seems to be called "heredoc" :)
    clear
    cat << 'EOF'
============================================================
                _..._
              .'     '.
             /  _   _  \
             | (o)_(o) |
              \(     ) /
              //'._.'\ \
             //   .   \ \
            ||   .     \ \
            |\   :     / |
            \ `) '   (`  /_
          _)``".____,.'"` (_
          )     )'--'(     (
           '---`      `---`
EOF

    cat << EOF
============================================================
  Cli to securely erase storage drives - v${version} (${date})
============================================================
$(df -h -x squashfs -x tmpfs -x devtmpfs)
------------------------------------------------------------
    Please enter your choice:
    Selected drive   (1): ${selected_drive}
    Wipe type        (2): ${wipe_types[$wipe_type_index]}
    Bytes            (3): ${dd_bytes}
    Display status   (4): ${status_options[$status_index]}

    Current wipe command: ${wipe_command}

                     (S)tart
                     (Q)uit
------------------------------------------------------------
EOF
    read -n 1 -s -p '    : ' choice
    case "$choice" in
        "1")
            PromptForDrive
            ;;
        "2")
            CycleWipeType
            ;;
        "3")
            PromptForBytes
            ;;
        "4")
            CycleDisplayStatus
            ;;
        "S")
            echo "Would wipe now"
            echo "${wipe_command}"
            local wipe_result=$(${wipe_command})
            retval=$?

            if [ $retval -eq 0 ]; then
                echo "Erasing ${selected_drive} succesfully."
            else
                echo "Something went wrong! Return code: ${retval}"
            fi
            exit
            ;;
        "Q")
            echo 'EXIT'
            exit
            ;;
        "s")
            echo "case sensitive!"
            sleep 2
            ;;
        "q")
            echo "case sensitive!"
            sleep 2
            ;;
        * )
            echo "invalid option"
            sleep 2
            ;;
    esac
done

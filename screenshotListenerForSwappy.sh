#!/bin/bash
# Script Name:  screenshotListenerForSwappy.sh
# Beschreibung: script to watch for new screenshot files and opening them in swappy for further editing
# Aufruf:       ./screenshotListenerForSwappy.sh [<param 1>]
#               [watching directory - absolute path of directory to watch for new files]
# Autor:        Nico Enderlein
# Version:      0.1
# Datum:        2023-09-02 6:25pm
version="0.1"
date="2023-09-02"

custom_dir=$1
if [ -z "$custom_dir" ]; then
    # directory was not provided, use gnomes default screenshot directory
    custom_dir="$HOME/Pictures/Screenshots"
fi

echo "Watching for new files in '$custom_dir'"

inotifywait -m $custom_dir -e create -e moved_to |
    while read dir action file; do
        echo "The file '$file' appeared in directory '$dir' via '$action'"

        # build array of all command parts
        file_type_command=(file -b "${dir}${file}")
        # execute command to check file type by appending all array element and save output as array again
        check_result=($("${file_type_command[@]}"))
        # only get first element, ex. PNG  |  JPEG
        file_type_ident=${check_result[0]}

        supported_formats=('JPEG PNG')
        if [[ " ${supported_formats[*]} " =~ " $file_type_ident " && "$action" = "CREATE" ]]; then
            # open newly created screenshot in swappy
            echo "opening swappy..."
            swappy -f "${dir}${file}"
        else
            echo "File type '${file_type_ident}' or action '${action}' not supported!"
        fi
    done
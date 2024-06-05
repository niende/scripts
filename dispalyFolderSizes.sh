#!/bin/bash
DIR_USAGE=$(du -s -h "$1" | cut -f 1)
#SIZE=$(printf "%'d\n" $DIR_USAGE)
SIZE=$DIR_USAGE
zenity --info --title "Directory Info - ${1@Q}" --text "Size: <b>$SIZE</b>" --width 250

#zenity --info --title "Directory Info" --text "Selected directory: $1\nDirectory size: \n $DIR_USAGE"

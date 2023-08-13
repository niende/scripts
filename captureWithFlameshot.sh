#!/bin/bash
# Script Name:  captureWithFlameshot.sh
# Beschreibung: Cli to handle some screenshot task that flameshot has not built in yet
# Aufruf:       ./captureWithFlameshot.sh [<param 1>]
#               [selection mode - 'current_screen' | 'active_window' | 'select_window' | EMPTY]
# Autor:        Nico Enderlein
# Version:      0.1
# Datum:        2023-08-13 06:55pm
version="0.1"
date="2023-08-13"

if [ -z "$1" ]; then
    # ---------------------------------#
    # first parameter was not provided #
    #----------------------------------#

    # launch flameshot gui for manual selection
    flameshot gui
    exit 0
fi


# --------------------------- #
# first parameter is provided #
# ----------------------------#

# check if first parameter is valid value
allowed_values=('current_screen active_window select_window')
if [[ ! " ${allowed_values[*]} " =~ " $1 " ]]; then
    echo "Invalid argument, must be one of: EMPTY, current_screen, active_window, select_window"
    exit 1
fi

# check with mode to use
if [ "$1" = "current_screen" ]; then
    # Get current screen
    SCREEN=$(xdotool get_desktop)
    REGION="screen${SCREEN}"

else
    if [ "$1" = "active_window" ]; then
        # Get active window geometry
        eval $(xdotool getactivewindow getwindowgeometry --shell)

    elif [ "$1" = "select_window" ]; then
        # Let the user select a window and get its geometry

        # only select window
        #eval $(xdotool selectwindow getwindowgeometry --shell)

        # select window and focus it before marking for screenshot
        eval $(xdotool selectwindow windowfocus getwindowgeometry --shell)
    fi

    # modify dimensions and coordinates to correctly target NON FULLSCREEN windows
    # WIDTH=$(($WIDTH + 2))
    # HEIGHT=$(($HEIGHT + 38))
    # X=$(($X - 2))
    # Y=$(($Y - 74))

    REGION="${WIDTH}x${HEIGHT}+${X}+${Y}"

fi

# launch flameshot gui with calculated region
flameshot gui --region "$REGION"

exit 0

#!/bin/bash

PropmtForInputFile () {
    read -p 'Please enter input file: ' INPUT_FILE
    while [ ! -f $INPUT_FILE ]
    do
        echo "File \"${INPUT_FILE}\" does not exist!"
        read -p 'Please enter existing source file: ' INPUT_FILE
    done

    GetInputFileInfo $INPUT_FILE
}
PromptForOutputFile () {
    read -p 'Please enter output file: ' OUTPUT_FILE
}

function CountArrayItems {
    ARRAY_LENGTH=0
    for index in $1; do
        ARRAY_LENGTH=$((ARRAY_LENGTH + 1))
    done

    return $ARRAY_LENGTH
}

UpdateCurrentCodec () {
    CURRENT_CODEC=${CODECS[$1]}
    # return $CURRENT_BITRATE
}
UpdateCurrentBitrate () {
    BITRATE_ARRAY_NAME=BITRATES_$1[$2]
    CURRENT_BITRATE=${!BITRATE_ARRAY_NAME}
    # return $CURRENT_BITRATE
}
UpdateCurrentDrc () {
    CURRENT_DRC=${DRC_SCALES[$1]}
    # return $CURRENT_BITRATE
}

UpdateBitrateArrayLength () {
    # get bitrates array for counting its items
    BITRATE_ARRAY_FULL_NAME=BITRATES_$CURRENT_CODEC[@]
    BITRATE_ARRAY_FULL=${!BITRATE_ARRAY_FULL_NAME}
    # # call function to count array items
    CountArrayItems "${BITRATE_ARRAY_FULL}"
    # # get return value of function
    BITRATE_ARRAY_LENGTH=$?
}
# UpdateDrcArrayLength () {
#     # call function to count array items
#     CountArrayItems ${DRC_SCALES[@]}
#     # get return value of function
#     DRC_ARRAY_LENGTH=$?
# }

GetInputFileInfo () {
    if [ -f $1 ]; then
        INPUT_FILE_INFO=$(mediainfo --Inform=file://mediainfo_template $1)
    else
        INPUT_FILE_INFO='Invalid audio file, please choose another one!'
    fi
}

StartConversion () {
    FFMPEG_COMMAND="ffmpeg -drc_scale ${DRC_SCALE} -y -i ${INPUT_FILE} -acodec ${CURRENT_CODEC,,} -b:a ${CURRENT_BITRATE}k -hide_banner ${OUTPUT_FILE}"
    echo $FFMPEG_COMMAND
    $(${FFMPEG_COMMAND})
    # ffmpeg -i "${INPUT_FILE}" -acodec ${CURRENT_CODEC,,} -b:a ${CURRENT_BITRATE}k "${OUTPUT_FILE}"
    # echo ffmpeg -i "${INPUT_FILE}" -acodec ${CURRENT_CODEC,,} -b:a ${CURRENT_BITRATE}k "${OUTPUT_FILE}"
    read -p 'xxx' TEST
    # sleep 20
}

# handle Drag'n'Drop here
DND_COUNT=${#@}
if [ $DND_COUNT -gt 0 ]; then
    # for FILE in "$@"; do
    #     echo "$FILE"
    # done
    FILES_STRING=""
    for FILE in "$@"; do
        FILES_STRING=$FILES_STRING$FILE$'\n        '
        # echo $FILE
    done

    cat << EOF

    Process $DND_COUNT file(s) together or individually?
        ${FILES_STRING}
    0: together  |  1: individually
EOF

    read -n1 -p "    : " PROCESSING
    if [ $PROCESSING -eq 0 ]; then PROCESSING="together"; else PROCESSING="individually"; fi
    printf "\n    Process files $PROCESSING.\n"

    read -p 'xxx' ABC
fi




# AUDIO CODECS
CODECS=("AC3" "DTS" "WAV" "FLAC")
# AUDIO BITRATES
BITRATES_AC3=("96" "128" "192" "224" "256" "384" "448" "640")
BITRATES_DTS=("768" "1510")
BITRATES_WAV=("-")
BITRATES_FLAC=("-")
# DRC SCALES
DRC_SCALES=("Off" "Partial" "Full")
# BIT DEPTHS
BITDEPTHS=("16" "24" "32")
# SAMPLE RATES
SAMPLERATES=("44100" "48000")

CODEC_INDEX=0
BITRATE_INDEX=3
DRC_INDEX=0
BITDEPTH_INDEX=0
SAMPLERATE_INDEX=1

# SETTING $CURRENT_CODEC HERE
UpdateCurrentCodec $CODEC_INDEX
# SETTING CURRENT_BITRATE HERE
UpdateCurrentBitrate $CURRENT_CODEC $BITRATE_INDEX
# SETTING $CURRENT_DRC HERE
UpdateCurrentDrc $DRC_INDEX

# SETTING CURRENT_BITDEPTH HERE
UpdateCurrentBitdepth $CURRENT_CODEC $BITRATE_INDEX
# SETTING CURRENT_SAMPLERATE HERE
UpdateCurrentSamplerate $CURRENT_CODEC $BITRATE_INDEX

# SETTING CODEC_ARRAY_LENGTH HERE
CODEC_ARRAY_LENGTH=${#CODECS}
# SETTING BITRATE_ARRAY_LENGTH HERE
UpdateBitrateArrayLength
# SETTING DRC_ARRAY_LENGTH HERE
DRC_ARRAY_LENGTH=${#DRC_SCALES}

while :
do
    # clear
    cat<<EOF

============================================================
    FFMPEG Audio Converter (by qwk)
============================================================
Audio info:
${INPUT_FILE_INFO}
------------------------------------------------------------
    Please enter your choice:

    Input file  (1): "${INPUT_FILE}"
    Output file (2): "${OUTPUT_FILE}"
    Codec       (3): ${CURRENT_CODEC}
    Bitrate     (4): ${CURRENT_BITRATE} Kbps
    DRC         (5): ${CURRENT_DRC}
    Bitdepth    (6): ${CURRENT_BITDEPTH} bits
    Samplerate  (7): ${CURRENT_SAMPLERATE} Hz

            (s)tart
            (q)uit
------------------------------------------------------------
EOF
    read -n1 -s -p '    : ' CHOICE
    case "$CHOICE" in
        "1")
            PropmtForInputFile
            ;;
        "2")
            PromptForOutputFile
            ;;
        "3")
            if [ $CODEC_INDEX -lt $((CODEC_ARRAY_LENGTH)) ]; then
                CODEC_INDEX=$((CODEC_INDEX + 1))
            else
                CODEC_INDEX=0
            fi

            BITRATE_INDEX=0

            # call function to update current codec
            UpdateCurrentCodec $CODEC_INDEX
            UpdateCurrentBitrate $CURRENT_CODEC $BITRATE_INDEX
            UpdateBitrateArrayLength
            ;;
        "4")
            if [ $BITRATE_INDEX -lt $((BITRATE_ARRAY_LENGTH - 1)) ]; then
                BITRATE_INDEX=$((BITRATE_INDEX + 1))
            else
                BITRATE_INDEX=0
            fi

            # call function to update current bitrate
            UpdateCurrentBitrate $CURRENT_CODEC $BITRATE_INDEX
            ;;
        "5")
            if [ $DRC_INDEX -lt $((DRC_ARRAY_LENGTH - 1)) ]; then
                DRC_INDEX=$((DRC_INDEX + 1))
            else
                DRC_INDEX=0
            fi

            # call function to update current drc
            UpdateCurrentDrc $DRC_INDEX
            ;;
        "s")
            echo "Would start audio processing now..."
            StartConversion
            ;;
        "q")
            echo ''
            exit
            ;;
        "S")
            echo "case sensitive!!" ;;
        "Q")
            echo "case sensitive!!" ;;
        * )
            echo "invalid option" ;;
    esac

done

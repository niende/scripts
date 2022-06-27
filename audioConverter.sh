#!/bin/bash

OUTPUT_SUFFIX="_ENC"
CODECS=("AC3" "DTS" "WAV" "FLAC")
BITRATES_AC3=("96" "128" "192" "224" "256" "384" "448" "640")
BITRATES_DTS=("768" "1510")
BITRATES_WAV=("-")
BITRATES_FLAC=("-")
DRC_SCALES=("Off" "Partial" "Full")
BITDEPTHS=("16" "24" "32")
SAMPLERATES=("44100" "48000" "96000")

CODEC_INDEX=0
BITRATE_INDEX=3
DRC_INDEX=0
BITDEPTH_INDEX=0
SAMPLERATE_INDEX=1

GetCurrentBitrateArray () {
    local BITRATE_ARRAY_NAME=BITRATES_$CURRENT_CODEC[@]
    local CURRENT_BITRATE_ARRAY=${!BITRATE_ARRAY_NAME}
    echo "${CURRENT_BITRATE_ARRAY[@]}"
}

UpdateCurrentCodec () {
    CURRENT_CODEC=${CODECS[$CODEC_INDEX]}
}
UpdateCurrentBitrate () {
    BITRATE_ARRAY_NAME=BITRATES_$CURRENT_CODEC[$BITRATE_INDEX]
    CURRENT_BITRATE=${!BITRATE_ARRAY_NAME}
    # return $CURRENT_BITRATE
}
UpdateCurrentDrc () {
    CURRENT_DRC=${DRC_SCALES[$DRC_INDEX]}
}
UpdateCurrentBitdepth () {
    CURRENT_BITDEPTH=${BITDEPTHS[$BITDEPTH_INDEX]}
}
UpdateCurrentSamplerate () {
    CURRENT_SAMPLERATE=${SAMPLERATES[$SAMPLERATE_INDEX]}
}

CycleCodec () {
    if [ $CODEC_INDEX -lt $((${#CODECS[@]} - 1)) ]; then
        CODEC_INDEX=$((CODEC_INDEX + 1))
    else
        CODEC_INDEX=0
    fi
    # reset bitrate index to avoid index out of bounds...
    BITRATE_INDEX=0

    UpdateCurrentCodec
    UpdateCurrentBitrate
    UpdateBitrateArrayLength
    UpdateOutputFiles
}
CycleBitrate () {
    local BITRATES=($(GetCurrentBitrateArray))
    # GetCurrentBitrateArray
    # local BITRATES=$?
    if [ $BITRATE_INDEX -lt $((${#BITRATES[@]} - 1)) ]; then
        BITRATE_INDEX=$((BITRATE_INDEX + 1))
    else
        BITRATE_INDEX=0
    fi

    UpdateCurrentBitrate
}
CycleDrc () {
    if [ $DRC_INDEX -lt $((${#DRC_SCALES[@]} - 1)) ]; then
        DRC_INDEX=$((DRC_INDEX + 1))
    else
        DRC_INDEX=0
    fi

    UpdateCurrentDrc
}
CycleBitdepth () {
    if [ $BITDEPTH_INDEX -lt $((${#BITDEPTHS[@]} - 1)) ]; then
        BITDEPTH_INDEX=$((BITDEPTH_INDEX + 1))
    else
        BITDEPTH_INDEX=0
    fi

    UpdateCurrentBitdepth
}
CycleSamplerate () {
    if [ $SAMPLERATE_INDEX -lt $((${#SAMPLERATES[@]} - 1)) ]; then
        SAMPLERATE_INDEX=$((SAMPLERATE_INDEX + 1))
    else
        SAMPLERATE_INDEX=0
    fi

    UpdateCurrentSamplerate
}

ChangeOutputFileSuffix () {
    echo ""
    local NEW_SUFFIX=""
    while [ -z "$NEW_SUFFIX" ] || [[ "$NEW_SUFFIX" = *" "* ]]; do
        read -p "Enter new output file suffix: " NEW_SUFFIX
    done

    OUTPUT_SUFFIX=$NEW_SUFFIX
    UpdateOutputFiles
}

function CountArrayItems {
    ARRAY_LENGTH=0
    for index in $1; do
        ARRAY_LENGTH=$((ARRAY_LENGTH + 1))
    done

    return $ARRAY_LENGTH
}
UpdateBitrateArrayLength () {
    # get bitrates array for counting its items
    BITRATE_ARRAY_FULL_NAME=BITRATES_$CURRENT_CODEC[@]
    BITRATE_ARRAY_FULL=${!BITRATE_ARRAY_FULL_NAME}
    # call function to count array items
    CountArrayItems "${BITRATE_ARRAY_FULL}"
    # get return value of function
    BITRATE_ARRAY_LENGTH=$?
}

# SETTING $CURRENT_CODEC HERE
UpdateCurrentCodec $CODEC_INDEX
# SETTING CURRENT_BITRATE HERE
UpdateCurrentBitrate $CURRENT_CODEC $BITRATE_INDEX
# SETTING $CURRENT_DRC HERE
UpdateCurrentDrc $DRC_INDEX
# SETTING CURRENT_BITDEPTH HERE
UpdateCurrentBitdepth $CURRENT_CODEC $BITRATE_INDEX
# SETTING CURRENT_SAMPLERATE HERE
# UpdateCurrentSamplerate $CURRENT_CODEC $BITRATE_INDEX

# SETTING CODEC_ARRAY_LENGTH HERE
CODEC_ARRAY_LENGTH=${#CODECS}
# SETTING BITRATE_ARRAY_LENGTH HERE
UpdateBitrateArrayLength
# SETTING DRC_ARRAY_LENGTH HERE
# DRC_ARRAY_LENGTH=${#DRC_SCALES}

PropmtForInputFiles () {
    read -p 'Please enter input file(s) comma separated: ' INPUT_FILES
    # while [ ! -f $INPUT_FILE ]
    # do
    #     echo "File \"${INPUT_FILE}\" does not exist!"
    #     read -p 'Please enter existing intput file(S): ' INPUT_FILES
    # done

    # GetInputFileInfo $INPUT_FILE
}
# PromptForOutputFile () {
#     read -p 'Please enter output file: ' OUTPUT_FILE
# }

UpdateOutputFiles () {
    # clear array before setting new output files
    OUTPUT_FILES=()
    for file in "${INPUT_FILES[@]}"; do
        # get file extension and set suffix for output files
        local extension=${file##*.}
        local extension_pos="$((${#file} - (${#extension} + 1)))"

        local file_name="${file:0:${extension_pos}}"
        #file_suffix="_ENC"
        local file_extension=".${CURRENT_CODEC,,}"
        # file_extension="${file:${extension_pos}}"

        # build output file names with suffix
        OUTPUT_FILES+=("$file_name$OUTPUT_SUFFIX$file_extension")
    done
}

RequestFlacInstallation () {
    if ! command -v flac &> /dev/null; then
        echo "Flac package is not installed on your system, install it now?"
        echo "(y)es | (n)o"
        read -n1 -p ': ' INSTALL_FLAC
        if [ $INSTALL_FLAC = "y" ]; then
            echo ""
            echo -n "Updating packages..."
            $(sudo apt update -qq 2>/dev/null >/dev/null)
            echo " DONE"
            echo -n "Installing flac..."
            $(sudo apt -y install flac -qq 2>/dev/null >/dev/null)
            echo " DONE"
        fi
    fi
}


GetInputFileInfo () {
    if [ -f $1 ]; then
        INPUT_FILE_INFO=$(mediainfo --Inform=file://mediainfo_template $1)
    else
        INPUT_FILE_INFO='Invalid audio file, please choose another one!'
    fi
}

StartConversion () {
    # "${!INPUT_FILES[@]}" get array keys | "${INPUT_FILES[@]}" gets array values
    for I in "${!INPUT_FILES[@]}"; do
        drc_scale_str="-drc_scale $DRC_INDEX"
        input_str="${INPUT_FILES[$I]}"
        codec_str="-c:a ${CURRENT_CODEC,,}"
        bitrate_str="-b:a ${CURRENT_BITRATE}k"
        hide_banner="-hide_banner"
        output_str="${OUTPUT_FILES[$I]}"

        case "$CURRENT_CODEC" in
            "AC3")
                echo "ffmpeg ${drc_scale_str} -i ${input_str} ${codec_str} ${bitrate_str} ${hide_banner} ${output_str}"
                convert_command=(ffmpeg ${drc_scale_str} -i "${input_str}" ${codec_str} ${bitrate_str} ${hide_banner} "${output_str}")
                ;;
            "DTS")
                ;;
            "FLAC")
                # TODO: figure out how to convert ac3 to flac without getting "ERROR: for encoding a raw file you must specify a value for --endian, --sign, --channels, --bps, and --sample-rate"
                # ask which encoder to use
                # echo "Select an encoder"
                # echo "(1) FLAC | (2) FFMPEG"
                # read -n1 -p ': ' ENCODER_CHOICE
                # echo ""
                encoder_choice=2

                if [ $encoder_choice -eq 1 ]; then
                    # FLAC Example: flac --best "%~1" -o "%~dpn1_[ENCODED_FLAC].flac"
                    RequestFlacInstallation

                    echo "flac --best ${input_str} -o ${output_str}"
                    convert_command=(flac --best "${input_str}" -o "${output_str}")

                else
                    # FFMPEG Example: ffmpeg -i "%%I" -c:a flac -compression_level 12 -sample_fmt s16 -ar 48000 -y -hide_banner "%~dp0OUTPUT\%%~nI_16bit_FFMPEG.flac"
                    echo "ffmpeg ${drc_scale_str} -i ${input_str} ${codec_str} -compression_level 12 -sample_fmt s16 -ar 48000 ${hide_banner} ${output_str}"
                    convert_command=(ffmpeg ${drc_scale_str} -i "${input_str}" ${codec_str} -compression_level 12 -sample_fmt s16 -ar 48000 ${hide_banner} "${output_str}")

                fi
                ;;
            "WAV")
                ;;
            *)
                ;;
        esac

        # execute ffmpeg command
        # declare -p convert_command
        "${convert_command[@]}"
    done

    read -n1 -s -r -p 'Press enter to continue'
}

# handle Drag'n'Drop here
DND_COUNT=${#@}
INPUT_FILES=()
files_no_ext=()
OUTPUT_FILES=()
if [ $DND_COUNT -gt 0 ]; then
    FILES_STRING=""
    for FILE in "$@"; do
        INPUT_FILES+=("$FILE")
        FILES_STRING=$FILES_STRING$FILE$'\n        '
    done

    # generate output file names with current codec extension
    UpdateOutputFiles

    if [ $DND_COUNT -gt 1 ]; then
        cat << EOF

    Process $DND_COUNT file(s) in batch or dialog?
        ${FILES_STRING}
    0: batch  |  1: dialog
EOF

        read -n1 -p "    : " processing_mode
        # Make distinctions here - "Batch processing" or "Dialog processing"
        # if [ $PROCESSING -eq 0 ]; then PROCESSING="together"; else PROCESSING="individually"; fi
        # printf "\n    Process files $PROCESSING.\n"
    fi
fi

nl=$'\n'
while :
do
# the following cat block seems to be called "heredoc" :)
    clear
    cat << EOF

============================================================
    FFMPEG Audio Converter (by qwk)
============================================================
Audio info:
${INPUT_FILE_INFO}
------------------------------------------------------------
    Please enter your choice:

    Input file(s)   (1): ${INPUT_FILES[@]/%/$nl                        }
    Output file(s)  (2): ${OUTPUT_FILES[@]/%/$nl                        }
    Output file suffix (o): ${OUTPUT_SUFFIX}$nl
    Codec           (3): ${CURRENT_CODEC}
    Bitrate (Kbps)  (4): ${CURRENT_BITRATE}
    DRC             (5): ${CURRENT_DRC}
    Bitdepth (bits) (6): ${CURRENT_BITDEPTH}
    Samplerate (Hz) (7): ${CURRENT_SAMPLERATE}

                    (s)tart
                    (q)uit
------------------------------------------------------------
EOF
    read -n1 -s -p '    : ' CHOICE
    case "$CHOICE" in
        "1")
            # PropmtForInputFile
            ;;
        "2")
            # PromptForOutputFile
            ;;
        "o")
            ChangeOutputFileSuffix
            ;;
        "3")
            CycleCodec
            ;;
        "4")
            CycleBitrate
            ;;
        "5")
            CycleDrc
            ;;
        "6")
            CycleBitdepth
            ;;
        "7")
            CycleSamplerate
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

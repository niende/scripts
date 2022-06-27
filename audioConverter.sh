#!/bin/bash

output_suffix="_ENC"
codecs=("AC3" "DTS" "FLAC" "WAV")
bitrates_ac3=("96" "128" "192" "224" "256" "384" "448" "640")
bitrates_dts=("768" "1510")
bitrates_flac=("-")
bitrates_wav=("-")
drc_scales=("Off" "Partial" "Full")
bitdepths=("16" "24" "32")
samplerates=("44100" "48000" "96000")

codec_index=0
bitrate_index=3
drc_index=0
bitdepth_index=0
samplerate_index=1

GetCurrentBitrateArray () {
    local bitrate_array_name=bitrates_${current_codec,,}[@]
    local current_bitrate_array=${!bitrate_array_name}
    echo "${current_bitrate_array[@]}"
}

UpdateCurrentCodec () {
    current_codec=${codecs[$codec_index]}
}
UpdateCurrentBitrate () {
    local bitrates=($(GetCurrentBitrateArray))
    current_bitrate="${bitrates[$bitrate_index]}"
}
UpdateCurrentDrc () {
    current_drc=${drc_scales[$drc_index]}
}
UpdateCurrentBitdepth () {
    current_bitdepth=${bitdepths[$bitdepth_index]}
}
UpdateCurrentSamplerate () {
    current_samplerate=${samplerates[$samplerate_index]}
}

CycleCodec () {
    if [ $codec_index -lt $((${#codecs[@]} - 1)) ]; then
        codec_index=$((codec_index + 1))
    else
        codec_index=0
    fi
    # reset bitrate index to avoid index out of bounds...
    bitrate_index=0

    UpdateCurrentCodec
    UpdateCurrentBitrate
    UpdateBitrateArrayLength
    UpdateOutputFiles
}
CycleBitrate () {
    local bitrates=($(GetCurrentBitrateArray))

    if [ $bitrate_index -lt $((${#bitrates[@]} - 1)) ]; then
        bitrate_index=$((bitrate_index + 1))
    else
        bitrate_index=0
    fi

    UpdateCurrentBitrate
}
CycleDrc () {
    if [ $drc_index -lt $((${#drc_scales[@]} - 1)) ]; then
        drc_index=$((drc_index + 1))
    else
        drc_index=0
    fi

    UpdateCurrentDrc
}
CycleBitdepth () {
    if [ $bitdepth_index -lt $((${#bitdepths[@]} - 1)) ]; then
        bitdepth_index=$((bitdepth_index + 1))
    else
        bitdepth_index=0
    fi

    UpdateCurrentBitdepth
}
CycleSamplerate () {
    if [ $samplerate_index -lt $((${#samplerates[@]} - 1)) ]; then
        samplerate_index=$((samplerate_index + 1))
    else
        samplerate_index=0
    fi

    UpdateCurrentSamplerate
}

ChangeOutputFileSuffix () {
    echo ""
    local new_suffix=""
    while [ -z "$new_suffix" ] || [[ "$new_suffix" = *" "* ]]; do
        read -p "Enter new output file suffix: " new_suffix
    done

    output_suffix=$new_suffix
    UpdateOutputFiles
}

# call function like this:
#     local array_length=($(CountArrayItems ${arr[@]}))
function CountArrayItems {
    local array_length=0
    for index in $1; do
        array_length=$((array_length + 1))
    done
    echo $array_length
}

UpdateCurrentCodec
UpdateCurrentBitrate
UpdateCurrentDrc
UpdateCurrentBitdepth
UpdateCurrentSamplerate

PropmtForInputFiles () {
    read -p 'Please enter input file(s) separated by spaces: ' input_files
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
    output_files=()
    for file in "${input_files[@]}"; do
        # get file extension and set suffix for output files
        local extension=${file##*.}
        local extension_pos="$((${#file} - (${#extension} + 1)))"

        local file_name="${file:0:${extension_pos}}"
        #file_suffix="_ENC"
        local file_extension=".${current_codec,,}"
        # file_extension="${file:${extension_pos}}"

        # build output file names with suffix
        output_files+=("$file_name$output_suffix$file_extension")
    done
}

RequestFlacInstallation () {
    if ! command -v flac &> /dev/null; then
        echo "Flac package is not installed on your system, install it now?"
        echo "(y)es | (n)o"
        read -n1 -p ': ' install_flac
        if [ $install_flac = "y" ]; then
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
        input_file_info=$(mediainfo --Inform=file://mediainfo_template $1)
    else
        input_file_info='Invalid audio file, please choose another one!'
    fi
}

StartConversion () {
    # "${!INPUT_FILES[@]}" get array keys | "${INPUT_FILES[@]}" gets array values
    for i in "${!input_files[@]}"; do
        drc_scale_str="-drc_scale $drc_index"
        input_str="${input_files[$i]}"
        codec_str="-c:a ${current_codec,,}"
        bitrate_str="-b:a ${current_bitrate}k"
        hide_banner="-hide_banner"
        output_str="${output_files[$i]}"

        case "$current_codec" in
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
dnd_count=${#@}
input_files=()
files_no_ext=()
output_files=()
if [ $dnd_count -gt 0 ]; then
    files_string=""
    for file in "$@"; do
        input_files+=("$file")
        files_string=$files_string$file$'\n        '
    done

    # generate output file names with current codec extension
    UpdateOutputFiles

    if [ $dnd_count -gt 1 ]; then
        cat << EOF

    Process $dnd_count file(s) in batch or dialog?
        ${files_string}
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
    Audio Converter
============================================================
Audio info:
${input_file_info}
------------------------------------------------------------
    Please enter your choice:

    Input file(s)   (1): ${input_files[@]/%/$nl                        }
    Output file(s)  (2): ${output_files[@]/%/$nl                        }
    Output file suffix (o): ${output_suffix}$nl
    Codec           (3): ${current_codec}
    Bitrate (Kbps)  (4): ${current_bitrate}
    DRC             (5): ${current_drc}
    Bitdepth (bits) (6): ${current_bitdepth}
    Samplerate (Hz) (7): ${current_samplerate}

                    (s)tart
                    (q)uit
------------------------------------------------------------
EOF
    read -n1 -s -p '    : ' choice
    case "$choice" in
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

#!/bin/bash

Install () {
    clear
    echo ''
    echo "Please enter input file(s) separated by \';\'"
    read -p ' : ' files

    input_files=()
    local input_array=(${files//;/ }) # split explode string at ';'
    for k in "${!input_array[@]}"; do
        local tmp="${input_array[$k]//\"}" # remove all " from file name
        local ifile="${tmp//\'}" # remove all ' from file name

        # check if file is valid and exists, otherwise query again
        while [ -z "$ifile" ] || [ ! -f "$ifile" ]; do
            echo ''
            echo "Error! \"$ifile\" does not exist. Enter correct file"
            read -p " : " ifile
            tmp="${ifile//\"}" # remove all double quotes from file name
            ifile="${tmp//\'}" # remove all single quotes from file name
        done

        input_files+=("$ifile") # add file to input files
    done

    UpdateOutputFiles

    # GetInputFileInfo $INPUT_FILE
}

Update () {
	# get installation path
	local location=$(rpm -ql nomachine | tail -1)

	# get latest binary
	
	
	# update nomachine
	rpm -Uvh  <pkgName>_<pkgVersion>_<arch>.rpm  --prefix /opt
}

Remove () {
	# uninstall NoMachine
	rpm -e nomachine
}

nl=$'\n'
while :
do
# the following cat block seems to be called "heredoc" :)
    clear
    cat << EOF

====================================
    Manage NoMachine installation
====================================
Audio info:
${input_file_info}
------------------------------------
    Please enter your choice:

    Install    (1)$nl
    Update     (2)$nl
    Uninstall  (3)$nl
               (q)uit
-------------------------------------
EOF
    read -n1 -s -p '    : ' choice
    case "$choice" in
        "1")
            PromptForInputFiles
            ;;
        "2")
            # TODO: allow setting custom output file names
            # PromptForOutputFile
            ;;
        "3")
            ChangeOutputFileSuffix
            ;;
        "q")
        "Q")
            echo ""
            exit
            ;;
        * )
            echo "invalid option" ;;
    esac
done

exit 0

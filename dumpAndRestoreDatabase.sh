#!/bin/bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    ${SCRIPT_NAME} [-v] [-m[mode]] [-d[database]] [-h[host]] [-p[port]] [-f[file]]
#%
#% DESCRIPTION
#%    This is a script template
#%    to start any good shell script.
#%
#% OPTIONS
#%    -m [mode], --mode=[mode]                Switch between dumping and restoring mode
#%                                            dump    - use for dumping database
#%                                            restore - use for restoring database
#%    -d [database], --database=[database]    Set the database name
#%    -h [host], --host=[host]                Set MySQL host (default=localhost)
#%    -p [port], --port=[port]                Set MySQL port (default=3306)
#%    -f [file], --file=[file]                set SQL dump file
#%
#%



#%    -o [file], --output=[file]    Set log file (default=/dev/null)
#%                                  use DEFAULT keyword to autoname file
#%                                  The default value is /dev/null.
#%    -t, --timelog                 Add timestamp to log ("+%y/%m/%d@%H:%M:%S")
#%    -x, --ignorelock              Ignore if lock file exists
#%    -h, --help                    Print this help
#%    -v, --version                 Print script information
#%
#% EXAMPLES
#%    ${SCRIPT_NAME} -o DEFAULT arg1 arg2
#%
#================================================================
#- IMPLEMENTATION
#-    version         ${SCRIPT_NAME} (www.uxora.com) 0.0.4
#-    author          Michel VONGVILAY
#-    copyright       Copyright (c) http://www.uxora.com
#-    license         GNU General Public License
#-    script_id       12345
#-
#================================================================
#  HISTORY
#     2015/03/01 : mvongvilay : Script creation
#     2015/04/01 : mvongvilay : Add long options and improvements
#
#================================================================
#  DEBUG OPTION
#    set -n  # Uncomment to check your syntax, without execution.
#    set -x  # Uncomment to debug this shell script
#
#================================================================
# END_OF_HEADER
#================================================================



# Script Name:  captureWithFlameshot.sh
# Beschreibung: Cli to handle some screenshot task that flameshot has not built in yet
# Aufruf:       ./dumpAndRestoreMySQLDatabase.sh [<param 1> <param 2> <param 3>]
#               [mode - 'dump' | 'restore']
#               [database]
#               [output_file - optional - default: "./<database>_<date>_<time>.sql"]
# Autor:        Nico Enderlein
# Version:      0.1
# Datum:        2024-02-21 09:56pm
version="0.1"
date="2024-02-21"

now=$(date '+%Y-%m-%d_%H-%M-%S')

mode=''
database=''
host="localhost"
port='3306'
file=''
verbose=''


# see: https://stackoverflow.com/a/21128172
print_usage() {
    printf "Usage: dumpAndRestoreMySqlDatabase.sh -v -m<dump|restore> -d<DATABASE> -h<HOST> -p<PORT> -f<FILE>"
}
# if a character is followed by a colon (e.g. f:), that option is expected to have an argument.
while getopts 'm:d:h:p:f:v' flag; do
  case "${flag}" in
    m) mode="${OPTARG}" ;;
    d) database="${OPTARG}" ;;
    h) host="${OPTARG}" ;;
    p) port="${OPTARG}" ;;
    f) file="${OPTARG}" ;;
    v) verbose='--verbose' ;;
    *) print_usage
       exit 1 ;;
  esac
done

# check if provided mode is valid
#allowed_modes=('dump restore')
allowed_modes=(dump restore)
if [[ ! " ${allowed_modes[*]} " =~ " $mode " ]]; then
    echo "Invalid argument provided for mode, must be one of:" $(printf "'%s' " "${allowed_modes[@]}")
    exit 1
fi

# check if database name was provided
if [ -z "$database" ]; then
    echo "No database name was provided!"
    exit 1
fi

# if output file was not provided -> use default
if [ -z "$file" ]; then
    file="${database}_${now}.sql"
fi

user=""
password=""

# ask for username
read -p 'Enter MySQL user: ' user
# ask for password
# read -p -s 'Enter MySQL password: ' password

if [[ "$mode" == "dump" ]]; then
    echo "mysqldump ${verbose} -u ${user} -p --host=${host} --port=${port} ${database} > ${file}"
    #mysqldump ${verbose} -u ${user} -p --host=${host} --port=${port} ${database} > ${file}
else
    echo "mysql ${verbose} -u ${user} -p --protocol=tcp --host=${host} --port=${port} ${database}"
    #mysql ${verbose} -u ${user} -p --protocol=tcp --host=${host} --port=${port} ${database}
fi

# directly import dump from inside gz archive
# cat ./ibelsa_rooms_live_2024-03-06.sql.gz | gunzip | mysql -h 127.0.0.1 --port 3307 -uroot -proot ibelsa_prod

exit 0

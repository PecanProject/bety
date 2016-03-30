#!/bin/bash

# The source for load.bety.sh:
SCRIPT_SOURCE_LOCATION=https://raw.githubusercontent.com/PecanProject/pecan/master/scripts/load.bety.sh

# These are options we want to pass through to load.bety.sh.  Update this as
# needed if load.bety.sh is revised:
LOAD_BETY_OPTION_STRING=a:cd:efghl:m:o:p:qr:tu

function configure_interactively {
    cat <<EOF

* Interactive configuration is as yet very rudimentary.  For now, the script
  just offers to replace the configuration file with a file containing set of
  stock options deemed most useful for BETYdb developers.  (If the file does not
  exist, it silently creates it.)  To do anything more complicated, you must
  edit the environment settings in the file $CONFIGFILE manually.

  Settings in the config file should be of the form

      export DATABASE=bety

* To see what variable names are significant, look inside the script file
  $LOAD_SCRIPT.

* Note that if no command line options are given, RUNNING THE SCRIPT WITH THE
  STOCK OPTION CONFIGURATION FILE WILL COMPLETELY REPLACE THE DATABASE bety WITH
  A FRESHLY DOWNLOADED COPY! It will also create a stock set of users having
  various permission levels and having logins of the form "caryaXY", where X and
  Y are numbers giving the access level and page access level of the user,
  respectively.

EOF
    if [ "$CONFIGFILE_EXISTS" = 0 ]; then
        read -p "Do you want to replace $CONFIGFILE with the stock options? (y|N) " ANSWER
        case $ANSWER in
            [Yy])
                ;;
            *)
                exit 0;
                ;;
        esac
    fi
    # If we get here, either there was no pre-existing config file or the user said to replace it:
    cat > $CONFIGFILE <<EOF
export CREATE=YES
export FIXSEQUENCE=YES
export USERS=YES
export DATABASE=bety
export GUESTUSER=YES
EOF
}

function display_help {
    local commandname=$(basename $0)
    cat <<EOF

NOTE: If you just want to create an up-to-date copy of the BETYdb database,
consider using the bety:db:populate Rake task.

USAGE:
 $commandname [-h|-i]
 [see below for further usage options]

OPTIONS:
 -h display this help; if the load script has been download, additional options and help is displayed below
 -i create a stock config file if one doesn't exist, or offer to replace an existing one

This is a wrapper script for the script $(basename $LOAD_SCRIPT) that downloads
and installs a copy of the BETYdb database.

To download $(basename $LOAD_SCRIPT), rerun this script without options.  To get
a fresh copy if you have previously downloaded it, delete or rename $LOAD_SCRIPT
and rerun this script without options.

EOF
}

THIS_DIR=$(dirname $0)

CONFIGFILE=$THIS_DIR/update.conf

CONFIGFILE_EXISTS=$(test -r "$CONFIGFILE"; echo $?)

LOAD_SCRIPT=$THIS_DIR/load.bety.sh

LOAD_SCRIPT_EXISTS=$(test  -x "$LOAD_SCRIPT"  -a   -x "$LOAD_SCRIPT"; echo $?)

if [ -f "$CONFIGFILE" ]; then
    source "$CONFIGFILE"
fi

# option defaults
HELP=NO
CONFIGURE_INTERACTIVELY=NO

while getopts i${LOAD_BETY_OPTION_STRING} opt; do
    case $opt in
        h)
            HELP=YES
            ;;
        i)
            CONFIGURE_INTERACTIVELY=YES
            ;;
    esac
done

if [ "$LOAD_SCRIPT_EXISTS" = 0 ]; then
    if [ "$CONFIGURE_INTERACTIVELY" = "YES" ]; then
        configure_interactively
        exit 0
    fi
else
    if [ "$HELP" = "YES" ]; then
        display_help
    elif [ "$CONFIGURE_INTERACTIVELY" = "YES" ]; then
        cat <<EOF

Run this script with no options to download $(basename $LOAD_SCRIPT) before
using the interactive configuration option.

EOF
    else
        # download load script
        curl "$SCRIPT_SOURCE_LOCATION" > "$LOAD_SCRIPT"
        chmod +x "$LOAD_SCRIPT"
    fi
    exit 0
fi

# We only get here if the load script existed to begin with and we didn't give the -i option.

if [ "$HELP" = "YES" ]; then
    display_help
    cat <<EOF
--------------------------------------------------------------------------------
HELP FOR load.bety.sh:

[Note that except for the -i option, options to this script ("$0") are passed
through to load.bety.sh.]

EOF
fi

echo -n "About to run $THIS_DIR/load.bety.sh"

# This convoluted sequence of commands should echo the positional parameters
# that are passed to load.bety.sh:
for value in "$@"; do
    if [ "${value/ /}" == "$value" ]; then
        # no spaces; echo without quoting
        echo -n " $value"
    else
        echo -n " \"$value\""
    fi
done
echo

"$THIS_DIR/load.bety.sh" "$@"

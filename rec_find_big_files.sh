#!/usr/bin/bash
# On windows: how : run on (Unix) proxy...
# ==============================================================================
# Script for searching for bigfiles (use case: analysis of why
# an alert suddenly raised on C: regarding size or 
#
# Mainly for use on Windows, as maxdepth=3 is already too deep for timeout
#
# Quite useless in my experience on Unix/Linux, as vfs.dir.get is much faster
# there...
#
# ==============================================================================
#
# As is is supposed to work on Windows
#
TOP_DIR="C:\\"
TOP_DIR="/"

HOST=${1:-127.0.0.1}
MIN_SIZE=${2:-10000000}
MAX_DEPTH=${3:-2}

# Let's search from /
# That would be [C:\,] in windows, without quotes
for subdir in $(zabbix_get -s $HOST -k vfs.dir.get[/,,,dir,,0] | jq -crM '.[] | .basename')
do
    echo "# searching from $subdir ..."
    zabbix_get -s $HOST -k "vfs.dir.get[/${subdir},,,file,,${MAX_DEPTH},${MIN_SIZE}]" 2>/dev/null | grep -v NOTSUPP | jq -crM '.[] | '
done


# ==============================================================================


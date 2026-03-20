#!/usr/bin/bash
# -------------------------------------------------------------------------------------
# Prep a data file for gnuplot
#
# HERE WE KEEP A LIST OF TOP CRITERION
#
# the key in the data (we hope)
# {"pid1":value1,"pid2":value2,...,"pidN":valueN}
#
# TODO : options ?

# -------------------------------------------------------------------------------------
# Config

# Where json outputs of nproc.get keys are supposed to be kept...
#DATA_DIR=/var/tmp

DATA_DIR=/var/tmp/multi_hosts/127.0.0.1

NTOP=11

PROGNAME=$(basename $0)

FMT_STRING="\"%s\":%d, "
# For float values (ex: pmem)
FMT_STRING_FLOAT="\"%s\":%f, "

TS_MIN=0
TS_MAX=2145999000 # more or less end of unix times

VERSION="0.3 (20-03-2026)"

# -------------------------------------------------------------------------------------
# Functions

function usage {
    cat <<EOF

	$PROGNAME: usage:

	$PROGNAME [criterion [from [to]]]

	BEWARE OF TYPE !!    
EOF
}

# -------------------------------------------------------------------------------------
# Main 
[[ $1 = "-h" ]] && usage && exit 0

cd $DATA_DIR || exit 1

CRITERION=${1:-ctx_switches}

# Must be received quoted, as "Mar 17 18:00" from instance
DATE_FROM="$2"
DATE_TO="$3"

[[ -n "$DATE_FROM" ]] && TS_MIN=$(date --date="$DATE_FROM" +%s)
[[ -n "$DATE_TO" ]]   && TS_MAX=$(date --date="$DATE_TO"   +%s)

echo "# Plotting data between $DATE_FROM and $DATE_TO ($TS_MIN and $TS_MAX) ..." 1>&2

[[ $CRITERION = "pmem" ]] && FMT_STRING="${FMT_STRING_FLOAT}"
#echo FMT_STRING="$FMT_STRING"

echo "# Generating data for criterion '$CRITERION' from data files found under $DATA_DIR ..." 1>&2

# We should add a HEADER here 
# Ceci collectionne les donnes pour 1 processus

#for fn in *_proc-get.json
ls -1tr | awk -vtsmin=$TS_MIN -vtsmax=$TS_MAX -F'_' '$1 <= tsmax && $1 >= tsmin {print}' | while read fn
do
    ts=${fn%_*}
    
    # On présume que 
    echo -e "{\c"
    printf '"ts":%d, ' $ts 

    cat $fn | jq -cM ".| sort_by(.ctx_switches) | .[] |{pid,ctx_switches}" | tail -n $NTOP | mlr --j2t cat | tail -n +2 \
    | while read pid value
    do
	printf "$FMT_STRING" $pid $value
    done
    echo "}"

    # Not really useful, as we don't really have a 3rd file descriptor!
    #echo -e ". \c" 1>&2
done

cat <<EOF 1>&2 

# The actual cmd line to prepare the data file for gnuplot is THIS
# -N to not add headers
# prep_data_file.sh $CRITERION 2>/dev/null | mlr -N --j2t cat > ctx_switches.dat

EOF

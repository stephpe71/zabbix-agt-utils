#!/usr/bin/bash
# -------------------------------------------------------------------------------------
# Prep a data file for gnuplot
#
# HERE WE KEEP A LIST OF TOP CTX SWITCHES
#
# the key in the data (we hope)
# {"pid1":value1,"pid2":value2,...,"pidN":valueN}
#
# TODO : options ?
#
# -------------------------------------------------------------------------------------
# Config

# Where json outputs of nproc.get keys are supposed to be kept...
#DATA_DIR=/var/tmp

DATA_DIR=/var/tmp/multi_hosts/127.0.0.1

# -------------------------------------------------------------------------------------
# Main 
cd $DATA_DIR || exit 1

# Ceci collectionne les donnes pour 1 processus
for fn in *_proc-get.json
do
    ts=${fn%_*}
    
    # On présume que 
    echo -e "{\c"
    printf '"ts":%d, ' $ts
    cat $fn | jq -cM '.| sort_by(.ctx_switches) | .[] |{pid,ctx_switches}' | tail -n 11 | mlr --j2t cat | tail -n +2 \
    | while read pid ctxsw
    do
	printf '"%s":%d, ' $pid $ctxsw
    done
    echo "}"

    # Not really useful, as we don't really have a 3rd file descriptor!
    #echo -e ". \c" 1>&2
done

cat <<EOF 1>&2 

# The actual cmd line to prepare the data file for gnuplot is THIS
# -N to not add headers
# prep_data_file.sh 2>/dev/null | mlr -N --j2t cat > ctx_switches.dat

EOF

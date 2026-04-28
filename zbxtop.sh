#!/usr/bin/env bash
# ==============================================================================
# On va le laisser en bash
# 
# Un script a mettre sous /tmp et
# executer via system.run
#
# TODO:
# Pour le cpu:
# - ramener au temps écoulé?
# - vérifier les unités
# Affichage avec awk
# - OK l'index du critere de tri peut etre recupérer
# Dispatch de la liste des critere seli
# ==============================================================================
# Variables

# On met la dest en 2eme parametre
ZBXHOST=${1:-127.0.0.1}

# pourrait
CRITERION=${2:-pmem}

NLINES=${3:-10}

CPU_FIELDS_LIN="pid,name,pmem,vsize,rss,cputime_user,cputime_system,threads,ctx_switches"
#CPU_FIELDS_LIN_LONG="ppid,pid,name,user,pmem,vsize,rss,swap,threads,ctx_switches,cputime_user,cputime_system"
CPU_FIELDS_LIN_LONG="pid,name,user,pmem,vsize,rss,swap,threads,ctx_switches,cputime_user,cputime_system"

CPU_FIELDS_WIN="pid,name,user,vmsize,wkset,cputime_user,cputime_system"
CPU_FIELDS_WIN_LONG="pid,name,vmsize,wkset,cputime_user,cputime_system,handles,page_faults"

# FIXME: better done by requesting type of remote system
CPU_FIELDS=$CPU_FIELDS_LIN

PROGNAME=$(basename $0)
DIRNAME=$( dirname  $0)

RECORD_DIR=/var/tmp

RECORD_DIR=/var/tmp/multi_hosts/$ZBXHOST
VERSION="0.9a (28-04-2026)"

GRID_STYLE=fancy_grid

# Or to use a modulo for saving the file?
DELAY=10

for fname in utils.sh colorlib.sh
do	     
    filepath=${DIRNAME}/${fname}
    [[ -r $filepath ]] && source $filepath
done

# ==============================================================================
# Fonctions

# $PROGNAME -n NLINES criterion
function usage {
    cat <<EOF

        $PROGNAME: usage:

        $PROGNAME [ip-or-host [criterion [[NLINES]]]]

        where criterion is one of
        pmem vsize rss cputime_user cputime_system

EOF
}

function criterion_index {
    criterion=$1
    echo $CPU_FIELDS | tr ',' '\n' | cat -n | grep "$criterion" | awk '{print $1}'
}

function check_commands_prerequisites {
    not_found=""
    for cmd in zabbix_get jq mlr tail awk
    do
        if which $cmd>/dev/null; then : ; else not_found="${not_found} $cmd"; fi
    done

    if [[ ! -z $not_found ]]; then
        echo "the following necessary command(s) was/were NOT FOUND:$not_found, exiting..."; exit 1;
    fi
}

# agent not reachable or
# <= 6.2 =>
function check_agent_version_os_type {
  local agent_version=$(zabbix_get -s $ZBXHOST -k agent.version)
  local os_type=$(zabbix_get -s $ZBXHOST -k system.sw.os | awk '{print $1}')

  # Beware : case is significant with =~ operator
  [[ $os_type =~ Win ]] && CPU_FIELDS=$CPU_FIELDS_WIN

  if [[ $os_type =~ Lin ]]; then
      case $agent_version in
	  7*)		CPU_FIELDS=$CPU_FIELDS_LIN_LONG ;;
	  *)		CPU_FIELDS=$CPU_FIELDS_LIN ;;
      esac
  fi
}

# ==============================================================================
[[ $1 = "-h" ]] && usage && exit 0
[[ $1 = "-V" ]] && echo "$VERSION" && exit 0

[[ $1 = "-r" ]] && DO_RECORD=1 && shift

check_commands_prerequisites
check_agent_version_os_type

#[[ -n $DO_RECORD ]] && mkdir -p $RECORD_DIR
mkdir -p $RECORD_DIR

awk_index="$(criterion_index $CRITERION)"

totmem=$(zabbix_get -s $ZBXHOST -k vm.memory.size[total] )
ncores=$(zabbix_get -s $ZBXHOST -k system.cpu.num[online])

#echo ncores=$ncores
while true
do
    clear
    echo $(colored "# Getting process data from '$ZBXHOST', sorting by '$CRITERION' ..." $BRIGHT)
    echo $(colored "# Total memory: $(convert_to_suffix $totmem), # of cpus: $ncores"    $BRIGHT)

    timestamp=$(date +%s)
    tmpfile=${RECORD_DIR}/${timestamp}_proc-get.json
    
    #zabbix_get -s $ZBXHOST -k proc.get 
    zabbix_get -s $ZBXHOST -k proc.get > ${tmpfile}

    cat $tmpfile | \
	jq -cM ". | sort_by(.${CRITERION}) | reverse | .[] | {$CPU_FIELDS}" | \
	head -n $NLINES | mlr --j2t cat | tabulate --sep="\t" -1 -f $GRID_STYLE

    sleep $DELAY

done



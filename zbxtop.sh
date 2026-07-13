#!/usr/bin/env zsh
# ==============================================================================
# On va le laisser en bash
# 
# Un script a mettre sous /tmp et
# executer via system.run
#
# BUG
# First incantation of system.cpu.num value is udefined ...
#
# TODO:
# Pour le cpu:
# - ramener au temps écoulé?
# - vérifier les unités
# Affichage avec awk
# - OK l'index du critere de tri peut etre recupérer
#
# Dispatch de la liste des critere seli
#
# ==============================================================================
# Variables

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
# TO BE verbessert (simple place now for communication with lisp program)
DATA_DIR=/var/tmp/zbxtop

VERSION="0.9c (03-07-2026)"

GRID_STYLE=simple
GRID_STYLE=fancy_grid

# Or to use a modulo for saving the file?
DELAY=10

#DEBUG=1
DEBUG=""

# ==============================================================================
# Fonctions

# $PROGNAME -n NLINES criterion
function usage {
    
    cat <<EOF

        $PROGNAME: usage:

        $PROGNAME [-html] [ip-or-host [criterion [[NLINES]]]]

        where criterion is one of
        pmem vsize rss cputime_user cputime_system

	-html: additionally generates html data, view with elinks zbxtop.html

EOF
}

function cleanup {
    [[ -z $DEBUG ]] && rm -f zbxtop.html ${DATA_DIR}/zbxtop.tsv
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

# ------------------------------------------------------------------------------
# HTML generation, trickier than needed
# Works sort of ...
# FIXME: should be much more abstract and clean !!
# Now we have to add color depending on value...
function emit_html_prelude {
    cat <<EOF
<html>
  <head>
    <meta http-equiv="refresh" content="10">
    Getting process data from <b>${ZBXHOST}</b>, sorting by <b>${CRITERION}</b>
    <br>
    Total memory: <b>${TOTMEM}</b>, #of cpus: <b>${NCORES} ($(date +%X))</b>
  </head>
  <body>
EOF
}

function emit_html_postlude {
    cat <<EOF
  </body>
</html>
EOF
}

function tsv2htbl_genhdr {
    echo -n "      <tr>"
    # FIXME: disparition of last field!!
    head -1 ${DATA_DIR}/zbxtop.tsv | \
	while read -d '	' field
	do
	    echo -n "<th>${field}</th>"
	done
    echo "</tr>"
}

# BETTER CODED IN lisp ?
# here we have to add add hoc colorization ...
# Is working on html right way of doing it ?
function tsv2htbl_genrows {
    # a while line should be inserted here
    local color=white
    local bgcolor=black
    
    while read -u 3 line
    do
	# At this point we have the '\t'
	colindex=1
        echo -n "       <tr>"
	echo "$line" | while read -d '	' value
	do
	    # HOW TO DO THAT BETTER?
	    if [[ $colindex -eq $CRITERION_INDEX ]]; then
		# simplistic for now
		# FIXME: does bash handle float => NO, use zsh for now
		# FIXME: factorize and more generic
		if   [[ $value -gt 4 ]]; then
		    bgcolor="red"
		elif [[ $value -gt 2.5 ]]; then
		    bgcolor="orange"
		elif [[ $value -gt 1.6 ]]; then
		    bgcolor="yellow"
		else
		    bgcolor="black"
		fi
		echo -n "<td style=\"color:${color};\" bgcolor=\"${bgcolor}\">${value}</td>"
	    else # standard ...
		echo -n "<td>${value}</td>"
	    fi
	    ((colindex+=1))
	done
        echo "</tr>"
    done 3< <(tail -n +2 ${DATA_DIR}/zbxtop.tsv)
}

function tsv2htbl {
    emit_html_prelude
    echo "    <table>"
    tsv2htbl_genhdr 
    tsv2htbl_genrows
    echo "    </table>"
    emit_html_postlude
}

# ==============================================================================
# foo; bar; baz
[[ $1 = "-h" ]] && usage && exit 0
[[ $1 = "-V" ]] && echo "$VERSION" && exit 0
[[ $1 = "-r" ]] && DO_RECORD=1 && shift

[[ $1 = "-html" ]] && DO_HTML_GEN=1 && shift

# On met la dest en 2eme parametre
ZBXHOST=${1:-127.0.0.1}

# pourrait
CRITERION=${2:-pmem}

NLINES=${3:-10}

for fname in utils.sh colorlib.sh
do	     
    filepath=${DIRNAME}/${fname}
    [[ -r $filepath ]] && source $filepath
done

check_commands_prerequisites
check_agent_version_os_type

#[[ -n $DO_RECORD ]] && mkdir -p $RECORD_DIR
mkdir -p $RECORD_DIR $DATA_DIR

CRITERION_INDEX="$(criterion_index $CRITERION)"
#echo CRITERION_INDEX=$AWK_INDEX


totmem=$(zabbix_get -s $ZBXHOST -k 'vm.memory.size[total]' )
TOTMEM=$(convert_to_suffix $totmem)


# When za cache empty, no value => warm up, the horrible way 
zabbix_get -s $ZBXHOST -k 'system.cpu.num[online]' >/dev/null 
sleep 1

#FIXME? system.cpu.num cannot be retrieved shortly after boot
#(agent cache now filled up yet?) => disgracefull errort messages displayed
NCORES=$(zabbix_get -s $ZBXHOST -k 'system.cpu.num[online]')

#echo ncores=$ncores
while true
do
    clear

    # Plain $BRIGHT works, too...
    echo "# Getting process data from $(colored $ZBXHOST $RED), sorting by $(colored $CRITERION $YELLOW) ..."
    echo "# Total memory: $(colored $TOTMEM $GREEN), # of cpus: $(colored $NCORES $BLUE)"
    
    timestamp=$(date +%s)
    tmpfile=${RECORD_DIR}/${timestamp}_proc-get.json
    
    #zabbix_get -s $ZBXHOST -k proc.get 
    zabbix_get -s $ZBXHOST -k proc.get > ${tmpfile}

    # HOW TO add a value specific
    # Apres le .[] on a un objet json par ligne unix (d'ou le head qui fonctionne)
    # HTML : Candidate line for transforming tsb into html table ... works, sort of (of to refresh ?)
    #cat ${DATA_DIR}/zbxtop.tsv | ~/src/tabulate/tabulate.sh -t "Zbxtop Data" -h "Getting data from 127.0.0.1, sorting by pmem" > test3.html

    #FIXME: Quoting of values
    cat $tmpfile | \
	jq -cM ". | sort_by(.${CRITERION}) | reverse | .[] | {$CPU_FIELDS}" | \
	#head -n $NLINES | mlr --j2t cat | tabulate --sep="\t" -1 -f $GRID_STYLE | tee zbxtop.out
	head -n $NLINES | mlr --j2t cat | tee ${DATA_DIR}/zbxtop.tsv | tabulate --sep="\t" -1 -f $GRID_STYLE

    [[ ! -z $DO_HTML_GEN ]] && tsv2htbl > zbxtop.html

    sleep $DELAY

done




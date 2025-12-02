#!/usr/bin/env bash
# ==============================================================================
# Champs intéressants (btop)
# pid program Command User MemB (avec suffix) Cpu%
#
# NOTES: many many new fields available in Zabbix Agt v7.4 !!
#
# ==============================================================================
# Section TODO
# - DONE convertion taille avec suffix
# - DONE affichage timestamps avec date
# - DONE mmettre le noom de la clé en surbrillance (avec colorlib.sh)
# - firstly : read agent.version and OS to adapt list of keys
# - MAYBE : process options : --with-expanded-json ?

# - EN COURS affichage JSON avec tailles FIXME: clause dans le case pas apppelée
# 
# - Faire des listes de clés différentiées pour window / linux / autre

# + MAYBE: faire des fonctions d'analyse :
#   - check du nom de host
#   - check de l'@IP DNS
#   - check des packages -/- à une liste de référence
#   - check des versions de package -/- à une liste de référence
#
# Quel format du fichier de reference ?
#
# ==============================================================================
# Section CONFIGURATION
#
# all linux proc.get fields, as of v7.4 
# pid ppid name cmdline user group uid gid vsize pmem rss data exe hwm lck lib
# peak pin pte size stk swap cputime_user cputime_system state ctx_switches
# threads page_faults pss

HOST=${1:-127.0.0.1}
KEYS_FILE="keys.txt"
VERSION="0.4 (02-12-2025)"

TIMEOUT=1
DEBUG=""

GLOBAL_RC=0

PROGNAME=$(basename $0)

# ==============================================================================
# Section FUNCTIONS
function usage {

    cat <<EOF

    $PROGNAME: usage:

    $PROGNAME [host-or-ip1 [host-or-ip2 ... [host-or-ipN ]]


    requests
 "all" keys from given host_or_ip


    all being the list of keys defined in $KEYS_FILE

EOF
}

# default checked ports are 10050 and 10050
function check_port_openness_for_zabbix {
    # check that we are running on a proxy
    remote_ip=${1:-127.0.0.1}
    port=${2:-10050}

    local_ip=127.0.0.1

    # check local -> distant 
    outgoing_status=$(zabbix_get -s $local_ip  -k "net.tcp.port[${remote_ip},${port}]")
    incoming_status=$(zabbix_get -s $remote_ip -k "net.tcp.port[${local_ip_ip},${port}]")

    echo "port $port status: outgoing ($local_ip -> $remote_ip): $(labeled_colored_status $outgoing_status)"
    echo "port $port status: incoming ($remote_ip -> $local_ip): $(labeled_colored_status $incoming_status)"
}²

# ==============================================================================
#  MAIN

case $1 in
    -h|--help)		usage ; exit 0;;
    -V|--version)	echo "$PROGNAME: $VERSION" ; exit 0 ;;

    -c|--check_ports)	DO_CHECK_PORTS=1 ; shift ;;

    *) : ;;
esac

[[ -r colorlib.sh ]] && source colorlib.sh

for host_or_ip in $*
do
    printf "================================= $(colored "$host_or_ip" 34) \n";

    if [[ ! -z $DO_CHECK_PORTS ]]; then
	printf "# Checking ports openness as requested\n";
	check_port_openness_for_zabbix $host_or_ip 10050
	check_port_openness_for_zabbix $host_or_ip 10051

	continue
    fi
    
    for key in $(grep -v '^#' $KEYS_FILE)
    do
	# Utiliser les fonctions de prompt de Zsh ??
	printf "========== $(colored "$key" 37) \n";
	
	value=$(zabbix_get -t $TIMEOUT -s $host_or_ip -k "$key")
	rc=$?

	# for the size we have to use a cascade of IFs/ELIFs/ELSE clauses
	# because we use a egrep regexp ...
	case $key in # insert size suffixes and timestamps display as datexs

	    *.get*)  len=$(echo $value | jq -C length)
		     echo "[json data with $len elements]" ;;

	    *disco*) len=$(echo $value | jq -C length)
		     echo "[json data with $len elements]" ;;

	    # must cover localtime[utc] 
	    *time*)  date --date=@${value} ;;

	    *packages*) len=$(echo $value | awk -F',' '{print NF}')
		     echo "[list of $len packages]" ;;
	    
	    *)	     echo $value ;;
	esac
	
	((GLOBAL_RC += rc))
    done
    echo
done

exit $GLOBAL_RC







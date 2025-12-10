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
# - Faire des listes de clés différentiées pour window / linux / autre
# - first : read agent.version and OS to adapt list of keys
# - MAYBE : process options : --with-expanded-json ?

# - Rendre plus robuste la recup de l'adresse IP
# Linux proxies zbx : ens192

# - EN COURS affichage JSON avec tailles FIXME: clause dans le case pas apppelée
# 

# + MAYBE: faire des fonctions d'analyse :
#   - check du nom de host
#   - check de l'@IP DNS
#   - check des packages -/- à une liste de référence
#   - check des versions de package -/- à une liste de référence
#
# Quel format du fichier de reference ?
# ------------------------------------------------------------------------------
# More long term
# - faire une version de génération de tableau avec les données résoltées
#   ou plutot genere du json ??x
# - faire une fonction check_health?
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
VERSION="0.5 (10-12-2025)"

TIMEOUT=1
DEBUG=""

GLOBAL_RC=0
PROGNAME=$(basename $0)

CSV_DELIM=";"

#set -x

# ==============================================================================
# Section FUNCTIONS

function usage {

    cat <<EOF

    $PROGNAME: usage

    $PROGNAME [host-or-ip1 [host-or-ip2 ... [host-or-ipN ]]


    requests  "all" keys from given host_or_ip
    all being the list of keys defined in $KEYS_FILE

    $PROGNAME -c|--check-ports [host-or-ip1 [host-or-ip2 ... [host-or-ipN ]]
    check ip connectivité for zabbix ports (but could work with other ports)
EOF
}

# default checked ports are 10050 and 10050
function check_port_openness_for_zabbix {
    # check that we are running on a proxy
    remote_ip=${1:-127.0.0.1}
    port=${2:-10050}

    local_ip=127.0.0.1
    # FIXME: make more robust!!
    local_ip=127.0.0.1

    # check local -> distant 
    outgoing_status=$(zabbix_get -s $local_ip  -k "net.tcp.port[${remote_ip},${port}]")
    incoming_status=$(zabbix_get -s $remote_ip -k "net.tcp.port[${local_ip},${port}]" )

    echo "port $port status: outgoing ($local_ip  -> $remote_ip): $(labeled_colored_status $outgoing_status)"
    echo "port $port status: incoming ($remote_ip -> $local_ip):  $(labeled_colored_status $incoming_status)"
}

# ==============================================================================
#  MAIN
case $1 in
    -h|--help)		usage ; exit 0;;
    -V|--version)	echo "$PROGNAME: $VERSION" ; exit 0 ;;

    -c|--check_ports)	DO_CHECK_PORTS=1 ; shift ;;

    -a|--array-output)	DO_OUTPUT_ARRAY=1 ; shift ;;
    #*) : ;;
esac


echo FOO
for libfilename in colorlib.sh utils.sh
do
    if [[ -r $libfilename ]]; then source $libfilename; fi
done

echo BAR

for host_or_ip in $*
do
    printf "================================= $(colored "$host_or_ip" 34)\n";

    if [[ ! -z $DO_CHECK_PORTS ]]; then
	printf "# Checking ports openness as requested\n";
	
	check_port_openness_for_zabbix $host_or_ip 10050
	check_port_openness_for_zabbix $host_or_ip 10051

	continue
    fi
    
    for key in $(grep -v '^#' $KEYS_FILE)
    do
	# Utiliser les fonctions de prompt de Zsh ??
	if [[ -z $DO_OUTPUT_ARRAY ]]; then printf "========== $(colored "$key" 37)\n"; fi
	
	value=$(zabbix_get -t $TIMEOUT -s $host_or_ip -k "$key")
	rc=$?

	# for the size we have to use a cascade of IFs/ELIFs/ELSE clauses
	# because we use a egrep regexp ...
	case $key in # insert size suffixes and timestamps display as datexs

	    *.get*)  len=$(echo $value | jq -C length)
		     valuestr="[json data with $len elements]" ;;

	    *disco*) len=$(echo $value | jq -C length)
		     valuestr="[json data with $len elements]" ;;

	    # must cover localtime[utc] 
	    *time*)  valuestr=$(date --date="@${value}") ;;

	    # use suffix adding ... 
	    *.size*) valuestr=$(convert_to_suffix $value) ;;

	    *packages*) len=$(echo $value | awk -F',' '{print NF}')
		     valuestr="[list of $len packages]" ;;
	    
	    *)	     valuestr=$value ;;

	esac
	if [[ ! -z $DO_OUTPUT_ARRAY ]]; then delim="$CSV_DELIM"; else delim="\n"; fi
	#echo $valuestr
	printf "%s\n" "$valuestr" #$delim
	
	((GLOBAL_RC += rc))
    done

    echo
done

exit $GLOBAL_RC







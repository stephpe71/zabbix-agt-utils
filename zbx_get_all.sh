#!/usr/bin/env bash
# ==============================================================================
# A small sc
# should be named zbxtop (Zabbix Agt Top)
# but zztop was overly top cool !
# ==============================================================================
# Champs intéressants (btop)
# pid program Command User MemB (avec suffix) Cpu%
#
# NOTES: many many new fields available in Zabbix Agt v7.4 !!
#
# ==============================================================================
# Section CONFIGURATION
#
# all linux proc.get fields, as of v7.4 
# pid ppid name cmdline user group uid gid vsize pmem rss data exe hwm lck lib
# peak pin pte size stk swap cputime_user cputime_system state ctx_switches
# threads page_faults pss
#set -x

HOST=${1:-127.0.0.1}
KEYS_FILE="keys.txt"
VERSION="0.2 (29-11-2025)"

TIMEOUT=1

DEBUG=""

# ==============================================================================
# Section FUNCTIONS
function usage {
    cat <<EOF

    $PROGNAME: usage:

    $PROGNAME [host-or-ip1 [host-or-ip2 ... [host-or-ipN ]]

    request "all" keys from given host_or_ip

    all being the list of keys defined in $KEYS_FILE

EOF
}

# ==============================================================================
#  MAIN

for host_or_ip in $*
do
    for key in $(grep -v '^#' $KEYS_FILE)
    do
	echo "========= $key";
	zabbix_get -t $TIMEOUT -s $host_or_ip -k "$key"
    done
done

exit 0




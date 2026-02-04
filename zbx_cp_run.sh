#!/usr/bin/bash
# ==============================================================================
# An idea of script deployment
# Maybe the necessity of base64-ing the
# data is useless (coming from interactive usage )
# ==============================================================================
# TODO: many thi ngs
# - checks avail
# - check checkum
# ==============================================================================
RWD=/tmp

WIDTH=150
PROGNAME=$(basename $0)

PERMISSIONS=755

VERSION="0.2 (04-02-2026)"

TRACE="on"
TRACE=""

# ==============================================================================
function usage {

    cat<<EOF

    $PROGNAME: usage:

    $PROGNAME script ip-or-host

    $PROGNAME will copy (piece by piece) script to $target and run said script

EOF
}

# ==============================================================================
case $1 in
    -h|--help)		usage && exit 0 ;;
    -V|--version)	echo "$PROGNAME: version $VERSION" && exit 0 ;;
    *)		: ;;
esac

IP_OR_HOST=$1
shift
SCRIPT=$1
shift

# ------------------------------------------------------------------------------
# the checks
# Protection contre cible not found ou sr not available
#zabbix_get -s $IP_OR_HOST -k ssytem.run[date] >/dev/null 

LOCAL_CHECKSUM=$(md5sum $SCRIPT | awk '{print $1}')

# ------------------------------------------------------------------------------
[[ ! -z $TRACE ]] && echo "# Copie progressive du script $SCRIPT sur la cible ${HOST_OR_IP}:${RWD} ... "

zabbix_get -s $IP_OR_HOST -k "system.run[echo '' > ${RWD}/f ]" >/dev/null
gzip -c $SCRIPT | base64 -w${WIDTH} | while read line
do
    #echo $line
    zabbix_get -s $IP_OR_HOST -k "system.run[echo ${line} >> ${RWD}/f ]" >/dev/null
done

[[ ! -z $TRACE ]] && echo "# Decompression du script sur la cible ... "
zabbix_get -s $IP_OR_HOST -k "system.run[cat ${RWD}/f | base64 -d | gunzip -c > ${RWD}/s]" >/dev/null

# # FIXME: the process must add some spaces somewhere (as copie scripts much resembles original ones)
# [[ ! -z $TRACE ]] && echo "# Verification du checksum du script sur la cible ... "
# REMOTE_CHECKSUM=$(zabbix_get -s $IP_OR_HOST -k "system.run[md5sum ${RWD}/s | awk '{print \$1}']")

# if [[ $REMOTE_CHECKSUM != $LOCAL_CHECKUM ]]; then
#     echo "# Remote cksum ($REMOTE_CHECKSUM) and local checkum ($LOCAL_CHECKSUM) do not match, exiting ... "
#     exit 1
# fi

[[ ! -z $TRACE ]] && echo "# Ajout des droits d'execution du script sur la cible ... "
zabbix_get -s $IP_OR_HOST -k "system.run[chmod 755 ${RWD}/s]" >/dev/null

[[ ! -z $TRACE ]] && echo "# Renommage du script sur la cible ... "
zabbix_get -s $IP_OR_HOST -k "system.run[mv ${RWD}/s ${RWD}/${SCRIPT}]" >/dev/null

[[ ! -z $TRACE ]] && echo "# Execution du script sur la cible avec les options '$*' ... "
zabbix_get -s $IP_OR_HOST -k "system.run[${RWD}/${SCRIPT} $*]"

# ------------------------------------------------------------------------------
# checksum
#zabbix_get -s $IP_OR_HOST -k system.run[md5sum 



    



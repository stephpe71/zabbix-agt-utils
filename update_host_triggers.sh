#!/usr/bin/env bash
# ====================================================================================================================
# Script de mise a jour de triggers d'une ou de machines données ...

# RAF :
# - recup du toke par interrog de la machine, et non pas en dur ...
#
# ====================================================================================================================

URL="http://XXXXXX/api_jsonrpc.php"

# A utiliser quand pb de quote resolu
TOKEN="b8dd01180793d2

host=${1:-YYYYYYYYYYY:}
string=${2:-EPI}

PROGNAME=$(basename $0)

# ====================================================================================================================

#function usage {
#  set -x
#  cat<<EOF
#
#       PROGNAME: usage:
#
#       PROGNAME
#
#        recherche les triggers zabbix pout hostname, filtre selon pattern et execute un update sur
#        les trigger ids trouvés ...
#
#EOF
#}

# ====================================================================================================================
#[[ $1 = "-h" ]] && usage && exit 0

# Recupération de/des triggers ids a partir du nom de hosts
ans1=$(curl -s -k -H "Content-Type: application/json" -X POST -d "{\"jsonrpc\":\"2.0\",\"method\":\"trigger.get\",\"params\":{\"host\": \"${host}\"},\"id\":6,\"auth\":\"${TOKEN}\"}" $URL)

trigger_ids=$(echo $ans1 | jq -c ".result[] | select(.description | match(\"${string}\")) | {triggerid}" | tr -d '"{}' | cut -d: -f2)

# ====================================================================================================================
# Update

for tgid in $trigger_ids
do
  echo "====== $tgid"
  echo curl -s -k -H "Content-Type: application/json" -X POST -d "{\"jsonrpc\": \"2.0\", \"method\": \"trigger.update\",\"params\": { \"triggerid\": \"${tgid}\", \"status\": 0}, \"id\": 1, \"auth\":\"${TOKEN}\"}" $URL

done





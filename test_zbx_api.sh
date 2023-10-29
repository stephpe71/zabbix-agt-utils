#!/usr/bin/env bash
# ==================================================================================================
# TENTATIVE de création d'objets (items pour commencer)
# WORKS ->

# ATTENTION :
# -double quoting des params
# - suppression des " dans les reponses !

# ==================================================================================================
# Codes Items

# param type
# 0 - Zabbix agent;
# 2 - Zabbix trapper;
# 3 - Simple check;
# 5 - Zabbix internal;
# 7 - Zabbix agent (active);
# 9 - Web item;
# 10 - External check;
# 11 - Database monitor;
# 12 - IPMI agent;
# 13 - SSH agent;
# 14 - Telnet agent;
# 15 - Calculated;
# 16 - JMX agent;
# 17 - SNMP trap;
# 18 - Dependent item;
# 19 - HTTP agent;
# 20 - SNMP agent;
# 21 - Script

# value_type
# 0 - numeric float;
# 1 - character;(255)
# 2 - log;
# 3 - numeric unsigned;
# 4 - text.


# # item preproc type
# 5 regexp
# 12 json path
# 21 javascript

# ==================================================================================================
URL="http://localhost/zabbix/api_jsonrpc.php"
HEADER="'Content-Type: application/json-rpc'"

# ==================================================================================================
id=1

# 1 CONNECTION
#reqdict=
ans=$(curl -s -X POST -H 'Content-Type: application/json-rpc' \
  -d '{ "jsonrpc": "2.0", "method": "user.login", "params": { "user": "Admin", "password": "zabbix" }, "id": 1, "auth": null }' $URL)

# 
#=<{"jsonrpc":"2.0","result":"b464417570feddd4d78a69ce9473f0de","id":1}
token=$(echo $ans | jq '.result' | tr -d '"')
echo "token=$token"

# --------------------------------------------------------------------------------------------------
# 2 GET HOSTS
ans=$(curl -s -X POST -H 'Content-Type: application/json-rpc' \
  -d "{ \"jsonrpc\": \"2.0\", \"method\": \"host.get\", \"params\": { \"output\": [ \"hostid\", \"host\"], \"selectInterfaces\": [ \"interfaceid\", \"ip\"]}, \"id\": 2, \"auth\": \"$token\" }" $URL)

#=> {"jsonrpc":"2.0","result":[{"hostid":"10084","host":"Zabbix server","interfaces":[{"interfaceid":"1","ip":"127.0.0.1"}]}],"id":2}%
#echo "ans=$ans"

#result=$(echo $ans | jq '.result')
#echo "result=$result"

hostid=$(echo $ans | jq '.result[0].hostid' | tr -d '"')
echo "hostid=$hostid"

# --------------------------------------------------------------------------------------------------
# 2 GET HOSTS
# 3 CREATE ITEM(S)
#ans="{\"jsonrpc\":\"2.0\",\"result\":[{\"hostid\":\"10084\",\"host\":\"Zabbix server\",\"interfaces\":[{\"interfaceid\":\"1\",\"ip\":\"127.0.0.1\"}]}],\"id\":2}"

# les params
name=""
key=""

item_type=18 # dependant item
value_type=3

# interfaceid is NECESSARY for CERTAIN item types (not dependant

# preprocessing est une clé supplementaire "preprocessing" (
# docu dans ma methode item.create des APIs zabbix
# ex doc: "preprocessing": [{"type":1, "params": "0.01", "error_handler":1,"error_handler_params":"",}"
ans=$(curl -s -X POST -H 'Content-Type: application/json-rpc' \
	   -d "{ \"jsonrpc\": \"2.0\", \"method\": \"item.create\", \"params\": { \"name\": \"$name\", \"key_\": \"$key\", \"hostid\": \"$hostid\", \"type\": $item_type, \"value_type\": $value_type }, \"auth\": \\"$token\\", \"id\": 3 }" $URL)



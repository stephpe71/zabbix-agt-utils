#!/usr/bin/env bash
# ==============================================================================
HOST=127.0.0.1
TMPFILE=tmp$$

#NAVIGATORS="firefox chromium. chrome edge"
NAVIGATORS="firefox chromium.sh" #chrome edge

DEBUG=1

# ==============================================================================
# Main boucle

rm -f $TMPFILE

# for tests
for navigator in firefox chromium.sh #chrome edge
do
    os_name=$(zabbix_get -s $HOST -k system.uname | awk '{print $1}')

    case $os_name in
	Windows)	navigator="${navigator}.exe" ;;

	*)		: ;;
    esac

    zabbix_get -s $HOST -k "proc.get[${navigator}]" | jq -cM '.[] | {user,name}' | mlr --j2t cat | tail +2 >> $TMPFILE

done

for user in $(cat $TMPFILE | awk '{print $1}' | uniq); do
    echo "user $user" ; grep $user $TMPFILE | uniq -c;
done

# ==============================================================================
# Cleaning
[[ -z $DEBUG ]] && rm -f $TMPFILE

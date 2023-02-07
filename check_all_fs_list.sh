#!/usr/bin/env bash

# 1p 
# 
echo "["
#for ip in $(cat liste.txt | grep -v '^$' | awk '{print $2}')

# liste.txt is a server list in a format
# <server-name> <server-ip>
for hn in $(cat liste.txt | grep -v '^$' | awk '{print $1}')
do
   ip=$(fgrep $hn liste.txt | awk '{print $2}')

   zabbix_get -t 1 -s $ip -k agent.ping 2>/dev/null >/dev/null
   rc=$?
   [[ $rc -gt 0 ]] && break

   printf "{\"hostname\":\"${hn}\""
   for fs in / /boot /home /var /var/log /opt
   do
      #echo -e "${fs}: \c"
      value=$(zabbix_get -t 1 -s $ip -k "vfs.fs.size[${fs},pused]" 2>/dev/null)
      printf ",\"${fs}\":\"${value}\"" $fs $value
   done
   printf "},\n"
done

# FIXME: supp error line when not accessible
echo "]"


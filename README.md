# zabbix-agt-utils

Various utilities for/via zabbix agent

- zafind: a find "clone" base on new capabilities 'vfs.dir.get' of zabbix agent (v6.0)

- zacheck: an example of cli 'check' tool, built as an example as replacement for a
  similar ssh-based check tool

- check_all_fs_list.sh: create a synthetic csv for gathering main fs occupation on a bunch of hosts: 
   a- check_all_fs_list.sh > tmp.json
   b- vi tmp.json
   c- mlr --fs ';' --j2c cat tmp.json > tmp.csv
   d- import tmp.csv in Excel, or visidata ...
   

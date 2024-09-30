# -*- conf -*-
#
# Fish shell completion for the 'zabbix_get' command
# (the one most used on the CLI)
#
# Inspired by default zabbix_get.fish
#
# Author:	Stephane Perrot 
# Version:	0.7
# Date:		2024-09-30
#
# DISCLAIMER : I'm new to fish, learning by examples
#
# TODO:
#  - documentation for each key/item (keep it short)
#  - completion of filenames/dirnames in [] would be nice
#
# This file is in the Public Domain 
#

# Variables for categoring the multiple keys (-k parameters) to the zabbix_get cmd
set -l _zg_agent_hosts	"127.0.0.1 localhost"

# General
# complete -c zabbix_get -f -s s -l host -d "Specify host name or IP address of a host."
complete -c zabbix_get -f -s p -l port -d "Specify port number of agent running on the host."
complete -c zabbix_get -f -s I -l source-address -d "Specify source IP address."
complete -c zabbix_get -f -s t -l timeout -d "Specify timeout."
complete -c zabbix_get -f -s h -l help -d "Display this help and exit."
complete -c zabbix_get -f -s V -l version -d "Output version information and exit."

# SPE
# No need to define completion all at once 
# 1 line by completion item is apparently acceptable...
complete --require-parameter zabbix_get -f -s s -d "Host name or IP address." \
	-a "$_zg_agent_hosts"

# Defined below, with a line for each item
#complete -c zabbix_get -f -s k -l key -d "Specify key of item to retrieve value for."

# Start of auto generated list
# Auto generated completion lines for fish
# from keys list as of Zabbix Agent (variant 1) v7.0, FreeBSD

complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a agent.hostmetadata
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a agent.hostname
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a agent.ping
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a agent.variant
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a agent.version

complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a eventlog
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a eventlog.count

complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a kernel.maxfiles
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a kernel.maxproc

complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a modbus.get

complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a net.dns
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a net.dns.perf
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a net.dns.record
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a net.if.collisions
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a net.if.discovery
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a net.if.in
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a net.if.out
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a net.if.total
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a net.tcp.dns
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a net.tcp.dns.query
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a net.tcp.listen
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a net.tcp.port
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a net.tcp.service
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a net.tcp.service.perf
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a net.udp.listen
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a net.udp.service
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a net.udp.service.perf

complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a proc.get
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a proc.mem
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a proc.num

complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a system.boottime
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a system.cpu.discovery
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a system.cpu.intr
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a system.cpu.load
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a system.cpu.num
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a system.cpu.switches
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a system.cpu.util
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a system.hostname
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a system.localtime
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a system.run
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a system.sw.arch
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a system.swap.size
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a system.uname
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a system.uptime
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a system.users.num
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a vfs.dev.read
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a vfs.dev.write
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a vfs.dir.count
complete -r -c  zabbix_get -f -s k -d "<Item zrgrepdoc>" -a vfs.dir.get
complete -r -c  zabbix_get -f -s k -d "<Item doc>" -a vfs.dir.size

# On ne met pas de -f pour vfs.file.
complete -r -c  zabbix_get -s k -d "<Item doc>" -a vfs.file.cksum
complete -r -c zabbix_get -s k -d "<Item doc>" -a vfs.file.contents
complete -r -c zabbix_get -s k -d "<Item doc>" -a vfs.file.exists
complete -r -c zabbix_get -s k -d "<Item doc>" -a vfs.file.get
complete -r -c zabbix_get -s k -d "<Item doc>" -a vfs.file.md5sum
complete -r -c zabbix_get -s k -d "<Item doc>" -a vfs.file.owner
complete -r -c zabbix_get -s k -d "<Item doc>" -a vfs.file.permissions
complete -r -c zabbix_get -s k -d "<Item doc>" -a vfs.file.regexp
complete -r -c zabbix_get -s k -d "<Item doc>" -a vfs.file.regmatch
complete -r -c zabbix_get -s k -d "<Item doc>" -a vfs.file.size
complete -r -c zabbix_get -s k -d "<Item doc>" -a vfs.file.time

complete -r -c zabbix_get -f -s k -d "<Item doc>" -a vfs.fs.discovery
complete -r -c zabbix_get -f -s k -d "<Item doc>" -a vfs.fs.get
complete -r -c zabbix_get -f -s k -d "<Item doc>" -a vfs.fs.inode
complete -r -c zabbix_get -f -s k -d "<Item doc>" -a vfs.fs.size
complete -r -c zabbix_get -f -s k -d "<Item doc>" -a vm.memory.size
complete -r -c zabbix_get -f -s k -d "<Item doc>" -a web.page.get
complete -r -c zabbix_get -f -s k -d "<Item doc>" -a web.page.perf
complete -r -c zabbix_get -f -s k -d "<Item doc>" -a web.page.regexp
complete -r -c zabbix_get -f -s k -d "<Item doc>" -a zabbix.stats


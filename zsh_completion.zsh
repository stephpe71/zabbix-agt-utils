# Old fashion Zsh completion (compctl based) for some zabbix utilities
# Author:		Stéphane Perrot
# Date:			April 2023

# EDIT Put your list of hosts here
za_hosts=(host1 host2 hostN)

# Keys taken from v6.4 doc: 
za_keys=(kernel.maxfiles kernel.maxproc kernel.openfiles log log.count logrt logrt.count modbus.get net.dns net.dns.record net.if.collisions net.if.discovery net.if.in net.if.out net.if.total net.tcp.listen net.tcp.port net.tcp.service net.tcp.service.perf net.tcp.socket.count net.udp.listen net.udp.service net.udp.service.perf net.udp.socket.count proc.cpu.util proc.get proc.mem proc.num sensor system.boottime system.cpu.discovery system.cpu.intr system.cpu.load system.cpu.num system.cpu.switches system.cpu.util system.hostname system.hw.chassis system.hw.cpu system.hw.devices system.hw.macaddr system.localtime system.run system.stat system.sw.arch system.sw.os system.sw.os.get system.sw.packages system.sw.packages.get system.swap.in system.swap.out system.swap.size system.uname system.uptime system.users.num vfs.dev.discovery vfs.dev.read vfs.dev.write vfs.dir.count vfs.dir.get vfs.dir.size vfs.file.cksum vfs.file.contents vfs.file.exists vfs.file.get vfs.file.md5sum vfs.file.owner vfs.file.permissions vfs.file.regexp vfs.file.regmatch vfs.file.size vfs.file.time vfs.fs.discovery vfs.fs.get vfs.fs.inode vfs.fs.size vm.memory.size web.page.get web.page.perf web.page.regexp agent.hostmetadata agent.hostname agent.ping agent.variant agent.version)

# For zabbix_get
compctl -x \
    's[-]' -k "(s k)" - \
    'C[-1,-s]' -k za_hosts - \
    'C[-1,-k]' -k za_keys - \
    -- zabbix_get


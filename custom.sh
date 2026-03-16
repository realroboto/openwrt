#!/bin/sh

ethtool -K eth1 rx-udp-gro-forwarding on rx-gro-list off
ethtool -K pppoe-wan rx-udp-gro-forwarding on rx-gro-list off

/etc/init.d/sysntpd enable
/etc/init.d/sysntpd restart
date

exit 0

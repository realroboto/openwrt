#!/bin/sh

#ethtool -K eth1 gro off
#ethtool -K pppoe-wan gro off

/etc/init.d/sysntpd enable
/etc/init.d/sysntpd restart
date

reboot

exit 0

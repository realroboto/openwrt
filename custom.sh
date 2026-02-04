#!/bin/sh

/etc/init.d/sysntpd enable
/etc/init.d/sysntpd restart
date

exit 0

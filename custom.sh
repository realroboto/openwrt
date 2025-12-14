#!/bin/sh

uci del system.ntp.enabled
uci del system.ntp.enable_server
uci del system.ntp.server
uci add_list system.ntp.server='2606:4700:f1::1'	# time.cloudflare.com
uci add_list system.ntp.server='2606:4700:f1::123'	# time.cloudflare.com
uci add_list system.ntp.server='162.159.200.123'  	# time.cloudflare.com
uci add_list system.ntp.server='162.159.200.1'    	# time.cloudflare.com
uci add_list system.ntp.server='216.239.35.0'     	# time.google.com
uci add_list system.ntp.server='216.239.35.4'     	# time.google.com
uci add_list system.ntp.server='216.239.35.8'     	# time.google.com
uci add_list system.ntp.server='216.239.35.12'    	# time.google.com
uci add_list system.ntp.server='time.cloudflare.com'
uci add_list system.ntp.server='time.google.com'
uci add_list system.ntp.server='time.apple.com'
uci add_list system.ntp.server='time.facebook.com'

uci commit system

reboot

exit 0

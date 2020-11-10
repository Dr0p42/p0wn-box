#!/bin/sh

# Display banner
cat /etc/motd

# Make sure /dev/net/tun exists if openvpn want to be used. 
mkdir -p /dev/net
stat /dev/net/tun 2>&1 > /dev/null || mknod /dev/net/tun c 10 200 && chmod 600 /dev/net/tun

exec $@
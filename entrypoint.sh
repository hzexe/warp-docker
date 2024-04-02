#!/bin/bash

# exit when any command fails
set -e

# create a tun device
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

# start dbus
mkdir -p /run/dbus
if [ -f /run/dbus/pid ]; then
  rm /run/dbus/pid
fi
dbus-daemon --config-file=/usr/share/dbus-1/system.conf

# start the daemon
warp-svc &

# sleep to wait for the daemon to start, default 2 seconds
sleep "$WARP_SLEEP"

# if /var/lib/cloudflare-warp/reg.json not exists, register the warp client
if [ ! -f /var/lib/cloudflare-warp/reg.json ]; then
    warp-cli register && echo "Warp client registered!"
    # if a license key is provided, register the license
    if [ -n "$WARP_LICENSE_KEY" ]; then
        echo "License key found, registering license..."
        warp-cli set-license "$WARP_LICENSE_KEY" && echo "Warp license registered!"
    fi
    # if a endpoint is provided,set tunnel endpoint
    if [ -n "$WARP_ENDPOINT" ]; then
        echo "Endpoint found"
        warp-cli tunnel endpoint reset
        warp-cli tunnel endpoint set "$WARP_ENDPOINT"
    fi
    # connect to the warp server
    warp-cli connect
else
    echo "Warp client already registered, skip registration"
fi

# start the proxy
gost $GOST_ARGS

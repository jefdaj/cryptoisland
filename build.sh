#!/usr/bin/env bash

# Tries to build the site. If successful it will also serve it at
# localhost:8000, and update when files are changed. If unsuccessful it falls
# back to GHCi.

set -x

cd "$( dirname "${BASH_SOURCE[0]}" )/src"

rm -rf .hakyll-cache
rm -rf ../.site

# which apt-get &> /dev/null && sudo apt-get install libgmp-dev zlib1g-dev

# uncomment to allow LAN access to your dev machine,
# to test the site with mobile phones and such
# (adjust destination ip pattern to match your lan first)
# sudo iptables -F # warning: clobbers your firewall settings until reboot
# sudo sysctl -w net.ipv4.conf.all.route_localnet=1
# sudo iptables -t nat -I PREROUTING -p tcp -d 10.0.0.0/24 --dport 8000 -j DNAT --to-destination 127.0.0.1:8000

(runhaskell site.hs clean && runhaskell site.hs watch) || ghci

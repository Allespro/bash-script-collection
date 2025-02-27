#!/bin/bash
AS="16345"
PORT="1723"
RULES_FILE="/etc/iptables/rules.v4"

# Get IP ranges
RANGES=$(whois -h whois.radb.net -- "-i origin AS${AS}" | grep -Eo '([0-9.]+){4}/[0-9]+')

# iptables -F # delete old rules if need

# ACCEPT only from ASN ip range
for RANGE in $RANGES; do
  #echo $RANGE
  iptables -A INPUT -p tcp --dport $PORT -s $RANGE -j ACCEPT
done

# Block all others
iptables -A INPUT -p tcp --dport $PORT -j DROP

iptables-save > $RULES_FILE

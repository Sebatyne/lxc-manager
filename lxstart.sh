#!/bin/bash

BRIDGE_NAME="br0"
GATEWAY_IP="192.168.9.1/24"
EXT_IF="wlan0"


######################################################################
# Argument Parser
######################################################################
while getopts "b:g:i:h" opt; do
    case $opt in
        b)
            BRIDGE_NAME=$OPTARG
            ;;
        g)
            GATEWAY_IP=$OPTARG
            ;;
        i)
            EXT_IF=$OPTARG
            ;;
        h)
            echo "Read the script for help"
            ;;
        \?)
            echo "Invalid option . -$OPTARG"
            ;;
    esac
done

shift $((OPTIND-1))

######################################################################
# Function declarations
######################################################################
bridge_create() {
    ip a | grep $BRIDGE_NAME > /dev/null

    if [ $? -ne 0 ];
    then
        brctl addbr $BRIDGE_NAME
        ip a add dev $BRIDGE_NAME $GATEWAY_IP
        ip link set $BRIDGE_NAME up
    fi
}

nat_create() {
    # Allow IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward

    # Set up NAT rules
    /sbin/iptables -t nat -A POSTROUTING -o $EXT_IF -j MASQUERADE
    /sbin/iptables -A FORWARD -i $EXT_IF -o $BRIDGE_NAME -m state --state RELATED,ESTABLISHED -j ACCEPT
    /sbin/iptables -A FORWARD -i $BRIDGE_NAME -o $EXT_IF -j ACCEPT
}

######################################################################
# Main
######################################################################
bridge_create
nat_create
lxc-start -n $1 -d

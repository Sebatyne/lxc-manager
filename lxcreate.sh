#!/bin/bash

BRIDGE_NAME="lxbr0"
LXPATH="/var/lib/lxc"
DISTRIB="debian"
VERSION="wheezy"

######################################################################
# Argument Parser
######################################################################
while getopts "i:g:b:n:h" opt; do
    case $opt in
        i)
            IP=$OPTARG
            ;;
        g)
            GATEWAY_IP=$OPTARG
            ;;
        n)
            VM_NAME=$OPTARG
            ;;
        h)
            print_help
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
print_help() {
    cat > /dev/stdout << EOF
lxcreate -i IP_CIDR -g GATEWAY_IP -n NAME
EOF
}

######################################################################
# Common checks
######################################################################
# Abort if not all mandatory parameters are not set
if [ -z $IP ] || [ -z $GATEWAY_IP ] || [ -z $VM_NAME ];
then
    echo "Please give all mandatory arguments"
    print_help
    exit 1
fi

if [ -d $LXPATH/$VM_NAME ];
then
    echo "$LXPATH/$VM_NAME already exists, you cannot create a VM"
else
    mkdir -p $LXPATH/$VM_NAME/rootfs
fi

######################################################################
# Main
######################################################################
lxc-create -t $DISTRIB -n $VM_NAME -- -r $VERSION

# Write config file
cat > $LXPATH/$VM_NAME/config << EOF
lxc.network.type = veth
lxc.network.flags = up
lxc.network.link = $BRIDGE_NAME
lxc.rootfs = $LXPATH/$VM_NAME/rootfs
lxc.network.ipv4 = $IP
lxc.network.ipv4.gateway = $GATEWAY_IP

# Common configuration
lxc.include = /usr/share/lxc/config/debian.common.conf

# Container specific configuration
lxc.mount = $LXPATH/$VM_NAME/fstab
lxc.utsname = $VM_NAME
lxc.arch = amd64
EOF

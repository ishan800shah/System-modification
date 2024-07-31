#!/bin/bash

set -e

# Function to transfer and execute the configuration script on a remote server
deploy_and_run() {
    local server=$1
    shift
    local params="$@"

    scp configure-host.sh remoteadmin@$server:/root/configure-host.sh
    ssh remoteadmin@$server -- /root/configure-host.sh $params
}

# Main script execution
verbose=false
params=""
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -verbose) verbose=true; params="$params -verbose" ;;
        *) params="$params $1" ;;
    esac
    shift
done

deploy_and_run server1-mgmt $params -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4
deploy_and_run server2-mgmt $params -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3

./configure-host.sh $params -hostentry loghost 192.168.16.3
./configure-host.sh $params -hostentry webhost 192.168.16.4

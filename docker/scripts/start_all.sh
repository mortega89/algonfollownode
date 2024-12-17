#!/bin/sh

set -e

# Start algod
cp node/genesisfiles/${ALGORAND_NETWORK}/genesis.json ${ALGORAND_DATA}
/algorand/node/algod -l 0.0.0.0:8080 &
sleep 5

# Store algod.token and algod.admin.token in kubernetes secret. Tokens are shared among node instances when replicas are greater than 1. 
export token=`kubectl get secrets/algon-api-token -o json  | jq .data | jq -r '."algod.token"' | base64 -d`
if [ "$token" = "null" ]; then
    kubectl create secret generic algon-api-token \
                --from-file=node/data/algod.token \
                --from-file=node/data/algod.admin.token \
                --save-config \
                --dry-run=client \
                -o yaml |
                kubectl apply -f -
else
    echo `kubectl get secrets/algon-api-token -o json  | jq .data | jq -r '."algod.token"' | base64 -d` >  node/data/algod.token
    echo `kubectl get secrets/algon-api-token -o json  | jq .data | jq -r '."algod.admin.token"' | base64 -d` >  node/data/algod.admin.token
fi
export token=

# Fast catchup
/algorand/node/goal node status

# Do not kill the pod
sleep infinity

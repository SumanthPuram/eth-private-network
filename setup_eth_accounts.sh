#!/usr/bin/env bash
ETH_DIR=/tmp/eth-local
DATA_DIR=data
NUM_NODES=2
GENESIS_FILE="genesis.json"
PASSWORD="ethereumlocal"
NETWORK_ID=5678

#Color
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
CYAN='\033[0;36m'

if [ -f ${GENESIS_FILE} ]; then
  echo "Found Genesis file"
else
  echo "No Genesis file. Exiting"
  exit 0
fi

mkdir -p ${ETH_DIR}
TMP_GENESIS_FILE=${ETH_DIR}/${GENESIS_FILE}.tmp
cp ${GENESIS_FILE} ${TMP_GENESIS_FILE}
cd ${ETH_DIR}
ps -ef | grep geth | grep ${ETH_DIR} | awk '{print $2}' | xargs kill -9
rm -rf ${DATA_DIR}
echo ${PASSWORD}  > password.txt
for (( num = 1; num <= ${NUM_NODES}; num++ )) 
do
  mkdir -p ${DATA_DIR}/0${num}
  log_file=${ETH_DIR}/data/0${num}/console.log
  geth --datadir=./data/0${num} --password password.txt account new > account0${num}.txt 2> ${log_file} 
  #Copy the addresses into genesis.json
  ACCOUNT=`cat account0${num}.txt | awk '{print $2}' | sed 's/[{|}]//g'`
  sed -i '' 's/ACCOUNT0${num}/${ACCOUNT}/' ${TMP_GENESIS_FILE}
done

echo "Created accounts for each node in ${ETH_DIR}/account*.txt"

for (( num = 1; num <= ${NUM_NODES}; num++ )) 
do
  log_file=${ETH_DIR}/data/0${num}/console.log
  geth --datadir "${ETH_DIR}/data/0${num}" init ${TMP_GENESIS_FILE} &> ${log_file}
  geth --datadir "${ETH_DIR}/data/0${num}"  --port 3030${num} --rpcport 854${num} --ipcpath geth0${num} --nodiscover --networkid ${NETWORK_ID} --rpc --rpcapi="db,eth,net,web3,personal" --rpccorsdomain "*" &> ${log_file} &
  echo "Node: 0${num}"
  echo "Logging into file: ${log_file}"
  echo "Connect to the console with following command:"
  echo "${CYAN}"
  echo "geth attach ipc:${ETH_DIR}/data/0${num}/geth0${num}"
  echo "$NC"
done


# Add nodes as peers
GET_NODE_INFO_JSON_REQ='{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}'
BASE_IPC_END_POINT=${ETH_DIR}/${DATA_DIR}/01/geth01

BASE_PEER_ENODE=`echo ${GET_NODE_INFO_JSON_REQ} | nc -U ${BASE_IPC_END_POINT} | jq '.result.enode'`

for (( num = 2; num <= ${NUM_NODES}; num++ ))
do
  ADD_PEER_JSON_REQ={\"jsonrpc\":\"2.0\",\"method\":\"admin_addPeer\",\"params\":[${BASE_PEER_ENODE}],\"id\":${num}}
  echo "Run the following command to connect Node: 0${num}"
  echo "${GREEN}"
  echo "echo '${ADD_PEER_JSON_REQ}' | nc -U ${ETH_DIR}/${DATA_DIR}/0${num}/geth0${num}"
  echo "$NC"
done

disown
exit 0

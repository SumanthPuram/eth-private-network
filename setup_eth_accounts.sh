DATA_DIR=/tmp/eth-local
NUM_NODES=2
GENESIS_FILE="genesis.json"
PASSWORD="ethereumlocal"
NETWORK_ID=5678
if [ -f ${GENESIS_FILE} ]; then
  echo "Found Genesis file"
else
  echo "No Genesis file. Exiting"
  exit 0
fi

mkdir -p ${DATA_DIR}
TMP_GENESIS_FILE=${DATA_DIR}/${GENESIS_FILE}.tmp
cp ${GENESIS_FILE} ${TMP_GENESIS_FILE}
cd ${DATA_DIR}
ps -ef | grep geth | grep ${DATA_DIR} | awk '{print $2}' | xargs kill -9
rm -rf data; mkdir -p data/01 && mkdir data/02
echo ${PASSWORD}  > password.txt
for (( num = 1; num <= ${NUM_NODES}; num++ )) 
do
  mkdir -p data/0${num}
  log_file=${DATA_DIR}/data/0${num}/console.log
  geth --datadir=./data/0${num} --password password.txt account new > account0${num}.txt 2> ${log_file} 
  #Copy the addresses into genesis.json
  ACCOUNT=`cat account0${num}.txt | awk '{print $2}' | sed 's/[{|}]//g'`
  sed -i '' 's/ACCOUNT0${num}/${ACCOUNT}/' ${TMP_GENESIS_FILE}
done

echo "Created accounts for each node in ${DATA_DIR}/account*.txt"

for (( num = 1; num <= ${NUM_NODES}; num++ )) 
do
  log_file=${DATA_DIR}/data/0${num}/console.log
  geth --datadir "${DATA_DIR}/data/0${num}" init ${TMP_GENESIS_FILE} &> ${log_file}
  geth --datadir "${DATA_DIR}/data/0${num}"  --port 3030${num} --rpcport 854${num} --ipcpath geth0${num} --nodiscover --networkid ${NETWORK_ID} --rpc --rpccorsdomain "*" &> ${log_file} &  
  echo "Node: 0${num}"
  echo "Logging into file: ${log_file}"
  echo "Connect to the console with following command:"
  echo "geth attach ipc:${DATA_DIR}/data/0${num}/geth0${num}"
  echo "\n"
done
disown
exit 0


#!/bin/bash
QUBE_VAULT_SERVICE=qube-vault
LOG_FILE=qube_vault_log

# start qube-vault service
docker-compose up -d $QUBE_VAULT_SERVICE

RUN_CMD="docker-compose exec $QUBE_VAULT_SERVICE vault"

# acquire unseal_key and root token
$RUN_CMD init -key-shares=1 -key-threshold=1 > $LOG_FILE
UNSEAL_KEY=`cat $LOG_FILE | awk -F': ' 'NR==1{print $2}'`
VAULT_TOKEN=`cat $LOG_FILE | awk -F': ' 'NR==2{print $2}'`

# unseal vault server
$RUN_CMD unseal $UNSEAL_KEY

# put key and token to .client_env
sed -ibak "s/<unseal_key>/$UNSEAL_KEY/g" .client_env
sed -ibak "s/<vault_token>/$VAULT_TOKEN/g" .client_env

# export variables in .client_env
# TODO

# vault auth
$RUN_CMD auth $VAULT_TOKEN

BASE_PATH="secret/resources"

# write data to vault
# tokens
$RUN_CMD write $BASE_PATH/$TENANT/$ENV_TYPE/$ENV_ID/supertoken value=$VAULT_TOKEN
$RUN_CMD write $BASE_PATH/$TENANT/$ENV_TYPE/$ENV_ID/usercreds_writer_token value=$VAULT_TOKEN
# firebase
$RUN_CMD write $BASE_PATH/$TENANT/$ENV_TYPE/$ENV_ID/firebase_qubeship api_key=$API_KEY service_key=@/vault/data/qubeship_firebase.json

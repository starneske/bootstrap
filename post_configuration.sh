#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR
export PATH=$PATH:$DIR/qubeship_home/bin

set -o allexport -x

if [ -e .client_env ]; then
    source $DIR/.client_env
    source $DIR/qubeship_home/config/scm.config
    source $DIR/qubeship_home/config/beta.config
    source ~/.qube_cli_profile
fi

echo "Please login with your qube builder url"
qube auth login
beta_access="false"
if [ ! -z $BETA_ACCESS_USER_NAME ];  then
    beta_access="true"
fi
orgId=$(qube auth user-info --org | jq -r '.tenant.orgs[0].id')
sed -ibak "s/39928fd4-b86a-36bf-8a06-20932b88ba81/${orgId}/g" load.js
sed -ibak "s/beta_access/${is_beta}/g" load.js


docker cp load.js $(docker-compose ps -q qube_mongodb):/tmp
docker-compose exec qube_mongodb sh -c "mongo < /tmp/load.js"

qube service postconfiguration

$DIR/run.sh

if [ ! -z $BETA_ACCESS_USER_NAME ];  then
    registry_endpoint_id=58edb422238503000b74d7a6
    qube endpoints postcredential --endpoint-id $registry_endpoint_id \
        --credential-type username_password \
        --credential-data '{"username": "qubeship", "password":"qubeship"}'
    echo "endpoint for default registry created successfully"
    echo "provisioning minikube"
    ./provision_minikube.sh

fi
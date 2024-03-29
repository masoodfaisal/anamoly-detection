#!/bin/bash


# Prior to running this script, you need to do the following
# 1) Run this to download the Red Hat OpenShift Application Services (RHOAS) Command Line Interface (CLI)
#    curl -o- https://raw.githubusercontent.com/redhat-developer/app-services-cli/main/scripts/install.sh | bash
# 2) Export the location of the RHOAS CLI to your system PATH,
#    e.g. on mac that's done as follows:
#    export PATH=%PATH%:/Users/<INSERT YOUR USERNAME HERE>/bin
# 3) Create a Red Hat Account - where the SaaS service, Red Hat OpenShift Service for Apache Kafka is located
#    Do that here:
#    http://console.redhat.com

## install rhoas from curl -o- https://raw.githubusercontent.com/redhat-developer/app-services-cli/main/scripts/install.sh | bash
## make sure you are logged into rhoas via 'rhoas

#curl -o- https://raw.githubusercontent.com/redhat-developer/app-services-cli/main/scripts/install.sh | bash

#export PATH
#brew install jq

KAFKA_NAME='fm-rocks-v3'
TOPIC_NAME='video-stream'

#oc login --user --password

rhoas login

export RHOAS_TELEMETRY=true

rhoas --version

rhoas kafka create --name ${KAFKA_NAME}

rhoas context set-kafka --name ${KAFKA_NAME}

while true
do
  STATUS=$(rhoas status)
  PROV='provisioning'
  READY='ready'

  if [[ "$STATUS" == *"$PROV"* ]]; then
    echo "Provisioning"
  elif [[ "$STATUS" == *"$READY"* ]]; then
    echo "Ready"
    break
  fi
  sleep 5
done

rhoas kafka topic create --name ${TOPIC_NAME}

rhoas service-account create --file-format json --short-description="${KAFKA_NAME}-service-account"

export SASL_USERNAME=$(cat credentials.json | jq  --raw-output '.clientID')
export SASL_PASSWORD=$(cat credentials.json | jq  --raw-output '.clientSecret')
export KAFKA_BROKER_URL=$(rhoas status -o json  | jq --raw-output '.kafka.bootstrap_server_host')
export KAFKAJS_NO_PARTITIONER_WARNING=1

echo "$KAFKA_BROKER_URL"
echo "$SASL_USERNAME"
echo "$SASL_PASSWORD"

#validate service account is created
rhoas service-account list | grep "${KAFKA_NAME}-service-account"

rhoas kafka acl grant-access --consumer --producer --service-account "${SASL_USERNAME}" --topic-prefix "${TOPIC_NAME}"  --group all -y

#change the consumer deployment yaml file

#sed -i "s/SASL_USERNAME_VALUE/${CLIENT_ID}/g" consumer-deployment.yaml
#sed -i "s/SASL_PASSWORD_VALUE/${CLIENT_SECRET}/g" consumer-deployment.yaml
#sed -i "s/KAFKA_BROKER_VALUE/${KAFKA_BROKER_URL}/g" consumer-deployment.yaml

# Mac (sed has peculiarities - use gnu-sed)
# run: brew install gnu-sed
# see: https://blog.birost.com/a?ID=00900-c6ae76a9-d665-4d1a-9fa8-0f962b6385e6
gsed -i "s/SASL_USERNAME_VALUE/${CLIENT_ID}/g" consumer-deployment.yaml
gsed -i "s/SASL_PASSWORD_VALUE/${CLIENT_SECRET}/g" consumer-deployment.yaml
gsed -i "s/KAFKA_BROKER_VALUE/${KAFKA_BROKER_URL}/g" consumer-deployment.yaml
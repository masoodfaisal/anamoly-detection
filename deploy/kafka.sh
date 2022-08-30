#!/bin/bash

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
    echo "Provisioing"
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


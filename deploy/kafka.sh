#!/bin/bash

## install rhoas from curl -o- https://raw.githubusercontent.com/redhat-developer/app-services-cli/main/scripts/install.sh | bash
## make sure you are logged into rhoas via 'rhoas

#curl -o- https://raw.githubusercontent.com/redhat-developer/app-services-cli/main/scripts/install.sh | bash

#export PATH
brew install jq

KAFKA_NAME='fm-rocks-v3'
TOPIC_NAME='video-stream'

ocm login --user --password

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

CLIENT_ID=$(cat credentials.json | jq  --raw-output '.clientID')
CLIENT_SECRET=$(cat credentials.json | jq  --raw-output '.clientSecret')

echo "$CLIENT_ID"
echo "$CLIENT_SECRET"

#validate service account is created
rhoas service-account list | grep "${KAFKA_NAME}-service-account"

rhoas kafka acl grant-access --consumer --producer --service-account "${CLIENT_ID}" --topic-prefix '*'  --group all


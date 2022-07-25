#!/bin/bash

## install rhoas from curl -o- https://raw.githubusercontent.com/redhat-developer/app-services-cli/main/scripts/install.sh | bash
## make sure you are logged into rhoas via 'rhoas

#curl -o- https://raw.githubusercontent.com/redhat-developer/app-services-cli/main/scripts/install.sh | bash

#export PATH

KAFKA_NAME='fm-rocks'
TOPIC_NAME='video-stream'

rhoas login

export RHOAS_TELEMETRY=false

rhoas --version

rhoas kafka create --name fm-rocks

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

rhoas context set-kafka --name ${KAFKA_NAME}

rhoas kafka topic create --name ${TOPIC_NAME}

#rhoas context status kafka

rhoas service-account create --file-format json --short-description="fmrocks-service-account"

rhoas kafka acl grant-access --consumer --producer --service-account srvc-acct-8c95ca5e1225-94a-41f1-ab97-aacf3df1 --topic-prefix '*'  --group all
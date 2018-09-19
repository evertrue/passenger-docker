#!/usr/bin/env bash

echo "Starting ecs-env-init"

ip route

# Extract env with https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-introspection.html
hostip=$(ip route show | awk '/default/ {print $3}')
APP_ENV=$(curl -s http://${hostip}:51678/v1/metadata | jq -r '.Cluster' | grep -oE 'stage|prod')

# If the cluster info cannot be found then default to stage
if [[ "$APP_ENV" == "" ]] || [[ "$APP_ENV" == "dev" ]]; then
	APP_ENV=stage
fi

# If the PASSENGER_APP_ENV value is not set then default to staging.  
# This passenger docker setting is required to properly route traffic to the Ruby application.
if [[ "$APP_ENV" == "stage" ]]; then
	PASSENGER_APP_ENV="staging"
else
	PASSENGER_APP_ENV="production"	
fi

AWS_REGION="us-east-1"
AWS_SECRETS_ENDPOINT="https://secretsmanager.us-east-1.amazonaws.com"

echo "APP_ENV =              "$APP_ENV
echo "PASSENGER_APP_ENV =    "$PASSENGER_APP_ENV
echo "AWS_REGION =           "$AWS_REGION
echo "AWS_SECRETS_ENDPOINT = "$AWS_SECRETS_ENDPOINT

# Environment variables need to be written to /etc/container_environment for access from other scripts
echo "Writing environment variables to /etc/container_environment"

echo $APP_ENV > /etc/container_environment/APP_ENV
echo $PASSENGER_APP_ENV > /etc/container_environment/PASSENGER_APP_ENV
echo $AWS_REGION > /etc/container_environment/AWS_REGION
echo $AWS_SECRETS_ENDPOINT > /etc/container_environment/AWS_SECRETS_ENDPOINT

echo "Finished ecs-env-init"

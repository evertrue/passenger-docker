#!/usr/bin/env bash

echo "starting vault_env_init"

echo "copying secrets from $VAULT_ADDR"
VAULT_TOKEN_OBFUSCATED=$(echo $VAULT_TOKEN | sed 's/./*/g')
echo "VAULT_TOKEN=$VAULT_TOKEN_OBFUSCATED"

VAULT_SECRETS=$(/usr/local/bin/vault read -format=json secret/default/$APP_NAME)
err=$?
if [[ "$err" != "0" ]]; then
  echo "FAILED TO READ SECRETS FROM VAULT! ($err)"
  exit 1
fi

while read ENV_VAR; do
    echo -n $VAULT_SECRETS | jq -r .data.$ENV_VAR > /etc/container_environment/$ENV_VAR
done </etc/nginx/main.d/env.conf

ls -la /etc/container_environment

echo "finished vault_env_init"

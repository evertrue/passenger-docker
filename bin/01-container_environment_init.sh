#!/usr/bin/env bash

echo "Starting container_env_init…"

echo "Copying container environment files from mounted host " \
      "/etc/container_environment_ro to /etc/container_environment"

ls -la /etc/container_environment_ro

cp -v /etc/container_environment_ro/* /etc/container_environment/

echo "The container_environment now contains:"
ls -la /etc/container_environment

echo "Finished container_env_init…"

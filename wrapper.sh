#!/usr/bin/env bash

set -eu

DIR="$(dirname "$(realpath "$0")")"

# https://github.com/orgs/boltops-tools/packages/container/package/terraspace
DOCKER_IMAGE="ghcr.io/atefhaloui/terraspace:0.1.0"

# Checking the presence of terraspace image
# I'm assuming you have the right to pull image
if [ -z "$$(docker images -q ${DOCKER_IMAGE})" ]; then \
  echo "Image '${DOCKER_IMAGE}' not found. Pulling..."
  docker pull ${DOCKER_IMAGE}
fi

docker run --rm \
  -v "${DIR}":/build \
  -v ${HOME}/.aws:/home/terraspace/.aws \
  -w /build \
  -u "$(id -u):$(id -g)" \
  -e AWS_PROFILE \
  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY \
  -e AWS_SESSION_TOKEN \
  -e AWS_REGION \
  -e TS_TERRAFORM_BIN \
  -e TS_ENV \
  -e TERRASPACE_ENV \
  -e TF_VAR_access_key \
  -e TF_VAR_secret_key \
  -e TF_VAR_session_token \
  -e TF_LOG \
  ${DOCKER_IMAGE} "$@"

#!/bin/bash

set -e

if [ "${AWS_INSTANCE_ROLE}" ]; then
  curl -o /tmp/credentials.json "http://169.254.169.254/latest/meta-data/iam/security-credentials/${AWS_INSTANCE_ROLE}"
  export AWS_ACCESS_KEY_ID="$(cat /tmp/credentials.json | jq -r ".AccessKeyId")"
  export AWS_SECRET_ACCESS_KEY="$(cat /tmp/credentials.json | jq -r ".SecretAccessKey")"
  export AWS_SESSION_TOKEN="$(cat /tmp/credentials.json | jq -r ".Token")"
  rm -f /tmp/credentials.json
fi

if [ "${AWS_ACCESS_KEY_ID}" = "**None**" ]; then
  echo "You need to set the AWS_ACCESS_KEY_ID environment variable."
  exit 1
fi

if [ "${AWS_SECRET_ACCESS_KEY}" = "**None**" ]; then
  echo "You need to set the AWS_SECRET_ACCESS_KEY environment variable."
  exit 1
fi

if [ "${AWS_REGION}" = "**None**" ]; then
  echo "You need to set the AWS_REGION environment variable."
  exit 1
fi

if [ "${AWS_BUCKET}" = "**None**" ]; then
  echo "You need to set the AWS_BUCKET environment variable."
  exit 1
fi

if [ "${PREFIX}" = "**None**" ]; then
  echo "You need to set the PREFIX environment variable."
  exit 1
fi

if [ "${PGDUMP_DATABASE}" = "**None**" ]; then
  echo "You need to set the PGDUMP_DATABASE environment variable."
  exit 1
fi

if [ -z "${POSTGRES_ENV_POSTGRES_USER}" ]; then
  echo "You need to set the POSTGRES_ENV_POSTGRES_USER environment variable."
  exit 1
fi

if [ -z "${POSTGRES_ENV_POSTGRES_PASSWORD}" ]; then
  echo "You need to set the POSTGRES_ENV_POSTGRES_PASSWORD environment variable."
  exit 1
fi

if [ -z "${POSTGRES_PORT_5432_TCP_ADDR}" ]; then
  echo "You need to set the POSTGRES_PORT_5432_TCP_ADDR environment variable or link to a container named POSTGRES."
  exit 1
fi

if [ -z "${POSTGRES_PORT_5432_TCP_PORT}" ]; then
  echo "You need to set the POSTGRES_PORT_5432_TCP_PORT environment variable or link to a container named POSTGRES."
  exit 1
fi

POSTGRES_HOST_OPTS="-h $POSTGRES_PORT_5432_TCP_ADDR -p $POSTGRES_PORT_5432_TCP_PORT -U $POSTGRES_ENV_POSTGRES_USER"

echo "Starting dump of ${PGDUMP_DATABASE} database(s) from ${POSTGRES_PORT_5432_TCP_ADDR}..."

export PGPASSWORD=$(echo "${POSTGRES_ENV_POSTGRES_PASSWORD}" | sed 's/\n$//')

(pg_dump $PGDUMP_OPTIONS $POSTGRES_HOST_OPTS $PGDUMP_DATABASE | aws s3 cp --region $AWS_REGION --sse AES256 - s3://$AWS_BUCKET/$PREFIX/$(date +"%Y")/$(date +"%m")/$(date +"%d").dump) || exit 2

echo "Done!"

exit 0

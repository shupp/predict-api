#!/bin/bash

ENV_FILE=/predict-api/.env

# Set up defaults
# See predict-api/.env.example
APP_NAME=${APP_NAME:-Lumen}
APP_ENV=${APP_ENV:-local}
APP_KEY=${APP_KEY}
APP_DEBUG=${APP_DEBUG:-true}
APP_URL=${APP_URL:-http://localhost}
APP_TIMEZONE=${APP_TIMEZONE:-UTC}
DB_CONNECTION=${DB_CONNECTION:-mysql}
DB_HOST=${DB_HOST:-127.0.0.1}
DB_PORT=${DB_PORT:-3306}
DB_DATABASE=${DB_DATABASE:-homestead}
DB_USERNAME=${DB_USERNAME:-homestead}
DB_PASSWORD=${DB_PASSWORD:-secret}

# Write out the local config
echo "APP_NAME=\"${APP_NAME}\"" > ${ENV_FILE}

echo "APP_ENV=\"${APP_ENV}\"" >> ${ENV_FILE}
echo "APP_KEY=\"${APP_KEY}\"" >> ${ENV_FILE}
echo "APP_DEBUG=\"${APP_DEBUG}\"" >> ${ENV_FILE}
echo "APP_URL=\"${APP_URL}\"" >> ${ENV_FILE}

echo "APP_TIMEZONE=\"${APP_TIMEZONE}\"" >> ${ENV_FILE}
echo "DB_CONNECTION=\"${DB_CONNECTION}\"" >> ${ENV_FILE}
echo "DB_HOST=\"${DB_HOST}\"" >> ${ENV_FILE}
echo "DB_PORT=\"${DB_PORT}\"" >> ${ENV_FILE}
echo "DB_DATABASE=\"${DB_DATABASE}\"" >> ${ENV_FILE}
echo "DB_USERNAME=\"${DB_USERNAME}\"" >> ${ENV_FILE}
echo "DB_PASSWORD=\"${DB_PASSWORD}\"" >> ${ENV_FILE}

chown nobody:nobody ${ENV_FILE}
chmod 400 ${ENV_FILE}

exec ${@}

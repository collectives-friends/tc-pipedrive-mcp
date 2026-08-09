#!/bin/sh
# Authenticate to Infisical with the service's machine identity, then run the
# app with secrets injected as env vars. Only INFISICAL_* bootstrap vars live in
# the platform env; all real secrets come from Infisical at runtime.
set -e
export INFISICAL_TOKEN="$(infisical login --method=universal-auth \
  --client-id="$INFISICAL_CLIENT_ID" --client-secret="$INFISICAL_CLIENT_SECRET" \
  --domain="$INFISICAL_API_URL" --silent --plain)"
exec infisical run --projectId="$INFISICAL_PROJECT_ID" --env="${INFISICAL_ENV:-prod}" \
  --domain="$INFISICAL_API_URL" --path="${INFISICAL_PATH:-/}" -- node build/index.js

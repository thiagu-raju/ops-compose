#!/bin/bash

set -e

echo "🚀 Starting Turnly Compose-backed infrastructure provisioning..."

compose="docker compose -f gateway.yml"

apps=$(find ./apps -name "*.yml" -type f)
infrastructure=$(find ./infrastructure -name "*.yml" -type f)

echo "📦 Appending infrastructure files to compose command..."

for file in $infrastructure; do
  compose="$compose -f $file"
done

echo "📦 Appending app files to compose command..."

for file in $apps; do
  compose="$compose -f $file"
done

case "$1" in
start | up)
  echo "🚀 Starting Turnly services in the background..."
  eval "$compose up -d --renew-anon-volumes"
  ;;
down)
  echo "🛑 Stopping Turnly services and removing volumes..."
  eval "$compose down -v"
  ;;
stop)
  echo "🛑 Stopping Turnly services..."
  eval "$compose stop"
  ;;
*)
  echo "Oops! 🤯 Something went wrong. Please try again."
  exit 1
  ;;
esac

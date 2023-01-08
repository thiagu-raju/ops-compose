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

function upgrade() {
  NO_RESTART_SERVICES=$infrastructure
  NO_RESTART_SERVICES+=("gateway.yml")

  echo "🔔 Warning: If the environment variables have changed, you may need update the .env file before running this command."

  if [[ -n $APP_VERSION ]]; then
    # Set the app version to .env file
    sed -i "s/APP_VERSION=.*/APP_VERSION=$APP_VERSION/g" .env
  fi

  if [[ $UPGRADE_ALL == true ]]; then
    echo "🔔 Warning: You are about to upgrade all Turnly services. This may take a while and cause downtime."
    echo "📡 Upgrading all apps and infrastructure services..."

    NO_RESTART_SERVICES=("gateway.yml")
  else
    echo "🔔 Warning: The infrastructure services are not restarted by default. If you want to upgrade them, run this command with the --upgrade-all flag."
  fi

  echo "🚀 Restarting services with zero-downtime deployment strategy..."

  echo "🏁 Getting docker compose service names..."
  services=$(eval "$compose" config --services)

  for service in $services; do
    if [[ "${NO_RESTART_SERVICES[*]}" == *"$service"* ]] &>/dev/null; then
      echo "🛑 Skipping $service service..."
      continue
    fi

    echo "🚀 Bring a new container up with the new image..."
    eval "$compose up -d --no-deps --scale $service=2 --no-recreate $service"

    old_container_id=$(docker ps -f name="$service" -q | tail -n1)

    if [[ -n $old_container_id ]]; then
      wait_period=0

      while true; do
        wait_period=$((wait_period + 10))

        if [ $wait_period -gt 180 ]; then
          echo "✅ The timeout of 3 minutes has been reached. We'll bring down the old container now."
          break
        else
          echo "🕐 Waiting 3 minutes for the new container to be ready, then we'll bring down the old one..."
          sleep 10
        fi
      done

      echo "🗑 Bringing down old container..."
      docker stop "$old_container_id"
      docker rm "$old_container_id"
    fi

    eval "$compose up -d --no-deps --scale $service=1 --no-recreate $service"

    echo "✅ The $service service has been upgraded successfully!"
  done

  echo "✅ ✅ All services upgraded successfully!"
}

COMMAND=$1
shift

[[ $* == *"--upgrade-all"* ]] && UPGRADE_ALL=true

case $COMMAND in
start | up)
  echo "🚀 Starting Turnly services in the background..."
  eval "$compose up -d --renew-anon-volumes $*"
  ;;
down)
  echo "🛑 Stopping Turnly services and removing volumes..."
  eval "$compose down -v $*"
  ;;
stop)
  echo "🛑 Stopping Turnly services..."
  eval "$compose stop $*"
  ;;
upgrade)
  echo "📦 Upgrading Turnly services..."
  upgrade
  ;;
*)
  echo "Oops! 🤯 Something went wrong. Please try again."
  exit 1
  ;;
esac

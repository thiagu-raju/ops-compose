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

  APP_VERSION=$(grep "APP_VERSION=" .env | awk -F '=' '{print $2}' | xargs)
  LATEST_VERSION=$(cat VERSION)

  if [[ $APP_VERSION != "$LATEST_VERSION" ]]; then
    echo "🔔 Warning: If the environment variables have changed, you may need update the .env file before running this command."
    echo "🔔 Info: The APP_VERSION in the .env file is not the same as the $LATEST_VERSION version. We'll update it for you."

    sed -i "s/APP_VERSION=.*/APP_VERSION=$LATEST_VERSION/g" .env
    APP_VERSION=$LATEST_VERSION
  else
    if [[ -z $FORCE ]]; then
      echo "🔔 Info: The current version is the same as the latest version. Skipping the upgrade..."
      echo "🔔 Info: If you want to force the upgrade, run this command with the --force flag."

      exit 0
    fi
  fi

  if [[ -n $UPGRADE_ALL ]]; then
    echo "🔔 Warning: You are about to upgrade all Turnly services. This may take a while and cause downtime."
    echo "🔔 Warning: When using the --upgrade-all flag, be sure to check the changelog for any breaking changes and schedule a maintenance notice for your users."
    echo ""
    echo "📡 Upgrading all apps and infrastructure services..."

    NO_RESTART_SERVICES=("gateway.yml")
  else
    echo "🔔 Warning: The infrastructure services are not restarted by default. If you want to upgrade them, run this command with the --upgrade-all flag."
  fi

  echo "🚀 Restarting services with zero-downtime deployment strategy, with $APP_VERSION version..."

  services=$(eval "$compose" config --services)

  for service in $services; do
    if [[ "${NO_RESTART_SERVICES[*]}" == *"$service"* ]] &>/dev/null; then
      echo "🔔 Info: Skipping $service service..."
      continue
    fi

    echo "🚀 Bring a new container up with the new image..."
    eval "$compose up -d --no-deps --scale $service=2 --no-recreate $service"

    old_container_id=$(docker ps -f name="$service" -q | tail -n1)

    if [[ -n $old_container_id ]]; then
      reached_timeout=120
      wait_period=0

      [[ $service == "iam" ]] && reached_timeout=240

      while true; do
        wait_period=$((wait_period + 10))

        if [ $wait_period -gt $reached_timeout ]; then
          echo "✅ The timeout of $reached_timeout seconds has been reached. We'll bring down the old container..."
          break
        else
          echo "🕐 Waiting $reached_timeout seconds for the new container to be ready, then we'll bring down the old one..."
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

  # Run cleanup for old images
  echo "🗑 Cleaning up old images..."
  docker image prune -f

  echo "✅ ✅ All services upgraded successfully!"
}

COMMAND=$1
shift

[[ $* == *"--upgrade-all"* ]] && UPGRADE_ALL=true
[[ $* == *"--force"* ]] && FORCE=true

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

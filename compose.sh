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
  LATEST_VERSION=$(cat ./etc/VERSION)

  if [[ $APP_VERSION != "$LATEST_VERSION" ]]; then
    echo "🔔 Warning: If the environment variables have changed, you may need update the .env file before running this command."
    echo "🔔 Info: The APP_VERSION in the .env file is not the same as the $LATEST_VERSION version. We'll update it for you."

    sed -i.bak -e "s#APP_VERSION=.*#APP_VERSION=$LATEST_VERSION#g" .env
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

  echo "🕐 Pulling latest images for Turnly services..."
  eval "$compose pull --ignore-pull-failures --quiet"
  echo "✅ Pulling latest images for Turnly services completed successfully!"

  echo "🚀 Restarting services with zero-downtime deployment strategy, with $APP_VERSION version..."
  services=$(eval "$compose" config --services)

  for service in $services; do
    if [[ "${NO_RESTART_SERVICES[*]}" == *"$service"* ]] &>/dev/null; then
      echo "🔔 Info: Skipping $service service..."
      continue
    fi

    echo "🚀 Bring a new container up with the new image for the $service service..."
    eval "$compose up -d --no-deps --scale $service=2 --no-recreate $service"

    old_container_id=$(docker ps -f name="$service" -q | tail -n1)

    if [[ -n $old_container_id ]]; then
      reached_timeout=12
      wait_period=0

      while true; do
        wait_period=$((wait_period + 4))

        if [ $wait_period -gt $reached_timeout ]; then
          echo "✅ The timeout of $reached_timeout seconds has been reached. We'll bring down the old container for the $service service..."
          break
        else
          echo "🕐 Waiting $reached_timeout seconds for the new container for the $service service to be ready, then we'll bring down the old one..."
          sleep 4
        fi
      done

      echo "🗑 Bringing down old container for the $service service..."
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

function uninstall() {
  echo -n "🔴 Prune action is irreversible. Are you sure you want to continue? [y/N]"
  read -r answer

  if [[ $answer != "y" && $answer != "yes" ]]; then
    echo "🟢 Ahoy! You've decided to cancel the prune action. Exiting..."
    exit 0
  fi

  echo "🔴 Running irreversible prune action, please wait..."
  eval "$compose down -v"

  if [[ -n $CLEANUP_IMAGES ]]; then
    echo "🗑 Removing all unused images..."
    docker image prune -f
  fi

  echo "✅ ✅ All services pruned successfully!"
}

COMMAND=$1
shift

[[ $* == *"--upgrade-all"* ]] && UPGRADE_ALL=true
[[ $* == *"--force"* ]] && FORCE=true
[[ $* == *"--images"* ]] && CLEANUP_IMAGES=true

case $COMMAND in
start)
  echo "🟢 Starting Turnly services..."
  eval "$compose up -d --renew-anon-volumes $*"
  ;;
stop)
  echo "🟠 Stopping Turnly services..."
  eval "$compose down"
  ;;
prune)
  echo "🔴 Pruning Turnly services..."
  uninstall
  ;;
upgrade)
  echo "🔵 Upgrading Turnly services..."
  upgrade
  ;;
*)
  echo "⚪ Something went wrong. Please try again."
  exit 1
  ;;
esac

#!/bin/bash

# Exit on error, unset var, or pipe failure
set -euo pipefail

ENV_FILE="env_files/mysql-db.env"

# Check if at least one profile is provided
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 [profile1] [profile2] ..."
  echo "Available profiles: user, order, monolith"
  exit 1
fi

# Load MySQL-related environment variables
set -o allexport
source "$ENV_FILE"
set +o allexport

# Create MySQL client config to avoid password prompts when running `mysql` commands inside the container
rm -rf .my.cnf
cat > .my.cnf <<EOF
[client]
user=root
password=${MYSQL_ROOT_PASSWORD}
EOF
chmod 600 .my.cnf

echo "Starting onboarding process with profiles: $*"

# Validate provided profiles and prepare Docker Compose arguments
valid_profiles=("monolith" "user" "order")
profiles=()
for profile in "$@"; do
  if [[ ! " ${valid_profiles[*]} " =~ " ${profile} " ]]; then
    echo "Error: Unknown profile '${profile}'"
    echo "Valid profiles are: ${valid_profiles[*]}"
    exit 1
  fi

  # Determine the base directory based on profile type
  if [[ "$profile" == "monolith" ]]; then
    base_dir="monolith"
  else
    base_dir="services/$profile"
  fi

  # Create Gradle cache directories to speed up builds
  mkdir -p "$base_dir/.gradle" "$base_dir/.gradle-cache"

  # Add profile to Docker Compose CLI args
  profiles+=(--profile "$profile")
done

echo "Starting containers..."
docker compose "${profiles[@]}" --profile db up -d

# Wait until MySQL inside the container becomes healthy
echo "Waiting for MySQL to become healthy..."
MAX_RETRIES=20
RETRY_DELAY=3
COUNTER=0

until docker exec mysql-db mysqladmin ping -h "mysql-db" --silent > /dev/null 2>&1; do
  sleep $RETRY_DELAY
  COUNTER=$((COUNTER+1))
  if [ $COUNTER -ge $MAX_RETRIES ]; then
    echo "MySQL did not become ready in time."
    exit 1
  fi
done

echo "Database is ready. Running initial setup..."

# Set up the initial database schema and user
docker exec -i mysql-db mysql "$MYSQL_DATABASE" < ./scripts/init.sql

echo "Setup complete. Starting services in background..."
echo "Please wait a few minutes for containers to finish initializing (e.g. Gradle build)."
echo "You can check progress with: docker logs -f <service name> (e.g. docker logs -f user)."
echo "Once initialization is complete,"

# Print service URLs for each started profile
declare -A ports=( ["monolith"]=8080 ["user"]=8081 ["order"]=8082 )
for profile in "$@"; do
  if [[ -n "${ports[$profile]+set}" ]]; then
    echo "access $profile service at: http://localhost:${ports[$profile]}"
  fi
done


#!/usr/bin/env bash
# scripts/cleanup.sh - stop and remove lab containers & volumes (with confirmation)
set -euo pipefail
IFS=$'\n\t'

read -r -p "This will stop and remove postgres, mysql, redis containers and their named volumes. Continue? (y/N) " ans
case "$ans" in
  y|Y|yes|YES) ;;
  *) echo "Aborted."; exit 0 ;;
 esac

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker not available"; exit 1
fi

SERVICES=(postgres mysql redis)
for svc in "${SERVICES[@]}"; do
  if docker ps --format '{{.Names}}' | grep -q "^${svc}$"; then
    echo "Stopping $svc ..."
    docker stop "$svc" || true
    echo "Removing $svc ..."
    docker rm "$svc" || true
  else
    echo "$svc not running"
  fi
 done

echo "Removing volumes ..."
for vol in $(docker volume ls --format '{{.Name}}' | grep -E '^(mysql|postgres|redis)$'); do
  docker volume rm "$vol" || true
 done

echo "Cleanup complete."
#!/usr/bin/env bash
# scripts/health.sh - basic environment health checks
set -euo pipefail
IFS=$'\n\t'

OK=0
FAIL=0

log_ok() { printf "[OK] %s\n" "$1"; }
log_fail() { printf "[FAIL] %s\n" "$1"; FAIL=$((FAIL+1)); }
log_warn() { printf "[WARN] %s\n" "$1"; }

check_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    log_ok "Command '$1' present ($(command -v "$1"))"
    OK=$((OK+1))
  else
    log_fail "Command '$1' missing"
  fi
}

check_container() {
  local name="$1"
  if docker ps --format '{{.Names}}' | grep -q "^${name}$"; then
    log_ok "Container '$name' running"
  else
    log_fail "Container '$name' not running"
  fi
}

check_port() {
  local port="$1"
  if nc -z localhost "$port" 2>/dev/null; then
    log_ok "Port $port reachable"
  else
    log_fail "Port $port not reachable"
  fi
}

# Core commands
for c in git docker "docker compose" redis-cli psql mariadb go node; do
  # handle space in 'docker compose'
  if [[ "$c" == "docker compose" ]]; then
    if docker compose version >/dev/null 2>&1; then
      log_ok "Docker Compose plugin available"
      OK=$((OK+1))
    else
      log_fail "Docker Compose plugin missing"
    fi
  else
    check_cmd "$c" || true
  fi
done

# Containers (if docker available)
if command -v docker >/dev/null 2>&1; then
  for svc in postgres mysql redis; do
    check_container "$svc" || true
  done
fi

# Ports
check_port 5432 || true
check_port 3306 || true
check_port 6379 || true

printf "\nSummary: OK=%d FAIL=%d\n" "$OK" "$FAIL"
if [[ $FAIL -gt 0 ]]; then
  exit 1
fi

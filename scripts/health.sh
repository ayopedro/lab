#!/usr/bin/env bash
# scripts/health.sh - basic environment health checks
set -euo pipefail
IFS=$'\n\t'

PASS=0
FAIL=0
WARN=0

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_ok() { printf "${GREEN}[PASS]${NC} %s\n" "$1"; }
log_fail() { printf "${RED}[FAIL]${NC} %s\n" "$1"; FAIL=$((FAIL+1)); }
log_warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; WARN=$((WARN+1)); }

check_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    log_ok "Command '$1' present ($(command -v "$1"))"
    PASS=$((PASS+1))
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
  if command -v nc >/dev/null 2>&1; then
    if nc -z localhost "$port" 2>/dev/null; then
      log_ok "Port $port reachable"
    else
      log_fail "Port $port not reachable"
    fi
  else
    log_warn "Cannot check port $port (nc not installed)"
  fi
}

# Core commands
for c in git docker go node; do
  check_cmd "$c" || true
done

# Docker Compose plugin
if docker compose version >/dev/null 2>&1; then
  log_ok "Docker Compose plugin available"
  PASS=$((PASS+1))
else
  log_fail "Docker Compose plugin missing"
fi

# Optional CLI tools (warn if missing, don't fail - they're in containers)
for c in redis-cli psql mariadb; do
  if command -v "$c" >/dev/null 2>&1; then
    log_ok "Command '$c' present (host install)"
    PASS=$((PASS+1))
  else
    log_warn "Command '$c' not on host (use via docker exec)"
  fi
done

# Containers (if docker available)
if command -v docker >/dev/null 2>&1; then
  for svc in lab-postgres-1 lab-mysql-1 lab-redis-1; do
    check_container "$svc" || true
  done
fi

# Ports
check_port 5432 || true
check_port 3306 || true
check_port 6379 || true

printf "\nSummary: \n${GREEN}PASS: %d${NC} \n${YELLOW}WARN: %d${NC} \n${RED}FAIL: %d${NC}\n" "$PASS" "$WARN" "$FAIL"
if [[ $FAIL -gt 0 ]]; then
  exit 1
fi

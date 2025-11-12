#!/usr/bin/env bash
# Bootstrap script for Lab environment setup
# Provides idempotent installation scaffolding.
# Safe mode settings:
set -euo pipefail
IFS=$'\n\t'

# --- Config -----------------------------------------------------------------
OS="$(uname -s | tr 'A-Z' 'a-z')"
IS_MAC=false
if [[ "$OS" == "darwin" ]]; then
  IS_MAC=true
fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_PREFIX="[lab-bootstrap]"

# --- Helpers ----------------------------------------------------------------
log() { printf "%s %s\n" "$LOG_PREFIX" "$*"; }
warn() { printf "\033[33m%s %s\033[0m\n" "$LOG_PREFIX" "$*"; }
error() { printf "\033[31m%s %s\033[0m\n" "$LOG_PREFIX" "$*" >&2; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    error "Missing required command: $1"
    return 1
  fi
}

# --- Installers --------------------------------------------------------------
install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    log "Oh My Zsh already installed"
    return
  fi
  log "Installing Oh My Zsh"
  # Non-interactive install
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
      warn "Oh My Zsh install script failed; continuing"
    }
}

install_nvm() {
  if [ -d "$HOME/.nvm" ]; then
    log "NVM already installed"
    return
  fi
  log "Installing NVM"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash || warn "NVM install failed"
}

install_docker_note() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker already present"
  else
    if $IS_MAC; then
      warn "Docker not found. Install Docker Desktop: https://www.docker.com/products/docker-desktop/"
    else
      warn "Docker not found. Install via distribution package manager."
    fi
  fi
}

install_go_note() {
  if command -v go >/dev/null 2>&1; then
    log "Go version: $(go version)"
  else
    if $IS_MAC; then
      warn "Go not found. Install with: brew install go (after Homebrew) or download from https://go.dev/dl/"
    else
      warn "Go not found. Install from https://go.dev/dl/"
    fi
  fi
}

install_homebrew() {
  if ! $IS_MAC; then
    return
  fi
  if command -v brew >/dev/null 2>&1; then
    log "Homebrew already installed"
    return
  fi
  log "Installing Homebrew (macOS)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || warn "Homebrew install failed"
  # Ensure brew available in current shell
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

brew_bundle() {
  if ! $IS_MAC; then
    return
  fi
  if ! command -v brew >/dev/null 2>&1; then
    warn "Skipping brew bundle; brew not installed"
    return
  fi
  if [[ -f "$SCRIPT_DIR/Brewfile" ]]; then
    log "Applying Brewfile bundle"
    brew bundle --file "$SCRIPT_DIR/Brewfile" || warn "brew bundle failed"
  else
    log "No Brewfile present; skipping bundle"
  fi
}

# --- Databases ---------------------------------------------------------------
start_databases_optional() {
  if [ -f "$SCRIPT_DIR/docker-compose.yml" ]; then
    if command -v docker compose >/dev/null 2>&1 || command -v docker-compose >/dev/null 2>&1; then
      log "Starting database services (optional)"
      (docker compose up -d 2>/dev/null || docker-compose up -d) || warn "Failed to start docker compose services"
    else
      warn "Docker Compose not available; skipping database startup"
    fi
  else
    warn "No docker-compose.yml found; skipping database services"
  fi
}

# --- Main -------------------------------------------------------------------
main() {
  log "Beginning bootstrap on $OS"

  require_cmd curl || exit 1

  install_homebrew
  brew_bundle
  install_oh_my_zsh
  install_nvm
  install_docker_note
  install_go_note
  start_databases_optional

  log "Bootstrap complete. Open a new terminal or source your shell config if updated."
}

main "$@"

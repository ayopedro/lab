#!/usr/bin/env bash
# Bootstrap script for Lab environment setup
# Provides idempotent installation scaffolding.
# Safe mode settings:
set -euo pipefail
IFS=$'\n\t'

# --- Config -----------------------------------------------------------------
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
IS_MAC=false
if [[ "$OS" == "darwin" ]]; then
  IS_MAC=true
fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_PREFIX="[lab-bootstrap]"
DRY_RUN=false
INTERACTIVE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -i|--interactive)
      INTERACTIVE=true
      shift
      ;;
    --help|-h)
      cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --dry-run        Show what would be installed without making changes
  -i, --interactive Prompt before each installation step
  --help, -h       Show this help message

Description:
  Bootstraps Lab development environment with:
  - Homebrew (macOS only)
  - Oh My Zsh
  - NVM (Node Version Manager)
  - Tools from Brewfile (if present)
  - Docker Compose services (if docker-compose.yml present)

EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# --- Helpers ----------------------------------------------------------------
log() { printf "%s %s\n" "$LOG_PREFIX" "$*"; }
warn() { printf "\033[33m%s %s\033[0m\n" "$LOG_PREFIX" "$*"; }
error() { printf "\033[31m%s %s\033[0m\n" "$LOG_PREFIX" "$*" >&2; }
dry_run() { 
  if $DRY_RUN; then
    printf "\033[36m%s [DRY-RUN] %s\033[0m\n" "$LOG_PREFIX" "$*"
    return 0
  fi
  return 1
}

prompt_yes_no() {
  local prompt="$1"
  local response
  while true; do
    read -r -p "$LOG_PREFIX $prompt (y/n): " response
    case "$response" in
      [Yy]|[Yy][Ee][Ss]) return 0 ;;
      [Nn]|[Nn][Oo]) return 1 ;;
      *) echo "Please answer y or n" ;;
    esac
  done
}

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
  if $INTERACTIVE && ! prompt_yes_no "Install Oh My Zsh?"; then
    log "Skipping Oh My Zsh"
    return
  fi
  if dry_run; then
    dry_run "Would install Oh My Zsh to $HOME/.oh-my-zsh"
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
  if $INTERACTIVE && ! prompt_yes_no "Install NVM (Node Version Manager)?"; then
    log "Skipping NVM"
    return
  fi
  if dry_run; then
    dry_run "Would install NVM to $HOME/.nvm"
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
  if $INTERACTIVE && ! prompt_yes_no "Install Homebrew (requires password)?"; then
    log "Skipping Homebrew"
    return
  fi
  if dry_run; then
    dry_run "Would install Homebrew (requires password prompt)"
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
    if $INTERACTIVE && ! prompt_yes_no "Install packages from Brewfile?"; then
      log "Skipping Brewfile bundle"
      return
    fi
    if dry_run; then
      dry_run "Would run: brew bundle --file $SCRIPT_DIR/Brewfile"
      if command -v brew >/dev/null 2>&1; then
        log "Packages that would be installed:"
        brew bundle list --file "$SCRIPT_DIR/Brewfile" 2>/dev/null || true
      fi
      return
    fi
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
      if $INTERACTIVE && ! prompt_yes_no "Start Docker Compose database services?"; then
        log "Skipping database services"
        return
      fi
      if dry_run; then
        dry_run "Would start Docker Compose services from $SCRIPT_DIR/docker-compose.yml"
        return
      fi
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
  if $DRY_RUN; then
    log "DRY-RUN MODE: No changes will be made"
  fi
  if $INTERACTIVE; then
    log "INTERACTIVE MODE: You will be prompted before each step"
  fi
  log "Beginning bootstrap on $OS"

  require_cmd curl || exit 1

  install_homebrew
  brew_bundle
  install_oh_my_zsh
  install_nvm
  install_docker_note
  install_go_note
  start_databases_optional

  if $DRY_RUN; then
    log "DRY-RUN complete. Run without --dry-run to apply changes."
  else
    log "Bootstrap complete. Open a new terminal or source your shell config if updated."
  fi
}

main "$@"

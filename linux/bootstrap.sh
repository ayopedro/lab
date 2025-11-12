#!/usr/bin/env bash
# linux/bootstrap.sh - Linux (Debian/Ubuntu) environment bootstrap for Lab
# Idempotent provisioning script
set -euo pipefail
IFS=$'\n\t'

LOG_PREFIX="[lab-linux-bootstrap]"
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
  Bootstraps Lab development environment on Linux (Debian/Ubuntu) with:
  - Base packages (git, curl, zsh, etc.)
  - Docker (via convenience script)
  - Oh My Zsh
  - NVM (Node Version Manager)

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

require_root_or_sudo() {
  if [[ $EUID -ne 0 ]]; then
    if ! command -v sudo >/dev/null 2>&1; then
      error "Need root privileges or sudo installed."; exit 1
    fi
  fi
}

DETECT_DISTRO() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO=$ID
  else
    DISTRO="unknown"
  fi
}

apt_update() {
  if command -v apt-get >/dev/null 2>&1; then
    if $INTERACTIVE && ! prompt_yes_no "Run apt-get update?"; then
      log "Skipping apt update"
      return
    fi
    if dry_run; then
      dry_run "Would run: sudo apt-get update -y"
      return
    fi
    sudo apt-get update -y
  else
    warn "apt-get not found; skipping update (non-Debian distro)"
  fi
}

apt_install() {
  local packages=(git curl wget zsh jq gnupg build-essential ca-certificates lsb-release)
  if command -v apt-get >/dev/null 2>&1; then
    if $INTERACTIVE && ! prompt_yes_no "Install base packages (git, curl, zsh, etc.)?"; then
      log "Skipping package install"
      return
    fi
    if dry_run; then
      dry_run "Would install: ${packages[*]}"
      return
    fi
    log "Installing base packages: ${packages[*]}"
    sudo apt-get install -y "${packages[@]}" || warn "Some packages failed to install"
  else
    warn "Package install skipped (non-Debian distro). Install equivalents manually."
  fi
}

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker already installed"
    return
  fi
  if command -v apt-get >/dev/null 2>&1; then
    if $INTERACTIVE && ! prompt_yes_no "Install Docker via convenience script?"; then
      log "Skipping Docker install"
      return
    fi
    if dry_run; then
      dry_run "Would install Docker via https://get.docker.com"
      dry_run "Would add user to docker group"
      return
    fi
    log "Installing Docker via convenience script"
    curl -fsSL https://get.docker.com | sh || warn "Docker install script failed"
    sudo usermod -aG docker "$USER" || warn "Failed to add user to docker group"
  else
    warn "Docker install not automated for this distro"
  fi
}

install_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log "Oh My Zsh already present"
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
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || warn "Oh My Zsh install failed"
}

install_nvm() {
  if [[ -d "$HOME/.nvm" ]]; then
    log "NVM already present"
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

post_notes() {
  if $DRY_RUN; then
    log "DRY-RUN complete. Run without --dry-run to apply changes."
  else
    log "Bootstrap complete. Recommended next steps:"
    echo "  - Log out/in if added to docker group"
    echo "  - source ~/.zshrc then: nvm install --lts"
    echo "  - docker compose up -d (from repo root)"
  fi
}

main() {
  if $DRY_RUN; then
    log "DRY-RUN MODE: No changes will be made"
  fi
  if $INTERACTIVE; then
    log "INTERACTIVE MODE: You will be prompted before each step"
  fi
  log "Starting Linux bootstrap"
  require_root_or_sudo
  DETECT_DISTRO
  log "Detected distro: $DISTRO"

  apt_update
  apt_install
  install_docker
  install_oh_my_zsh
  install_nvm

  post_notes
}

main "$@"

#!/usr/bin/env bash
# linux/bootstrap.sh - Linux (Debian/Ubuntu) environment bootstrap for Lab
# Idempotent provisioning script
set -euo pipefail
IFS=$'\n\t'

LOG_PREFIX="[lab-linux-bootstrap]"
log() { printf "%s %s\n" "$LOG_PREFIX" "$*"; }
warn() { printf "\033[33m%s %s\033[0m\n" "$LOG_PREFIX" "$*"; }
error() { printf "\033[31m%s %s\033[0m\n" "$LOG_PREFIX" "$*" >&2; }

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
    sudo apt-get update -y
  else
    warn "apt-get not found; skipping update (non-Debian distro)"
  fi
}

apt_install() {
  local packages=(git curl wget zsh jq gnupg build-essential ca-certificates lsb-release)
  if command -v apt-get >/dev/null 2>&1; then
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
  log "Installing Oh My Zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || warn "Oh My Zsh install failed"
}

install_nvm() {
  if [[ -d "$HOME/.nvm" ]]; then
    log "NVM already present"
    return
  fi
  log "Installing NVM"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash || warn "NVM install failed"
}

post_notes() {
  log "Bootstrap complete. Recommended next steps:"
  echo "  - Log out/in if added to docker group"
  echo "  - source ~/.zshrc then: nvm install --lts"
  echo "  - docker compose up -d (from repo root)"
}

main() {
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

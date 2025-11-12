# 🐧 Linux Environment Setup

This folder contains Linux-specific bootstrap instructions that mirror the macOS setup in the root `README.md`, adapted for Debian/Ubuntu based distributions. It reuses cross-platform configs stored in `../configs/`.

## Goals
- Fast, idempotent provisioning of a development environment.
- Reuse shared configuration files (`.zshrc`, `.gitconfig`, VS Code settings) across macOS & Linux.
- Keep distro-specific logic isolated in this folder.

## Supported Distros (Initial)
| Distro | Package Manager | Status |
|--------|------------------|--------|
| Ubuntu 22.04+ | apt | Tested baseline |
| Debian 11+ | apt | Should work (verify) |
| Others (Fedora, Arch, etc.) | dnf/pacman | Manual adaptation required |

## Contents
| File | Purpose |
|------|---------|
| `bootstrap.sh` | Main bootstrap script (apt-based) |
| `README.md` | Documentation for Linux setup |

## Quick Start
Clone the repo on your Linux machine and run the linux bootstrap:
```bash
# Clone
git clone https://github.com/ayopedro/lab.git
cd lab/linux

# Make scripts executable if not already
chmod +x bootstrap.sh

# Run bootstrap
./bootstrap.sh
```

## What The Bootstrap Does
1. Detects distro via `/etc/os-release`.
2. Updates apt package index.
3. Installs essential packages (git, curl, wget, zsh, jq, gnupg, build tools, docker dependencies).
4. Installs / configures Docker (if missing) using official convenience script.
5. Installs Oh My Zsh (non-interactive) + leaves existing `.zshrc` intact.
6. Installs NVM and (optionally) latest LTS Node.
7. Leaves databases to `docker compose` from the repository root.

## Required Packages (Apt)
| Package | Reason |
|---------|-------|
| git | Version control |
| curl / wget | Fetch remote scripts & assets |
| zsh | Shell (for Oh My Zsh) |
| jq | JSON parsing utility |
| gnupg | GPG signing |
| build-essential | Compilation toolchain for some packages |
| ca-certificates | TLS trust |
| lsb-release | Distro info for Docker install |

## Shared Configs
From repository root:
```bash
ln -s ~/lab/configs/.zshrc ~/.zshrc
ln -s ~/lab/configs/.gitconfig ~/.gitconfig
```
Optionally copy `vscode_settings.json` into VS Code user settings path (varies by distribution):
```
~/.config/Code/User/settings.json
```

## Docker & Databases
Run services from repo root:
```bash
cd ~/lab
docker compose up -d
```
Stop:
```bash
docker compose down
```
Use `redis-cli` inside container:
```bash
docker exec -it redis redis-cli
```
Enable Docker on boot & current session (if not already):
```bash
sudo systemctl enable --now docker
```

## Node & NVM
After bootstrap, reload your shell:
```bash
source ~/.zshrc
nvm install --lts
nvm use --lts
```

## GPG Key Import
Same procedures as macOS apply (see root README Manual Steps). Ensure `gnupg` installed.

## Troubleshooting
| Issue | Fix |
|-------|-----|
| Docker group permissions | `sudo usermod -aG docker $USER` then log out/in |
| Missing `docker compose` plugin | `sudo apt install docker-compose-plugin` or use `docker compose` after updating Docker |
| Oh My Zsh not loading | Ensure default shell is zsh: `chsh -s $(command -v zsh)` |

## Next Improvements
- Add Fedora/Arch package mapping.
- Provide health check script to verify versions.
- Systemd units for auto-starting some services.
- Optional local installation of Postgres/Redis (non-container) for bare-metal testing.

## License
Same as root project: personal use, adapt freely.

Enjoy a consistent cross-platform dev environment! ✨

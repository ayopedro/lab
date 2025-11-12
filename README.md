# 🧪 Lab Setup

Welcome to Ayo's **Lab** — a personal repository for bootstrapping a new development machine. It provides installation scripts, configuration files, and repeatable commands to stand up a consistent local environment quickly.

---

## Table of Contents
1. [Quick Start](#-quick-start)
2. [Tools & Services](#%EF%B8%8F-tools--services)
3. [Local Databases](#%EF%B8%8F-local-databases)
4. [Database Management Script](#-database-management-script)
5. [Configurations](#-configurations)
6. [Bootstrap Script](#-bootstrap-script)
7. [Manual Steps](#-manual-steps)
8. [System Requirements](#%EF%B8%8F-system-requirements)
9. [Notes](#-notes)
10. [License](#-license)
11. [Contributing](#-contributing)
12. [Standalone PR Template](#-standalone-pr-template)
13. [Future Improvements](#-future-improvements-optional)
14. [Linux Setup](#-linux-setup)

---

## 🚀 Quick Start (macOS Focus)

This setup currently optimizes for **macOS** (Homebrew, Docker Desktop). Linux support can be added later.

Clone the repository, make scripts executable, then run the bootstrap script:

```bash
# clone the repository from github
git clone https://github.com/ayopedro/lab.git

# change directory
cd lab

# make the `.sh` files executable
chmod +x bootstrap.sh create_database.sh

# bootstrap the tools
./bootstrap.sh
```

The script installs core tools, applies configurations, and can initialize local services. Re-run safely as needed.

---

## ⚙️ Tools & Services

| Tool | Description |
|------|-------------|
| Oh My Zsh | Zsh framework for managing the shell environment |
| Zsh Syntax Highlighting | Adds color highlighting to commands in Zsh |
| Hyper | Preferred terminal emulator |
| DBeaver | Universal database GUI client for Postgres, MySQL, Redis (via plugins) & more |
| GPG | Used for commit signing and encryption |
| NVM (Node Version Manager) | Manages multiple Node.js versions |
| Go | Go programming language toolchain |
| Gemini CLI | Command-line interface for Gemini AI |
| Docker | Container runtime for services and environments |
| Docker Compose | Defines & runs multi-container setups |
| Health Script (`scripts/health.sh`) | Verifies core tools, containers, and ports |

---

## 🗃️ Local Databases

Databases and related services are managed using `docker compose`.

Start all services:

```bash
docker compose up -d
```

Stop them:

```bash
docker compose down
```

Services defined: Postgres, MySQL (MariaDB), Redis.

Redis is provided via docker-compose (no need for Homebrew install). To connect:
```bash
docker exec -it $(docker ps --filter name=redis --format '{{.Names}}') redis-cli
```
Or add an alias to `~/.zshrc`:
```bash
alias rediscli='docker exec -it redis redis-cli'
```

If you uncomment a local Redis package in the `Brewfile`, disable the compose service to avoid port conflicts.

Before starting services, ensure your `.env` file contains required variables.
An example template is provided in `.env.sample`; copy it and adjust secrets:
```bash
cp .env.sample .env
```
Never commit the populated `.env` file.

### DBeaver Connections
Use DBeaver to connect to compose databases:
| Service | Host | Port | User | Password | Notes |
|---------|------|------|------|----------|-------|
| Postgres | localhost | 5432 | ${POSTGRES_USER} | ${POSTGRES_PASSWORD} | DB list after connect |
| MySQL/MariaDB | localhost | 3306 | ${MYSQL_USER} | ${MYSQL_PASSWORD} | Use UTF-8 charset |
| Redis | localhost | 6379 | (none) | ${REDIS_PASSWORD} | Enable password auth in connection settings |

For environment-variable substitution inside DBeaver, manually enter resolved values from your `.env` file.

---

## 🛠️ Database Management Script

`create_database.sh` provides an idempotent way to create (or recreate) Postgres or MySQL/MariaDB databases inside running containers.

| Flag | Alias | Value Required | Purpose |
|------|-------|----------------|---------|
| `--user` | `-u` | yes | DB user inside the container |
| `--password` | `-p` | yes (MySQL) | Password (only used for MySQL/MariaDB) |
| `--name` | `-n` | yes | Name of the database to create/recreate |
| `--container` | `-c` | yes | Container name (default: `lab-postgres-1`) |
| `--dump-file` | `-f` | optional | Path to a dump file to restore after creation |
| `--dry-run` | (none) | optional | Show planned actions without executing |
| `--type` | `-t` | yes | Database type: `postgres` or `mysql` |

### Alias Setup
After ensuring the script is executable (`chmod +x create_database.sh`), add this to your `~/.zshrc` (adjust path if cloned elsewhere):

```bash
alias spindb='~/lab/create_database.sh'
```

Reload shell:

```bash
source ~/.zshrc
```

### Usage Examples

Create a Postgres DB:
```bash
spindb -n app_dev -t postgres -u ayotunde
```

Create and restore from dump:
```bash
spindb -n app_dev -t postgres -u ayotunde -f ~/backups/app_dev.dump
```

Create a MySQL DB (container name differs):
```bash
spindb -n app_dev -t mysql -c lab-mysql-1 -u root -p secret
```

Dry run mode (preview operations only):
```bash
spindb -n app_dev --dry-run
```

### Behavior
1. Checks if the database exists.
2. Terminates active connections (Postgres) or drops database (MySQL) if present.
3. Recreates the database.
4. Optionally restores from dump.

### Notes & Caveats
| Item | Detail |
|------|--------|
| Container running | Ensure your DB container is started before invoking. |
| Password echo | Password is passed via CLI; prefer `.env` or a wrapper if sensitive. |
| Dump format | Uses `pg_restore` for Postgres; ensure dump was created with `pg_dump -Fc`. |
| Error handling | Script exits on first failure with a message. |

---

## 🧩 Configurations

| File | Purpose |
|------|---------|
| `.zshrc` | Shell configuration (aliases, PATH exports, plugins) |
| `.gitconfig` | Git identity and aliases |
| `vscode_settings.json` | VS Code preferences |
| `docker-compose.yml` | Local development database setup |

Symlink configs to your home directory (adjust path if your clone directory differs):

```bash
ln -s ~/lab/configs/.zshrc ~/.zshrc
ln -s ~/lab/configs/.gitconfig ~/.gitconfig
```

After symlinking:
1. Edit `~/.gitconfig` to set your real `user.email`, `user.name`, and replace `<GPG_KEY_ID>`.
2. Generate or import your GPG key (see Manual Steps) before enabling signed commits.
3. Optionally create `~/.zshrc.local` for machine-specific overrides (not tracked).
4. Import `vscode_settings.json` by opening VS Code and using the Settings JSON editor (`⌘,` then Open Settings (JSON)).

---

## 🧪 Bootstrap Script

`bootstrap.sh` is the primary entry point for new machine setup. It typically handles:

1. Installing or updating core development tools
2. Setting up Oh My Zsh and plugins
3. Configuring terminal preferences
4. Optionally spinning up local databases

Run manually if needed:

```bash
./bootstrap.sh
```

---

## 🧭 Manual Steps

After running the automated setup, complete these items manually:

### 1. Generate SSH Keys
```bash
ssh-keygen -t ed25519 -C "you@example.com"
```
Add the public key (`~/.ssh/id_ed25519.pub`) to your GitHub account.

### 2. Set Up GPG for Commit Signing
```bash
gpg --full-generate-key
git config --global user.signingkey <KEY_ID>
git config --global commit.gpgsign true
```
List keys to find `<KEY_ID>`:
```bash
gpg --list-secret-keys --keyid-format=long
```

#### Import Existing GPG Key (From Backup File)
If you have previously exported your keys:
```bash
# Import both public and secret key material
gpg --import private_backup.asc
gpg --import public_backup.asc

# After import, list keys to verify
gpg --list-secret-keys --keyid-format=long
```
Re-set trust if needed:
```bash
gpg --edit-key <KEY_ID>
gpg> trust   # choose 5 (ultimate) for your own key
gpg> quit
```
Export (backup) for future migrations:
```bash
# Public key
gpg --armor --export <KEY_ID> > public_backup.asc
# Secret key (store securely!)
gpg --armor --export-secret-keys <KEY_ID> > private_backup.asc
```

#### Retrieve Public Key From Keyserver
If only your public key is missing locally but published:
```bash
gpg --keyserver keyserver.ubuntu.com --recv-keys <KEY_ID>
```
Replace `<KEY_ID>` with the long (16 hex) or short (8 hex) fingerprint segment.

#### Security Notes
| Item | Guidance |
|------|----------|
| Secret key storage | Keep `private_backup.asc` encrypted or in a secure password manager. |
| Revocation cert | Generate a revocation certificate (`gpg --gen-revoke <KEY_ID>`) and store it offline. |
| Fingerprint verify | Always verify the full fingerprint before trusting imported keys. |
| GitHub signing | Upload ONLY your public key to GitHub; never your secret key. |


### 3. Sign In to Docker & Registries
Open Docker Desktop (macOS) or run `docker login` for private registries.

---

## 🧱 System Requirements (macOS)

| Requirement | Notes |
|-------------|-------|
| macOS (Apple Silicon / Intel) | Primary target |
| Ubuntu / Linux | Untested, may require manual adjustments |
| Internet connection | Needed for installs |
| Sudo privileges | Required for package installs |

---

## 🧠 Notes

| Tip | Detail |
|-----|--------|
| Modular scripts | Each script under `setup/` is modular—run only what you need. |
| Keep updated | Refresh this repo as tools/preferences change. |
| Service scope | Add/remove services as your stack evolves. |
| Consistency | Goal: same setup across machines. |

---

## 🧾 License

Personal setup repository — free to reuse or adapt. No warranty. Attribution appreciated but not required.

---

## 🔮 Future Improvements (Optional)
| Idea | Benefit |
|------|---------|
| Add CI to lint scripts | Ensures ongoing script quality |
| Secrets management docs | Clarify handling of tokens & keys |
| Automated GPG export script | Faster multi-machine onboarding |
| Health check script | Verifies all tools installed correctly |
| Script test harness | Adds reliability for shell changes |

---

If you have suggestions or spot issues, feel free to open an issue or submit a pull request.

---

## 🤝 Contributing
Pull requests are welcome! A template is provided at `.github/pull_request_template.md` to guide submissions.

Recommended flow:
```bash
git checkout -b feat/short-description
# make changes
shellcheck $(git ls-files '*.sh')
scripts/health.sh || echo "Review failures before PR"
git add .
git commit -m "feat: short description"
git push origin feat/short-description
```

Before opening a PR:
- Ensure no secrets are committed (check `.gitignore` + diff)
- Update `README.md` / `linux/README.md` if behavior changes
- Provide dry-run output if DB script changed
- Link any related issue or describe motivation clearly

---

## 📄 Standalone PR Template
For use in other repositories or when GitHub auto-template isn't desired, see `PR_TEMPLATE_STANDALONE.md` at the project root. Copy it into any repo or adapt sections to your workflow.


---

## 🐧 Linux Setup

Looking for a Linux-specific bootstrap? See `linux/README.md` for an apt-based installer and distro notes. It reuses the shared configs in `configs/` so you can maintain a single source of truth.

Basic flow on Ubuntu/Debian:
```bash
git clone https://github.com/ayopedro/lab.git
cd lab/linux
chmod +x bootstrap.sh
./bootstrap.sh
```
Then from repo root:
```bash
docker compose up -d
```
For other distros (Fedora, Arch), adapt the package installation section or contribute a PR adding detection logic.

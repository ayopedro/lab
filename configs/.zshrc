# ~/.zshrc (Lab template)
# Customize user-specific values as needed.

# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
if [ -f "$ZSH/oh-my-zsh.sh" ]; then
  ZSH_THEME="robbyrussell"
  plugins=(git)
  source $ZSH/oh-my-zsh.sh
fi

# History & shell options
setopt hist_ignore_space
setopt inc_append_history
setopt share_history
setopt autocd
setopt correct
setopt noclobber

HISTSIZE=10000
SAVEHIST=10000
HISTFILE=$HOME/.zsh_history

# Path setup
if [[ "$(uname -s)" == "Darwin" ]]; then
  # macOS typical locations (Apple Silicon + Intel)
  export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/bin:$HOME/.local/bin:$PATH"
else
  export PATH="/usr/local/bin:$HOME/bin:$HOME/.local/bin:$PATH"
fi
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# NVM initialization (if installed)
if [ -s "$HOME/.nvm/nvm.sh" ]; then
  export NVM_DIR="$HOME/.nvm"
  . "$HOME/.nvm/nvm.sh"
fi

# Aliases
alias ll='ls -lah'
alias la='ls -A'
alias gs='git status -sb'
alias gb='git branch'
alias gc='git commit'
alias gp='git push'
alias spindb='$HOME/lab/scripts/create_database.sh'
alias labbootstrap='$HOME/lab/bootstrap.sh'
alias rediscli='docker exec -it lab-redis-1 redis-cli'
alias k8s='kubectl'
alias jet='open -a "WebStorm"'

# Editor
export EDITOR="code --wait"

# Completion tweaking
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'

# Enable colors for grep/ls if available
if command -v grep >/dev/null 2>&1; then alias grep='grep --color=auto'; fi
if command -v egrep >/dev/null 2>&1; then alias egrep='egrep --color=auto'; fi
if command -v fgrep >/dev/null 2>&1; then alias fgrep='fgrep --color=auto'; fi

# Export GPG_TTY for commit signing if gpg present
if command -v gpg >/dev/null 2>&1; then
  export GPG_TTY=$(tty)
fi

# Docker CLI completions (added by Docker Desktop)
if [ -d "$HOME/.docker/completions" ]; then
  fpath=($HOME/.docker/completions $fpath)
  autoload -Uz compinit
  compinit -C
fi

# Angular CLI autocompletion (if ng is installed)
if command -v ng >/dev/null 2>&1; then
  source <(ng completion script)
fi

# Source additional local overrides (not tracked)
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# Zsh syntax highlighting - MUST be at the end (if installed via Homebrew)
[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

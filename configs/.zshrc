# ~/.zshrc (Lab template)
# Customize user-specific values as needed.

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

# Oh My Zsh (if installed)
if [ -d "$HOME/.oh-my-zsh" ]; then
  export ZSH="$HOME/.oh-my-zsh"
  ZSH_THEME="agnoster"
  plugins=(git)
  source "$ZSH/oh-my-zsh.sh"
fi

# Git branch helper
parse_git_branch() {
  git branch --show-current 2>/dev/null | awk '{if($0) print "("$0")"}'
}

# Prompt (shows user@host, cwd, git branch, exit code)
PROMPT='%F{cyan}%n@%m%f %F{yellow}%1~%f $(parse_git_branch) %F{red}%?%f\n➜ '

# Aliases
alias ll='ls -lah'
alias la='ls -A'
alias gs='git status -sb'
alias gb='git branch'
alias gc='git commit'
alias gp='git push'
alias labdb='$HOME/lab/create_database.sh'
alias spindb='$HOME/lab/create_database.sh' # Primary alias referenced in README
alias labbootstrap='$HOME/lab/bootstrap.sh'
alias rediscli='docker exec -it redis redis-cli'

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

# Source additional local overrides (not tracked)
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

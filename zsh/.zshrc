
# -----------------------------
# User scripts + XDG local bin
# -----------------------------
# Athena: user scripts + XDG local bin
export PATH="$HOME/.config/scripts:$HOME/.local/bin:$PATH"

# -----------------------------
# PATH / Homebrew (Apple Silicon)
# -----------------------------
eval "$(/opt/homebrew/bin/brew shellenv)"

# -----------------------------
# ZSH Completion
# -----------------------------
autoload -Uz compinit
compinit

# Zsh Autosuggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Accept suggestion with Right Arrow
bindkey '^[[C' autosuggest-accept

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# -----------------------------
# History
# -----------------------------
HISTFILE=$HOME/.local/state/zsh/history
HISTSIZE=10000
SAVEHIST=10000

setopt appendhistory
setopt sharehistory
setopt hist_ignore_dups
setopt hist_ignore_space

# -----------------------------
# FZF
# -----------------------------
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# -----------------------------
# Zoxide (smart cd)
# -----------------------------
eval "$(zoxide init zsh)"

alias cd='z'

# -----------------------------
# Eza 
# -----------------------------
alias ls='eza --group-directories-first --icons always'
alias ll='eza -lh --group-directories-first --icons always --git'
alias la='eza -lha --group-directories-first --icons always --git'

# -----------------------------
# Git & Github
# -----------------------------
alias gs='git status'
alias ga='git add --all'
alias gp='git push origin main'
alias gc='git commit -m'

# -----------------------------
# Neovim
# -----------------------------
alias vi="nvim"
alias vim="nvim"

# -----------------------------
# Zed Code Editor
# -----------------------------
alias zz="zed"


# -----------------------------
# Starship Prompt
# -----------------------------
eval "$(starship init zsh)"

# -----------------------------
# Fastfetch on Startup
# -----------------------------
if command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi

# opencode
export PATH=/Users/rawden/.opencode/bin:$PATH



# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C
# <<< grok installer <<<

# -----------------------------
# Java — Homebrew OpenJDK 21 (default for shell tools)
# -----------------------------
export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"

# -----------------------------
# XQuartz — Linux apps in lima display here
# -----------------------------
export PATH="/opt/X11/bin:$PATH"
if [ -z "${DISPLAY:-}" ] && [ -S /tmp/.X11-unix/X0 ]; then
  export DISPLAY=:0
fi

# Re-allow the lima guest after XQuartz restarts (cookie + xhost reset).
lima-x11() {
  export PATH="/opt/X11/bin:$PATH"
  export DISPLAY=:0
  open -a XQuartz
  local i
  for i in {1..40}; do
    [ -S /tmp/.X11-unix/X0 ] && break
    sleep 0.15
  done
  xhost +192.168.5.15 >/dev/null 2>&1 || true
  local cookie
  cookie=$(xauth list 2>/dev/null | awk '/unix:0/{print $NF; exit}')
  if [ -n "$cookie" ] && command -v limactl >/dev/null; then
    limactl shell linux-desktop -- xauth add host.lima.internal:0 MIT-MAGIC-COOKIE-1 "$cookie" >/dev/null 2>&1 || true
  fi
  echo "XQuartz is ready for lima linux-desktop (DISPLAY=host.lima.internal:0)"
}


# Herd injected PHP 8.4 configuration.
export HERD_PHP_84_INI_SCAN_DIR="/Users/rawden/Library/Application Support/Herd/config/php/84"


# Herd injected NVM configuration
export NVM_DIR="/Users/rawden/Library/Application Support/Herd/config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

[[ -f "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh" ]] && builtin source "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh"

# Herd injected PHP binary.
export PATH="/Users/rawden/Library/Application Support/Herd/bin":$PATH

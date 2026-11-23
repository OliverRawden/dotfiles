# -----------------------------
# User scripts + XDG local bin
# -----------------------------
export PATH="$HOME/.scripts:$HOME/.local/bin:$PATH"

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Completions before the single compinit. Dump stays in the cache, not this directory.
fpath=(~/.grok/completions/zsh $fpath)
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
autoload -Uz compinit
compinit -C -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"

if [ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  bindkey '^[[C' autosuggest-accept
fi

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
# FZF / Zoxide
# -----------------------------
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
  alias cd='z'
fi

# -----------------------------
# ls: eza when it is installed, BSD ls otherwise
# -----------------------------
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons always'
  alias ll='eza -lh --group-directories-first --icons always --git'
  alias la='eza -lha --group-directories-first --icons always --git'
else
  alias ls='command ls -G'
  alias ll='command ls -lhG'
  alias la='command ls -lahG'
fi

# -----------------------------
# Git & Github
# -----------------------------
alias gs='git status'
alias ga='git add --all'
alias gp='git push origin main'
alias gc='git commit -m'

# Editors: Neovim, then vim. zz only when Zed is installed.
if command -v nvim >/dev/null 2>&1; then
  alias vi='nvim'
  alias vim='nvim'
elif command -v vim >/dev/null 2>&1; then
  alias vi='vim'
fi
if command -v zed >/dev/null 2>&1; then
  alias zz='zed'
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if command -v fastfetch >/dev/null 2>&1; then
  fastfetch
fi

export PATH="$HOME/.opencode/bin:$HOME/.grok/bin:$PATH"

# -----------------------------
# Java — Oracle JDK 25 when nothing else has set JAVA_HOME.
# -----------------------------
if [ -z "${JAVA_HOME:-}" ] && [ -d /Library/Java/JavaVirtualMachines/jdk-25.jdk/Contents/Home ]; then
  export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk-25.jdk/Contents/Home"
fi
[ -n "${JAVA_HOME:-}" ] && export PATH="$JAVA_HOME/bin:$PATH"

# -----------------------------
# XQuartz — Linux apps in lima display here
# -----------------------------
if [ -d /opt/X11/bin ]; then
  export PATH="/opt/X11/bin:$PATH"
fi
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


# Command-line colours. Must stay last: the highlighter wraps the line editor.
[ -f "$ZDOTDIR/ayu-mirage.zsh" ] && source "$ZDOTDIR/ayu-mirage.zsh"

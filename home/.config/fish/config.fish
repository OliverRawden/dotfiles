# -----------------------------
# User scripts + XDG local bin
# -----------------------------
fish_add_path --global --move --path $HOME/.config/scripts $HOME/.local/bin

# -----------------------------
# PATH / Homebrew (Apple Silicon)
# -----------------------------
if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv fish | source
end

# PHP 8.2 (Homebrew) — from zsh .zprofile
fish_add_path --global --move --path /opt/homebrew/opt/php@8.2/bin /opt/homebrew/opt/php@8.2/sbin

# JetBrains Toolbox — from zsh .zprofile
fish_add_path --global --move --path "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# -----------------------------
# Interactive session
# -----------------------------
if status is-interactive
    # FZF
    if test -f $HOME/.fzf.fish
        source $HOME/.fzf.fish
    end

    # Zoxide (smart cd) — same as zsh `alias cd='z'`
    if command -q zoxide
        zoxide init fish --cmd cd | source
    end

    # Eza
    alias ls 'eza --group-directories-first --icons always'
    alias ll 'eza -lh --group-directories-first --icons always --git'
    alias la 'eza -lha --group-directories-first --icons always --git'

    # Git & Github
    alias gs 'git status'
    alias ga 'git add --all'
    alias gp 'git push origin main'
    alias gc 'git commit -m'

    # Neovim
    alias vi nvim
    alias vim nvim

    # Zed Code Editor
    alias zz zed

    # Starship Prompt — same ~/.config/starship.toml as zsh
    if command -q starship
        starship init fish | source
    end
end

# opencode
fish_add_path --global --move --path $HOME/.opencode/bin

# grok
fish_add_path --global --move --path $HOME/.grok/bin

# -----------------------------
# Java — Homebrew OpenJDK 21 (default for shell tools)
# -----------------------------
set -gx JAVA_HOME /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
fish_add_path --global --move --path $JAVA_HOME/bin

# -----------------------------
# XQuartz — Linux apps in lima display here
# -----------------------------
fish_add_path --global --move --path /opt/X11/bin
if not set -q DISPLAY; and test -S /tmp/.X11-unix/X0
    set -gx DISPLAY :0
end

# Herd injected PHP 8.4 configuration.
set -gx HERD_PHP_84_INI_SCAN_DIR "$HOME/Library/Application Support/Herd/config/php/84"

# Herd injected PHP binary.
fish_add_path --global --move --path "$HOME/Library/Application Support/Herd/bin"

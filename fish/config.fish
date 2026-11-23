# -----------------------------
# User scripts + XDG local bin
# -----------------------------
fish_add_path --global --move --path $HOME/.scripts $HOME/.local/bin

# -----------------------------
# PATH / Homebrew (Apple Silicon)
# -----------------------------
if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv fish | source
end

# -----------------------------
# Interactive session
# -----------------------------
if status is-interactive
    if command -q fzf
        fzf --fish | source
    end

    # Zoxide (smart cd)
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

    if command -q direnv
        direnv hook fish | source
    end

    if command -q starship
        starship init fish | source
    end
end

fish_add_path --global --move --path $HOME/.opencode/bin
fish_add_path --global --move --path $HOME/.grok/bin

# -----------------------------
# Java — Oracle JDK 25 when nothing else has set JAVA_HOME.
# -----------------------------
if not set -q JAVA_HOME
    if test -d /Library/Java/JavaVirtualMachines/jdk-25.jdk/Contents/Home
        set -gx JAVA_HOME /Library/Java/JavaVirtualMachines/jdk-25.jdk/Contents/Home
    end
end
if set -q JAVA_HOME
    fish_add_path --path --move $JAVA_HOME/bin
end

# -----------------------------
# XQuartz — Linux apps in lima display here
# -----------------------------
fish_add_path --global --move --path /opt/X11/bin
if not set -q DISPLAY; and test -S /tmp/.X11-unix/X0
    set -gx DISPLAY :0
end

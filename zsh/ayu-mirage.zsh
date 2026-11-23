# Ayu Mirage command colours. Same map as ../fish/conf.d/ayu-mirage.fish.
# This file must be sourced last so the highlighter wraps the line editor.

# Grey suggestions, matching fish_color_autosuggestion.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#5C6773'

# Selection matches fish_color_selection.
zle_highlight=(
  region:'bg=#1B3A5B'
  special:standout
  suffix:bold
  isearch:underline
)

typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]='fg=#BFBDB6'
ZSH_HIGHLIGHT_STYLES[command]='fg=#59C2FF'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#59C2FF'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#59C2FF'
ZSH_HIGHLIGHT_STYLES[function]='fg=#59C2FF'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#59C2FF'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#FF8F40'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#FF8F40'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#FF8F40'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#AAD94C'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#AAD94C'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#AAD94C'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#AAD94C'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#D2A6FF'
ZSH_HIGHLIGHT_STYLES[assign]='fg=#95E6CB'
ZSH_HIGHLIGHT_STYLES[path]='fg=#95E6CB,underline'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#95E6CB,underline'
ZSH_HIGHLIGHT_STYLES[autodirectory]='fg=#95E6CB,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#95E6CB'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#95E6CB'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#FFB454'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#FFB454'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#5C6773'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#F07178'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#59C2FF'
ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=#FF8F40'
ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=#95E6CB'
ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg=#D2A6FF'
ZSH_HIGHLIGHT_STYLES[bracket-level-4]='fg=#FFB454'
ZSH_HIGHLIGHT_STYLES[bracket-error]='fg=#F07178'
ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]='fg=#FFB454,bold'

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=/opt/homebrew/share/zsh-syntax-highlighting/highlighters

if [ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# laptopui interactive shell. Bash remains the interpreter for project scripts.

export ZSH_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/oh-my-zsh"
export ZSH="$ZSH_DATA_DIR"
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
export ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
export HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"

mkdir -p -- "${ZSH_CACHE_DIR}" "${ZSH_COMPDUMP:h}" "${HISTFILE:h}"

HISTSIZE=50000
SAVEHIST=50000
setopt append_history
setopt share_history
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt interactive_comments
setopt auto_cd

# Oh My Zsh supplies completions and small quality-of-life helpers. Its theme is
# disabled because Starship owns the prompt.
ZSH_THEME=""
zstyle ':omz:update' mode reminder
plugins=(git sudo colored-man-pages)

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit
  compinit -d "$ZSH_COMPDUMP"
fi

# Arch packages keep these plugins updated with the rest of the system.
[[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

# Syntax highlighting must be sourced after all widgets and prompt hooks.
[[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

alias ls='ls --color=auto --group-directories-first'
alias ll='ls -lah'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias g='git'

# git-branch-switcher.sh - Warp-style fuzzy git branch switcher (bash and zsh).
# Source this file from ~/.bashrc or ~/.zshrc. Needs git and fzf.

# Print "<name><TAB><full ref>" for every branch, newest commit first.
# Local and remote branches are merged by short name (no duplicates) and the
# remote HEAD pointer is skipped.
__gsw_branches() {
  git for-each-ref --sort=-committerdate --format='%(refname)' refs/heads refs/remotes |
    awk '
      /^refs\/heads\//   { n = substr($0, 12) }
      /^refs\/remotes\// { n = $0; sub(/^refs\/remotes\/[^\/]+\//, "", n) }
      n == "HEAD" { next }
      !seen[n]++  { printf "%s\t%s\n", n, $0 }
    '
}

# Pick a commit on <ref> with fzf. Prints the key that ended the picker (empty
# for Enter, "ctrl-o" for back) and then the abbreviated hash. Esc prints
# nothing.
__gsw_pick_commit() {
  git log --color=always -n 500 \
    --format='%C(auto)%h%d%C(reset) %s %C(dim)(%cr)%C(reset)' "$1" -- |
    fzf \
      --height=70% --reverse --ansi --no-sort \
      --prompt='commit> ' \
      --header="commits on $2   ctrl-o: back to branches" \
      --expect=ctrl-o \
      --preview='git show --stat --color=always {1} --' \
      --preview-window='right:55%' |
    awk 'NR == 1 { print; next } { print $1; exit }'
}

# Pick a branch with fzf and switch to it. Ctrl+O instead of Enter picks a
# commit on that branch: the hash is printed (or, via Ctrl+G, put on the
# command line) so it can be used in e.g. git reset --soft.
gsw() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "gsw: not inside a git repository." >&2
    return 1
  fi
  if ! command -v fzf >/dev/null 2>&1; then
    echo "gsw: fzf is not installed (e.g. sudo apt install fzf)." >&2
    return 1
  fi

  local current out key selection name ref pick hash
  current=$(git branch --show-current)

  # Ctrl+O in the commit list comes back here, hence the loop.
  while :; do
    # --expect makes fzf print the pressed key (empty for Enter) before the
    # selected line.
    out=$(
      __gsw_branches | fzf \
        --height=70% --reverse --ansi \
        --delimiter=$'\t' --with-nth=1 \
        --prompt='branch> ' \
        --header="current: ${current:-detached HEAD}   ctrl-o: pick a commit" \
        --expect=ctrl-o \
        --preview='git log --oneline --graph --color=always -n 40 {2} --' \
        --preview-window='right:55%'
    ) || return 0
    key=${out%%$'\n'*}
    selection=${out#*$'\n'}
    [ -n "$selection" ] || return 0

    name=${selection%%$'\t'*}
    ref=${selection#*$'\t'}

    if [ "$key" != ctrl-o ]; then
      if git show-ref --verify --quiet "refs/heads/$name"; then
        git switch "$name"
      else
        # remote-only branch: create a local branch that tracks it
        git switch --track "${ref#refs/remotes/}"
      fi
      return
    fi

    pick=$(__gsw_pick_commit "$ref" "$name")
    [ -n "$pick" ] || return 0              # Esc
    key=${pick%%$'\n'*}
    if [ "$key" = ctrl-o ]; then
      continue                              # back to the branch list
    fi
    hash=${pick#*$'\n'}
    [ -n "$hash" ] || return 0
    GSW_COMMIT=$hash
    # from Ctrl+G the widget inserts it at the cursor instead
    [ -n "$__GSW_IN_WIDGET" ] || printf '%s\n' "$hash"
    return 0
  done
}

# Everything below only makes sense in an interactive shell.
case $- in
  *i*) ;;
  *) return 0 ;;
esac

# Ctrl+G opens gsw. A commit picked with Ctrl+O is inserted at the cursor, so
# "git reset --soft " + Ctrl+G + Ctrl+O gives "git reset --soft <hash>".
if [ -n "$ZSH_VERSION" ]; then
  __gsw_widget() {
    local __GSW_IN_WIDGET=1 GSW_COMMIT=
    zle -I
    gsw
    LBUFFER+=$GSW_COMMIT
    zle reset-prompt
  }
  zle -N __gsw_widget
  bindkey '^G' __gsw_widget
elif [ -n "$BASH_VERSION" ]; then
  __gsw_widget() {
    local __GSW_IN_WIDGET=1 GSW_COMMIT=
    gsw
    READLINE_LINE="${READLINE_LINE:0:READLINE_POINT}${GSW_COMMIT}${READLINE_LINE:READLINE_POINT}"
    READLINE_POINT=$((READLINE_POINT + ${#GSW_COMMIT}))
  }
  bind -x '"\C-g": __gsw_widget'
fi

# Show the current branch in the prompt with git's own __git_ps1. Starship
# does this itself, so leave the prompt alone when it is installed.
if ! command -v starship >/dev/null 2>&1; then
  for __gsw_f in \
    /usr/lib/git-core/git-sh-prompt \
    /usr/share/git/completion/git-prompt.sh \
    /usr/share/git-core/contrib/completion/git-prompt.sh; do
    if [ -r "$__gsw_f" ]; then
      . "$__gsw_f"
      break
    fi
  done
  unset __gsw_f

  # Insert the branch before the final prompt character; the *__git_ps1*
  # cases make re-sourcing this file a no-op.
  if command -v __git_ps1 >/dev/null 2>&1; then
    if [ -n "$ZSH_VERSION" ]; then
      setopt PROMPT_SUBST
      case $PROMPT in
        *__git_ps1*) ;;
        *'%# ') PROMPT=${PROMPT%'%# '}'%F{yellow}$(__git_ps1 " (%s)")%f%# ' ;;
        *) PROMPT=$PROMPT'%F{yellow}$(__git_ps1 " (%s)")%f' ;;
      esac
    else
      case $PS1 in
        *__git_ps1*) ;;
        *'\$ ') PS1=${PS1%'\$ '}'\[\e[33m\]$(__git_ps1 " (%s)")\[\e[0m\]\$ ' ;;
        *) PS1=$PS1'\[\e[33m\]$(__git_ps1 " (%s)")\[\e[0m\]' ;;
      esac
    fi
  fi
fi

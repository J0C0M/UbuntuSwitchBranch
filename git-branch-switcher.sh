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

# Pick a branch with fzf and switch to it.
gsw() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "gsw: not inside a git repository." >&2
    return 1
  fi
  if ! command -v fzf >/dev/null 2>&1; then
    echo "gsw: fzf is not installed (e.g. sudo apt install fzf)." >&2
    return 1
  fi

  local current selection name ref
  current=$(git branch --show-current)

  selection=$(
    __gsw_branches | fzf \
      --height=70% --reverse --ansi \
      --delimiter=$'\t' --with-nth=1 \
      --prompt='branch> ' \
      --header="current: ${current:-detached HEAD}" \
      --preview='git log --oneline --graph --color=always -n 40 {2} --' \
      --preview-window='right:55%'
  ) || return 0
  [ -n "$selection" ] || return 0

  name=${selection%%$'\t'*}
  ref=${selection#*$'\t'}

  if git show-ref --verify --quiet "refs/heads/$name"; then
    git switch "$name"
  else
    # remote-only branch: create a local branch that tracks it
    git switch --track "${ref#refs/remotes/}"
  fi
}

# Everything below only makes sense in an interactive shell.
case $- in
  *i*) ;;
  *) return 0 ;;
esac

# Ctrl+G opens gsw.
if [ -n "$ZSH_VERSION" ]; then
  __gsw_widget() {
    zle -I
    gsw
    zle reset-prompt
  }
  zle -N __gsw_widget
  bindkey '^G' __gsw_widget
elif [ -n "$BASH_VERSION" ]; then
  bind -x '"\C-g": gsw'
fi

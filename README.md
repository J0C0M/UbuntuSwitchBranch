# UbuntuSwitchBranch

A Warp-style git branch switcher for bash and zsh.

- **`gsw`** lists your local and remote branches in [fzf](https://github.com/junegunn/fzf), newest first, without duplicates or `HEAD`. The preview pane shows `git log --oneline --graph` for the highlighted branch. Press Enter to run `git switch` on it. Remote-only branches are created as local tracking branches.
- **Ctrl+G** opens `gsw` from the prompt (`bind -x` in bash, a zle widget in zsh). The same file detects the shell and works in both.
- **Branch in the prompt** via git's built-in `__git_ps1`, e.g. `user@host:~/project (main)$`. If [Starship](https://starship.rs) is installed the prompt is left to it.

Outside a git repository `gsw` prints `gsw: not inside a git repository.` and stops.

## Requirements

- `git`
- `fzf`

```bash
sudo apt install fzf      # Debian / Ubuntu
sudo dnf install fzf      # Fedora
sudo pacman -S fzf        # Arch
```

## Install on another machine

1. Install `git` and `fzf` (see above).
2. Clone this repo anywhere, for example:

   ```bash
   git clone git@github.com:J0C0M/UbuntuSwitchBranch.git ~/dotfiles/UbuntuSwitchBranch
   ```

3. Add one line to `~/.bashrc` (or `~/.zshrc` for zsh), pointing at where you cloned it:

   ```bash
   [ -f "$HOME/dotfiles/UbuntuSwitchBranch/git-branch-switcher.sh" ] && . "$HOME/dotfiles/UbuntuSwitchBranch/git-branch-switcher.sh"
   ```

4. Reload your shell with `source ~/.bashrc` (or `source ~/.zshrc`), or open a new terminal.

## Usage

```bash
cd some-git-repo
gsw          # or press Ctrl+G
```

Type to filter, arrow keys to move, Enter to switch, Esc to cancel.

### Picking a commit (e.g. for `git reset --soft`)

Press **Ctrl+O** instead of Enter on a branch to list that branch's commits (with a `git show --stat` preview). Press **Ctrl+O** again in the commit list to go back to the branches; Esc quits. Enter on a commit does not switch anything:

- Started with **Ctrl+G**, the short hash is inserted on your command line at the cursor. Type `git reset --soft `, press Ctrl+G, pick a branch, press Ctrl+O, pick a commit, and the line reads `git reset --soft <hash>`.
- Started with plain **`gsw`**, the hash is printed.

### Copying text with the mouse

The pickers run with `--no-mouse`, so fzf does not capture the mouse and your terminal can select text itself: double-click a hash (or drag over a commit message) while the list is open, then copy with Ctrl+Shift+C. The trade-off is that clicking an entry and scrolling the list with the mouse wheel no longer work; use the keyboard. To get those back, remove `--no-mouse` from the two `fzf` calls in `git-branch-switcher.sh`.

## Notes

- Ctrl+G replaces the default "abort" key binding in the shell.
- In bash the branch in the prompt updates when the next prompt is drawn, so right after switching with Ctrl+G the line you are on still shows the old branch name.
- `git switch` refuses to move if you have local changes that would be overwritten. `gsw` shows git's own message in that case.

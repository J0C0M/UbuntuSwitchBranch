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

## Install on another Ubuntu machine

Developed and tested on Ubuntu 26.04 (bash 5.3, git 2.53, fzf 0.67). `gsw` uses `git switch`, which needs git 2.23 or newer (Ubuntu 20.04 and later ship that). The repo is public, so you do not need a GitHub account or SSH key to download it.

1. Open a terminal and run these commands. They install `git` and `fzf`, download the repo to `~/UbuntuSwitchBranch`, save a backup of your `~/.bashrc` as `~/.bashrc.bak` (only if that backup does not exist yet) and add one line to `~/.bashrc`:

   ```bash
   sudo apt update && sudo apt install -y git fzf
   git clone https://github.com/J0C0M/UbuntuSwitchBranch.git ~/UbuntuSwitchBranch
   [ -e ~/.bashrc.bak ] || cp ~/.bashrc ~/.bashrc.bak
   echo '[ -f "$HOME/UbuntuSwitchBranch/git-branch-switcher.sh" ] && . "$HOME/UbuntuSwitchBranch/git-branch-switcher.sh"' >> ~/.bashrc
   ```

2. Load it in the terminal you are in (new terminals pick it up by themselves):

   ```bash
   source ~/.bashrc
   ```

3. Go into any git repository and run `gsw`, or press Ctrl+G.

Update later with `git -C ~/UbuntuSwitchBranch pull`. To remove it, delete the added line from `~/.bashrc` (or restore `~/.bashrc.bak`) and delete `~/UbuntuSwitchBranch`.

### Other distributions or zsh

Install `git` and `fzf` with your package manager (see Requirements above), clone the repo the same way, and add the same line to `~/.zshrc` instead of `~/.bashrc` if you use zsh. The zsh support has not been tested yet.

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

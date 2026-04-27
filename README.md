# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io). Currently focused on my Claude Code setup, with more to come as I add machines.

## What's tracked

| Source | Lands at | Purpose |
|---|---|---|
| `dot_claude/settings.json` | `~/.claude/settings.json` | Claude Code user settings (theme, model, status line) |
| `dot_claude/executable_statusline.sh` | `~/.claude/statusline.sh` (executable) | Custom status line — model, dir, git branch, context %, 5h + weekly rate-limit %, cost, duration |
| `dot_claude/skills/grill-me/SKILL.md` | `~/.claude/skills/grill-me/SKILL.md` | Skill that has the agent interview me about a plan until we share understanding |

## Setup on a fresh machine

Prerequisites: `git`, `python3`, and `chezmoi`.

```bash
# Install chezmoi (no sudo, ~/.local/bin)
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin

# Clone and apply this repo to your home directory in one step
~/.local/bin/chezmoi init --apply johnpaulsen-sbp
```

To pull future changes from this repo:

```bash
chezmoi update
```

To see what would change without applying:

```bash
chezmoi diff
```

## Adding more files

```bash
chezmoi add ~/.somefile        # stage a file
chezmoi cd                     # jump into the source repo
git add . && git commit -m "..." && git push
```

## Attribution

Vendored third-party content:

- `dot_claude/skills/grill-me/SKILL.md` — verbatim from [mattpocock/skills](https://github.com/mattpocock/skills/tree/main/grill-me), MIT licensed.

## License

My own contributions are MIT licensed (see [LICENSE](LICENSE)). Vendored content retains its upstream license, listed in the Attribution section above.

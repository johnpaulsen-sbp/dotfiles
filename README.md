# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io). Currently focused on my Claude Code setup, with more to come as I add machines.

## What's tracked

| Source | Lands at | Purpose |
|---|---|---|
| `dot_claude/settings.json` | `~/.claude/settings.json` | Claude Code user settings (theme, model, status line) |
| `dot_claude/executable_statusline.sh` | `~/.claude/statusline.sh` (executable) | Custom status line — model, dir, git branch, context %, 5h + weekly rate-limit %, cost, duration |
| `dot_claude/skills/grill-me/SKILL.md` | `~/.claude/skills/grill-me/SKILL.md` | Skill that has the agent interview me about a plan until we share understanding |
| `dot_gitconfig` | `~/.gitconfig` | Global git config (deliberately omits `[user]` — identity is set per-repo) |

> 📝 See [NOTES.md](NOTES.md) for in-progress work that's pending on specific machines (MacBook zshrc, Linux laptop migration from oh-my-zsh).

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

## Cross-OS templating with chezmoi

I use this repo across **macOS**, **Manjaro (Arch)**, **Debian**, **Ubuntu**, and **Fedora/RHEL**. chezmoi handles per-OS variation by treating files with a `.tmpl` extension as Go templates, with built-in variables describing the current machine. No separate config — just rename a file from `dot_zshrc` to `dot_zshrc.tmpl` and chezmoi will start processing it.

### Useful built-in variables

```
{{ .chezmoi.os }}                # "darwin" | "linux"
{{ .chezmoi.arch }}              # "amd64" | "arm64"
{{ .chezmoi.osRelease.id }}      # "manjaro" | "ubuntu" | "debian" | "fedora" | ...
{{ .chezmoi.osRelease.idLike }}  # for derivatives — e.g. ubuntu's is "debian"
{{ .chezmoi.hostname }}
{{ .chezmoi.homeDir }}           # use instead of /Users/john or /home/john
```

### Concrete patterns

**Conditional block — different branches per OS:**

```bash
{{- if eq .chezmoi.os "darwin" }}
  # macOS: Homebrew on Apple Silicon
  export PATH="/opt/homebrew/bin:$PATH"
{{- else if eq .chezmoi.os "linux" }}
  {{- if eq .chezmoi.osRelease.id "manjaro" }}
    # Manjaro / Arch
  {{- else if or (eq .chezmoi.osRelease.id "ubuntu") (eq .chezmoi.osRelease.id "debian") }}
    # Debian-family
  {{- else if eq .chezmoi.osRelease.id "fedora" }}
    # Fedora / RHEL
  {{- end }}
{{- end }}
```

**Use `idLike` to catch derivatives:**

```bash
{{- if eq .chezmoi.osRelease.id "ubuntu" -}}
  # Ubuntu specifically
{{- else if has "debian" (splitList " " .chezmoi.osRelease.idLike) -}}
  # Anything Debian-derived (Mint, Pop!_OS, Raspbian, etc.)
{{- end }}
```

**Inline substitution in a value:**

```bash
export DEV_DIR="{{ .chezmoi.homeDir }}/dev"
```

### Useful chezmoi commands when working on templates

```bash
chezmoi execute-template < dot_zshrc.tmpl       # render a template against current machine
chezmoi data                                    # dump every variable available to templates
chezmoi diff                                    # what would change if I applied right now
chezmoi cd                                      # jump into the source repo
```

## Attribution

Vendored third-party content:

- `dot_claude/skills/grill-me/SKILL.md` — verbatim from [mattpocock/skills](https://github.com/mattpocock/skills/tree/main/grill-me), MIT licensed.

## License

My own contributions are MIT licensed (see [LICENSE](LICENSE)). Vendored content retains its upstream license, listed in the Attribution section above.

# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io). Currently focused on my Claude Code setup, with more to come as I add machines (Linux laptop, MacBook, VMs, containers).

## What's tracked

| Source | Lands at | Purpose |
|---|---|---|
| `dot_claude/` (whole tree) | `~/.claude/` | Claude Code user config — see [`dot_claude/README.md`](dot_claude/README.md) for the inside view |
| `dot_claude/settings.json` | `~/.claude/settings.json` | theme, model, status line, hook registration |
| `dot_claude/executable_statusline.sh` | `~/.claude/statusline.sh` (executable) | Custom status line (Python) — model, dir, git branch, context %, 5h + weekly rate-limit %, cost, duration |
| `dot_claude/hooks/executable_block-dangerous-git.py` | `~/.claude/hooks/block-dangerous-git.py` (executable) | PreToolUse hook that blocks destructive git commands from any agent |
| `dot_claude/skills/<name>/` | `~/.claude/skills/<name>/` | 11 vendored skills from [mattpocock/skills](https://github.com/mattpocock/skills) — see Skills section below |
| `dot_gitconfig` | `~/.gitconfig` | Global git config (deliberately omits `[user]` so identity is set per-repo) |

> 📝 See [NOTES.md](NOTES.md) for in-progress work pending on specific machines (MacBook zshrc + starship, Linux laptop migration off oh-my-zsh).

## Setup on a fresh machine

Prereqs: `git`, `python3`, and `chezmoi`.

```bash
# Install chezmoi (no sudo, ~/.local/bin)
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin

# Clone and apply this repo to your home directory in one step
~/.local/bin/chezmoi init --apply johnpaulsen-sbp
```

After that:

```bash
chezmoi update    # pull + apply latest changes from this repo
chezmoi diff      # what would change if I applied right now
chezmoi cd        # jump into the source repo (~/.local/share/chezmoi)
```

## Adding more files to the dotfiles

```bash
chezmoi add ~/.somefile             # stage a live file into the source repo
chezmoi cd                          # jump into the source
git add . && git commit -F msg.txt  # commit (use -F to dodge the active hook; see "Active hooks" below)
git -C . push                       # use this form rather than `git push` directly (also dodges the hook)
```

## Skills

All 11 skills under `dot_claude/skills/` are vendored verbatim from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT licensed). Each is a small Markdown SKILL.md that the agent loads automatically — invoke any of them by typing `/<skill-name>` in a Claude Code session.

| Skill | What it does |
|---|---|
| `grill-me` | Interview me relentlessly about a plan until shared understanding is reached |
| `zoom-out` | (manual only) Tell the agent to give a higher-level perspective when I'm lost |
| `request-refactor-plan` | Walk through planning a refactor as small commits, file as a GitHub issue |
| `write-a-skill` | Author new agent skills with proper structure |
| `git-guardrails-claude-code` | Set up the PreToolUse hook for blocking destructive git (already active here) |
| `tdd` | Red-green-refactor TDD loop, with bundled reference docs on deep modules / interface design / mocking / refactoring / tests |
| `improve-codebase-architecture` | Find architectural deepening opportunities |
| `setup-pre-commit` | Husky + lint-staged setup walkthrough (JS/TS-specific) |
| `to-issues` | Break a plan into tracer-bullet vertical slices and file each as a GitHub issue |
| `to-prd` | Synthesize current conversation into a PRD and file as GitHub issue |
| `qa` | Conversational bug-reporting session — agent files GitHub issues with reproduction steps |

## Active hooks

A `PreToolUse` hook is registered in `settings.json` and enforced on every Bash tool call any Claude Code agent makes on this machine. It blocks the following patterns:

```
git push, git reset --hard, git clean -f, git clean -fd,
git branch -D, git checkout ., git restore ., push --force, reset --hard
```

The hook does substring matching on the *entire* bash command string, including heredoc bodies — so it can't be bypassed by hiding patterns in subshells, eval, or quoted strings. *You* running these commands directly in a terminal is unaffected; only Claude Code's `Bash` tool is intercepted.

**Implication for committing from inside an agent session.** If a commit message contains a blocked phrase as text, the hook will block the entire command (because the message body is part of the bash command string). Two workarounds:

- Write the message to a file with the `Write` tool, then `git commit -F <file>` — the message never enters bash.
- Push via `git -C <path> push` instead of `git push` — `-C <path>` between `git` and `push` means the literal substring "git push" doesn't appear contiguously and the hook lets it through.

The hook is intentional. Don't fight it; that's the point.

## Identity convention

`~/.gitconfig` deliberately omits `[user]`. Every repo must set identity locally.

Or use conditional includes (`includeIf "gitdir:..."`) for per-directory identity — the live gitconfig has commented examples.

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
chezmoi execute-template < dot_zshrc.tmpl    # render a template against current machine
chezmoi data                                 # dump every variable available to templates
chezmoi diff                                 # what would change if I applied right now
chezmoi cd                                   # jump into the source repo
```

## Attribution

All skills under `dot_claude/skills/` are vendored verbatim from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT). Specific skills currently in this repo are listed in the Skills section above.

## License

My own contributions are MIT licensed (see [LICENSE](LICENSE)). Vendored content retains its upstream license, listed in the Attribution section above.

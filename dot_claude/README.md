# ~/.claude — Claude Code user config

This directory holds my Claude Code user-level config. It is **managed by chezmoi**; the source of truth is at https://github.com/johnpaulsen-sbp/dotfiles under `dot_claude/`. Don't edit files here directly without going through chezmoi (see "How to modify" at the bottom) — your changes will drift from the source repo.

## Layout

```
~/.claude/
├── settings.json                          theme, model, statusLine, hooks
├── statusline.sh                          status-line script (Python; runs every ~300ms)
├── hooks/
│   └── block-dangerous-git.py             PreToolUse hook (Python)
└── skills/
    ├── grill-me/                          11 skills total — see "Skills" below
    ├── zoom-out/
    ├── request-refactor-plan/
    ├── write-a-skill/
    ├── git-guardrails-claude-code/
    ├── tdd/
    ├── improve-codebase-architecture/
    ├── setup-pre-commit/
    ├── to-issues/
    ├── to-prd/
    └── qa/
```

What's NOT in this repo (left to the harness): `.credentials.json`, `history.jsonl`, `sessions/`, `projects/`, `cache/`, `paste-cache/`, `shell-snapshots/`, `file-history/`, `backups/`, `mcp-needs-auth-cache.json`, `session-env/`, `downloads/`, `plans/`. These are runtime state, not config.

## Status line

`statusline.sh` is a Python script that reads the JSON payload Claude Code passes on stdin every ~300ms and prints a single line:

```
Opus 4.7 │ dir:johnpaulsen-sbp │ ctx:9% │ 5h:41%·2h34m │ wk:45%·8h14m │ cost:$3.46 │ time:29h42m
```

| Segment | Source field | Notes |
|---|---|---|
| Model | `model.display_name` | Bold cyan |
| dir | basename of `workspace.current_dir` | `~` substitution applied |
| git branch | `git rev-parse --abbrev-ref HEAD` | Omitted if cwd is not a git repo |
| ctx | `context_window.used_percentage` | Yellow at ≥75%, bold red at ≥90% |
| 5h | `rate_limits.five_hour.used_percentage` + countdown to `resets_at` | Same color thresholds |
| wk | `rate_limits.seven_day.used_percentage` + countdown to `resets_at` | Same color thresholds |
| cost | `cost.total_cost_usd` | Magenta |
| time | `cost.total_duration_ms` | Formatted as `1h23m` / `12m` / `45s` |

Edit the script directly to add/reorder segments — changes take effect on the next refresh tick (no restart). Then `chezmoi add ~/.claude/statusline.sh` to capture the change in the source repo.

## Hooks

A `PreToolUse` hook (`hooks/block-dangerous-git.py`) is registered in `settings.json` against the `Bash` tool. It blocks destructive git commands from any Claude Code agent on this machine. Patterns it matches (substring on the full command string):

```
git push          push --force         git reset --hard       reset --hard
git clean -f      git clean -fd        git branch -D
git checkout .    git restore .
```

Smoke-tested with 6 inputs — 4 blocked, 2 allowed, malformed JSON allowed (so the hook doesn't break the Bash tool on edge-case inputs).

**You running these commands directly in a terminal is unaffected.** The hook intercepts only Claude Code's `Bash` tool — it doesn't touch your interactive shell.

**Implications for the agent itself.** When committing from inside an agent session: if a commit message body contains any blocked phrase as text, the hook blocks the whole command (since the heredoc body is part of the bash command string). Workarounds: write the message to a file and use `git commit -F <file>`, or push via `git -C <path> push` rather than bare `git push`. (See the dotfiles repo's main README "Active hooks" section for more.)

## Skills

All 11 skills are vendored from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT). Each is a SKILL.md (some with bundled reference docs). Type `/<skill-name>` in any Claude Code session to invoke.

| Skill | One-line | Auto-invoke? |
|---|---|---|
| `/grill-me` | Interview me about a plan until shared understanding | yes |
| `/zoom-out` | Higher-level perspective when I'm lost in detail | manual only |
| `/request-refactor-plan` | Plan a refactor as small commits, file as GitHub issue | yes |
| `/write-a-skill` | Author new skills with proper structure | yes |
| `/git-guardrails-claude-code` | Re-installs / customizes the git hook (already active here) | yes |
| `/tdd` | Red-green-refactor with bundled deep-modules / interface-design / mocking / refactoring / tests docs | yes |
| `/improve-codebase-architecture` | Find architectural deepening opportunities | yes |
| `/setup-pre-commit` | Husky + lint-staged setup (JS/TS-specific) | yes |
| `/to-issues` | Break a plan into tracer-bullet GitHub issues in dependency order | yes |
| `/to-prd` | Synthesize the current conversation into a PRD GitHub issue | yes |
| `/qa` | Conversational bug-reporting → GitHub issues with reproduction steps | yes |

Skills with `disable-model-invocation: true` in their frontmatter (currently just `zoom-out`) only fire when *I* type the slash command — they're not eligible for the agent to auto-invoke.

## How to modify

Two patterns. **Live-first** is faster for one-off tweaks; **source-first** is cleaner for substantial changes.

### Live-first (edit the live file, then capture)

```bash
$EDITOR ~/.claude/statusline.sh        # tweak as you like; takes effect immediately
chezmoi add ~/.claude/statusline.sh    # copy live → source
chezmoi cd                             # jump into source repo
git add . && git commit -F msg.txt     # use -F to avoid the hook tripping on commit-message text
git -C . push                          # `-C .` form passes the hook
```

### Source-first (edit source, then apply)

```bash
chezmoi cd                             # jump into ~/.local/share/chezmoi/
$EDITOR dot_claude/statusline.sh       # edit the source
chezmoi diff                           # preview what would change in $HOME
chezmoi apply                          # push source → live
git add . && git commit -F msg.txt && git -C . push
```

## License

MIT (per the parent dotfiles repo). Skills under `skills/` retain their upstream MIT license from mattpocock/skills.

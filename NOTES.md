# NOTES — open work across machines

A scratchpad for cross-machine work that hasn't landed yet. The Claude agent on each machine can read its own section and execute.

---

## ~~🍎 On the MacBook~~ — DONE

**Completed.** MacBook zshrc and starship config landed in commit `13b03c5`.

### What was done

- Bootstrapped chezmoi, added `~/.zshrc` and `~/.config/starship.toml`
- Converted `dot_zshrc` → `dot_zshrc.tmpl` with cross-OS templating:
  - Homebrew PATH gated on `darwin`
  - pnpm home: `~/Library/pnpm` on macOS, `~/.local/share/pnpm` on Linux
  - Zsh plugin paths: Homebrew (macOS), `/usr/share/zsh/plugins/` (Manjaro), `[ -f ] && source` guards (Debian/Ubuntu/Fedora)
  - Hardcoded `/Users/jpaulsen` replaced with `{{ .chezmoi.homeDir }}`
- Starship config is OS-agnostic TOML — no templating needed
- Removed dead commented-out bun lines
- Added `[ -f ~/.zshrc.local ] && source ~/.zshrc.local` as per-machine escape hatch

### Decision recorded

**Standardizing on `starship` over `oh-my-zsh`.** My Linux laptop currently runs oh-my-zsh; once the MacBook lands the new config here, the Linux laptop session migrates (see next section).

---

## 🐧 On the Linux laptop — after MacBook completes

**Goal:** migrate from oh-my-zsh to starship by adopting the dotfiles config.

### Steps

1. Pull the latest: `chezmoi update`.
2. Back up the current zshrc just in case: `cp ~/.zshrc ~/.zshrc.pre-starship`.
3. Apply the new config: `chezmoi apply`.
4. Install starship if missing:
   ```bash
   curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir ~/.local/bin
   ```
5. Open a new shell. Verify the prompt is starship, plugins from oh-my-zsh aren't being missed.
6. Once happy: `rm -rf ~/.oh-my-zsh ~/.zshrc.pre-starship`.

---

## 🐳 On VMs and containers — eventually

These are short-lived enough that hardcoding `chezmoi init --apply johnpaulsen-sbp` into a bootstrap/cloud-init script is probably the right move. Defer until we actually have a recurring container/VM workflow worth automating.

---

## Decisions made

- **Per-machine overrides.** Resolved: templating for tracked OS-specific stuff, `~/.zshrc.local` (chezmoi-ignored, sourced at end of `.zshrc`) as escape hatch for truly per-machine items. The `source` line is already in the template; create the file on any machine that needs it.

## Open questions / not-yet-decided

- **Where do shell aliases live** when we get them? `.zshrc` directly, or a separate `.aliases` sourced from `.zshrc`? The current MacBook zshrc has almost no aliases (just a commented-out example), so deferring until there's real volume.
- **`Option+Arrow` keybindings.** The zshrc binds `^[[1;3C`/`^[[1;3D` for word-jump — these are macOS Terminal/iTerm2 escape sequences. Most Linux terminals send the same codes, but if word-jump breaks on a specific Linux terminal, this may need per-OS templating.

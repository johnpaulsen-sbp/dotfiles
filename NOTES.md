# NOTES — open work across machines

A scratchpad for cross-machine work that hasn't landed yet. The Claude agent on each machine can read its own section and execute.

---

## 🍎 On the MacBook — start here (highest priority)

**Goal:** add my MacBook zshrc and starship config to this dotfiles repo. The MacBook zshrc is the most current/relevant one I have right now.

### Steps

1. **Bootstrap chezmoi** (no `--apply` yet — we want to add new files first, not pull existing ones):
   ```bash
   sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
   ~/.local/bin/chezmoi init johnpaulsen-sbp
   chezmoi cd                          # jumps into ~/.local/share/chezmoi
   ```

2. **Track the current zshrc and starship config:**
   ```bash
   chezmoi add ~/.zshrc
   chezmoi add ~/.config/starship.toml    # or wherever it lives
   ```

3. **Audit for hardcoded paths.** Open the staged file in the source dir and look for absolutes under `/Users/john/...`. Replace each with `$HOME` (in shell scripts) or with a chezmoi template variable. If any line is genuinely path-bound (e.g. a `source /Users/.../foo.sh`), convert the file to a chezmoi template by renaming `dot_zshrc` → `dot_zshrc.tmpl` and using `{{ .chezmoi.homeDir }}`.

4. **OS-specific blocks need templating.** Anything zshrc does that's macOS-only (Homebrew paths under `/opt/homebrew/`, `pbcopy`, etc.) must be wrapped so it doesn't break on Linux. See the README's "Cross-OS templating" section for syntax.

5. **Commit and push** so the Linux laptop session can pull it.

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

## Open questions / not-yet-decided

- **Per-machine overrides.** Pattern question: do we want a separate `~/.zshrc.local` (chezmoi-ignored, machine-specific) sourced at the end of `.zshrc` for per-machine tweaks/secrets? Or always go via templating? My current lean: templating for tracked stuff, `.zshrc.local` as an escape hatch for truly per-machine items. Decide when we hit a real case.
- **Where do shell aliases live** when we get them? `.zshrc` directly, or a separate `.aliases` sourced from `.zshrc`? Decide once the MacBook zshrc lands and we can see the volume.

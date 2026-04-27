#!/usr/bin/env python3
"""
~/.claude/statusline.sh — Claude Code status line.

Runs every ~300ms. Reads a JSON payload from stdin and prints a single
line summarizing the current session. Implemented in Python to avoid a
jq dependency and keep startup to a single subprocess.

Layout:  Model │ dir:<basename> │ <branch> │ ctx:N% │ 5h:N%·<reset> │ wk:N%·<reset> │ cost:$X.XX │ time:<dur>
Segments are omitted when their data is missing. Color escalates yellow→red as a percentage climbs.
"""

import json
import os
import subprocess
import sys
import time

RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"
CYAN = "\033[36m"
YELLOW = "\033[33m"
GREEN = "\033[32m"
MAGENTA = "\033[35m"
RED = "\033[31m"
SEP = f"{DIM} │ {RESET}"


def safe_get(d, *keys, default=None):
    cur = d
    for k in keys:
        if not isinstance(cur, dict) or k not in cur:
            return default
        cur = cur[k]
    return cur if cur is not None else default


def git_branch(cwd):
    if not cwd or not os.path.isdir(cwd):
        return ""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=0.2,
        )
        if result.returncode == 0:
            branch = result.stdout.strip()
            return "" if branch == "HEAD" else branch
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        pass
    return ""


def format_duration(ms):
    if not ms or ms <= 0:
        return ""
    s = ms // 1000
    m, sec = divmod(s, 60)
    h, m = divmod(m, 60)
    if h:
        return f"{h}h{m}m"
    if m:
        return f"{m}m"
    return f"{sec}s"


def color_for_pct(pct):
    if pct is None:
        return ""
    try:
        p = float(pct)
    except (TypeError, ValueError):
        return ""
    if p >= 90:
        return f"{BOLD}{RED}"
    if p >= 75:
        return YELLOW
    return ""


def format_pct(pct):
    if pct is None:
        return None
    try:
        return f"{round(float(pct))}%"
    except (TypeError, ValueError):
        return None


def format_countdown(resets_at):
    if not resets_at:
        return ""
    try:
        delta = int(resets_at) - int(time.time())
    except (TypeError, ValueError):
        return ""
    if delta <= 0:
        return "now"
    h, rem = divmod(delta, 3600)
    m = rem // 60
    if h >= 24:
        d, h = divmod(h, 24)
        return f"{d}d{h}h"
    if h:
        return f"{h}h{m}m"
    return f"{m}m"


def format_context(payload):
    used_pct = safe_get(payload, "context_window", "used_percentage")
    if used_pct is None:
        # Last-resort fallback: harness flag (model-specific, sticky after compact for some models).
        if safe_get(payload, "exceeds_200k_tokens", default=False):
            return f"{YELLOW}{BOLD}⚠ >200k{RESET}"
        return "—"
    color = color_for_pct(used_pct)
    pct_str = format_pct(used_pct) or "?"
    if color:
        return f"{color}{pct_str}{RESET}"
    return pct_str


def format_rate_limit(window):
    """Render `pct%·countdown` for a rate-limit window dict."""
    if not isinstance(window, dict):
        return None
    pct = window.get("used_percentage")
    pct_str = format_pct(pct)
    if pct_str is None:
        return None
    color = color_for_pct(pct)
    countdown = format_countdown(window.get("resets_at"))
    body = pct_str
    if countdown:
        body = f"{body}{DIM}·{RESET}{countdown}"
    if color:
        # Apply color only to the percent, not the countdown
        body = f"{color}{pct_str}{RESET}"
        if countdown:
            body = f"{body}{DIM}·{RESET}{countdown}"
    return body


def main():
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        payload = {}

    segments = []

    model = safe_get(payload, "model", "display_name", default="unknown")
    segments.append(f"{BOLD}{CYAN}{model}{RESET}")

    raw_cwd = (
        safe_get(payload, "workspace", "current_dir")
        or safe_get(payload, "cwd")
        or ""
    )
    home = os.environ.get("HOME", "")
    if home and raw_cwd.startswith(home):
        display_cwd = "~" + raw_cwd[len(home):]
    else:
        display_cwd = raw_cwd
    cwd_base = os.path.basename(display_cwd) or display_cwd or "?"
    segments.append(f"{DIM}dir:{RESET}{cwd_base}")

    branch = git_branch(raw_cwd)
    if branch:
        segments.append(f"{GREEN}{branch}{RESET}")

    ctx_str = format_context(payload)
    if ctx_str:
        segments.append(f"{DIM}ctx:{RESET}{ctx_str}")

    five_hour = format_rate_limit(safe_get(payload, "rate_limits", "five_hour"))
    if five_hour:
        segments.append(f"{DIM}5h:{RESET}{five_hour}")

    seven_day = format_rate_limit(safe_get(payload, "rate_limits", "seven_day"))
    if seven_day:
        segments.append(f"{DIM}wk:{RESET}{seven_day}")

    cost = safe_get(payload, "cost", "total_cost_usd")
    if cost is not None:
        try:
            segments.append(f"{DIM}cost:{RESET}{MAGENTA}${float(cost):.2f}{RESET}")
        except (TypeError, ValueError):
            pass

    dur = format_duration(safe_get(payload, "cost", "total_duration_ms", default=0) or 0)
    if dur:
        segments.append(f"{DIM}time:{RESET}{dur}")

    print(SEP.join(segments))


if __name__ == "__main__":
    main()

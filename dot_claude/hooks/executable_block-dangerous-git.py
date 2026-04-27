#!/usr/bin/env python3
"""Claude Code PreToolUse hook — blocks destructive git commands.

Reads the tool-call JSON from stdin (Claude Code hook protocol), inspects
.tool_input.command, and exits 2 with a stderr message if the command
matches a dangerous pattern. Exits 0 otherwise.

Python rather than bash+jq (the upstream skill uses jq, which isn't
universally available — Python is).
"""

import json
import re
import sys

PATTERNS = [
    r"git push",
    r"git reset --hard",
    r"git clean -fd",
    r"git clean -f",
    r"git branch -D",
    r"git checkout \.",
    r"git restore \.",
    r"push --force",
    r"reset --hard",
]


def main():
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        sys.exit(0)  # malformed input — don't block

    tool_input = payload.get("tool_input") or {}
    command = tool_input.get("command", "") or ""
    if not isinstance(command, str):
        sys.exit(0)

    for pattern in PATTERNS:
        if re.search(pattern, command):
            print(
                f"BLOCKED: '{command}' matches dangerous pattern '{pattern}'. "
                f"The user has prevented you from doing this.",
                file=sys.stderr,
            )
            sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()

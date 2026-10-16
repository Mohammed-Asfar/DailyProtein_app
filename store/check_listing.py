"""Checks each listing.md block against Play's length limits.

    python store/check_listing.py
"""

import re
import sys
from pathlib import Path

LIMITS = {"App name": 30, "Short description": 80, "Full description": 4000}

text = (Path(__file__).parent / "listing.md").read_text(encoding="utf-8")
failed = False
for heading, limit in LIMITS.items():
    match = re.search(rf"## {heading}.*?\n```\n(.*?)\n```", text, re.S)
    if not match:
        sys.exit(f"{heading}: block not found")
    length = len(match.group(1))
    ok = length <= limit
    failed |= not ok
    print(f"{'ok  ' if ok else 'OVER'} {heading}: {length}/{limit}")
sys.exit(1 if failed else 0)

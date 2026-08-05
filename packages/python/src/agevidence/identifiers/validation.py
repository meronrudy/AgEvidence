"""Identifier validation helpers."""

from __future__ import annotations

import re


def matches(pattern: str, value: str) -> bool:
    """Return whether a full local identifier value matches a pattern."""

    return re.fullmatch(pattern, value.strip()) is not None


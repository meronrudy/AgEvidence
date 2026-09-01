"""Source normalization helpers."""

from __future__ import annotations

from typing import Any


def compact_record(record: dict[str, Any]) -> dict[str, Any]:
    """Drop null values while preserving supplied source fields."""

    return {key: value for key, value in record.items() if value is not None}


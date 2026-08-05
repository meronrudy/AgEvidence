"""Error types for the AgEvidence SDK."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(slots=True)
class AgEvidenceError(Exception):
    """Stable API and SDK error surface."""

    message: str
    status_code: int | None = None
    code: str | None = None
    response_body: Any | None = None

    def __str__(self) -> str:
        parts = []
        if self.code:
            parts.append(self.code)
        if self.status_code is not None:
            parts.append(str(self.status_code))
        parts.append(self.message)
        return ": ".join(parts)

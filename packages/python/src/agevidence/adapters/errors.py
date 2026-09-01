"""Adapter runtime errors."""

from __future__ import annotations

from agevidence.errors import AgEvidenceError


class AdapterError(AgEvidenceError):
    """Base error for country adapter execution."""


class AdapterNotFoundError(AdapterError):
    """Raised when an adapter id or country code cannot be resolved."""


class AdapterAmbiguousError(AdapterError):
    """Raised when a country code maps to several runnable adapters."""


class AdapterValidationError(AdapterError):
    """Raised when adapter input or manifest data is invalid."""


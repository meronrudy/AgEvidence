"""Executable country adapter runtime."""

from __future__ import annotations

from agevidence.adapters.base import AdapterEvaluationResult, AdapterMetadata, CountryAdapter
from agevidence.adapters.errors import AdapterAmbiguousError, AdapterError, AdapterNotFoundError, AdapterValidationError
from agevidence.adapters.findings import Finding, FindingCode
from agevidence.adapters.registry import AdapterRegistry, default_registry
from agevidence.plugins import PluginMetadata, PluginRegistry, registry

__all__ = [
    "AdapterAmbiguousError",
    "AdapterError",
    "AdapterEvaluationResult",
    "AdapterMetadata",
    "AdapterNotFoundError",
    "AdapterRegistry",
    "AdapterValidationError",
    "CountryAdapter",
    "Finding",
    "FindingCode",
    "PluginMetadata",
    "PluginRegistry",
    "default_registry",
    "registry",
]


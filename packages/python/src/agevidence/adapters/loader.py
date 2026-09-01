"""Adapter plugin loading."""

from __future__ import annotations

from importlib import import_module, metadata
from typing import Callable

from agevidence.adapters.base import CountryAdapter
from agevidence.adapters.errors import AdapterValidationError


AdapterFactory = Callable[[], CountryAdapter] | type[CountryAdapter]


def instantiate(factory: AdapterFactory) -> CountryAdapter:
    """Instantiate an adapter factory or class."""

    adapter = factory()
    if not isinstance(adapter, CountryAdapter):
        raise AdapterValidationError("Adapter factory did not return a CountryAdapter.", code="ADAPTER_INVALID")
    return adapter


def load_entry_point_adapters(group: str = "agevidence.country_adapters") -> list[CountryAdapter]:
    """Load installed Python entry-point adapters."""

    adapters: list[CountryAdapter] = []
    for entry_point in metadata.entry_points().select(group=group):
        adapters.append(instantiate(entry_point.load()))
    return adapters


def load_local_adapter(spec: str) -> CountryAdapter:
    """Load a local development adapter from `module:object`."""

    if ":" not in spec:
        raise AdapterValidationError("Local adapter specs must use module:object.", code="ADAPTER_LOCAL_SPEC_INVALID")
    module_name, object_name = spec.split(":", 1)
    module = import_module(module_name)
    factory = getattr(module, object_name)
    return instantiate(factory)


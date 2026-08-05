"""Executable country adapter registry."""

from __future__ import annotations

from agevidence.adapters.base import CountryAdapter
from agevidence.adapters.errors import AdapterAmbiguousError, AdapterNotFoundError
from agevidence.adapters.loader import load_entry_point_adapters, load_local_adapter


class AdapterRegistry:
    """Registry for built-in, entry-point, and local adapters."""

    def __init__(self) -> None:
        self._adapters: dict[str, CountryAdapter] = {}

    def register(self, adapter: CountryAdapter) -> None:
        self._adapters[adapter.metadata.id] = adapter

    def register_local(self, spec: str) -> CountryAdapter:
        adapter = load_local_adapter(spec)
        self.register(adapter)
        return adapter

    def load_entry_points(self) -> list[CountryAdapter]:
        adapters = load_entry_point_adapters()
        for adapter in adapters:
            self.register(adapter)
        return adapters

    def get(self, adapter_id: str) -> CountryAdapter:
        try:
            return self._adapters[adapter_id]
        except KeyError as exc:
            raise AdapterNotFoundError(f"Unknown country adapter: {adapter_id}", code="ADAPTER_NOT_FOUND") from exc

    def all(self) -> list[CountryAdapter]:
        return sorted(self._adapters.values(), key=lambda adapter: (adapter.metadata.country_code, adapter.metadata.id))

    def resolve(self, value: str) -> CountryAdapter:
        if value in self._adapters:
            return self._adapters[value]
        code = value.upper().replace("-", "_")
        matches = [adapter for adapter in self._adapters.values() if adapter.metadata.country_code.upper().replace("-", "_") == code]
        active = [adapter for adapter in matches if adapter.metadata.status == "active"]
        selected = active or matches
        if len(selected) == 1:
            return selected[0]
        if selected:
            ids = ", ".join(adapter.metadata.id for adapter in selected)
            raise AdapterAmbiguousError(f"Country code {value} maps to multiple adapters: {ids}", code="ADAPTER_AMBIGUOUS")
        raise AdapterNotFoundError(f"Unknown country adapter or country code: {value}", code="ADAPTER_NOT_FOUND")


def default_registry(*, load_entry_points: bool = True) -> AdapterRegistry:
    """Build the default registry with built-in adapters."""

    from agevidence.countries.australia import AustraliaAdapter
    from agevidence.countries.canada import CanadaAdapter
    from agevidence.countries.eu import EuropeanUnionAdapter
    from agevidence.countries.new_zealand import NewZealandAdapter
    from agevidence.countries.uk import UnitedKingdomAdapter

    registry = AdapterRegistry()
    for adapter in [
        AustraliaAdapter(),
        CanadaAdapter(),
        NewZealandAdapter(),
        UnitedKingdomAdapter(),
        EuropeanUnionAdapter(),
    ]:
        registry.register(adapter)
    if load_entry_points:
        registry.load_entry_points()
    return registry


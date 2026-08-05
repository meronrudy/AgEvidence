"""Capability plugin registry.

Plugins declare adapter metadata only. They do not confer certification,
government approval, institutional reliance, or receipt authority.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class PluginMetadata:
    id: str
    country_code: str | None
    domain: str
    status: str
    description: str


class PluginRegistry:
    def __init__(self) -> None:
        self._plugins: dict[str, PluginMetadata] = {}

    def register(self, plugin: PluginMetadata) -> None:
        self._plugins[plugin.id] = plugin

    def get(self, plugin_id: str) -> PluginMetadata:
        return self._plugins[plugin_id]

    def all(self) -> list[PluginMetadata]:
        return list(self._plugins.values())


registry = PluginRegistry()

for plugin in [
    PluginMetadata("au_nlis", "AU", "livestock", "placeholder", "National Livestock Identification System adapter placeholder."),
    PluginMetadata("au_lpa", "AU", "livestock", "placeholder", "Livestock Production Assurance adapter placeholder."),
    PluginMetadata("au_nfas", "AU", "livestock", "placeholder", "National Feedlot Accreditation Scheme adapter placeholder."),
    PluginMetadata("au_envd", "AU", "livestock", "placeholder", "Electronic National Vendor Declaration adapter placeholder."),
    PluginMetadata("au_pic", "AU", "livestock", "placeholder", "Property Identification Code adapter placeholder."),
    PluginMetadata("au_mla", "AU", "livestock", "placeholder", "Meat & Livestock Australia adapter placeholder."),
    PluginMetadata("farm_management", None, "farm_management", "placeholder", "Farm management system adapter family placeholder."),
    PluginMetadata("soil_carbon", None, "soil", "placeholder", "Soil carbon adapter family placeholder."),
    PluginMetadata("satellite", None, "satellite", "placeholder", "Remote sensing adapter family placeholder."),
    PluginMetadata("registry", None, "registry", "placeholder", "Carbon registry adapter family placeholder."),
    PluginMetadata("trials", None, "trials", "placeholder", "Scientific trial adapter family placeholder."),
    PluginMetadata("laboratory", None, "laboratory", "placeholder", "Laboratory adapter family placeholder."),
    PluginMetadata("supply_chain", None, "supply_chain", "placeholder", "Supply-chain adapter family placeholder."),
    PluginMetadata("manufacturing", None, "manufacturing", "placeholder", "Food manufacturing adapter family placeholder."),
    PluginMetadata("biodiversity", None, "biodiversity", "placeholder", "Biodiversity adapter family placeholder."),
    PluginMetadata("water", None, "water", "placeholder", "Water adapter family placeholder."),
    PluginMetadata("forestry", None, "forestry", "placeholder", "Forestry adapter family placeholder."),
    PluginMetadata("renewable_energy", None, "renewable_energy", "placeholder", "Renewable energy adapter family placeholder."),
    PluginMetadata("esg", None, "esg", "placeholder", "ESG adapter family placeholder."),
    PluginMetadata("assurance", None, "assurance", "placeholder", "Assurance adapter family placeholder."),
    PluginMetadata("finance", None, "finance", "placeholder", "Financial institution adapter family placeholder."),
]:
    registry.register(plugin)

from __future__ import annotations

import importlib.util
from pathlib import Path


def load_script_module(name: str, relative_path: str):
    repo_root = Path(__file__).resolve().parents[3]
    spec = importlib.util.spec_from_file_location(name, repo_root / relative_path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def test_country_loc_accounting_excludes_campaign_by_default():
    loc = load_script_module("agevidence_loc", "scripts/agevidence_loc.py")

    assert loc.include_path("sdks/python/src/agevidence/country_cli.py")
    assert loc.include_path("specs/agevidence/country_adapters/australia/adapter.yml")
    assert not loc.include_path("sdks/python/src/agevidence/campaign/client.py")
    assert not loc.include_path("specs/campaign/events.yml")
    assert loc.include_path("specs/campaign/events.yml", include_all=True)


from __future__ import annotations

import importlib.util
import sys
from pathlib import Path
from types import ModuleType

REPO_ROOT = Path(__file__).resolve().parents[2]
SDK_SRC = REPO_ROOT / "sdks" / "python" / "src"
SHARED = REPO_ROOT / "examples" / "researchers" / "_shared"
for path in (SDK_SRC, SHARED, REPO_ROOT):
    if str(path) not in sys.path:
        sys.path.insert(0, str(path))


def load_example(relative: str) -> ModuleType:
    path = REPO_ROOT / relative
    spec = importlib.util.spec_from_file_location(path.stem, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load example: {relative}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def bundle_ids(bundle: dict) -> set[str]:
    ids = set()
    for key in (
        "sources",
        "observations",
        "intervention_events",
        "operational_events",
        "calibration_records",
        "transformations",
        "derived_observations",
        "exclusion_decisions",
        "model_runs",
        "statements",
    ):
        ids.update(item["id"] for item in bundle.get(key, []) if "id" in item)
    return ids


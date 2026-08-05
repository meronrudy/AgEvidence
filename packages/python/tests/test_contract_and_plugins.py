from __future__ import annotations

import inspect
from pathlib import Path

from agevidence import Client
from agevidence.livestock import FeedAdditive, Herd, NLISIdentifier
from agevidence.plugins import registry


def test_client_method_inventory_matches_openapi_paths():
    repo_root = Path(__file__).resolve().parents[3]
    openapi = (repo_root / "docs/openapi/agevidence.v1.yaml").read_text(encoding="utf-8")
    required_paths = [
        "/v1/developer/projects",
        "/v1/developer/projects/{project_id}/source_records",
        "/v1/developer/projects/{project_id}/model_runs",
        "/v1/developer/candidates/{id}",
        "/v1/pricing/products",
        "/v1/pricing/quotes",
        "/v1/artifact-orders",
        "/v1/integrations/events",
    ]
    for path in required_paths:
        assert path in openapi

    methods = set(name for name, _ in inspect.getmembers(Client, predicate=inspect.isfunction))
    for method in [
        "create_project",
        "submit_source_record",
        "run_model",
        "review_candidate",
        "create_quote",
        "create_order",
        "checkout_order",
        "build_artifact",
        "get_artifact",
        "download_artifact_metadata",
        "get_operation",
        "wait_for_operation",
        "submit_event",
        "get_event",
        "replay_event",
        "list_products",
        "register_webhook_endpoint",
    ]:
        assert method in methods


def test_livestock_value_objects_are_lightweight_and_typed():
    herd = Herd(herd_id="herd-1", species="species.beef_cattle")
    additive = FeedAdditive(intervention_id="int-1", intervention_type="intervention.feed_additive", product_id="prod-1")
    nlis = NLISIdentifier(value="982000000000001")

    assert herd.species == "species.beef_cattle"
    assert additive.product_id == "prod-1"
    assert nlis.status == "unverified"


def test_australian_plugins_are_placeholders_not_certifications():
    plugins = {plugin.id: plugin for plugin in registry.all()}

    assert plugins["au_nlis"].status == "placeholder"
    assert plugins["au_lpa"].country_code == "AU"
    assert "placeholder" in plugins["au_mla"].description.lower()

"""Campaign Control Plane CLI commands."""

from __future__ import annotations

import json
from typing import Any

import typer

from .cli_support import client_factory
from .cli_support import emit as _emit
from .cli_support import handle_error as _handle_error
from .cli_support import payload as _payload


campaign_app = typer.Typer(help="Campaign Control Plane commands")
campaign_account_app = typer.Typer(help="Campaign account commands")
campaign_activation_app = typer.Typer(help="Campaign activation commands")
campaign_handoff_app = typer.Typer(help="Campaign handoff commands")


def _client(**kwargs: Any):
    try:
        from . import cli as root_cli

        factory = getattr(root_cli, "_client", client_factory)
    except Exception:  # noqa: BLE001 - fallback for direct module execution.
        factory = client_factory
    return factory(**kwargs)


def register_campaign_cli(app: typer.Typer) -> None:
    app.add_typer(campaign_app, name="campaign")
    campaign_app.add_typer(campaign_account_app, name="account")
    campaign_app.add_typer(campaign_activation_app, name="activation")
    campaign_app.add_typer(campaign_handoff_app, name="handoff")


@campaign_app.command("dashboard")
def campaign_dashboard(output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit(_client().campaign.get_dashboard(), output)
    except Exception as exc:
        _handle_error(exc)


@campaign_app.command("status")
def campaign_status(output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit(_client().campaign.get_dashboard(), output)
    except Exception as exc:
        _handle_error(exc)


@campaign_app.command("identify")
def campaign_identify(account_id: str = typer.Option(...), output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit(_client().campaign.get_account(account_id), output)
    except Exception as exc:
        _handle_error(exc)


@campaign_account_app.command("create")
def campaign_account_create(
    name: str = typer.Option(...),
    country_code: str = typer.Option("AU"),
    account_id: str | None = typer.Option(None, "--account-id"),
    domain: str | None = typer.Option(None),
    subsector: str | None = typer.Option(None),
    funding_stage: str | None = typer.Option(None),
    priority_score: int = typer.Option(0),
    evidence_obligation_code: str | None = typer.Option(None),
    evidence_obligation_summary: str | None = typer.Option(None),
    output: str = typer.Option("json", "--format"),
) -> None:
    try:
        payload = {
            "name": name,
            "country_code": country_code,
            "priority_score": priority_score,
        }
        for key, value in {
            "external_id": account_id,
            "domain": domain,
            "subsector": subsector,
            "funding_stage": funding_stage,
            "evidence_obligation_code": evidence_obligation_code,
            "evidence_obligation_summary": evidence_obligation_summary,
        }.items():
            if value is not None:
                payload[key] = value
        _emit(_client().campaign.create_account(**payload), output)
    except Exception as exc:
        _handle_error(exc)


@campaign_account_app.command("list")
def campaign_account_list(output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit({"accounts": [_payload(account) for account in _client().campaign.list_accounts()]}, output)
    except Exception as exc:
        _handle_error(exc)


@campaign_account_app.command("show")
def campaign_account_show(account_id: str = typer.Option(...), output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit(_client().campaign.get_account(account_id), output)
    except Exception as exc:
        _handle_error(exc)


@campaign_activation_app.command("start")
def campaign_activation_start(
    account_id: str = typer.Option(...),
    path_type: str = typer.Option(...),
    activation_id: str | None = typer.Option(None),
    repository_sha: str | None = typer.Option(None),
    guide_path: str | None = typer.Option(None),
    developer_project_external_id: str | None = typer.Option(None),
    output: str = typer.Option("json", "--format"),
) -> None:
    try:
        fields = {"path_type": path_type, "status": "started"}
        for key, value in {
            "external_id": activation_id,
            "repository_sha": repository_sha,
            "guide_path": guide_path,
            "developer_project_external_id": developer_project_external_id,
        }.items():
            if value is not None:
                fields[key] = value
        _emit(_client().campaign.start_activation(account_id, **fields), output)
    except Exception as exc:
        _handle_error(exc)


@campaign_activation_app.command("complete")
def campaign_activation_complete(account_id: str = typer.Option(...), activation_id: str = typer.Option(...), output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit(_client().campaign.complete_activation(account_id, activation_id), output)
    except Exception as exc:
        _handle_error(exc)


@campaign_activation_app.command("fail")
def campaign_activation_fail(
    account_id: str = typer.Option(...),
    activation_id: str = typer.Option(...),
    failure_code: str = typer.Option("activation_failed"),
    output: str = typer.Option("json", "--format"),
) -> None:
    try:
        _emit(_client().campaign.fail_activation(account_id, activation_id, failure_code=failure_code), output)
    except Exception as exc:
        _handle_error(exc)


@campaign_app.command("qualify")
def campaign_qualify(
    account_id: str = typer.Option(...),
    developer_project_id: str | None = typer.Option(None),
    named_obligation_code: str | None = typer.Option(None),
    named_relying_party_type: str | None = typer.Option(None),
    reusable_mapping_identified: bool = typer.Option(False),
    product_code: str | None = typer.Option(None),
    scope_estimate: str | None = typer.Option(None),
    accountable_buyer_or_sponsor: str | None = typer.Option(None),
    timing_window: str | None = typer.Option(None),
    permitted_commercial_handoff: bool = typer.Option(False),
    output: str = typer.Option("json", "--format"),
) -> None:
    try:
        fields: dict[str, Any] = {
            "permitted_commercial_handoff": permitted_commercial_handoff,
            "reusable_mapping_identified": reusable_mapping_identified,
        }
        for key, value in {
            "developer_project_id": developer_project_id,
            "named_obligation_code": named_obligation_code,
            "named_relying_party_type": named_relying_party_type,
            "product_code": product_code,
            "scope_estimate": scope_estimate,
            "accountable_buyer_or_sponsor": accountable_buyer_or_sponsor,
            "timing_window": timing_window,
        }.items():
            if value is not None:
                fields[key] = value
        _emit(_client().campaign.evaluate_qualification(account_id, **fields), output)
    except Exception as exc:
        _handle_error(exc)


@campaign_handoff_app.command("create")
def campaign_handoff_create(
    account_id: str = typer.Option(...),
    qualification_id: str = typer.Option(...),
    product_code: str = typer.Option("evidence_architecture_sprint"),
    planning_value_cents: int = typer.Option(0),
    currency: str = typer.Option("USD"),
    scope_json: str = typer.Option("{}", help="JSON object of handoff scope."),
    output: str = typer.Option("json", "--format"),
) -> None:
    try:
        _emit(
            _client().campaign.create_handoff(
                account_id,
                qualification_id=qualification_id,
                product_code=product_code,
                planning_value_cents=planning_value_cents,
                currency=currency,
                scope=json.loads(scope_json),
            ),
            output,
        )
    except Exception as exc:
        _handle_error(exc)


@campaign_handoff_app.command("list")
def campaign_handoff_list(account_id: str = typer.Option(...), output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit({"handoffs": [_payload(handoff) for handoff in _client().campaign.handoffs.list(account_id)]}, output)
    except Exception as exc:
        _handle_error(exc)

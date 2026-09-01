"""Shared CLI helpers."""

from __future__ import annotations

import json
from typing import Any

import typer
from rich.console import Console
from rich.table import Table

from .client import Client
from .errors import AgEvidenceError


console = Console()
error_console = Console(stderr=True)


def client_factory(
    base_url: str | None = None,
    *,
    campaign_account_id: str | None = None,
    activation_id: str | None = None,
    repository_sha: str | None = None,
) -> Client:
    return Client(
        base_url=base_url,
        campaign_account_id=campaign_account_id,
        activation_id=activation_id,
        repository_sha=repository_sha,
    )


def payload(value: Any) -> Any:
    if hasattr(value, "model_dump"):
        return value.model_dump(mode="json", exclude_none=True)
    return value


def emit(value: Any, output: str = "json") -> None:
    item = payload(value)
    if output == "json":
        console.print_json(data=item)
        return
    if output == "yaml":
        console.print(to_yaml(item))
        return

    if isinstance(item, dict):
        table = Table(show_header=True, header_style="bold")
        table.add_column("Field")
        table.add_column("Value")
        for key, value in item.items():
            table.add_row(str(key), json.dumps(value) if isinstance(value, (dict, list)) else str(value))
        console.print(table)
        return

    console.print(item)


def to_yaml(value: Any, indent: int = 0) -> str:
    spaces = " " * indent
    if isinstance(value, dict):
        lines: list[str] = []
        for key, item in value.items():
            if isinstance(item, (dict, list)):
                lines.append(f"{spaces}{key}:")
                lines.append(to_yaml(item, indent + 2))
            else:
                lines.append(f"{spaces}{key}: {yaml_scalar(item)}")
        return "\n".join(lines)
    if isinstance(value, list):
        lines = []
        for item in value:
            if isinstance(item, (dict, list)):
                lines.append(f"{spaces}-")
                lines.append(to_yaml(item, indent + 2))
            else:
                lines.append(f"{spaces}- {yaml_scalar(item)}")
        return "\n".join(lines)
    return f"{spaces}{yaml_scalar(value)}"


def yaml_scalar(value: Any) -> str:
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    text = str(value)
    if not text or any(char in text for char in [":", "#", "\n", "{", "}", "[", "]"]):
        return json.dumps(text)
    return text


def handle_error(exc: Exception) -> None:
    if isinstance(exc, AgEvidenceError):
        error_console.print(f"[red]{exc}[/red]")
        raise typer.Exit(code=1)
    raise exc

"""Identifier binding helpers."""

from __future__ import annotations

from agevidence.identifiers.models import IdentifierBinding


def build_binding(
    *,
    identifier_system: str,
    issuing_authority: str,
    local_value: str,
    global_subject: str,
    jurisdiction: str,
    source_commitment: str | None = None,
    limitations: list[str] | None = None,
) -> IdentifierBinding:
    """Create a complete identifier binding record."""

    return IdentifierBinding(
        identifier_system=identifier_system,
        issuing_authority=issuing_authority,
        local_value=local_value,
        global_subject=global_subject,
        source_commitment=source_commitment,
        jurisdiction=jurisdiction,
        limitations=limitations or [],
    )


"""Campaign commercial handoff SDK methods."""

from __future__ import annotations

from typing import Any, Callable

from agevidence.request_models import CampaignHandoffCreateRequest

from .models import CommercialHandoff


class HandoffsResource:
    def __init__(self, request: Callable[..., Any]) -> None:
        self._request = request

    def create(self, account_id: str, **fields: Any) -> CommercialHandoff:
        body = CampaignHandoffCreateRequest(**fields)
        return CommercialHandoff.model_validate(
            self._request(
                "POST",
                f"/v1/campaign/accounts/{account_id}/handoffs",
                json={"handoff": body.model_dump(mode="json", exclude_none=True)},
            )
        )

    def list(self, account_id: str) -> list[CommercialHandoff]:
        payload = self._request("GET", f"/v1/campaign/accounts/{account_id}/handoffs")
        return [CommercialHandoff.model_validate(item) for item in payload.get("handoffs", [])]

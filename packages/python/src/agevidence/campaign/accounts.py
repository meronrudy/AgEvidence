"""Campaign account SDK methods."""

from __future__ import annotations

from typing import Any, Callable

from agevidence.request_models import CampaignAccountCreateRequest, CampaignAccountUpdateRequest

from .models import CampaignAccount


class AccountsResource:
    def __init__(self, request: Callable[..., Any]) -> None:
        self._request = request

    def create(self, **fields: Any) -> CampaignAccount:
        body = CampaignAccountCreateRequest(**fields)
        return CampaignAccount.model_validate(
            self._request("POST", "/v1/campaign/accounts", json={"campaign_account": body.model_dump(mode="json", exclude_none=True)})
        )

    def get(self, account_id: str) -> CampaignAccount:
        return CampaignAccount.model_validate(self._request("GET", f"/v1/campaign/accounts/{account_id}"))

    def list(self) -> list[CampaignAccount]:
        payload = self._request("GET", "/v1/campaign/accounts")
        return [CampaignAccount.model_validate(item) for item in payload.get("accounts", [])]

    def update(self, account_id: str, **fields: Any) -> CampaignAccount:
        body = CampaignAccountUpdateRequest(**fields)
        return CampaignAccount.model_validate(
            self._request(
                "PATCH",
                f"/v1/campaign/accounts/{account_id}",
                json={"campaign_account": body.model_dump(mode="json", exclude_none=True)},
            )
        )

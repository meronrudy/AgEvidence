"""Campaign activation SDK methods."""

from __future__ import annotations

from typing import Any, Callable

from agevidence.request_models import CampaignActivationFailRequest, CampaignActivationStartRequest

from .models import ActivationPath


class ActivationsResource:
    def __init__(self, request: Callable[..., Any]) -> None:
        self._request = request

    def start(self, account_id: str, **fields: Any) -> ActivationPath:
        body = CampaignActivationStartRequest(**fields)
        return ActivationPath.model_validate(
            self._request(
                "POST",
                f"/v1/campaign/accounts/{account_id}/activations",
                json={"activation": body.model_dump(mode="json", exclude_none=True)},
            )
        )

    def list(self, account_id: str) -> list[ActivationPath]:
        payload = self._request("GET", f"/v1/campaign/accounts/{account_id}/activations")
        return [ActivationPath.model_validate(item) for item in payload.get("activations", [])]

    def complete(self, account_id: str, activation_id: str) -> ActivationPath:
        return ActivationPath.model_validate(
            self._request("POST", f"/v1/campaign/accounts/{account_id}/activations/{activation_id}/complete", json={})
        )

    def fail(self, account_id: str, activation_id: str, *, failure_code: str = "activation_failed") -> ActivationPath:
        body = CampaignActivationFailRequest(failure_code=failure_code)
        return ActivationPath.model_validate(
            self._request(
                "POST",
                f"/v1/campaign/accounts/{account_id}/activations/{activation_id}/fail",
                json=body.model_dump(mode="json"),
            )
        )

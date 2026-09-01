"""Campaign qualification SDK methods."""

from __future__ import annotations

from typing import Any, Callable

from agevidence.request_models import CampaignQualificationRequest

from .models import TechnicalQualification


class QualificationsResource:
    def __init__(self, request: Callable[..., Any]) -> None:
        self._request = request

    def evaluate(self, account_id: str, **fields: Any) -> TechnicalQualification:
        body = CampaignQualificationRequest(**fields)
        return TechnicalQualification.model_validate(
            self._request(
                "POST",
                f"/v1/campaign/accounts/{account_id}/qualifications",
                json={"qualification": body.model_dump(mode="json", exclude_none=True)},
            )
        )

    def list(self, account_id: str) -> list[TechnicalQualification]:
        payload = self._request("GET", f"/v1/campaign/accounts/{account_id}/qualifications")
        return [TechnicalQualification.model_validate(item) for item in payload.get("qualifications", [])]

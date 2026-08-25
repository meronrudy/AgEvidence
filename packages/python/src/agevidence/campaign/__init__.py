"""Campaign Control Plane client namespace."""

from __future__ import annotations

from typing import Any, Callable

from .accounts import AccountsResource
from .activations import ActivationsResource
from .handoffs import HandoffsResource
from .models import (
    ActivationPath,
    CampaignAccount,
    CampaignContactRef,
    CampaignDashboard,
    CommercialHandoff,
    TechnicalQualification,
)
from .qualifications import QualificationsResource


class CampaignClient:
    def __init__(self, request: Callable[..., Any]) -> None:
        self.accounts = AccountsResource(request)
        self.activations = ActivationsResource(request)
        self.qualifications = QualificationsResource(request)
        self.handoffs = HandoffsResource(request)
        self._request = request

    def create_account(self, **fields: Any) -> CampaignAccount:
        return self.accounts.create(**fields)

    def get_account(self, account_id: str) -> CampaignAccount:
        return self.accounts.get(account_id)

    def list_accounts(self) -> list[CampaignAccount]:
        return self.accounts.list()

    def update_account(self, account_id: str, **fields: Any) -> CampaignAccount:
        return self.accounts.update(account_id, **fields)

    def start_activation(self, account_id: str, **fields: Any) -> ActivationPath:
        return self.activations.start(account_id, **fields)

    def complete_activation(self, account_id: str, activation_id: str) -> ActivationPath:
        return self.activations.complete(account_id, activation_id)

    def fail_activation(self, account_id: str, activation_id: str, *, failure_code: str = "activation_failed") -> ActivationPath:
        return self.activations.fail(account_id, activation_id, failure_code=failure_code)

    def evaluate_qualification(self, account_id: str, **fields: Any) -> TechnicalQualification:
        return self.qualifications.evaluate(account_id, **fields)

    def create_handoff(self, account_id: str, **fields: Any) -> CommercialHandoff:
        return self.handoffs.create(account_id, **fields)

    def get_dashboard(self) -> CampaignDashboard:
        return CampaignDashboard.model_validate(self._request("GET", "/v1/campaign/dashboard"))


__all__ = [
    "ActivationPath",
    "CampaignAccount",
    "CampaignClient",
    "CampaignContactRef",
    "CampaignDashboard",
    "CommercialHandoff",
    "TechnicalQualification",
]

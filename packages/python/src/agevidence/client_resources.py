"""Synchronous resource namespaces for the AgEvidence client."""

from __future__ import annotations

import time
from typing import Any, Callable

from .errors import AgEvidenceError
from .models import (
    ArtifactDownloadMetadata,
    ArtifactOrder,
    CountryAdapterInfo,
    CountryAdapterValidation,
    CountryDetermination,
    DeveloperProject,
    EventSubmission,
    EvidenceCandidate,
    IntegrationEventStatus,
    ModelRun,
    Operation,
    PricingQuote,
    ProductCatalog,
    SourceRecord,
    WebhookEndpoint,
)
from .request_models import (
    ArtifactBuildRequest,
    CountryDeterminationCreateRequest,
    EventReplayRequest,
    ModelRunCreateRequest,
    OrderCreateRequest,
    ProjectCreateRequest,
    QuoteCreateRequest,
    ReviewCandidateRequest,
    SourceRecordCreateRequest,
    WebhookEndpointCreateRequest,
)
from .transport import list_payload_items


RequestFn = Callable[..., Any]


class ProjectsResource:
    def __init__(self, request: RequestFn) -> None:
        self._request = request

    def create(
        self,
        *,
        account_name: str,
        project_name: str,
        target_claim: str,
        funding_stage: str = "sandbox",
        project_type: str = "intervention",
        external_project_id: str | None = None,
        country_context: dict[str, Any] | None = None,
        idempotency_key: str | None = None,
    ) -> DeveloperProject:
        body = ProjectCreateRequest(
            account_name=account_name,
            project_name=project_name,
            target_claim=target_claim,
            funding_stage=funding_stage,
            project_type=project_type,
            external_project_id=external_project_id,
            country_context=country_context,
        )
        return DeveloperProject.model_validate(
            self._request("POST", "/v1/developer/projects", json=body.api_payload(), idempotency_key=idempotency_key)
        )

    def get(self, project_id: str | int) -> DeveloperProject:
        return DeveloperProject.model_validate(self._request("GET", f"/v1/developer/projects/{project_id}"))


class SourceRecordsResource:
    def __init__(self, request: RequestFn) -> None:
        self._request = request

    def submit(
        self,
        *,
        project_id: str | int,
        document_id: str,
        evidence_type: str,
        controlled_uri: str,
        commitment: str,
        source_system: str = "python_sdk",
        evidence_class: str | None = None,
        metadata: dict[str, Any] | None = None,
        idempotency_key: str | None = None,
    ) -> SourceRecord:
        body = SourceRecordCreateRequest(
            document_id=document_id,
            evidence_type=evidence_type,
            controlled_uri=controlled_uri,
            commitment=commitment,
            source_system=source_system,
            evidence_class=evidence_class,
            metadata=metadata,
        )
        return SourceRecord.model_validate(
            self._request(
                "POST",
                f"/v1/developer/projects/{project_id}/source_records",
                json=body.api_payload(),
                idempotency_key=idempotency_key,
            )
        )


class ModelRunsResource:
    def __init__(self, request: RequestFn) -> None:
        self._request = request

    def run(self, *, project_id: str | int, adapter_id: str = "qwen3.5-4b-reference", idempotency_key: str | None = None) -> ModelRun:
        body = ModelRunCreateRequest(adapter_id=adapter_id)
        return ModelRun.model_validate(
            self._request(
                "POST",
                f"/v1/developer/projects/{project_id}/model_runs",
                json=body.model_dump(mode="json"),
                idempotency_key=idempotency_key,
            )
        )


class ReviewsResource:
    def __init__(self, request: RequestFn) -> None:
        self._request = request

    def review_candidate(
        self,
        *,
        candidate_id: str | int,
        decision: str,
        reason: str,
        reviewer_role: str = "scientific_reviewer_sandbox",
        policy_version: str | None = None,
        idempotency_key: str | None = None,
    ) -> EvidenceCandidate:
        body = ReviewCandidateRequest(decision=decision, reason=reason, reviewer_role=reviewer_role, policy_version=policy_version)
        return EvidenceCandidate.model_validate(
            self._request(
                "PATCH",
                f"/v1/developer/candidates/{candidate_id}",
                json=body.api_payload(),
                idempotency_key=idempotency_key,
            )
        )


class PricingResource:
    def __init__(self, request: RequestFn) -> None:
        self._request = request

    def products(self) -> ProductCatalog:
        return ProductCatalog.model_validate(self._request("GET", "/v1/pricing/products"))

    def create_quote(
        self,
        *,
        project_id: str | int,
        product_code: str,
        scope: dict[str, Any] | None = None,
        idempotency_key: str | None = None,
    ) -> PricingQuote:
        body = QuoteCreateRequest(project_id=str(project_id), product_code=product_code, scope=scope or {})
        return PricingQuote.model_validate(
            self._request("POST", "/v1/pricing/quotes", json=body.api_payload(), idempotency_key=idempotency_key)
        )

    def get_quote(self, quote_id: str) -> PricingQuote:
        return PricingQuote.model_validate(self._request("GET", f"/v1/pricing/quotes/{quote_id}"))


class OrdersResource:
    def __init__(self, request: RequestFn) -> None:
        self._request = request

    def create(self, *, quote_id: str, artifact_scope: dict[str, Any] | None = None, idempotency_key: str | None = None) -> ArtifactOrder:
        body = OrderCreateRequest(quote_id=quote_id, artifact_scope=artifact_scope or {})
        return ArtifactOrder.model_validate(
            self._request("POST", "/v1/artifact-orders", json=body.api_payload(), idempotency_key=idempotency_key)
        )

    def checkout(self, *, order_id: str, idempotency_key: str | None = None) -> ArtifactOrder:
        return ArtifactOrder.model_validate(
            self._request("POST", f"/v1/artifact-orders/{order_id}/checkout", json={}, idempotency_key=idempotency_key)
        )

    def get(self, order_id: str) -> ArtifactOrder:
        return ArtifactOrder.model_validate(self._request("GET", f"/v1/artifact-orders/{order_id}"))


class ArtifactsResource:
    def __init__(self, request: RequestFn) -> None:
        self._request = request

    def build(
        self,
        *,
        project_id: str | int,
        order_id: str | None = None,
        quote_id: str | None = None,
        product_code: str | None = None,
        sandbox_checkout: bool = False,
        scope: dict[str, Any] | None = None,
        idempotency_key: str | None = None,
    ) -> ArtifactOrder:
        body = ArtifactBuildRequest(
            order_id=order_id,
            quote_id=quote_id,
            product_code=product_code,
            sandbox_checkout=sandbox_checkout,
            scope=scope,
        )
        return ArtifactOrder.model_validate(
            self._request(
                "POST",
                f"/v1/developer/projects/{project_id}/artifacts",
                json=body.model_dump(mode="json", exclude_none=True),
                idempotency_key=idempotency_key,
            )
        )

    def get(self, *, project_id: str | int, artifact_id: str) -> ArtifactOrder:
        return ArtifactOrder.model_validate(self._request("GET", f"/v1/developer/projects/{project_id}/artifacts/{artifact_id}"))

    def download_metadata(self, *, project_id: str | int, artifact_id: str) -> ArtifactDownloadMetadata:
        return ArtifactDownloadMetadata.model_validate(
            self._request("GET", f"/v1/developer/projects/{project_id}/artifacts/{artifact_id}/download")
        )


class OperationsResource:
    def __init__(self, request: RequestFn) -> None:
        self._request = request

    def get(self, operation_id: str) -> Operation:
        return Operation.model_validate(self._request("GET", f"/v1/developer/operations/{operation_id}"))

    def get_integration(self, operation_id: str) -> Operation:
        return Operation.model_validate(self._request("GET", f"/v1/integrations/operations/{operation_id}"))

    def wait(self, operation_id: str, *, timeout: float = 60.0, interval: float = 2.0) -> Operation:
        deadline = time.monotonic() + timeout
        while True:
            operation = self.get(operation_id)
            if operation.terminal:
                return operation
            if time.monotonic() >= deadline:
                raise AgEvidenceError(f"Operation did not complete within {timeout} seconds.", code="OPERATION_TIMEOUT")
            time.sleep(interval)


class EventsResource:
    def __init__(self, request: RequestFn) -> None:
        self._request = request

    def submit(
        self,
        event: dict[str, Any],
        *,
        source: str,
        timestamp: str,
        signature: str,
        idempotency_key: str | None = None,
    ) -> EventSubmission:
        return EventSubmission.model_validate(
            self._request(
                "POST",
                "/v1/integrations/events",
                json=event,
                headers={
                    "X-Athian-Integration-Source": source,
                    "X-Athian-Timestamp": timestamp,
                    "X-Athian-Signature": signature,
                },
                idempotency_key=idempotency_key,
            )
        )

    def get(self, event_id: str, *, source: str | None = None) -> IntegrationEventStatus:
        headers = {"X-Athian-Integration-Source": source} if source else None
        return IntegrationEventStatus.model_validate(self._request("GET", f"/v1/integrations/events/{event_id}", headers=headers))

    def replay(self, event_id: str, *, source: str | None = None, reason: str = "python_sdk_replay", idempotency_key: str | None = None) -> EventSubmission:
        headers = {"X-Athian-Integration-Source": source} if source else None
        body = EventReplayRequest(reason=reason)
        return EventSubmission.model_validate(
            self._request(
                "POST",
                f"/v1/integrations/events/{event_id}/replay",
                json=body.model_dump(mode="json"),
                headers=headers,
                idempotency_key=idempotency_key,
            )
        )

    def register_webhook_endpoint(
        self,
        *,
        source: str,
        url: str,
        signing_secret: str,
        subscribed_event_types: list[str] | None = None,
        idempotency_key: str | None = None,
    ) -> WebhookEndpoint:
        body = WebhookEndpointCreateRequest(
            url=url,
            signing_secret=signing_secret,
            subscribed_event_types=subscribed_event_types,
        )
        return WebhookEndpoint.model_validate(
            self._request(
                "POST",
                "/v1/integrations/webhook_endpoints",
                json=body.model_dump(mode="json", exclude_none=True),
                headers={"X-Athian-Integration-Source": source},
                idempotency_key=idempotency_key,
            )
        )


class CountryResource:
    def __init__(self, request: RequestFn) -> None:
        self._request = request

    def list_adapters(self) -> list[CountryAdapterInfo]:
        payload = self._request("GET", "/v1/country_adapters")
        return [CountryAdapterInfo.model_validate(item) for item in list_payload_items(payload, "country_adapters", "adapters")]

    def get_adapter(self, adapter_id: str) -> CountryAdapterInfo:
        return CountryAdapterInfo.model_validate(self._request("GET", f"/v1/country_adapters/{adapter_id}"))

    def validate_adapter(self, adapter_id: str, *, idempotency_key: str | None = None) -> CountryAdapterValidation:
        return CountryAdapterValidation.model_validate(
            self._request("POST", f"/v1/country_adapters/{adapter_id}/validate", json={}, idempotency_key=idempotency_key)
        )

    def list_determinations(self, project_id: str | int) -> list[CountryDetermination]:
        payload = self._request("GET", f"/v1/developer/projects/{project_id}/country_determinations")
        return [
            CountryDetermination.model_validate(item)
            for item in list_payload_items(payload, "country_determinations", "determinations")
        ]

    def create_determination(
        self,
        *,
        project_id: str | int,
        adapter: str,
        institution_profile: dict[str, Any] | None = None,
        idempotency_key: str | None = None,
    ) -> CountryDetermination:
        body = CountryDeterminationCreateRequest(adapter=adapter, institution_profile=institution_profile)
        return CountryDetermination.model_validate(
            self._request(
                "POST",
                f"/v1/developer/projects/{project_id}/country_determinations",
                json=body.model_dump(mode="json", exclude_none=True),
                idempotency_key=idempotency_key,
            )
        )

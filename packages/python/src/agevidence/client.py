"""Synchronous AgEvidence Developer OS client."""

from __future__ import annotations

import time
from typing import Any

import httpx

from .config import SDKConfig
from .errors import AgEvidenceError
from .models import (
    ArtifactDownloadMetadata,
    ArtifactOrder,
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


class Client:
    """Typed client for the current Rails /v1 Developer OS API."""

    def __init__(
        self,
        base_url: str | None = None,
        *,
        api_token: str | None = None,
        timeout: float = 10.0,
        retries: int = 1,
        transport: httpx.BaseTransport | None = None,
    ) -> None:
        config = SDKConfig.load()
        self.base_url = (base_url or config.base_url).rstrip("/")
        self.api_token = api_token if api_token is not None else config.api_token
        self.timeout = timeout
        self.retries = retries
        self._client = httpx.Client(base_url=self.base_url, timeout=timeout, transport=transport)

    def close(self) -> None:
        self._client.close()

    def __enter__(self) -> "Client":
        return self

    def __exit__(self, *_exc: object) -> None:
        self.close()

    def create_project(
        self,
        *,
        account_name: str,
        project_name: str,
        target_claim: str,
        funding_stage: str = "sandbox",
        project_type: str = "intervention",
        external_project_id: str | None = None,
        country_context: dict[str, Any] | None = None,
    ) -> DeveloperProject:
        payload: dict[str, Any] = {
            "developer_account": {"name": account_name, "funding_stage": funding_stage},
            "project": {
                "name": project_name,
                "project_type": project_type,
                "target_claim": target_claim,
            },
        }
        if external_project_id:
            payload["project"]["external_project_id"] = external_project_id
        if country_context:
            payload["project"]["country_context"] = country_context
        return DeveloperProject.model_validate(self._request("POST", "/v1/developer/projects", json=payload))

    def get_project(self, project_id: str | int) -> DeveloperProject:
        return DeveloperProject.model_validate(self._request("GET", f"/v1/developer/projects/{project_id}"))

    def submit_source_record(
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
    ) -> SourceRecord:
        source_record: dict[str, Any] = {
            "document_id": document_id,
            "evidence_type": evidence_type,
            "controlled_uri": controlled_uri,
            "commitment": commitment,
            "source_system": source_system,
        }
        if evidence_class:
            source_record["evidence_class"] = evidence_class
        if metadata:
            source_record["metadata_json"] = metadata
        return SourceRecord.model_validate(
            self._request("POST", f"/v1/developer/projects/{project_id}/source_records", json={"source_record": source_record})
        )

    def run_model(self, *, project_id: str | int, adapter_id: str = "qwen3.5-4b-reference") -> ModelRun:
        return ModelRun.model_validate(
            self._request("POST", f"/v1/developer/projects/{project_id}/model_runs", json={"adapter_id": adapter_id})
        )

    def review_candidate(
        self,
        *,
        candidate_id: str | int,
        decision: str,
        reason: str,
        reviewer_role: str = "scientific_reviewer_sandbox",
        policy_version: str | None = None,
    ) -> EvidenceCandidate:
        review: dict[str, Any] = {"decision": decision, "reason": reason, "reviewer_role": reviewer_role}
        if policy_version:
            review["policy_version"] = policy_version
        return EvidenceCandidate.model_validate(
            self._request("PATCH", f"/v1/developer/candidates/{candidate_id}", json={"review_decision": review})
        )

    def list_products(self) -> ProductCatalog:
        return ProductCatalog.model_validate(self._request("GET", "/v1/pricing/products"))

    def create_quote(self, *, project_id: str | int, product_code: str, scope: dict[str, Any] | None = None) -> PricingQuote:
        return PricingQuote.model_validate(
            self._request(
                "POST",
                "/v1/pricing/quotes",
                json={"quote": {"project_id": str(project_id), "product_code": product_code, "scope": scope or {}}},
            )
        )

    def get_quote(self, quote_id: str) -> PricingQuote:
        return PricingQuote.model_validate(self._request("GET", f"/v1/pricing/quotes/{quote_id}"))

    def create_order(self, *, quote_id: str, artifact_scope: dict[str, Any] | None = None) -> ArtifactOrder:
        payload = {"artifact_order": {"quote_id": quote_id, "artifact_scope": artifact_scope or {}}}
        return ArtifactOrder.model_validate(self._request("POST", "/v1/artifact-orders", json=payload))

    def checkout_order(self, *, order_id: str) -> ArtifactOrder:
        return ArtifactOrder.model_validate(self._request("POST", f"/v1/artifact-orders/{order_id}/checkout", json={}))

    def get_order(self, order_id: str) -> ArtifactOrder:
        return ArtifactOrder.model_validate(self._request("GET", f"/v1/artifact-orders/{order_id}"))

    def build_artifact(
        self,
        *,
        project_id: str | int,
        order_id: str | None = None,
        quote_id: str | None = None,
        product_code: str | None = None,
        sandbox_checkout: bool = False,
        scope: dict[str, Any] | None = None,
    ) -> ArtifactOrder:
        payload: dict[str, Any] = {"sandbox_checkout": sandbox_checkout}
        if order_id:
            payload["order_id"] = order_id
        if quote_id:
            payload["quote_id"] = quote_id
        if product_code:
            payload["product_code"] = product_code
        if scope:
            payload["scope"] = scope
        return ArtifactOrder.model_validate(self._request("POST", f"/v1/developer/projects/{project_id}/artifacts", json=payload))

    def get_artifact(self, *, project_id: str | int, artifact_id: str) -> ArtifactOrder:
        return ArtifactOrder.model_validate(self._request("GET", f"/v1/developer/projects/{project_id}/artifacts/{artifact_id}"))

    def download_artifact_metadata(self, *, project_id: str | int, artifact_id: str) -> ArtifactDownloadMetadata:
        return ArtifactDownloadMetadata.model_validate(
            self._request("GET", f"/v1/developer/projects/{project_id}/artifacts/{artifact_id}/download")
        )

    def get_operation(self, operation_id: str) -> Operation:
        return Operation.model_validate(self._request("GET", f"/v1/developer/operations/{operation_id}"))

    def wait_for_operation(self, operation_id: str, *, timeout: float = 60.0, interval: float = 2.0) -> Operation:
        deadline = time.monotonic() + timeout
        while True:
            operation = self.get_operation(operation_id)
            if operation.terminal:
                return operation
            if time.monotonic() >= deadline:
                raise AgEvidenceError(f"Operation did not complete within {timeout} seconds.", code="OPERATION_TIMEOUT")
            time.sleep(interval)

    def submit_event(
        self,
        event: dict[str, Any],
        *,
        source: str,
        timestamp: str,
        signature: str,
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
            )
        )

    def get_event(self, event_id: str, *, source: str | None = None) -> IntegrationEventStatus:
        headers = {"X-Athian-Integration-Source": source} if source else None
        return IntegrationEventStatus.model_validate(self._request("GET", f"/v1/integrations/events/{event_id}", headers=headers))

    def replay_event(self, event_id: str, *, source: str | None = None, reason: str = "python_sdk_replay") -> EventSubmission:
        headers = {"X-Athian-Integration-Source": source} if source else None
        return EventSubmission.model_validate(
            self._request("POST", f"/v1/integrations/events/{event_id}/replay", json={"reason": reason}, headers=headers)
        )

    def get_integration_operation(self, operation_id: str) -> Operation:
        return Operation.model_validate(self._request("GET", f"/v1/integrations/operations/{operation_id}"))

    def register_webhook_endpoint(
        self,
        *,
        source: str,
        url: str,
        signing_secret: str,
        subscribed_event_types: list[str] | None = None,
    ) -> WebhookEndpoint:
        payload: dict[str, Any] = {"url": url, "signing_secret": signing_secret}
        if subscribed_event_types:
            payload["subscribed_event_types"] = subscribed_event_types
        return WebhookEndpoint.model_validate(
            self._request("POST", "/v1/integrations/webhook_endpoints", json=payload, headers={"X-Athian-Integration-Source": source})
        )

    def _request(
        self,
        method: str,
        path: str,
        *,
        json: dict[str, Any] | None = None,
        headers: dict[str, str] | None = None,
    ) -> Any:
        merged_headers = {"Accept": "application/json", **(headers or {})}
        if self.api_token:
            merged_headers["Authorization"] = f"Bearer {self.api_token}"

        attempts = self.retries + 1 if method.upper() == "GET" else 1
        last_error: httpx.HTTPError | None = None
        for attempt in range(attempts):
            try:
                response = self._client.request(method, path, json=json, headers=merged_headers)
                return self._decode_response(response)
            except httpx.HTTPError as exc:
                last_error = exc
                if attempt + 1 >= attempts:
                    break
                time.sleep(0.2 * (attempt + 1))
        raise AgEvidenceError("HTTP request failed.", code="HTTP_REQUEST_FAILED", response_body=str(last_error)) from last_error

    def _decode_response(self, response: httpx.Response) -> Any:
        try:
            body = response.json()
        except ValueError:
            body = response.text

        if response.is_error:
            error_body = body.get("error", {}) if isinstance(body, dict) else {}
            raise AgEvidenceError(
                error_body.get("message") or response.reason_phrase,
                status_code=response.status_code,
                code=error_body.get("code"),
                response_body=body,
            )
        return body

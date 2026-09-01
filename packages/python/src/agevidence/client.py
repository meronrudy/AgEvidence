"""Synchronous AgEvidence Developer OS client."""

from __future__ import annotations

from typing import Any

import httpx

from .campaign import CampaignClient
from .config import SDKConfig
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
from .client_resources import (
    ArtifactsResource,
    CountryResource,
    EventsResource,
    ModelRunsResource,
    OperationsResource,
    OrdersResource,
    PricingResource,
    ProjectsResource,
    ReviewsResource,
    SourceRecordsResource,
)
from .transport import (
    RetryPolicy,
    decode_response,
    merged_headers,
    request_can_retry,
    sdk_version,
    should_retry_error,
    should_retry_response,
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
        retry_policy: RetryPolicy | None = None,
        transport: httpx.BaseTransport | None = None,
        campaign_account_id: str | None = None,
        activation_id: str | None = None,
        repository_sha: str | None = None,
    ) -> None:
        config = SDKConfig.load()
        self.base_url = (base_url or config.base_url).rstrip("/")
        self.api_token = api_token if api_token is not None else config.api_token
        self.timeout = timeout
        self.retries = retries
        self.retry_policy = retry_policy or RetryPolicy.from_retries(retries)
        self.campaign_account_id = campaign_account_id
        self.activation_id = activation_id
        self.repository_sha = repository_sha
        self._client = httpx.Client(base_url=self.base_url, timeout=timeout, transport=transport)
        self.projects = ProjectsResource(self._request)
        self.source_records = SourceRecordsResource(self._request)
        self.model_runs = ModelRunsResource(self._request)
        self.reviews = ReviewsResource(self._request)
        self.pricing = PricingResource(self._request)
        self.orders = OrdersResource(self._request)
        self.artifacts = ArtifactsResource(self._request)
        self.operations = OperationsResource(self._request)
        self.events = EventsResource(self._request)
        self.country = CountryResource(self._request)
        self.campaign = CampaignClient(self._request)

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
        return self.projects.create(
            account_name=account_name,
            project_name=project_name,
            target_claim=target_claim,
            funding_stage=funding_stage,
            project_type=project_type,
            external_project_id=external_project_id,
            country_context=country_context,
        )

    def get_project(self, project_id: str | int) -> DeveloperProject:
        return self.projects.get(project_id)

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
        return self.source_records.submit(
            project_id=project_id,
            document_id=document_id,
            evidence_type=evidence_type,
            controlled_uri=controlled_uri,
            commitment=commitment,
            source_system=source_system,
            evidence_class=evidence_class,
            metadata=metadata,
        )

    def run_model(self, *, project_id: str | int, adapter_id: str = "qwen3.5-4b-reference") -> ModelRun:
        return self.model_runs.run(project_id=project_id, adapter_id=adapter_id)

    def review_candidate(
        self,
        *,
        candidate_id: str | int,
        decision: str,
        reason: str,
        reviewer_role: str = "scientific_reviewer_sandbox",
        policy_version: str | None = None,
    ) -> EvidenceCandidate:
        return self.reviews.review_candidate(
            candidate_id=candidate_id,
            decision=decision,
            reason=reason,
            reviewer_role=reviewer_role,
            policy_version=policy_version,
        )

    def list_products(self) -> ProductCatalog:
        return self.pricing.products()

    def list_country_adapters(self) -> list[CountryAdapterInfo]:
        return self.country.list_adapters()

    def get_country_adapter(self, adapter_id: str) -> CountryAdapterInfo:
        return self.country.get_adapter(adapter_id)

    def validate_country_adapter(self, adapter_id: str) -> CountryAdapterValidation:
        return self.country.validate_adapter(adapter_id)

    def list_country_determinations(self, project_id: str | int) -> list[CountryDetermination]:
        return self.country.list_determinations(project_id)

    def create_country_determination(
        self,
        *,
        project_id: str | int,
        adapter: str,
        institution_profile: dict[str, Any] | None = None,
    ) -> CountryDetermination:
        return self.country.create_determination(project_id=project_id, adapter=adapter, institution_profile=institution_profile)

    def create_quote(self, *, project_id: str | int, product_code: str, scope: dict[str, Any] | None = None) -> PricingQuote:
        return self.pricing.create_quote(project_id=project_id, product_code=product_code, scope=scope)

    def get_quote(self, quote_id: str) -> PricingQuote:
        return self.pricing.get_quote(quote_id)

    def create_order(self, *, quote_id: str, artifact_scope: dict[str, Any] | None = None) -> ArtifactOrder:
        return self.orders.create(quote_id=quote_id, artifact_scope=artifact_scope)

    def checkout_order(self, *, order_id: str) -> ArtifactOrder:
        return self.orders.checkout(order_id=order_id)

    def get_order(self, order_id: str) -> ArtifactOrder:
        return self.orders.get(order_id)

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
        return self.artifacts.build(
            project_id=project_id,
            order_id=order_id,
            quote_id=quote_id,
            product_code=product_code,
            sandbox_checkout=sandbox_checkout,
            scope=scope,
        )

    def get_artifact(self, *, project_id: str | int, artifact_id: str) -> ArtifactOrder:
        return self.artifacts.get(project_id=project_id, artifact_id=artifact_id)

    def download_artifact_metadata(self, *, project_id: str | int, artifact_id: str) -> ArtifactDownloadMetadata:
        return self.artifacts.download_metadata(project_id=project_id, artifact_id=artifact_id)

    def get_operation(self, operation_id: str) -> Operation:
        return self.operations.get(operation_id)

    def wait_for_operation(self, operation_id: str, *, timeout: float = 60.0, interval: float = 2.0) -> Operation:
        return self.operations.wait(operation_id, timeout=timeout, interval=interval)

    def submit_event(
        self,
        event: dict[str, Any],
        *,
        source: str,
        timestamp: str,
        signature: str,
    ) -> EventSubmission:
        return self.events.submit(event, source=source, timestamp=timestamp, signature=signature)

    def get_event(self, event_id: str, *, source: str | None = None) -> IntegrationEventStatus:
        return self.events.get(event_id, source=source)

    def replay_event(self, event_id: str, *, source: str | None = None, reason: str = "python_sdk_replay") -> EventSubmission:
        return self.events.replay(event_id, source=source, reason=reason)

    def get_integration_operation(self, operation_id: str) -> Operation:
        return self.operations.get_integration(operation_id)

    def register_webhook_endpoint(
        self,
        *,
        source: str,
        url: str,
        signing_secret: str,
        subscribed_event_types: list[str] | None = None,
    ) -> WebhookEndpoint:
        return self.events.register_webhook_endpoint(
            source=source,
            url=url,
            signing_secret=signing_secret,
            subscribed_event_types=subscribed_event_types,
        )

    def _request(
        self,
        method: str,
        path: str,
        *,
        json: dict[str, Any] | None = None,
        headers: dict[str, str] | None = None,
        idempotency_key: str | None = None,
    ) -> Any:
        request_headers = merged_headers(
            api_token=self.api_token,
            campaign_headers=self._campaign_headers(),
            headers=headers,
            idempotency_key=idempotency_key,
        )
        retryable = request_can_retry(method, idempotency_key)
        attempts = self.retry_policy.max_attempts if retryable else 1
        last_error: httpx.HTTPError | None = None
        for attempt in range(attempts):
            try:
                response = self._client.request(method, path, json=json, headers=request_headers)
                if retryable and should_retry_response(response, self.retry_policy) and attempt + 1 < attempts:
                    self.retry_policy.sleep(attempt)
                    continue
                return self._decode_response(response)
            except httpx.HTTPError as exc:
                last_error = exc
                if not retryable or not should_retry_error(exc) or attempt + 1 >= attempts:
                    break
                self.retry_policy.sleep(attempt)
        raise AgEvidenceError("HTTP request failed.", code="HTTP_REQUEST_FAILED", response_body=str(last_error)) from last_error

    def _decode_response(self, response: httpx.Response) -> Any:
        return decode_response(response)

    def _campaign_headers(self) -> dict[str, str]:
        headers: dict[str, str] = {}
        if self.campaign_account_id:
            headers["X-AgEvidence-Campaign-Account"] = self.campaign_account_id
        if self.activation_id:
            headers["X-AgEvidence-Activation"] = self.activation_id
        if self.repository_sha:
            headers["X-AgEvidence-Repository-SHA"] = self.repository_sha
        if headers:
            headers["X-AgEvidence-SDK-Version"] = _sdk_version()
        return headers


def _sdk_version() -> str:
    return sdk_version()

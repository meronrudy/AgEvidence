"""Asynchronous AgEvidence Developer OS client."""

from __future__ import annotations

import asyncio
from typing import Any

import httpx

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
from .request_models import (
    ArtifactBuildRequest,
    CampaignAccountCreateRequest,
    CampaignAccountUpdateRequest,
    CampaignActivationFailRequest,
    CampaignActivationStartRequest,
    CampaignHandoffCreateRequest,
    CampaignQualificationRequest,
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
from .transport import (
    RetryPolicy,
    decode_response,
    list_payload_items,
    merged_headers,
    request_can_retry,
    sdk_version,
    should_retry_error,
    should_retry_response,
)


class AsyncProjectsResource:
    def __init__(self, client: "AsyncClient") -> None:
        self._client = client

    async def create(self, **kwargs: Any) -> DeveloperProject:
        idempotency_key = kwargs.pop("idempotency_key", None)
        body = ProjectCreateRequest(**kwargs)
        return DeveloperProject.model_validate(
            await self._client._request("POST", "/v1/developer/projects", json=body.api_payload(), idempotency_key=idempotency_key)
        )

    async def get(self, project_id: str | int) -> DeveloperProject:
        return DeveloperProject.model_validate(await self._client._request("GET", f"/v1/developer/projects/{project_id}"))


class AsyncSourceRecordsResource:
    def __init__(self, client: "AsyncClient") -> None:
        self._client = client

    async def submit(self, *, project_id: str | int, idempotency_key: str | None = None, **kwargs: Any) -> SourceRecord:
        body = SourceRecordCreateRequest(**kwargs)
        return SourceRecord.model_validate(
            await self._client._request(
                "POST",
                f"/v1/developer/projects/{project_id}/source_records",
                json=body.api_payload(),
                idempotency_key=idempotency_key,
            )
        )


class AsyncModelRunsResource:
    def __init__(self, client: "AsyncClient") -> None:
        self._client = client

    async def run(self, *, project_id: str | int, adapter_id: str = "qwen3.5-4b-reference", idempotency_key: str | None = None) -> ModelRun:
        body = ModelRunCreateRequest(adapter_id=adapter_id)
        return ModelRun.model_validate(
            await self._client._request(
                "POST",
                f"/v1/developer/projects/{project_id}/model_runs",
                json=body.model_dump(mode="json"),
                idempotency_key=idempotency_key,
            )
        )


class AsyncReviewsResource:
    def __init__(self, client: "AsyncClient") -> None:
        self._client = client

    async def review_candidate(self, *, candidate_id: str | int, idempotency_key: str | None = None, **kwargs: Any) -> EvidenceCandidate:
        body = ReviewCandidateRequest(**kwargs)
        return EvidenceCandidate.model_validate(
            await self._client._request(
                "PATCH",
                f"/v1/developer/candidates/{candidate_id}",
                json=body.api_payload(),
                idempotency_key=idempotency_key,
            )
        )


class AsyncPricingResource:
    def __init__(self, client: "AsyncClient") -> None:
        self._client = client

    async def products(self) -> ProductCatalog:
        return ProductCatalog.model_validate(await self._client._request("GET", "/v1/pricing/products"))

    async def create_quote(self, *, project_id: str | int, product_code: str, scope: dict[str, Any] | None = None, idempotency_key: str | None = None) -> PricingQuote:
        body = QuoteCreateRequest(project_id=str(project_id), product_code=product_code, scope=scope or {})
        return PricingQuote.model_validate(
            await self._client._request("POST", "/v1/pricing/quotes", json=body.api_payload(), idempotency_key=idempotency_key)
        )

    async def get_quote(self, quote_id: str) -> PricingQuote:
        return PricingQuote.model_validate(await self._client._request("GET", f"/v1/pricing/quotes/{quote_id}"))


class AsyncOrdersResource:
    def __init__(self, client: "AsyncClient") -> None:
        self._client = client

    async def create(self, *, quote_id: str, artifact_scope: dict[str, Any] | None = None, idempotency_key: str | None = None) -> ArtifactOrder:
        body = OrderCreateRequest(quote_id=quote_id, artifact_scope=artifact_scope or {})
        return ArtifactOrder.model_validate(
            await self._client._request("POST", "/v1/artifact-orders", json=body.api_payload(), idempotency_key=idempotency_key)
        )

    async def checkout(self, *, order_id: str, idempotency_key: str | None = None) -> ArtifactOrder:
        return ArtifactOrder.model_validate(
            await self._client._request("POST", f"/v1/artifact-orders/{order_id}/checkout", json={}, idempotency_key=idempotency_key)
        )

    async def get(self, order_id: str) -> ArtifactOrder:
        return ArtifactOrder.model_validate(await self._client._request("GET", f"/v1/artifact-orders/{order_id}"))


class AsyncArtifactsResource:
    def __init__(self, client: "AsyncClient") -> None:
        self._client = client

    async def build(self, *, project_id: str | int, idempotency_key: str | None = None, **kwargs: Any) -> ArtifactOrder:
        body = ArtifactBuildRequest(**kwargs)
        return ArtifactOrder.model_validate(
            await self._client._request(
                "POST",
                f"/v1/developer/projects/{project_id}/artifacts",
                json=body.model_dump(mode="json", exclude_none=True),
                idempotency_key=idempotency_key,
            )
        )

    async def get(self, *, project_id: str | int, artifact_id: str) -> ArtifactOrder:
        return ArtifactOrder.model_validate(await self._client._request("GET", f"/v1/developer/projects/{project_id}/artifacts/{artifact_id}"))

    async def download_metadata(self, *, project_id: str | int, artifact_id: str) -> ArtifactDownloadMetadata:
        return ArtifactDownloadMetadata.model_validate(
            await self._client._request("GET", f"/v1/developer/projects/{project_id}/artifacts/{artifact_id}/download")
        )


class AsyncOperationsResource:
    def __init__(self, client: "AsyncClient") -> None:
        self._client = client

    async def get(self, operation_id: str) -> Operation:
        return Operation.model_validate(await self._client._request("GET", f"/v1/developer/operations/{operation_id}"))

    async def get_integration(self, operation_id: str) -> Operation:
        return Operation.model_validate(await self._client._request("GET", f"/v1/integrations/operations/{operation_id}"))

    async def wait(self, operation_id: str, *, timeout: float = 60.0, interval: float = 2.0) -> Operation:
        loop = asyncio.get_running_loop()
        deadline = loop.time() + timeout
        while True:
            operation = await self.get(operation_id)
            if operation.terminal:
                return operation
            if loop.time() >= deadline:
                raise AgEvidenceError(f"Operation did not complete within {timeout} seconds.", code="OPERATION_TIMEOUT")
            await asyncio.sleep(interval)


class AsyncEventsResource:
    def __init__(self, client: "AsyncClient") -> None:
        self._client = client

    async def submit(
        self,
        event: dict[str, Any],
        *,
        source: str,
        timestamp: str,
        signature: str,
        idempotency_key: str | None = None,
    ) -> EventSubmission:
        return EventSubmission.model_validate(
            await self._client._request(
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

    async def get(self, event_id: str, *, source: str | None = None) -> IntegrationEventStatus:
        headers = {"X-Athian-Integration-Source": source} if source else None
        return IntegrationEventStatus.model_validate(await self._client._request("GET", f"/v1/integrations/events/{event_id}", headers=headers))

    async def replay(self, event_id: str, *, source: str | None = None, reason: str = "python_sdk_replay", idempotency_key: str | None = None) -> EventSubmission:
        headers = {"X-Athian-Integration-Source": source} if source else None
        body = EventReplayRequest(reason=reason)
        return EventSubmission.model_validate(
            await self._client._request(
                "POST",
                f"/v1/integrations/events/{event_id}/replay",
                json=body.model_dump(mode="json"),
                headers=headers,
                idempotency_key=idempotency_key,
            )
        )

    async def register_webhook_endpoint(
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
            await self._client._request(
                "POST",
                "/v1/integrations/webhook_endpoints",
                json=body.model_dump(mode="json", exclude_none=True),
                headers={"X-Athian-Integration-Source": source},
                idempotency_key=idempotency_key,
            )
        )


class AsyncCountryResource:
    def __init__(self, client: "AsyncClient") -> None:
        self._client = client

    async def list_adapters(self) -> list[CountryAdapterInfo]:
        payload = await self._client._request("GET", "/v1/country_adapters")
        return [CountryAdapterInfo.model_validate(item) for item in list_payload_items(payload, "country_adapters", "adapters")]

    async def get_adapter(self, adapter_id: str) -> CountryAdapterInfo:
        return CountryAdapterInfo.model_validate(await self._client._request("GET", f"/v1/country_adapters/{adapter_id}"))

    async def validate_adapter(self, adapter_id: str, *, idempotency_key: str | None = None) -> CountryAdapterValidation:
        return CountryAdapterValidation.model_validate(
            await self._client._request("POST", f"/v1/country_adapters/{adapter_id}/validate", json={}, idempotency_key=idempotency_key)
        )

    async def list_determinations(self, project_id: str | int) -> list[CountryDetermination]:
        payload = await self._client._request("GET", f"/v1/developer/projects/{project_id}/country_determinations")
        return [
            CountryDetermination.model_validate(item)
            for item in list_payload_items(payload, "country_determinations", "determinations")
        ]

    async def create_determination(
        self,
        *,
        project_id: str | int,
        adapter: str,
        institution_profile: dict[str, Any] | None = None,
        idempotency_key: str | None = None,
    ) -> CountryDetermination:
        body = CountryDeterminationCreateRequest(adapter=adapter, institution_profile=institution_profile)
        return CountryDetermination.model_validate(
            await self._client._request(
                "POST",
                f"/v1/developer/projects/{project_id}/country_determinations",
                json=body.model_dump(mode="json", exclude_none=True),
                idempotency_key=idempotency_key,
            )
        )


class AsyncCampaignClient:
    """Async Campaign Control Plane namespace."""

    def __init__(self, client: "AsyncClient") -> None:
        self._client = client

    async def create_account(self, **fields: Any) -> Any:
        body = CampaignAccountCreateRequest(**fields)
        from .campaign.models import CampaignAccount

        return CampaignAccount.model_validate(
            await self._client._request("POST", "/v1/campaign/accounts", json={"campaign_account": body.model_dump(mode="json", exclude_none=True)})
        )

    async def get_account(self, account_id: str) -> Any:
        from .campaign.models import CampaignAccount

        return CampaignAccount.model_validate(await self._client._request("GET", f"/v1/campaign/accounts/{account_id}"))

    async def list_accounts(self) -> list[Any]:
        from .campaign.models import CampaignAccount

        payload = await self._client._request("GET", "/v1/campaign/accounts")
        return [CampaignAccount.model_validate(item) for item in list_payload_items(payload, "accounts")]

    async def update_account(self, account_id: str, **fields: Any) -> Any:
        body = CampaignAccountUpdateRequest(**fields)
        from .campaign.models import CampaignAccount

        return CampaignAccount.model_validate(
            await self._client._request(
                "PATCH",
                f"/v1/campaign/accounts/{account_id}",
                json={"campaign_account": body.model_dump(mode="json", exclude_none=True)},
            )
        )

    async def start_activation(self, account_id: str, **fields: Any) -> Any:
        body = CampaignActivationStartRequest(**fields)
        from .campaign.models import ActivationPath

        return ActivationPath.model_validate(
            await self._client._request(
                "POST",
                f"/v1/campaign/accounts/{account_id}/activations",
                json={"activation": body.model_dump(mode="json", exclude_none=True)},
            )
        )

    async def complete_activation(self, account_id: str, activation_id: str) -> Any:
        from .campaign.models import ActivationPath

        return ActivationPath.model_validate(
            await self._client._request("POST", f"/v1/campaign/accounts/{account_id}/activations/{activation_id}/complete", json={})
        )

    async def fail_activation(self, account_id: str, activation_id: str, *, failure_code: str = "activation_failed") -> Any:
        body = CampaignActivationFailRequest(failure_code=failure_code)
        from .campaign.models import ActivationPath

        return ActivationPath.model_validate(
            await self._client._request(
                "POST",
                f"/v1/campaign/accounts/{account_id}/activations/{activation_id}/fail",
                json=body.model_dump(mode="json"),
            )
        )

    async def evaluate_qualification(self, account_id: str, **fields: Any) -> Any:
        body = CampaignQualificationRequest(**fields)
        from .campaign.models import TechnicalQualification

        return TechnicalQualification.model_validate(
            await self._client._request(
                "POST",
                f"/v1/campaign/accounts/{account_id}/qualifications",
                json={"qualification": body.model_dump(mode="json", exclude_none=True)},
            )
        )

    async def create_handoff(self, account_id: str, **fields: Any) -> Any:
        body = CampaignHandoffCreateRequest(**fields)
        from .campaign.models import CommercialHandoff

        return CommercialHandoff.model_validate(
            await self._client._request(
                "POST",
                f"/v1/campaign/accounts/{account_id}/handoffs",
                json={"handoff": body.model_dump(mode="json", exclude_none=True)},
            )
        )

    async def get_dashboard(self) -> Any:
        from .campaign.models import CampaignDashboard

        return CampaignDashboard.model_validate(await self._client._request("GET", "/v1/campaign/dashboard"))


class AsyncClient:
    """Async typed client for the Rails /v1 Developer OS API."""

    def __init__(
        self,
        base_url: str | None = None,
        *,
        api_token: str | None = None,
        timeout: float = 10.0,
        retries: int = 1,
        retry_policy: RetryPolicy | None = None,
        transport: httpx.AsyncBaseTransport | None = None,
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
        self._client = httpx.AsyncClient(base_url=self.base_url, timeout=timeout, transport=transport)
        self.projects = AsyncProjectsResource(self)
        self.source_records = AsyncSourceRecordsResource(self)
        self.model_runs = AsyncModelRunsResource(self)
        self.reviews = AsyncReviewsResource(self)
        self.pricing = AsyncPricingResource(self)
        self.orders = AsyncOrdersResource(self)
        self.artifacts = AsyncArtifactsResource(self)
        self.operations = AsyncOperationsResource(self)
        self.events = AsyncEventsResource(self)
        self.country = AsyncCountryResource(self)
        self.campaign = AsyncCampaignClient(self)

    async def aclose(self) -> None:
        await self._client.aclose()

    async def __aenter__(self) -> "AsyncClient":
        return self

    async def __aexit__(self, *_exc: object) -> None:
        await self.aclose()

    async def _request(
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
                response = await self._client.request(method, path, json=json, headers=request_headers)
                if retryable and should_retry_response(response, self.retry_policy) and attempt + 1 < attempts:
                    await asyncio.sleep(self.retry_policy.backoff_seconds * (attempt + 1))
                    continue
                return decode_response(response)
            except httpx.HTTPError as exc:
                last_error = exc
                if not retryable or not should_retry_error(exc) or attempt + 1 >= attempts:
                    break
                await asyncio.sleep(self.retry_policy.backoff_seconds * (attempt + 1))
        raise AgEvidenceError("HTTP request failed.", code="HTTP_REQUEST_FAILED", response_body=str(last_error)) from last_error

    def _campaign_headers(self) -> dict[str, str]:
        headers: dict[str, str] = {}
        if self.campaign_account_id:
            headers["X-AgEvidence-Campaign-Account"] = self.campaign_account_id
        if self.activation_id:
            headers["X-AgEvidence-Activation"] = self.activation_id
        if self.repository_sha:
            headers["X-AgEvidence-Repository-SHA"] = self.repository_sha
        if headers:
            headers["X-AgEvidence-SDK-Version"] = sdk_version()
        return headers

    async def create_project(self, **kwargs: Any) -> DeveloperProject:
        return await self.projects.create(**kwargs)

    async def get_project(self, project_id: str | int) -> DeveloperProject:
        return await self.projects.get(project_id)

    async def submit_source_record(self, *, project_id: str | int, **kwargs: Any) -> SourceRecord:
        return await self.source_records.submit(project_id=project_id, **kwargs)

    async def run_model(self, *, project_id: str | int, adapter_id: str = "qwen3.5-4b-reference") -> ModelRun:
        return await self.model_runs.run(project_id=project_id, adapter_id=adapter_id)

    async def review_candidate(self, *, candidate_id: str | int, **kwargs: Any) -> EvidenceCandidate:
        return await self.reviews.review_candidate(candidate_id=candidate_id, **kwargs)

    async def list_products(self) -> ProductCatalog:
        return await self.pricing.products()

    async def create_quote(self, *, project_id: str | int, product_code: str, scope: dict[str, Any] | None = None) -> PricingQuote:
        return await self.pricing.create_quote(project_id=project_id, product_code=product_code, scope=scope)

    async def get_quote(self, quote_id: str) -> PricingQuote:
        return await self.pricing.get_quote(quote_id)

    async def create_order(self, *, quote_id: str, artifact_scope: dict[str, Any] | None = None) -> ArtifactOrder:
        return await self.orders.create(quote_id=quote_id, artifact_scope=artifact_scope)

    async def checkout_order(self, *, order_id: str) -> ArtifactOrder:
        return await self.orders.checkout(order_id=order_id)

    async def get_order(self, order_id: str) -> ArtifactOrder:
        return await self.orders.get(order_id)

    async def build_artifact(self, *, project_id: str | int, **kwargs: Any) -> ArtifactOrder:
        return await self.artifacts.build(project_id=project_id, **kwargs)

    async def get_artifact(self, *, project_id: str | int, artifact_id: str) -> ArtifactOrder:
        return await self.artifacts.get(project_id=project_id, artifact_id=artifact_id)

    async def download_artifact_metadata(self, *, project_id: str | int, artifact_id: str) -> ArtifactDownloadMetadata:
        return await self.artifacts.download_metadata(project_id=project_id, artifact_id=artifact_id)

    async def get_operation(self, operation_id: str) -> Operation:
        return await self.operations.get(operation_id)

    async def wait_for_operation(self, operation_id: str, *, timeout: float = 60.0, interval: float = 2.0) -> Operation:
        return await self.operations.wait(operation_id, timeout=timeout, interval=interval)

    async def submit_event(self, event: dict[str, Any], *, source: str, timestamp: str, signature: str) -> EventSubmission:
        return await self.events.submit(event, source=source, timestamp=timestamp, signature=signature)

    async def get_event(self, event_id: str, *, source: str | None = None) -> IntegrationEventStatus:
        return await self.events.get(event_id, source=source)

    async def replay_event(self, event_id: str, *, source: str | None = None, reason: str = "python_sdk_replay") -> EventSubmission:
        return await self.events.replay(event_id, source=source, reason=reason)

    async def get_integration_operation(self, operation_id: str) -> Operation:
        return await self.operations.get_integration(operation_id)

    async def register_webhook_endpoint(
        self,
        *,
        source: str,
        url: str,
        signing_secret: str,
        subscribed_event_types: list[str] | None = None,
    ) -> WebhookEndpoint:
        return await self.events.register_webhook_endpoint(
            source=source,
            url=url,
            signing_secret=signing_secret,
            subscribed_event_types=subscribed_event_types,
        )

    async def list_country_adapters(self) -> list[CountryAdapterInfo]:
        return await self.country.list_adapters()

    async def get_country_adapter(self, adapter_id: str) -> CountryAdapterInfo:
        return await self.country.get_adapter(adapter_id)

    async def validate_country_adapter(self, adapter_id: str) -> CountryAdapterValidation:
        return await self.country.validate_adapter(adapter_id)

    async def list_country_determinations(self, project_id: str | int) -> list[CountryDetermination]:
        return await self.country.list_determinations(project_id)

    async def create_country_determination(
        self,
        *,
        project_id: str | int,
        adapter: str,
        institution_profile: dict[str, Any] | None = None,
    ) -> CountryDetermination:
        return await self.country.create_determination(project_id=project_id, adapter=adapter, institution_profile=institution_profile)

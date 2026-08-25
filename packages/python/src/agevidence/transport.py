"""Shared HTTP transport behavior for the AgEvidence SDK."""

from __future__ import annotations

import time
from dataclasses import dataclass, field
from importlib.metadata import PackageNotFoundError, version
from typing import Any

import httpx

from .errors import AgEvidenceError


IDEMPOTENT_METHODS = {"GET", "HEAD", "OPTIONS"}
RETRY_STATUS_CODES = frozenset({408, 429, 500, 502, 503, 504})


@dataclass(frozen=True, slots=True)
class RetryPolicy:
    """Retry policy for transient SDK HTTP failures."""

    max_attempts: int = 2
    backoff_seconds: float = 0.2
    retry_status_codes: frozenset[int] = field(default_factory=lambda: RETRY_STATUS_CODES)

    @classmethod
    def from_retries(cls, retries: int) -> "RetryPolicy":
        return cls(max_attempts=max(1, retries + 1))

    def sleep(self, attempt: int) -> None:
        if self.backoff_seconds > 0:
            time.sleep(self.backoff_seconds * (attempt + 1))


def sdk_version() -> str:
    try:
        return version("agevidence")
    except PackageNotFoundError:
        from . import __version__

        return __version__


def merged_headers(
    *,
    api_token: str | None = None,
    campaign_headers: dict[str, str] | None = None,
    headers: dict[str, str] | None = None,
    idempotency_key: str | None = None,
) -> dict[str, str]:
    merged = {"Accept": "application/json", **(campaign_headers or {}), **(headers or {})}
    if api_token:
        merged["Authorization"] = f"Bearer {api_token}"
    if idempotency_key:
        merged["Idempotency-Key"] = idempotency_key
    return merged


def request_can_retry(method: str, idempotency_key: str | None = None) -> bool:
    return method.upper() in IDEMPOTENT_METHODS or bool(idempotency_key)


def should_retry_response(response: httpx.Response, policy: RetryPolicy) -> bool:
    return response.status_code in policy.retry_status_codes


def should_retry_error(exc: httpx.HTTPError) -> bool:
    return isinstance(exc, (httpx.ConnectError, httpx.ConnectTimeout, httpx.ReadError, httpx.ReadTimeout, httpx.PoolTimeout))


def decode_response(response: httpx.Response) -> Any:
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


def list_payload_items(payload: Any, *keys: str) -> list[Any]:
    """Accept both bare arrays and common paginated/list envelopes."""

    if isinstance(payload, list):
        return payload
    if not isinstance(payload, dict):
        return []
    for key in (*keys, "items", "data", "results"):
        value = payload.get(key)
        if isinstance(value, list):
            return value
    return []

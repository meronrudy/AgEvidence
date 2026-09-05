"""Integration event helpers.

These helpers sign upstream integration events only. They do not sign receipts
or produce receipt commitments.
"""

from __future__ import annotations

import copy
import hashlib
import hmac
import json
import math
from pathlib import Path
from typing import Any, Iterable


MAX_SAFE_JSON_INTEGER = 9_007_199_254_740_991


def canonical_value(value: Any) -> Any:
    if isinstance(value, dict):
        return {key: canonical_value(value[key]) for key in sorted(value)}
    if isinstance(value, list):
        return [canonical_value(item) for item in value]
    return value


def canonical_json(value: Any) -> str:
    return _jcs_dumps(value)


def canonical_event_payload(event: dict[str, Any], source: str | None = None) -> str:
    payload = canonical_value(copy.deepcopy(event))
    if source:
        payload["source"] = source
    payload.setdefault("integrity", {})
    payload["integrity"].pop("payload_digest", None)
    payload["integrity"].pop("signature", None)
    payload["integrity"].setdefault("signature_algorithm", "hmac-sha256")
    return canonical_json(payload)


def sign_hmac_event(event: dict[str, Any], *, source: str, secret: str, timestamp: str | None = None) -> dict[str, Any]:
    signed = copy.deepcopy(event)
    signed["source"] = source
    signed.setdefault("integrity", {})
    signed["integrity"]["signature_algorithm"] = "hmac-sha256"
    occurred_at = timestamp or signed["occurred_at"]
    canonical = canonical_event_payload(signed, source=source)
    digest = hashlib.sha256(canonical.encode("utf-8")).hexdigest()
    signature = hmac.new(secret.encode("utf-8"), f"{occurred_at}\n{canonical}".encode("utf-8"), hashlib.sha256).hexdigest()
    signed["integrity"]["payload_digest"] = f"sha256:{digest}"
    signed["integrity"]["signature"] = f"v1={signature}"
    return signed


def load_event(path: str | Path) -> dict[str, Any]:
    return json.loads(Path(path).read_text(encoding="utf-8"))


def project_4030_event_files(root: str | Path | None = None) -> list[Path]:
    base = Path(root) if root else Path(__file__).resolve().parents[4] / "examples" / "integrations" / "project_4030_beef"
    return sorted(base.glob("[0-9][0-9]-*.json"))


def load_project_4030_events(root: str | Path | None = None) -> Iterable[dict[str, Any]]:
    for path in project_4030_event_files(root):
        yield load_event(path)


def _jcs_dumps(value: Any) -> str:
    if value is None:
        return "null"
    if value is True:
        return "true"
    if value is False:
        return "false"
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    if isinstance(value, int) and not isinstance(value, bool):
        if abs(value) > MAX_SAFE_JSON_INTEGER:
            raise ValueError("integer is outside the RFC 8785 interoperable JSON number range")
        return str(value)
    if isinstance(value, float):
        return _format_float_jcs(value)
    if isinstance(value, list):
        return "[" + ",".join(_jcs_dumps(item) for item in value) + "]"
    if isinstance(value, dict):
        items = []
        for key in sorted(value, key=lambda item: str(item).encode("utf-16-be")):
            if not isinstance(key, str):
                raise TypeError("JCS object keys must be strings")
            items.append(f"{_jcs_dumps(key)}:{_jcs_dumps(value[key])}")
        return "{" + ",".join(items) + "}"
    raise TypeError(f"unsupported JSON value: {type(value).__name__}")


def _format_float_jcs(value: float) -> str:
    if not math.isfinite(value):
        raise ValueError("NaN and Infinity are not valid RFC 8785 JSON numbers")
    if value == 0:
        return "0"

    sign = "-" if value < 0 else ""
    text = repr(abs(value)).lower()
    coefficient, exponent_text = text.split("e") if "e" in text else (text, "0")
    exponent = int(exponent_text)
    if "." in coefficient:
        integer, fraction = coefficient.split(".", 1)
        decimal_point = len(integer) + exponent
        digits = integer + fraction
    else:
        decimal_point = len(coefficient) + exponent
        digits = coefficient

    leading_zeroes = len(digits) - len(digits.lstrip("0"))
    digits = digits.lstrip("0") or "0"
    decimal_point -= leading_zeroes
    digits = digits.rstrip("0") or "0"
    adjusted_exponent = decimal_point - 1

    if -6 <= adjusted_exponent < 21:
        if decimal_point <= 0:
            rendered = "0." + ("0" * -decimal_point) + digits
        elif decimal_point >= len(digits):
            rendered = digits + ("0" * (decimal_point - len(digits)))
        else:
            rendered = digits[:decimal_point] + "." + digits[decimal_point:]
        if "." in rendered:
            rendered = rendered.rstrip("0").rstrip(".")
        return sign + rendered

    if len(digits) == 1:
        mantissa = digits
    else:
        mantissa = digits[0] + "." + digits[1:]
    exponent_sign = "+" if adjusted_exponent >= 0 else ""
    return f"{sign}{mantissa}e{exponent_sign}{adjusted_exponent}"

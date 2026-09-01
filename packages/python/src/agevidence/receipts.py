"""Receipt boundary notes.

The Python SDK does not issue, sign, or verify receipts directly. Use Rails
through /v1 for workflow orchestration and `ink_receipts`/Rust for trust
operations.
"""

TRUST_BOUNDARY_NOTICE = "Receipt operations are delegated to ink_receipts and Rust."

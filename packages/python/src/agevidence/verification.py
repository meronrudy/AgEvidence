"""Verifier delegation helpers."""

from __future__ import annotations

import shlex
import subprocess
from dataclasses import dataclass
from pathlib import Path

from .config import SDKConfig
from .errors import AgEvidenceError
from .models import VerifyResult


@dataclass(slots=True)
class Verifier:
    command: str | None = None

    def verify_bundle(self, bundle: str | Path) -> VerifyResult:
        configured = self.command or SDKConfig.load().verifier_command
        if not configured:
            raise AgEvidenceError(
                "Set AGEVIDENCE_VERIFIER_COMMAND or run `agevidence login --verifier-command ...`.",
                code="VERIFIER_COMMAND_MISSING",
            )

        command = shlex.split(configured) + ["verify-bundle", str(bundle)]
        try:
            completed = subprocess.run(command, capture_output=True, text=True, check=False)
        except FileNotFoundError as exc:
            raise AgEvidenceError(
                f"Verifier command was not found: {command[0]}",
                code="VERIFIER_COMMAND_NOT_FOUND",
            ) from exc

        if completed.returncode != 0:
            raise AgEvidenceError(
                "Verifier command failed.",
                status_code=completed.returncode,
                code="VERIFIER_FAILED",
                response_body={"stdout": completed.stdout, "stderr": completed.stderr, "command": command},
            )

        return VerifyResult(status="delegated", command=command, returncode=completed.returncode, stdout=completed.stdout, stderr=completed.stderr)

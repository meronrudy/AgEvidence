"""Configuration loading for the AgEvidence SDK and CLI."""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from pathlib import Path


DEFAULT_BASE_URL = "http://localhost:3000"


def default_config_path() -> Path:
    override = os.environ.get("AGEVIDENCE_CONFIG_PATH")
    if override:
        return Path(override).expanduser()
    return Path(os.environ.get("XDG_CONFIG_HOME", "~/.config")).expanduser() / "agevidence" / "config.json"


@dataclass(slots=True)
class SDKConfig:
    base_url: str = DEFAULT_BASE_URL
    api_token: str | None = None
    integration_source: str | None = None
    integration_secret: str | None = None
    verifier_command: str | None = None

    @classmethod
    def load(cls, path: Path | None = None) -> "SDKConfig":
        config_path = path or default_config_path()
        file_values: dict[str, str | None] = {}
        if config_path.exists():
            file_values = json.loads(config_path.read_text(encoding="utf-8"))

        return cls(
            base_url=os.environ.get("AGEVIDENCE_BASE_URL") or file_values.get("base_url") or DEFAULT_BASE_URL,
            api_token=os.environ.get("AGEVIDENCE_API_TOKEN") or file_values.get("api_token"),
            integration_source=os.environ.get("AGEVIDENCE_INTEGRATION_SOURCE") or file_values.get("integration_source"),
            integration_secret=os.environ.get("AGEVIDENCE_INTEGRATION_SECRET") or file_values.get("integration_secret"),
            verifier_command=os.environ.get("AGEVIDENCE_VERIFIER_COMMAND") or file_values.get("verifier_command"),
        )

    def save(self, path: Path | None = None) -> Path:
        config_path = path or default_config_path()
        config_path.parent.mkdir(parents=True, exist_ok=True)
        values = {
            "base_url": self.base_url,
            "api_token": self.api_token,
            "integration_source": self.integration_source,
            "verifier_command": self.verifier_command,
        }
        config_path.write_text(json.dumps(values, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        try:
            config_path.chmod(0o600)
        except PermissionError:
            pass
        return config_path

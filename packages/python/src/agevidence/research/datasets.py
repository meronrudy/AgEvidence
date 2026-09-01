"""Dataset download and workbook loading helpers for researcher examples."""

from __future__ import annotations

from pathlib import Path

import httpx
import pandas as pd

from .bundles import verify_checksum


def ensure_download(
    *,
    url: str,
    path: Path,
    sha256: str,
    md5: str | None = None,
    force: bool = False,
) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    if force or not path.exists():
        with httpx.stream("GET", url, follow_redirects=True, timeout=120.0) as response:
            response.raise_for_status()
            with path.open("wb") as handle:
                for chunk in response.iter_bytes():
                    handle.write(chunk)
    verify_checksum(path, sha256=sha256, md5=md5)
    return path


def load_excel(path: Path) -> dict[str, pd.DataFrame]:
    return pd.read_excel(path, sheet_name=None, engine="openpyxl")


def normalize_columns(frame: pd.DataFrame) -> pd.DataFrame:
    renamed = {column: str(column).strip() for column in frame.columns}
    return frame.rename(columns=renamed)

from __future__ import annotations

import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
SHARED = REPO_ROOT / "examples" / "researchers" / "_shared"
if str(SHARED) not in sys.path:
    sys.path.insert(0, str(SHARED))

from data_sources import ensure_download  # noqa: E402

URL = "https://journals.plos.org/plosone/article/file?id=10.1371/journal.pone.0247820.s001&type=supplementary"
SHA256 = "sha256:f8c90ca7b106d95abc2df4c316ac520b482a47350ab2ea0f3647a1442181b409"
TARGET = Path(__file__).with_name("pone.0247820.s001.xlsx")


def main() -> None:
    path = ensure_download(url=URL, path=TARGET, sha256=SHA256)
    print(path)


if __name__ == "__main__":
    main()


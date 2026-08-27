from __future__ import annotations

from pathlib import Path

from agevidence.research.datasets import ensure_download

URL = "https://journals.plos.org/plosone/article/file?id=10.1371/journal.pone.0247820.s001&type=supplementary"
SHA256 = "sha256:f8c90ca7b106d95abc2df4c316ac520b482a47350ab2ea0f3647a1442181b409"
REPO_ROOT = Path(__file__).resolve().parents[4]
TARGET = REPO_ROOT / "research" / ".data" / "kebreab" / "roque-2021" / "pone.0247820.s001.xlsx"


def main() -> None:
    path = ensure_download(url=URL, path=TARGET, sha256=SHA256)
    print(path)


if __name__ == "__main__":
    main()

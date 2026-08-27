from __future__ import annotations

import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
SHARED = REPO_ROOT / "examples" / "researchers" / "_shared"
if str(SHARED) not in sys.path:
    sys.path.insert(0, str(SHARED))

from data_sources import ensure_download  # noqa: E402

URL = "https://zenodo.org/records/10832823/files/Enteric%20CH4%20yield%20and%20its%20variability%20in%20dairy%20cows.xlsx?download=1"
SHA256 = "sha256:b5a5064306bbaedb778a4177d4de31a4a6d0742440e0e013a92b36edf9017b2e"
MD5 = "md5:2c98c4b5042606fb80606793e7ddd4f0"
TARGET = Path(__file__).with_name("Enteric CH4 yield and its variability in dairy cows.xlsx")


def main() -> None:
    path = ensure_download(url=URL, path=TARGET, sha256=SHA256, md5=MD5)
    print(path)


if __name__ == "__main__":
    main()

from __future__ import annotations

import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SDK_SRC = REPO_ROOT / "packages" / "python" / "src"
for path in (SDK_SRC, REPO_ROOT, Path(__file__).resolve().parent):
    if str(path) not in sys.path:
        sys.path.insert(0, str(path))

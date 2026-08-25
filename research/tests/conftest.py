from __future__ import annotations

import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SDK_SRC = REPO_ROOT / "sdks" / "python" / "src"
SHARED = REPO_ROOT / "examples" / "researchers" / "_shared"
for path in (SDK_SRC, SHARED, REPO_ROOT, Path(__file__).resolve().parent):
    if str(path) not in sys.path:
        sys.path.insert(0, str(path))

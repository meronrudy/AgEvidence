#!/usr/bin/env sh
set -eu

python3 scripts/agevidence_manifest_check.py
python3 scripts/agevidence_vocabulary_check.py
python3 scripts/agevidence_isolation_check.py
python3 scripts/agevidence_conformance.py
python3 scripts/agevidence_openapi_check.py
python3 scripts/agevidence_loc.py

#!/usr/bin/env sh
set -eu

python3 protocol/conformance/scripts/agevidence_manifest_check.py
python3 protocol/conformance/scripts/agevidence_vocabulary_check.py
python3 protocol/conformance/scripts/agevidence_isolation_check.py
python3 protocol/conformance/scripts/agevidence_canonicalization_vectors.py
python3 protocol/conformance/scripts/agevidence_conformance.py
python3 protocol/conformance/scripts/agevidence_openapi_check.py
python3 protocol/conformance/scripts/agevidence_loc.py

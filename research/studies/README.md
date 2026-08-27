# Researcher Dataset Fixtures

This directory stores provenance metadata and download scripts for public
research datasets used by the researcher examples.

Raw workbooks are not committed. Each dataset directory contains:

- `source.yml` for publication, DOI, license, source URL, and expected
  commitments.
- `download.py` for fetching the workbook from the authoritative source.

Generated or downloaded `.xlsx` files under this directory are ignored by git.

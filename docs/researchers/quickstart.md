# Researcher Quickstart

## Install

For basic SDK use:

```bash
pip install agevidence
```

For executable research notebooks and Excel workbooks:

```bash
python3 -m pip install -e "packages/python[research,test]"
```

## Run The First Reconstruction

```bash
python research/studies/kebreab/roque-2021/run.py
```

Expected shape:

```text
AgEvidence Research Reconstruction
Study:
Roque et al. 2021
Sources registered:           1
Animals represented:         20
Treatment groups:             3
Observations:               ...
Intervention events:         ...
Model runs:                   1
Scientific statements:        ...
Evidence bundle:
./output/roque_2021.agevidence.json
Verification:
[ok] source integrity
[ok] observation lineage
[ok] intervention lineage
[ok] model provenance
[ok] statement reconstruction
```

The script downloads the PLOS S1 workbook, verifies the SHA-256 commitment,
reconstructs evidence records from the workbook, and writes a local bundle.

## Run The Meta-Analysis Workflow

```bash
python research/studies/kebreab/methane-database-2024/run.py
```

This downloads Zenodo v2, verifies SHA-256 and MD5 commitments, records
SEM-to-SD transformations, applies an SD exclusion rule, and creates a
sample-size model-run record.

## What This Does Not Claim

These examples demonstrate reconstructable evidence lineage. They do not assert
regulatory eligibility, scientific validity, carbon-credit issuance,
third-party verification, claim ownership, or institutional reliance.

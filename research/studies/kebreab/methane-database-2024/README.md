# Ramirez-Agudelo and Kebreab 2024 Methane Database

Run from the repository root:

```bash
python3 -m pip install -e "packages/python[research,test]"
python3 research/studies/kebreab/methane-database-2024/run.py
```

The script downloads Zenodo record v2, verifies the workbook checksum, preserves
literature-extraction fields, records SEM-to-SD transformations, applies the
`SD > 4.8` exclusion rule, and writes
`output/methane_database_2024.agevidence.json`.

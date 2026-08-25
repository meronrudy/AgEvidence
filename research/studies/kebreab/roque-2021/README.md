# Roque et al. 2021 Research Reconstruction

Run from the repository root:

```bash
python3 -m pip install -e "sdks/python[research,test]"
python examples/researchers/01_roque_2021/run.py
```

The script downloads the PLOS S1 workbook into `fixtures/researchers/roque_2021`
if needed, verifies its SHA-256 commitment, reconstructs evidence records from
the workbook sheets, and writes `output/roque_2021.agevidence.json`.


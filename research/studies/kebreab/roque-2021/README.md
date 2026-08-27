# Roque et al. 2021 Research Reconstruction

Run from the repository root:

```bash
python3 -m pip install -e "packages/python[research,test]"
python research/studies/kebreab/roque-2021/run.py
```

The script downloads the PLOS S1 workbook into `research/.data/kebreab/roque-2021`
if needed, verifies its SHA-256 commitment, reconstructs evidence records from
the workbook sheets, and writes `output/roque_2021.agevidence.json`.


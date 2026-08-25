# Meta-Analysis

The methane database example starts from a public Zenodo workbook and preserves
the evidence DAG behind a literature-derived analysis.

```text
reported SEM
  -> transformation: SD = SEM * sqrt(n)
  -> derived SD
  -> exclusion rule: SD > 4.8
  -> analysis population
  -> sample-size model run
```

Run:

```bash
python examples/researchers/02_methane_database_2024/run.py
```

The output bundle keeps the original workbook commitment and records
transformation and exclusion decisions before computing a derived sample-size
result.


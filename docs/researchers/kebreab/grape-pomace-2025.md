# Grape Pomace 2025

Akter et al. 2025 describes a grape-pomace feeding experiment with 24
multiparous Holstein cows, three treatments, a 3 x 3 Latin-square design, three
four-week periods, GreenFeed gas measurement, and milk sampling.

- Article: https://doi.org/10.3168/jds.2024-25419
- Example: ../../../examples/researchers/04_grape_pomace/

Run:

```bash
python examples/researchers/04_grape_pomace/run.py
```

Public-data boundary:

The article provides methods, design, and published results. This branch does
not include row-level cow-period, GreenFeed, or milk-lab rows because a public
row-level dataset was not located.

The case study still preserves:

- treatment and period structure
- feed, gas, and milk measurement streams
- GreenFeed calibration context
- SAS 9.4 / PROC GLIMMIX statistical lineage
- the explicit limitation that no private raw rows are reconstructed


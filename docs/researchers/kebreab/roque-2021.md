# Roque Et Al. 2021

Roque et al. published the original data workbook for the 2021 PLOS ONE
Asparagopsis beef-steer experiment.

- Publication: https://doi.org/10.1371/journal.pone.0247820
- Supporting data: https://doi.org/10.1371/journal.pone.0247820.s001
- Fixture manifest: ../../../research/studies/kebreab/roque-2021/source.yml
- Example: ../../../research/studies/kebreab/roque-2021/

Run:

```bash
python3 research/studies/kebreab/roque-2021/run.py
```

The reconstruction maps:

- animal/treatment assignment to intervention events
- high, medium, and low forage regimes to operational events
- gas, production, carcass, and taste-panel workbook rows to observations
- treatment-level CH4 summaries to a model run
- statement records to explicit basis object IDs

This is the canonical first tutorial because it starts from real public source
data, not a synthetic methane CSV.

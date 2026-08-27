# Experiment To Evidence

The first executable path reconstructs Roque et al. 2021 from its public PLOS
S1 workbook.

```text
published XLSX
  -> SourceRecord
  -> Observations
  -> InterventionEvents
  -> OperationalEvents
  -> ModelRun
  -> ScientificStatement records
```

Run:

```bash
python research/studies/kebreab/roque-2021/run.py
```

The workbook sheets are mapped as follows:

- `ProductionData`: DMI, body weight, gain, feed conversion, cost per gain.
- `GasData`: CH4, CO2, and H2 production and yield by animal, diet, treatment,
  and experimental week.
- `CarcassData`: carcass and meat-quality measurements.
- `TastePanelData`: sensory-panel results.


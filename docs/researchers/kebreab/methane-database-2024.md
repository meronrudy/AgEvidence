# Methane Database 2024

Ramirez-Agudelo and Kebreab published a Zenodo workbook for dairy-cow methane
yield and variability.

- Zenodo v2 dataset: https://doi.org/10.5281/zenodo.10832823
- Concept DOI: https://doi.org/10.5281/zenodo.10356505
- Publication DOI: https://doi.org/10.3168/jds.2023-24529
- Fixture manifest: ../../../fixtures/researchers/methane_database_2024/SOURCE.md
- Example: ../../../examples/researchers/02_methane_database_2024/

Run:

```bash
python examples/researchers/02_methane_database_2024/run.py
```

The tutorial records:

- workbook DOI, URL, SHA-256, MD5, and license
- study title, authors, country, breed, method, design, DMI, CH4 production,
  CH4 yield, SEM, SEM type, and SD
- SEM to SD transformation
- `SD > 4.8` exclusion decisions
- sample-size model-run inputs and outputs

This chapter is the evidence-DAG tutorial: source claim, transformation,
derived observation, exclusion decision, analysis population, and derived model
result.


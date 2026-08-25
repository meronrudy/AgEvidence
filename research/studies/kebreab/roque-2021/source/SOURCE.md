# Roque et al. 2021 Source

## Study

Roque, B. M., Venegas, M., Kinley, R. D., de Nys, R., Duarte, T. L.,
Yang, X., et al. 2021. Red seaweed (*Asparagopsis taxiformis*)
supplementation reduces enteric methane by over 80 percent in beef steers.
PLOS ONE 16(3): e0247820.

## Source Dataset

- Publication DOI: https://doi.org/10.1371/journal.pone.0247820
- Supporting dataset DOI: https://doi.org/10.1371/journal.pone.0247820.s001
- Dataset title: S1 Table. Original data.
- Download URL: https://journals.plos.org/plosone/article/file?id=10.1371/journal.pone.0247820.s001&type=supplementary
- Local filename after download: `pone.0247820.s001.xlsx`

## License And Distribution Status

The article page states that the article is distributed under the Creative
Commons Attribution License and that relevant data are in the paper and
supporting information files. The researcher examples still download from PLOS
instead of committing the workbook, so source custody and checksum verification
remain visible.

## Transformations Performed By AgEvidence Examples

- Register the workbook as one `SourceRecord`.
- Reconstruct animal-level gas, production, carcass, and sensory observations.
- Reconstruct treatment assignment and TMR regime events from workbook columns.
- Build one local model-run record with treatment-level gas summaries.
- Build scientific-statement records as example bundle records, not SDK
  primitives.


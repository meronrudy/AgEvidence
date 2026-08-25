# Ramirez-Agudelo and Kebreab 2024 Source

## Study And Dataset

Ramirez Agudelo, J. F., and Kebreab, E. 2024. Systematic review for
optimizing sample size in dairy cow methane emission studies in temperate
regions: A comprehensive methodological approach. Journal of Dairy Science.

## Source Dataset

- Dataset DOI, v2: https://doi.org/10.5281/zenodo.10832823
- Concept DOI: https://doi.org/10.5281/zenodo.10356505
- Dataset title: Systematic review for optimizing sample size in dairy cow
  methane emission studies: a comprehensive methodological approach
- Workbook title: `Enteric CH4 yield and its variability in dairy cows.xlsx`
- Download URL: https://zenodo.org/records/10832823/files/Enteric%20CH4%20yield%20and%20its%20variability%20in%20dairy%20cows.xlsx?download=1

## License And Distribution Status

Zenodo marks the v2 record as open access with license `cc-by-4.0`. The
researcher examples download from Zenodo rather than committing the workbook, so
version and checksum provenance remain explicit.

## Transformations Performed By AgEvidence Examples

- Register the Zenodo workbook as a `SourceRecord`.
- Preserve literature DOI, title, authors, country, breed, measurement method,
  experimental design, DMI, CH4 production, CH4 yield, SEM type, SEM, and SD.
- Record SEM to SD transformation metadata.
- Record inclusion/exclusion decisions for the `SD > 4.8` rule.
- Build one sample-size `ModelRun` over the accepted analysis population.


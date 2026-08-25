# RationSmart

UC Davis describes RationSmart as a feed-ration formulation and methane
accounting system using local feed libraries for smallholder dairy systems in
Africa and Asia.

- UC Davis project page: https://caes.ucdavis.edu/outreach/geo/projects/FDROP
- UC Davis news: https://caes.ucdavis.edu/news/new-mobile-app-seeks-reduce-dairy-methane-emissions-africa-asia
- Example: ../../../examples/researchers/06_rationsmart/

Run:

```bash
python examples/researchers/06_rationsmart/run.py
```

Evidence architecture:

```text
feed sample
  -> wet lab or NIRS analysis
  -> national feed database
  -> ration formulation model
  -> animal and farmer context
  -> recommended ration
  -> predicted production
  -> predicted methane intensity
```

This is an architecture case study, not a country-specific feed-library export.


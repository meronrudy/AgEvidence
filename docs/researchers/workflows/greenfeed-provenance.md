# GreenFeed Provenance

GreenFeed observations are not just gas values. A useful evidence object also
needs the instrument and quality context that made the value possible.

The case study maps:

```text
instrument
  -> calibration record
  -> RFID visit
  -> gas spot sample
  -> cow-period aggregation
  -> treatment mean
```

Run:

```bash
python3 research/studies/kebreab/greenfeed/run.py
```

The bundle uses protocol-level records because the public grape-pomace paper
does not provide row-level GreenFeed exports.

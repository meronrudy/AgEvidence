# Calibration

Calibration connects an instrument observation to the conditions under which it
was produced.

The GreenFeed case study represents:

- instrument identity
- daily standard calibration
- CH4 and CO2 calibration gas
- zero-air N2 standard
- CO2 recovery calibration before each period
- reported recovery metadata

The current branch uses existing calibration-record-shaped objects inside
example bundles. It does not add a new `CalibrationEnvelope` primitive.


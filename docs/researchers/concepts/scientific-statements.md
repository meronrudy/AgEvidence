# Scientific Statements

Scientific statements are represented as example bundle records on this branch,
not as SDK primitives.

Each statement has:

- text
- statement type
- source
- basis object IDs
- limitations
- checksum commitment

This keeps the core SDK API stable while making statements reconstructable from
source records, observations, interventions, transformations, exclusion
decisions, and model runs.

Future promotion into the SDK should wait until at least two materially
different workflows need the same generic interface.


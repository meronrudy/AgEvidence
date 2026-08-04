# baink-agevidence

`baink-agevidence` is the AgEvidence domain adapter for the BAINK workspace.

It validates normalized agricultural evidence payloads before the existing BAINK kernel commits to them. It does not run models, call Python, fetch documents, sign receipts, or perform review decisions.

## Responsibilities

- Validate model execution payloads.
- Validate evidence candidate and gap payloads.
- Validate append-only human review payloads.
- Validate premium artifact assembly and reliance event payloads.
- Report the receipt type and parent requirements expected by the Rails and `ink_receipts` scaffold.

## Non-responsibilities

- Qwen, vLLM, SGLang, FastAPI, HTTP, or GPU execution.
- Scientific approval, VVB determination, AVSA issuance, or legal certification.
- Bundle ZIP assembly or public-key verification, which remain in the existing bundle and verifier crates.

## Scaffold notes

The current crate intentionally performs lightweight structural validation. Production completion should replace the field checks with JSON-schema driven validation while preserving the public API exposed here.

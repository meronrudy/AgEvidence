# AgEvidence Canonical JSON

AgEvidence canonical JSON is **RFC 8785 JSON Canonicalization Scheme (JCS)**.
The protocol identifier is:

```text
agevidence.canonical.jcs.v1
```

Any AgEvidence receipt commitment, bundle commitment, schema commitment, policy
commitment, or cross-language event commitment that claims this canonicalization
identifier MUST hash or sign the exact UTF-8 bytes produced by RFC 8785.

## Normative Rules

- Input MUST be valid JSON and MUST comply with the I-JSON constraints used by
  RFC 8785.
- Output MUST be UTF-8 JSON with no insignificant whitespace.
- Object properties MUST be sorted recursively using RFC 8785 property sorting.
- Array order MUST be preserved.
- Strings MUST preserve Unicode scalar values and use RFC 8785 JSON escaping:
  control characters are escaped, non-control Unicode is emitted as UTF-8, and
  lone surrogates are invalid.
- Numbers MUST be serialized with the ECMAScript number serialization rules
  required by RFC 8785.
- `-0` and `-0.0` MUST serialize as `0`.
- NaN, Infinity, and negative Infinity are unsupported and MUST fail
  canonicalization.
- Integers outside the interoperable JSON number range MUST be represented as
  strings unless a future protocol version explicitly defines another encoding.

## Byte Representation

The canonical byte sequence is the UTF-8 encoding of the JCS output string. No
byte-order mark, trailing newline, or transport-specific framing is included.

For example:

```json
{"a":true,"m":null,"z":1}
```

hashes as exactly those 25 UTF-8 bytes.

## Conformance

Protocol conformance vectors live under:

```text
protocol/conformance/canonicalization/vectors/
```

Ruby, Python, and Rust implementations MUST produce the checked-in
`expected.json` bytes and `expected.sha256` digest for every positive vector,
and MUST reject vectors marked with `expected_error` in `metadata.yaml`.

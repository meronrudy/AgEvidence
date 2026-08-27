# AgEvidence JSON Canonicalization

AgEvidence canonical JSON is the UTF-8 byte representation produced by these
rules:

1. Serialize JSON in compact form with no insignificant whitespace.
2. Sort every object by key recursively before serialization.
3. Preserve array order.
4. Emit strings as UTF-8 JSON strings.
5. Emit booleans, nulls, and numbers using the runtime JSON encoder without
   additional formatting.

The canonical byte sequence is the UTF-8 encoding of that compact JSON string.
Implementations must hash or sign those bytes exactly.

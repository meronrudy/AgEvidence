# Independent Verification Release

The assurance milestone is not that Rust compiles. The milestone is that an
independent party can receive an AgEvidence artifact and determine
cryptographic integrity without trusting AgEvidence infrastructure.

Release checklist:

- publish `agevidence` verifier binaries for Linux and macOS;
- publish SHA-256 checksums for each binary;
- publish an SBOM;
- publish a release signature;
- publish protocol conformance vectors and verifier test bundles;
- verify a Rails-produced artifact from a clean machine;
- repeat verification without network access where the trust policy permits;
- have a second developer independently implement canonicalization and hash
  verification from `protocol/canonicalization.md` and match the same bytes.

Verifier command:

```bash
agevidence verify bundle.zip --json
```

Exit codes:

```text
0 verified
1 cryptographically invalid
2 indeterminate
3 malformed input
4 unsupported protocol
5 verifier/system failure
```

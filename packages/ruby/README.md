# AgEvidence Ruby SDK

The Ruby SDK targets the active Rails `/api/v1` contract in
`../../protocol/openapi/agevidence-v1.yaml`.

It provides:

- HTTP resource facades for active `/api/v1` resources;
- integration-friendly configuration;
- local verifier delegation through `agevidence verify <bundle> --json`.

It does not issue receipts, sign receipts, compute receipt commitments, or
verify receipt cryptography in Ruby.

## Configure

```ruby
client = AgEvidence::Client.new(
  base_url: "http://localhost:3000",
  api_token: ENV["AGEVIDENCE_API_TOKEN"]
)
```

## Use

```ruby
artifact = client.artifacts.get("RA-AU-000184")
result = AgEvidence::Verifier.new.verify_bundle("bundle.zip")
```

`AGEVIDENCE_VERIFIER_COMMAND` may be set to the verifier executable path.

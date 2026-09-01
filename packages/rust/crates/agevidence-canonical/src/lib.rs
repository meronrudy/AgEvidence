#![forbid(unsafe_code)]
#![deny(missing_docs)]
#![deny(unused_must_use)]
#![deny(clippy::unwrap_used)]
#![deny(clippy::expect_used)]
#![deny(clippy::panic)]

//! Deterministic JSON canonicalization for the AgEvidence verifier core.

use serde::Serialize;
use serde_json::Value;
use thiserror::Error;

/// Error during canonicalization.
#[derive(Debug, Error)]
pub enum CanonicalError {
    /// Serialization error.
    #[error("serialization error: {0}")]
    Serialization(#[from] serde_json::Error),
}

/// Canonical JSON representation.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CanonicalJson {
    bytes: Vec<u8>,
}

impl CanonicalJson {
    /// Get the canonical bytes.
    pub fn as_bytes(&self) -> &[u8] {
        &self.bytes
    }

    /// Get the canonical string.
    pub fn as_str(&self) -> Result<&str, std::str::Utf8Error> {
        std::str::from_utf8(&self.bytes)
    }
}

/// Canonicalize a serializable value.
pub fn canonicalize<T: Serialize>(value: &T) -> Result<CanonicalJson, CanonicalError> {
    let value = serde_json::to_value(value)?;
    let mut bytes = Vec::new();
    write_canonical_value(&value, &mut bytes)?;
    Ok(CanonicalJson { bytes })
}

fn write_canonical_value(value: &Value, bytes: &mut Vec<u8>) -> Result<(), serde_json::Error> {
    match value {
        Value::Null | Value::Bool(_) | Value::Number(_) | Value::String(_) => {
            serde_json::to_writer(bytes, value)?;
        }
        Value::Array(items) => {
            bytes.push(b'[');
            for (index, item) in items.iter().enumerate() {
                if index > 0 {
                    bytes.push(b',');
                }
                write_canonical_value(item, bytes)?;
            }
            bytes.push(b']');
        }
        Value::Object(map) => {
            bytes.push(b'{');
            let mut keys = map.keys().collect::<Vec<_>>();
            keys.sort();
            for (index, key) in keys.iter().enumerate() {
                if index > 0 {
                    bytes.push(b',');
                }
                serde_json::to_writer(&mut *bytes, key)?;
                bytes.push(b':');
                if let Some(nested) = map.get(*key) {
                    write_canonical_value(nested, bytes)?;
                }
            }
            bytes.push(b'}');
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn recursively_sorts_object_keys_without_whitespace() {
        let value = json!({
            "z": 1,
            "a": {
                "b": [3, {"y": true, "x": null}],
                "a": "first"
            }
        });

        let canonical = match canonicalize(&value) {
            Ok(value) => value,
            Err(error) => panic!("{}", error),
        };
        assert_eq!(
            canonical.as_bytes(),
            br#"{"a":{"a":"first","b":[3,{"x":null,"y":true}]},"z":1}"#
        );
    }

    #[test]
    fn matches_shared_canonicalization_fixture() {
        let value: Value = match serde_json::from_str(include_str!(
            "../../../../../protocol/conformance/fixtures/canonicalization/input.json"
        )) {
            Ok(value) => value,
            Err(error) => panic!("{}", error),
        };
        let expected = match include_bytes!(
            "../../../../../protocol/conformance/fixtures/canonicalization/expected.json"
        )
        .strip_suffix(b"\n")
        {
            Some(bytes) => bytes,
            None => include_bytes!(
                "../../../../../protocol/conformance/fixtures/canonicalization/expected.json"
            ),
        };

        let canonical = match canonicalize(&value) {
            Ok(value) => value,
            Err(error) => panic!("{}", error),
        };

        assert_eq!(canonical.as_bytes(), expected);
    }
}

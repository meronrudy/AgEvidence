use crate::error::{AgEvidenceError, Result};
use serde::Serialize;
use serde_json::Value;

/// RFC 8785/JCS canonical JSON representation.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CanonicalJson {
    bytes: Vec<u8>,
}

impl CanonicalJson {
    /// Canonical UTF-8 bytes.
    pub fn as_bytes(&self) -> &[u8] {
        &self.bytes
    }

    /// Canonical JSON string.
    pub fn as_str(&self) -> Result<&str> {
        std::str::from_utf8(&self.bytes)
            .map_err(|error| AgEvidenceError::Canonical(error.to_string()))
    }
}

/// Canonicalize any serializable value using RFC 8785/JCS.
pub fn canonicalize<T: Serialize>(value: &T) -> Result<CanonicalJson> {
    let bytes = serde_json_canonicalizer::to_vec(value)
        .map_err(|error| AgEvidenceError::Canonical(error.to_string()))?;
    Ok(CanonicalJson { bytes })
}

/// Canonicalize a JSON value using RFC 8785/JCS.
pub fn canonicalize_value(value: &Value) -> Result<CanonicalJson> {
    canonicalize(value)
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;
    use std::fs;
    use std::path::Path;

    #[test]
    fn recursively_sorts_object_keys_without_whitespace() {
        let value = json!({
            "z": 1,
            "a": {
                "b": [3, {"y": true, "x": null}],
                "a": "first"
            }
        });

        let canonical = canonicalize(&value).unwrap();
        assert_eq!(
            canonical.as_bytes(),
            br#"{"a":{"a":"first","b":[3,{"x":null,"y":true}]},"z":1}"#
        );
    }

    #[test]
    fn matches_protocol_vectors() {
        let root = Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("../../../../protocol/conformance/canonicalization/vectors");
        for entry in fs::read_dir(root).unwrap() {
            let entry = entry.unwrap();
            if !entry.file_type().unwrap().is_dir() {
                continue;
            }
            let vector = entry.path();
            let metadata = fs::read_to_string(vector.join("metadata.yaml")).unwrap();
            let input = fs::read_to_string(vector.join("input.json")).unwrap();
            if metadata.contains("expected_error:") {
                assert!(
                    serde_json::from_str::<Value>(&input)
                        .and_then(|value| serde_json_canonicalizer::to_string(&value))
                        .is_err(),
                    "{} should fail",
                    vector.display()
                );
                continue;
            }
            let value: Value = serde_json::from_str(&input).unwrap();
            let mut expected = fs::read(vector.join("expected.json")).unwrap();
            if expected.ends_with(b"\n") {
                expected.pop();
            }
            let canonical = canonicalize_value(&value).unwrap();
            assert_eq!(canonical.as_bytes(), expected, "{}", vector.display());
        }
    }
}

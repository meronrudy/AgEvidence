use crate::canonical::canonicalize_value;
use crate::crypto::{digest_matches, sha256_typed};
use crate::error::{AgEvidenceError, Result};
use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};

/// Signature information extracted from a receipt.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SignatureInfo {
    /// Signing algorithm.
    pub algorithm: String,
    /// Signer key identifier.
    pub key_id: String,
    /// Unpadded base64url signature bytes.
    pub value: String,
}

/// Receipt metadata extracted without committing to a concrete receipt schema.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ReceiptMetadata {
    /// Receipt schema/version identifier.
    pub receipt_version: Option<String>,
    /// Payload schema identifier.
    pub schema_id: Option<String>,
    /// Receipt commitment.
    pub receipt_commitment: Option<String>,
    /// Body digest or payload digest.
    pub body_digest: Option<String>,
    /// Signature block.
    pub signature: Option<SignatureInfo>,
    /// Signer key identifier from legacy receipt fields.
    pub signer_key_id: Option<String>,
}

/// Extract schema-neutral receipt metadata.
pub fn receipt_metadata(receipt: &Value) -> Result<ReceiptMetadata> {
    let object = receipt
        .as_object()
        .ok_or_else(|| AgEvidenceError::Malformed("receipt must be a JSON object".to_owned()))?;
    let signature = match object.get("signature") {
        Some(Value::Null) | None => None,
        Some(value) => Some(parse_signature(value)?),
    };
    Ok(ReceiptMetadata {
        receipt_version: string_at(object, "receipt_version")
            .or_else(|| string_at(object, "version")),
        schema_id: string_at(object, "schema_id").or_else(|| string_at(object, "schema")),
        receipt_commitment: string_at(object, "receipt_commitment")
            .or_else(|| string_at(object, "commitment")),
        body_digest: string_at(object, "body_digest").or_else(|| string_at(object, "payload_digest")),
        signature,
        signer_key_id: string_at(object, "signer_key_id"),
    })
}

/// Compute the canonical signing bytes for a receipt.
pub fn receipt_signing_bytes(receipt: &Value) -> Result<Vec<u8>> {
    let payload = receipt_signing_payload(receipt)?;
    Ok(canonicalize_value(&payload)?.as_bytes().to_vec())
}

/// Compute `receipt:sha256:<digest>` for a receipt.
pub fn receipt_commitment(receipt: &Value) -> Result<String> {
    Ok(sha256_typed("receipt", &receipt_signing_bytes(receipt)?))
}

/// Verify a receipt commitment if one is declared.
pub fn receipt_commitment_matches(receipt: &Value, declared: &str) -> Result<bool> {
    Ok(digest_matches(
        declared,
        "receipt",
        &receipt_signing_bytes(receipt)?,
        true,
    ))
}

/// Verify the body digest against the receipt `payload` field.
pub fn body_digest_matches(receipt: &Value, declared: &str) -> Result<Option<bool>> {
    let Some(payload) = receipt.get("payload") else {
        return Ok(None);
    };
    Ok(Some(digest_matches(
        declared,
        "receipt",
        canonicalize_value(payload)?.as_bytes(),
        true,
    )))
}

/// Verify a legacy `record_hash` object against a record.
pub fn legacy_record_hash_matches(receipt: &Value, record: &Value) -> Result<Option<bool>> {
    let Some(record_hash) = receipt.get("record_hash") else {
        return Ok(None);
    };
    let declared = if let Some(value) = record_hash.as_str() {
        value.to_owned()
    } else {
        let algorithm = record_hash
            .get("algorithm")
            .and_then(Value::as_str)
            .unwrap_or("sha256");
        let value = record_hash
            .get("value")
            .and_then(Value::as_str)
            .ok_or_else(|| AgEvidenceError::Malformed("record_hash.value missing".to_owned()))?;
        if algorithm != "sha256" {
            return Err(AgEvidenceError::UnsupportedProtocol(format!(
                "unsupported record hash algorithm: {algorithm}"
            )));
        }
        format!("sha256:{value}")
    };
    Ok(Some(digest_matches(
        &declared,
        "app",
        canonicalize_value(record)?.as_bytes(),
        true,
    )))
}

fn receipt_signing_payload(receipt: &Value) -> Result<Value> {
    let mut value = receipt
        .as_object()
        .ok_or_else(|| AgEvidenceError::Malformed("receipt must be a JSON object".to_owned()))?
        .clone();
    value.remove("receipt_commitment");
    value.remove("commitment");
    if let Some(Value::Object(signature)) = value.get_mut("signature") {
        signature.remove("value");
    }
    Ok(Value::Object(value))
}

fn parse_signature(value: &Value) -> Result<SignatureInfo> {
    let object = value
        .as_object()
        .ok_or_else(|| AgEvidenceError::Malformed("signature must be an object".to_owned()))?;
    let algorithm = string_at(object, "algorithm")
        .ok_or_else(|| AgEvidenceError::Malformed("signature.algorithm missing".to_owned()))?;
    let key_id = string_at(object, "key_id")
        .ok_or_else(|| AgEvidenceError::Malformed("signature.key_id missing".to_owned()))?;
    let value = string_at(object, "value")
        .ok_or_else(|| AgEvidenceError::Malformed("signature.value missing".to_owned()))?;
    Ok(SignatureInfo {
        algorithm,
        key_id,
        value,
    })
}

fn string_at(object: &Map<String, Value>, key: &str) -> Option<String> {
    object
        .get(key)
        .and_then(Value::as_str)
        .map(ToOwned::to_owned)
}

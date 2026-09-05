use crate::canonical::canonicalize_value;
use crate::crypto::{sha256_hex, sha256_typed, PublicKey};
use crate::error::{AgEvidenceError, Result};
use crate::policy::{RevocationSnapshot, TrustPolicy};
use serde::{Deserialize, Serialize};
use serde_json::{json, Map, Value};
use std::collections::BTreeMap;
use std::fs::File;
use std::io::Read;
use std::path::{Path, PathBuf};
use zip::ZipArchive;

/// Loaded bundle format.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum BundleFormat {
    /// JSON bundle document.
    Json,
    /// ZIP bundle archive.
    Zip,
}

/// Bundle material extracted for verification.
#[derive(Debug, Clone)]
pub struct LoadedBundle {
    /// Original path.
    pub path: PathBuf,
    /// Source format.
    pub format: BundleFormat,
    /// Manifest or JSON root document.
    pub manifest: Value,
    /// Record objects.
    pub records: Vec<Value>,
    /// Receipt objects.
    pub receipts: Vec<Value>,
    /// Public keys available for local signature verification.
    pub keys: Vec<PublicKey>,
    /// Trust policy, if bundled.
    pub trust_policy: Option<TrustPolicy>,
    /// Revocation snapshot.
    pub revocation: RevocationSnapshot,
    /// Declared bundle commitment.
    pub declared_bundle_commitment: Option<String>,
    /// Computed bundle commitment.
    pub computed_bundle_commitment: String,
    /// File-level commitments for ZIP bundles.
    pub file_commitments: Vec<FileCommitment>,
}

/// ZIP entry commitment used to compute the bundle commitment.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct FileCommitment {
    /// ZIP path.
    pub path: String,
    /// SHA-256 over the entry commitment bytes.
    pub sha256: String,
}

/// Load a JSON or ZIP bundle from disk.
pub fn load_bundle(path: impl AsRef<Path>) -> Result<LoadedBundle> {
    let path = path.as_ref();
    let mut file = File::open(path)?;
    let mut prefix = [0_u8; 4];
    let read = file.read(&mut prefix)?;
    drop(file);
    if read >= 4 && prefix == [0x50, 0x4b, 0x03, 0x04] {
        load_zip_bundle(path)
    } else {
        load_json_bundle(path)
    }
}

/// Compute a JSON bundle commitment after removing self-referential fields.
pub fn bundle_commitment_for_json_value(value: &Value) -> Result<String> {
    let stripped = strip_bundle_commitment(value);
    Ok(sha256_typed(
        "bundle",
        canonicalize_value(&stripped)?.as_bytes(),
    ))
}

fn load_json_bundle(path: &Path) -> Result<LoadedBundle> {
    let bytes = std::fs::read(path)?;
    let manifest: Value = serde_json::from_slice(&bytes)?;
    let records = collect_inline_or_named_values(&manifest, "record", "records")?;
    let receipts = collect_inline_or_named_values(&manifest, "receipt", "receipts")?;
    let keys = collect_keys_from_value(manifest.get("keys"))?;
    let trust_policy = manifest
        .get("trust_policy")
        .filter(|value| value.is_object())
        .map(|value| serde_json::from_value(value.clone()))
        .transpose()?;
    let revocation = manifest
        .get("revocation")
        .or_else(|| manifest.get("revocation_snapshot"))
        .filter(|value| value.is_object())
        .map(|value| serde_json::from_value(value.clone()))
        .transpose()?
        .unwrap_or_default();
    let declared_bundle_commitment = string_field(&manifest, "bundle_commitment")
        .or_else(|| string_field(&manifest, "commitment"));
    let computed_bundle_commitment = bundle_commitment_for_json_value(&manifest)?;
    Ok(LoadedBundle {
        path: path.to_path_buf(),
        format: BundleFormat::Json,
        manifest,
        records,
        receipts,
        keys,
        trust_policy,
        revocation,
        declared_bundle_commitment,
        computed_bundle_commitment,
        file_commitments: vec![],
    })
}

fn load_zip_bundle(path: &Path) -> Result<LoadedBundle> {
    let file = File::open(path)?;
    let mut archive = ZipArchive::new(file)?;
    let mut entries = BTreeMap::<String, Vec<u8>>::new();
    for index in 0..archive.len() {
        let mut file = archive.by_index(index)?;
        if file.is_dir() {
            continue;
        }
        let name = file.name().to_owned();
        let mut bytes = Vec::new();
        file.read_to_end(&mut bytes)?;
        entries.insert(name, bytes);
    }
    let manifest = match entries.get("manifest.json") {
        Some(bytes) => serde_json::from_slice(bytes)?,
        None => json!({ "contract_version": "agevidence.bundle.v1" }),
    };
    let records = collect_zip_values(&manifest, &entries, "record", "records", "records/")?;
    let receipts = collect_zip_values(&manifest, &entries, "receipt", "receipts", "receipts/")?;
    let keys = if let Some(value) = manifest.get("keys").filter(|value| !value.is_string()) {
        collect_keys_from_value(Some(value))?
    } else if let Some(path) = string_field(&manifest, "keys") {
        collect_keys_from_bytes(entries.get(&path), &path)?
    } else {
        collect_keys_from_bytes(entries.get("trust/keys.json"), "trust/keys.json")?
    };
    let trust_policy = if let Some(value) = manifest
        .get("trust_policy")
        .filter(|value| value.is_object())
    {
        Some(serde_json::from_value(value.clone())?)
    } else if let Some(path) = string_field(&manifest, "trust_policy") {
        parse_optional_json_object::<TrustPolicy>(&entries, &path)?
    } else {
        parse_optional_json_object::<TrustPolicy>(&entries, "trust/trust-policy.json")?
    };
    let revocation = if let Some(value) = manifest
        .get("revocation")
        .or_else(|| manifest.get("revocation_snapshot"))
        .filter(|value| value.is_object())
    {
        serde_json::from_value(value.clone())?
    } else if let Some(path) = string_field(&manifest, "revocation") {
        parse_optional_json_object::<RevocationSnapshot>(&entries, &path)?.unwrap_or_default()
    } else {
        parse_optional_json_object::<RevocationSnapshot>(&entries, "trust/revocation-snapshot.json")?
            .unwrap_or_default()
    };
    let declared_bundle_commitment = string_field(&manifest, "bundle_commitment")
        .or_else(|| string_field(&manifest, "commitment"));
    let file_commitments = zip_file_commitments(&entries)?;
    let commitment_manifest = json!({ "files": file_commitments });
    let computed_bundle_commitment = sha256_typed(
        "bundle",
        canonicalize_value(&commitment_manifest)?.as_bytes(),
    );
    Ok(LoadedBundle {
        path: path.to_path_buf(),
        format: BundleFormat::Zip,
        manifest,
        records,
        receipts,
        keys,
        trust_policy,
        revocation,
        declared_bundle_commitment,
        computed_bundle_commitment,
        file_commitments,
    })
}

fn collect_inline_or_named_values(
    root: &Value,
    singular: &str,
    plural: &str,
) -> Result<Vec<Value>> {
    let mut values = Vec::new();
    if let Some(value) = root.get(singular) {
        if !value.is_string() {
            values.push(value.clone());
        }
    }
    if let Some(Value::Array(items)) = root.get(plural) {
        for item in items {
            if !item.is_string() {
                values.push(item.clone());
            }
        }
    }
    Ok(values)
}

fn collect_zip_values(
    manifest: &Value,
    entries: &BTreeMap<String, Vec<u8>>,
    singular: &str,
    plural: &str,
    fallback_prefix: &str,
) -> Result<Vec<Value>> {
    let mut values = Vec::new();
    if let Some(path) = string_field(manifest, singular) {
        values.push(parse_required_entry(entries, &path)?);
    } else if let Some(value) = manifest.get(singular).filter(|value| value.is_object()) {
        values.push(value.clone());
    }
    if let Some(Value::Array(items)) = manifest.get(plural) {
        for item in items {
            if let Some(path) = item.as_str().or_else(|| item.get("path").and_then(Value::as_str)) {
                values.push(parse_required_entry(entries, path)?);
            } else if item.is_object() {
                values.push(item.clone());
            }
        }
    }
    if values.is_empty() {
        for (name, bytes) in entries {
            if name.starts_with(fallback_prefix) && name.ends_with(".json") {
                values.push(serde_json::from_slice(bytes)?);
            }
        }
    }
    Ok(values)
}

fn collect_keys_from_value(value: Option<&Value>) -> Result<Vec<PublicKey>> {
    let Some(value) = value else {
        return Ok(vec![]);
    };
    if let Some(keys) = value.as_array() {
        return keys
            .iter()
            .cloned()
            .map(serde_json::from_value)
            .collect::<std::result::Result<Vec<_>, _>>()
            .map_err(AgEvidenceError::from);
    }
    if let Some(keys) = value.get("keys").and_then(Value::as_array) {
        return keys
            .iter()
            .cloned()
            .map(serde_json::from_value)
            .collect::<std::result::Result<Vec<_>, _>>()
            .map_err(AgEvidenceError::from);
    }
    Err(AgEvidenceError::Malformed(
        "keys must be an array or object with keys array".to_owned(),
    ))
}

fn collect_keys_from_bytes(bytes: Option<&Vec<u8>>, label: &str) -> Result<Vec<PublicKey>> {
    let Some(bytes) = bytes else {
        return Ok(vec![]);
    };
    let value: Value = serde_json::from_slice(bytes)
        .map_err(|error| AgEvidenceError::Malformed(format!("{label}: {error}")))?;
    collect_keys_from_value(Some(&value))
}

fn parse_optional_json_object<T: serde::de::DeserializeOwned>(
    entries: &BTreeMap<String, Vec<u8>>,
    path: &str,
) -> Result<Option<T>> {
    let Some(bytes) = entries.get(path) else {
        return Ok(None);
    };
    Ok(Some(serde_json::from_slice(bytes)?))
}

fn parse_required_entry(entries: &BTreeMap<String, Vec<u8>>, path: &str) -> Result<Value> {
    let bytes = entries
        .get(path)
        .ok_or_else(|| AgEvidenceError::Malformed(format!("bundle entry missing: {path}")))?;
    Ok(serde_json::from_slice(bytes)?)
}

fn zip_file_commitments(entries: &BTreeMap<String, Vec<u8>>) -> Result<Vec<FileCommitment>> {
    let mut commitments = Vec::new();
    for (path, bytes) in entries {
        if is_generated_or_non_trust_entry(path) {
            continue;
        }
        let commitment_bytes = if path == "manifest.json" {
            let value: Value = serde_json::from_slice(bytes)?;
            canonicalize_value(&strip_bundle_commitment(&value))?
                .as_bytes()
                .to_vec()
        } else {
            bytes.clone()
        };
        commitments.push(FileCommitment {
            path: path.clone(),
            sha256: sha256_hex(&commitment_bytes),
        });
    }
    Ok(commitments)
}

fn is_generated_or_non_trust_entry(path: &str) -> bool {
    path == "README.txt"
        || path == "verification-report.json"
        || path.starts_with("reports/")
        || path.ends_with('/')
}

fn strip_bundle_commitment(value: &Value) -> Value {
    if let Value::Object(object) = value {
        let mut stripped = Map::new();
        for (key, value) in object {
            if key == "bundle_commitment" || key == "commitment" {
                continue;
            }
            stripped.insert(key.clone(), value.clone());
        }
        Value::Object(stripped)
    } else {
        value.clone()
    }
}

fn string_field(value: &Value, key: &str) -> Option<String> {
    value
        .get(key)
        .and_then(Value::as_str)
        .map(ToOwned::to_owned)
}

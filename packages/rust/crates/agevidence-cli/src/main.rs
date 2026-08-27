use anyhow::{Context, Result};
use baink_agevidence::{validate_payload, AgEvidenceSchema};
use baink_bundle::{EvidenceBundle, InkReceipt};
use baink_canonical::canonicalize;
use baink_core::{HashAlgorithm, IssuerId, VerificationStatus};
use baink_crypto::hash_bytes;
use baink_schema::DecisionRecord;
use baink_verify::verify_bundle;
use clap::{Parser, Subcommand};
use serde_json::{json, Value};
use std::fs;
use std::path::PathBuf;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Initialize a new BAINK workspace
    Init,
    /// Hash a decision record
    Hash {
        /// Path to the record JSON file
        record: PathBuf,
    },
    /// Generate a receipt for a decision record
    Receipt {
        /// Path to the record JSON file
        record: PathBuf,
    },
    /// Issue a generic receipt projection for any JSON payload
    Issue {
        /// Path to the payload JSON file
        payload: PathBuf,
        /// Issuer identifier
        #[arg(long)]
        issuer: String,
        /// Receipt type
        #[arg(long = "receipt-type")]
        receipt_type: String,
        /// Schema identifier
        #[arg(long)]
        schema: Option<String>,
        /// Lifecycle state
        #[arg(long, default_value = "observed")]
        lifecycle: String,
        /// AVSA identifier
        #[arg(long)]
        avsa: Option<String>,
        /// Signer key identifier
        #[arg(long)]
        signer: Option<String>,
        /// Parent digest
        #[arg(long = "parent")]
        parents: Vec<String>,
    },
    /// Create an evidence bundle
    Bundle {
        /// Path to the record JSON file
        record: PathBuf,
        /// Output path for the bundle
        #[arg(long)]
        out: PathBuf,
    },
    /// Verify an evidence bundle
    Verify {
        /// Path to the bundle JSON file
        bundle: PathBuf,
        /// Emit machine-readable JSON report
        #[arg(long)]
        json: bool,
    },
    /// Export a generic receipt graph from a JSON receipt projection list
    Graph {
        /// Path to a JSON file with a receipts array
        payload: PathBuf,
    },
    /// Generate a methodology migration delta receipt projection
    Migrate {
        /// Path to the AVSA/migration JSON payload
        payload: PathBuf,
        /// Old methodology label
        #[arg(long = "old-methodology")]
        old_methodology: String,
        /// New methodology label
        #[arg(long = "new-methodology")]
        new_methodology: String,
    },
    /// Generate a verification report
    Report {
        /// Path to the bundle JSON file
        bundle: PathBuf,
        /// Output format (e.g., markdown)
        #[arg(long, default_value = "markdown")]
        format: String,
    },
    /// Validate and issue AgEvidence domain payloads
    Agevidence {
        /// AgEvidence subcommand
        #[command(subcommand)]
        command: AgevidenceCommands,
    },
}

#[derive(Subcommand)]
enum AgevidenceCommands {
    /// Validate an AgEvidence payload and emit JSON
    Validate {
        /// AgEvidence schema name or schema id
        #[arg(long)]
        schema: String,
        /// Path to the payload JSON file
        payload: PathBuf,
    },
    /// Validate and issue an AgEvidence receipt projection
    Issue {
        /// AgEvidence schema name or schema id
        #[arg(long)]
        schema: String,
        /// Path to the payload JSON file
        payload: PathBuf,
        /// Issuer identifier
        #[arg(long)]
        issuer: String,
        /// Signer key identifier
        #[arg(long)]
        signer: String,
        /// Lifecycle state
        #[arg(long, default_value = "sealed")]
        lifecycle: String,
        /// AVSA identifier
        #[arg(long)]
        avsa: Option<String>,
        /// Parent digest
        #[arg(long = "parent")]
        parents: Vec<String>,
    },
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Commands::Init => {
            println!("Initialized empty BAINK workspace.");
        }
        Commands::Hash { record } => {
            let record_str = fs::read_to_string(&record).context("Failed to read record file")?;
            let record: DecisionRecord =
                serde_json::from_str(&record_str).context("Failed to parse record JSON")?;
            let canonical = canonicalize(&record).context("Failed to canonicalize record")?;
            let hash = hash_bytes(canonical.as_bytes(), HashAlgorithm::Sha256);
            println!("sha256:{}", hash.value);
        }
        Commands::Receipt { record } => {
            let record_str = fs::read_to_string(&record).context("Failed to read record file")?;
            let record: DecisionRecord =
                serde_json::from_str(&record_str).context("Failed to parse record JSON")?;
            let canonical = canonicalize(&record).context("Failed to canonicalize record")?;
            let record_hash = hash_bytes(canonical.as_bytes(), HashAlgorithm::Sha256);
            // Dummy bundle hash for now
            let bundle_hash = hash_bytes(b"dummy_bundle", HashAlgorithm::Sha256);
            let receipt = InkReceipt::issue(record_hash, bundle_hash, IssuerId("local".into()))
                .map_err(|e| anyhow::anyhow!(e))?;
            let receipt_json =
                serde_json::to_string_pretty(&receipt).context("Failed to serialize receipt")?;
            println!("{}", receipt_json);
        }
        Commands::Issue {
            payload,
            issuer,
            receipt_type,
            schema,
            lifecycle,
            avsa,
            signer,
            parents,
        } => {
            let payload_str =
                fs::read_to_string(&payload).context("Failed to read payload file")?;
            let value: Value =
                serde_json::from_str(&payload_str).context("Failed to parse payload JSON")?;
            let receipt = issue_projection(
                value,
                issuer,
                receipt_type,
                schema,
                lifecycle,
                avsa,
                signer,
                parents,
            )
            .context("Failed to issue receipt projection")?;
            println!("{}", serde_json::to_string_pretty(&receipt)?);
        }
        Commands::Bundle { record, out } => {
            let record_str = fs::read_to_string(&record).context("Failed to read record file")?;
            let record: DecisionRecord =
                serde_json::from_str(&record_str).context("Failed to parse record JSON")?;
            let canonical = canonicalize(&record).context("Failed to canonicalize record")?;
            let record_hash = hash_bytes(canonical.as_bytes(), HashAlgorithm::Sha256);
            let bundle_hash = hash_bytes(b"dummy_bundle", HashAlgorithm::Sha256);
            let receipt = InkReceipt::issue(record_hash, bundle_hash, IssuerId("local".into()))
                .map_err(|e| anyhow::anyhow!(e))?;
            let bundle = EvidenceBundle::new(record, receipt).map_err(|e| anyhow::anyhow!(e))?;
            let bundle_json =
                serde_json::to_string_pretty(&bundle).context("Failed to serialize bundle")?;
            fs::write(&out, bundle_json).context("Failed to write bundle file")?;
            println!("Bundle written to {}", out.display());
        }
        Commands::Verify { bundle, json } => {
            let bundle_str = fs::read_to_string(&bundle).context("Failed to read bundle file")?;
            let bundle: EvidenceBundle =
                serde_json::from_str(&bundle_str).context("Failed to parse bundle JSON")?;
            let report = verify_bundle(&bundle).map_err(|e| anyhow::anyhow!(e))?;
            if json {
                println!("{}", serde_json::to_string_pretty(&report)?);
            } else if report.status == VerificationStatus::Pass {
                println!("Verification PASS");
            } else {
                println!("Verification {:?}", report.status);
            }
        }
        Commands::Graph { payload } => {
            let payload_str =
                fs::read_to_string(&payload).context("Failed to read graph payload")?;
            let value: Value =
                serde_json::from_str(&payload_str).context("Failed to parse graph payload JSON")?;
            let graph = graph_projection(&value);
            println!("{}", serde_json::to_string_pretty(&graph)?);
        }
        Commands::Migrate {
            payload,
            old_methodology,
            new_methodology,
        } => {
            let payload_str =
                fs::read_to_string(&payload).context("Failed to read migration payload")?;
            let value: Value =
                serde_json::from_str(&payload_str).context("Failed to parse migration JSON")?;
            let receipt = issue_projection(
                json!({
                    "payload": value,
                    "old_methodology": old_methodology,
                    "new_methodology": new_methodology,
                }),
                "Athian Methodology Migration".into(),
                "methodology_delta_receipt".into(),
                Some("athian.methodology_delta.v1".into()),
                "sealed".into(),
                None,
                Some("did:key:athian-methodology-demo".into()),
                vec![],
            )
            .context("Failed to generate migration receipt")?;
            println!(
                "{}",
                serde_json::to_string_pretty(&json!({
                    "receipt": receipt,
                    "status": "impact_review",
                    "old_methodology": old_methodology,
                    "new_methodology": new_methodology,
                }))?
            );
        }
        Commands::Report { bundle, format } => {
            let bundle_str = fs::read_to_string(&bundle).context("Failed to read bundle file")?;
            let bundle: EvidenceBundle =
                serde_json::from_str(&bundle_str).context("Failed to parse bundle JSON")?;
            let report = verify_bundle(&bundle).map_err(|e| anyhow::anyhow!(e))?;

            if format == "markdown" {
                println!("BAINK VERIFY REPORT\n");
                println!("Status: {:?}\n", report.status);
                println!("Checks:");
                for check in report.checks {
                    let status_str = match check.status {
                        VerificationStatus::Pass => "PASS",
                        VerificationStatus::Warning => "WARNING",
                        VerificationStatus::Fail => "FAIL",
                        VerificationStatus::Skipped => "SKIPPED",
                    };
                    println!("[{}] {}", status_str, check.name);
                }
                println!("\nRecord Hash:");
                if let Some(hash) = report.record_hash {
                    println!("sha256:{}", hash.value);
                }
                println!("\nBundle Hash:");
                if let Some(hash) = report.bundle_hash {
                    println!("sha256:{}", hash.value);
                }
            } else {
                println!("Unsupported format: {}", format);
            }
        }
        Commands::Agevidence { command } => match command {
            AgevidenceCommands::Validate { schema, payload } => {
                let schema = AgEvidenceSchema::parse(&schema)
                    .map_err(|error| anyhow::anyhow!(error.to_string()))?;
                let payload = read_json_payload(&payload).context("Failed to read payload")?;
                let validated = validate_payload(schema, &payload)
                    .map_err(|error| anyhow::anyhow!(error.to_string()))?;
                println!("{}", serde_json::to_string_pretty(&validated)?);
            }
            AgevidenceCommands::Issue {
                schema,
                payload,
                issuer,
                signer,
                lifecycle,
                avsa,
                parents,
            } => {
                let schema = AgEvidenceSchema::parse(&schema)
                    .map_err(|error| anyhow::anyhow!(error.to_string()))?;
                if schema.requires_parent() && parents.is_empty() {
                    return Err(anyhow::anyhow!(
                        "schema {} requires at least one parent",
                        schema.schema_id()
                    ));
                }
                let payload = read_json_payload(&payload).context("Failed to read payload")?;
                let _validated = validate_payload(schema, &payload)
                    .map_err(|error| anyhow::anyhow!(error.to_string()))?;
                let receipt = issue_projection(
                    payload,
                    issuer,
                    schema.receipt_type().to_owned(),
                    Some(schema.schema_id().to_owned()),
                    lifecycle,
                    avsa,
                    Some(signer),
                    parents,
                )
                .context("Failed to issue AgEvidence receipt projection")?;
                println!("{}", serde_json::to_string_pretty(&receipt)?);
            }
        },
    }

    Ok(())
}

fn read_json_payload(path: &PathBuf) -> Result<Value> {
    let payload_str = fs::read_to_string(path).context("Failed to read JSON payload file")?;
    serde_json::from_str(&payload_str).context("Failed to parse JSON payload")
}

fn issue_projection(
    payload: Value,
    issuer: String,
    receipt_type: String,
    schema: Option<String>,
    lifecycle: String,
    avsa: Option<String>,
    signer: Option<String>,
    parents: Vec<String>,
) -> Result<Value> {
    let envelope = json!({
        "payload": payload,
        "issuer": issuer,
        "receipt_type": receipt_type,
        "schema": schema,
        "lifecycle": lifecycle,
        "avsa": avsa,
        "signer": signer,
        "parents": parents,
    });
    let canonical = canonicalize(&envelope).context("Failed to canonicalize payload")?;
    let body_hash = hash_bytes(canonical.as_bytes(), HashAlgorithm::Sha256);
    let schema_id = schema.unwrap_or_else(|| format!("athian.{}.v1", receipt_type));
    let schema_hash = hash_bytes(schema_id.as_bytes(), HashAlgorithm::Sha256);
    let evidence_hash = hash_bytes(
        format!("evidence:{}", body_hash.value).as_bytes(),
        HashAlgorithm::Sha256,
    );
    let policy_hash = hash_bytes(b"athian.ink.trust-policy.demo.v1", HashAlgorithm::Sha256);
    let trace_hash = hash_bytes(
        format!(
            "trace:{}:{}",
            avsa.unwrap_or_else(|| receipt_type.clone()),
            body_hash.value
        )
        .as_bytes(),
        HashAlgorithm::Sha256,
    );
    let signer_key_id = signer.unwrap_or_else(|| "did:key:athian-demo".into());

    Ok(json!({
        "receipt_version": "athian.ink.receipt.v1",
        "receipt_type": receipt_type,
        "schema_id": schema_id,
        "schema_digest": schema_hash.value,
        "lifecycle_state": lifecycle,
        "issuer": issuer,
        "signer_key_id": signer_key_id.clone(),
        "parent_digests": parents,
        "body_digest": body_hash.value,
        "evidence_commitment": evidence_hash.value,
        "policy_commitment": policy_hash.value,
        "trace_commitment": trace_hash.value,
        "canonical_encoding_hex": hex_encode(canonical.as_bytes()),
        "public_key": format!("{}#public-key", signer_key_id),
        "trust_policy": "athian.ink.trust-policy.demo.v1",
        "signature": null,
        "integrity_status": "valid"
    }))
}

fn graph_projection(value: &Value) -> Value {
    let receipts = value
        .get("receipts")
        .and_then(Value::as_array)
        .or_else(|| value.as_array())
        .cloned()
        .unwrap_or_default();

    let nodes: Vec<Value> = receipts
        .iter()
        .map(|receipt| {
            json!({
                "id": receipt.get("id").cloned().unwrap_or(Value::Null),
                "label": receipt.get("title").cloned().unwrap_or(Value::Null),
                "receipt_type": receipt.get("receipt_type").cloned().unwrap_or(Value::Null),
                "lifecycle": receipt.get("lifecycle_state").cloned().unwrap_or(Value::Null),
                "digest": receipt.get("body_digest").cloned().unwrap_or(Value::Null),
            })
        })
        .collect();

    let edges: Vec<Value> = receipts
        .iter()
        .flat_map(|receipt| {
            let target = receipt.get("id").cloned().unwrap_or(Value::Null);
            receipt
                .get("parent_receipt_ids")
                .and_then(Value::as_array)
                .cloned()
                .unwrap_or_default()
                .into_iter()
                .map(move |source| json!({ "source": source, "target": target }))
        })
        .collect();

    json!({ "nodes": nodes, "edges": edges })
}

fn hex_encode(bytes: &[u8]) -> String {
    bytes.iter().map(|byte| format!("{:02x}", byte)).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn issue_projection_emits_parseable_receipt() {
        let receipt = match issue_projection(
            json!({ "avsa": "AVSA-1", "event": "practice" }),
            "Athian Test".into(),
            "practice_receipt".into(),
            Some("athian.practice_receipt.v1".into()),
            "sealed".into(),
            Some("AVSA-1".into()),
            Some("did:key:test".into()),
            vec!["parent-digest".into()],
        ) {
            Ok(receipt) => receipt,
            Err(error) => panic!("{}", error),
        };

        assert_eq!(receipt["receipt_type"], "practice_receipt");
        assert_eq!(receipt["lifecycle_state"], "sealed");
        assert!(receipt["body_digest"].as_str().is_some());
        assert!(receipt["canonical_encoding_hex"].as_str().is_some());
    }

    #[test]
    fn graph_projection_emits_parent_edges() {
        let graph = graph_projection(&json!({
            "receipts": [
                { "id": 1, "title": "Practice", "receipt_type": "practice_receipt", "lifecycle_state": "sealed", "body_digest": "a", "parent_receipt_ids": [] },
                { "id": 2, "title": "Measurement", "receipt_type": "measurement_receipt", "lifecycle_state": "sealed", "body_digest": "b", "parent_receipt_ids": [1] }
            ]
        }));

        assert_eq!(graph["nodes"].as_array().map(Vec::len), Some(2));
        assert_eq!(graph["edges"].as_array().map(Vec::len), Some(1));
    }
}

use agevidence::{
    canonicalize_value, load_bundle, sha256_typed, verify_path, AgEvidenceError, CheckStatus,
};
use clap::{Parser, Subcommand};
use serde_json::{json, Value};
use std::path::PathBuf;
use std::process::ExitCode;

#[derive(Parser)]
#[command(author, version, about = "AgEvidence portable verifier", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Verify an AgEvidence JSON or ZIP bundle
    Verify {
        /// Path to a bundle JSON file or ZIP archive
        bundle: PathBuf,
        /// Emit machine-readable JSON
        #[arg(long)]
        json: bool,
    },
    /// Inspect a bundle without deciding validity
    Inspect {
        /// Path to a bundle JSON file or ZIP archive
        bundle: PathBuf,
    },
    /// Hash a JSON payload with RFC 8785/JCS canonicalization
    Hash {
        /// Path to the JSON payload
        payload: PathBuf,
        /// Digest domain
        #[arg(long, default_value = "app")]
        domain: String,
    },
    /// Emit canonical JSON for a payload
    Canonicalize {
        /// Path to the JSON payload
        payload: PathBuf,
    },
    /// Run bundled protocol conformance checks
    Conformance,
    /// Print verifier and protocol version
    Version,
}

fn main() -> ExitCode {
    match run() {
        Ok(code) => code,
        Err(error) => {
            eprintln!("{error}");
            error_exit_code(&error)
        }
    }
}

fn run() -> Result<ExitCode, AgEvidenceError> {
    let cli = Cli::parse();
    match cli.command {
        Commands::Verify { bundle, json } => verify_command(bundle, json),
        Commands::Inspect { bundle } => inspect_command(bundle),
        Commands::Hash { payload, domain } => hash_command(payload, domain),
        Commands::Canonicalize { payload } => canonicalize_command(payload),
        Commands::Conformance => conformance_command(),
        Commands::Version => {
            println!(
                "agevidence {} protocol {}",
                env!("CARGO_PKG_VERSION"),
                agevidence::verify::PROTOCOL_VERSION
            );
            Ok(ExitCode::SUCCESS)
        }
    }
}

fn verify_command(bundle: PathBuf, json_output: bool) -> Result<ExitCode, AgEvidenceError> {
    match verify_path(&bundle) {
        Ok(report) => {
            if json_output {
                println!("{}", serde_json::to_string_pretty(&report)?);
            } else {
                println!("Verification {:?}", report.status);
                println!("Bundle commitment: {}", report.bundle_commitment);
            }
            Ok(status_exit_code(report.status))
        }
        Err(error) => {
            if json_output {
                let payload = json!({
                    "verifier_version": env!("CARGO_PKG_VERSION"),
                    "protocol_version": agevidence::verify::PROTOCOL_VERSION,
                    "status": error_status(&error),
                    "cryptographic_status": error_status(&error),
                    "checks": [],
                    "warnings": [],
                    "errors": [{"code": error_code(&error), "message": error.to_string()}]
                });
                println!("{}", serde_json::to_string_pretty(&payload)?);
            } else {
                eprintln!("{error}");
            }
            Ok(error_exit_code(&error))
        }
    }
}

fn inspect_command(bundle: PathBuf) -> Result<ExitCode, AgEvidenceError> {
    let bundle = load_bundle(&bundle)?;
    println!(
        "{}",
        serde_json::to_string_pretty(&json!({
            "format": bundle.format,
            "path": bundle.path,
            "records": bundle.records.len(),
            "receipts": bundle.receipts.len(),
            "keys": bundle.keys.len(),
            "trust_policy_present": bundle.trust_policy.is_some(),
            "bundle_commitment": bundle.computed_bundle_commitment,
            "declared_bundle_commitment": bundle.declared_bundle_commitment,
            "file_commitments": bundle.file_commitments,
        }))?
    );
    Ok(ExitCode::SUCCESS)
}

fn hash_command(payload: PathBuf, domain: String) -> Result<ExitCode, AgEvidenceError> {
    let value = read_json(payload)?;
    let canonical = canonicalize_value(&value)?;
    println!("{}", sha256_typed(&domain, canonical.as_bytes()));
    Ok(ExitCode::SUCCESS)
}

fn canonicalize_command(payload: PathBuf) -> Result<ExitCode, AgEvidenceError> {
    let value = read_json(payload)?;
    let canonical = canonicalize_value(&value)?;
    println!("{}", canonical.as_str()?);
    Ok(ExitCode::SUCCESS)
}

fn conformance_command() -> Result<ExitCode, AgEvidenceError> {
    let root = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../../../../protocol/conformance/canonicalization/vectors");
    let mut failures = Vec::new();
    for entry in std::fs::read_dir(root)? {
        let entry = entry?;
        if !entry.file_type()?.is_dir() {
            continue;
        }
        let vector = entry.path();
        let metadata = std::fs::read_to_string(vector.join("metadata.yaml"))?;
        let input = std::fs::read_to_string(vector.join("input.json"))?;
        if metadata.contains("expected_error:") {
            if serde_json::from_str::<Value>(&input)
                .ok()
                .and_then(|value| canonicalize_value(&value).ok())
                .is_some()
            {
                failures.push(format!("{} should fail", vector.display()));
            }
            continue;
        }
        let value: Value = serde_json::from_str(&input)?;
        let mut expected = std::fs::read(vector.join("expected.json"))?;
        if expected.ends_with(b"\n") {
            expected.pop();
        }
        let canonical = canonicalize_value(&value)?;
        if canonical.as_bytes() != expected {
            failures.push(format!("{} mismatch", vector.display()));
        }
    }
    if failures.is_empty() {
        println!("AgEvidence Rust canonicalization conformance passed");
        Ok(ExitCode::SUCCESS)
    } else {
        for failure in failures {
            eprintln!("{failure}");
        }
        Ok(ExitCode::from(1))
    }
}

fn read_json(path: PathBuf) -> Result<Value, AgEvidenceError> {
    Ok(serde_json::from_slice(&std::fs::read(path)?)?)
}

fn status_exit_code(status: CheckStatus) -> ExitCode {
    match status {
        CheckStatus::Pass | CheckStatus::Warning | CheckStatus::Skipped => ExitCode::SUCCESS,
        CheckStatus::Fail => ExitCode::from(1),
        CheckStatus::Indeterminate => ExitCode::from(2),
    }
}

fn error_exit_code(error: &AgEvidenceError) -> ExitCode {
    match error {
        AgEvidenceError::Json(_) | AgEvidenceError::Zip(_) | AgEvidenceError::Malformed(_) => {
            ExitCode::from(3)
        }
        AgEvidenceError::UnsupportedProtocol(_) => ExitCode::from(4),
        AgEvidenceError::Io(_) | AgEvidenceError::Canonical(_) | AgEvidenceError::Crypto(_) => {
            ExitCode::from(5)
        }
    }
}

fn error_status(error: &AgEvidenceError) -> &'static str {
    match error {
        AgEvidenceError::UnsupportedProtocol(_) => "unsupported",
        AgEvidenceError::Json(_) | AgEvidenceError::Zip(_) | AgEvidenceError::Malformed(_) => {
            "malformed"
        }
        _ => "error",
    }
}

fn error_code(error: &AgEvidenceError) -> &'static str {
    match error {
        AgEvidenceError::Json(_) => "JSON_MALFORMED",
        AgEvidenceError::Zip(_) => "ZIP_MALFORMED",
        AgEvidenceError::Malformed(_) => "INPUT_MALFORMED",
        AgEvidenceError::UnsupportedProtocol(_) => "UNSUPPORTED_PROTOCOL",
        AgEvidenceError::Io(_) => "IO_ERROR",
        AgEvidenceError::Canonical(_) => "CANONICALIZATION_FAILED",
        AgEvidenceError::Crypto(_) => "CRYPTO_ERROR",
    }
}

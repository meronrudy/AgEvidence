#![forbid(unsafe_code)]
#![deny(missing_docs)]
#![deny(unused_must_use)]
#![deny(clippy::unwrap_used)]
#![deny(clippy::expect_used)]
#![deny(clippy::panic)]

//! Hashing, signing, and verification primitives for the BAINK kernel.

use baink_core::{HashAlgorithm, HashDigest};
use sha2::{Digest, Sha256};

/// Hash bytes using the specified algorithm.
pub fn hash_bytes(bytes: &[u8], algorithm: HashAlgorithm) -> HashDigest {
    match algorithm {
        HashAlgorithm::Sha256 => {
            let mut hasher = Sha256::new();
            hasher.update(bytes);
            let result = hasher.finalize();
            HashDigest {
                algorithm: HashAlgorithm::Sha256,
                value: hex::encode(result),
            }
        }
        HashAlgorithm::Blake3 => {
            let hash = blake3::hash(bytes);
            HashDigest {
                algorithm: HashAlgorithm::Blake3,
                value: hash.to_hex().to_string(),
            }
        }
    }
}

// We need hex encoding

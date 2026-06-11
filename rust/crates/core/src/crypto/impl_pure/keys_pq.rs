//! Post-quantum key generation placeholders.

use crate::crypto::Result;

const POST_QUANTUM_KEYPAIR_PLACEHOLDER: &[u8] = b"POST_QUANTUM_KEYPAIR_PLACEHOLDER";

/// Generate a post-quantum key pair, includes a pre-quantum key pair prefixed.
pub fn generate_keypair_pq() -> Result<(Vec<u8>, Vec<u8>)> {
    let (mut public_key, mut secret_key) = crate::crypto::keys::generate_keypair()?;
    public_key.extend_from_slice(POST_QUANTUM_KEYPAIR_PLACEHOLDER);
    secret_key.extend_from_slice(POST_QUANTUM_KEYPAIR_PLACEHOLDER);
    Ok((public_key, secret_key))
}

use ente_core::crypto::hpke;

const HPKE_INFO: &[u8] = b"ente-push";

pub struct NotificationKeyPair {
    pub public_key: Vec<u8>,
    pub private_key: Vec<u8>,
}

#[flutter_rust_bridge::frb(sync)]
pub fn generate_notification_key_pair() -> NotificationKeyPair {
    let private_key = hpke::SecretKey::generate();
    NotificationKeyPair {
        public_key: private_key.public_key().as_bytes().to_vec(),
        private_key: private_key.as_bytes().to_vec(),
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn decrypt_notification(ciphertext: Vec<u8>, private_key: Vec<u8>) -> Result<Vec<u8>, String> {
    let private_key =
        hpke::SecretKey::try_from_slice(&private_key).map_err(|error| error.to_string())?;
    hpke::open(&ciphertext, &private_key, HPKE_INFO).map_err(|error| error.to_string())
}

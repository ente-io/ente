use crate::api::client::ApiClient;
use crate::api::models::{
    AuthResponse, CreateSrpSessionRequest, CreateSrpSessionResponse, GetSrpAttributesResponse,
    SendOtpRequest, SrpAttributes, VerifyEmailRequest, VerifySrpSessionRequest, VerifyTotpRequest,
};
use crate::crypto::{derive_argon_key, derive_login_key};
use crate::models::error::Result;
use base64::{Engine, engine::general_purpose::STANDARD};
use num_bigint::{BigUint, RandBigInt};
use sha2::{Digest, Sha256};

/// Simple SRP-6a client implementation matching Go's behavior
struct SimpleSrpClient {
    n: BigUint, // Safe prime
    g: BigUint, // Generator
}

impl SimpleSrpClient {
    fn new() -> Self {
        // SRP-4096 group parameters (same as used in Go client)
        let n_hex = "FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74020BBEA63B139B22514A08798E3404DDEF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7EDEE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45B3DC2007CB8A163BF0598DA48361C55D39A69163FA8FD24CF5F83655D23DCA3AD961C62F356208552BB9ED529077096966D670C354E4ABC9804F1746C08CA18217C32905E462E36CE3BE39E772C180E86039B2783A2EC07A28FB5C55DF06F4C52C9DE2BCBF6955817183995497CEA956AE515D2261898FA051015728E5A8AAAC42DAD33170D04507A33A85521ABDF1CBA64ECFB850458DBEF0A8AEA71575D060C7DB3970F85A6E1E4C7ABF5AE8CDB0933D71E8C94E04A25619DCEE3D2261AD2EE6BF12FFA06D98A0864D87602733EC86A64521F2B18177B200CBBE117577A615D6C770988C0BAD946E208E24FA074E5AB3143DB5BFCE0FD108E4B82D120A92108011A723C12A787E6D788719A10BDBA5B2699C327186AF4E23C1A946834B6150BDA2583E9CA2AD44CE8DBBBC2DB04DE8EF92E8EFC141FBECAA6287C59474E6BC05D99B2964FA090C3A2233BA186515BE7ED1F612970CEE2D7AFB81BDD762170481CD0069127D5B05AA993B4EA988D8FDDC186FFB7DC90A6C08F4DF435C93402849236C3FAB4D27C7026C1D4DCB2602646DEC9751E763DBA37BDF8FF9406AD9E530EE5DB382F413001AEB06A53ED9027D831179727B0865A8918DA3EDBEBCF9B14ED44CE6CBACED4BB1BDB7F1447E6CC254B332051512BD7AF426FB8F401378CD2BF5983CA01C64B92ECF032EA15D1721D03F482D7CE6E74FEF6D55E702F46980C82B5A84031900B1C9E59E7C97FBEC7E8F323A97A7E36CC88BE0F1D45B7FF585AC54BD407B22B4154AACC8F6D7EBF48E1D814CC5ED20F8037E0A79715EEF29BE32806A1D58BB7C5DA76F550AA3D8A1FBFF0EB19CCB1A313D55CDA56C9EC2EF29632387FE8D76E3C0468043E8F663F4860EE12BF2D5B0B7474D6E694F91E6DBE115974A3926F12FEE5E438777CB6A932DF8CD8BEC4D073B931BA3BC832B68D9DD300741FA7BF8AFC47ED2576F6936BA424663AAB639C5AE4F5683423B4742BF1C978238F16CBE39D652DE3FDB8BEFC848AD922222E04A4037C0713EB57A81A23F0C73473FC646CEA306B4BCBC8862F8385DDFA9D4B7FA2C087E879683303ED5BDD3A062B3CF5B3A278A66D2A13F83F44F82DDF310EE074AB6A364597E899A0255DC164F31CC50846851DF9AB48195DED7EA1B1D510BD7EE74D73FAF36BC31ECFA268359046F4EB879F924009438B481C6CD7889A002ED5EE382BC9190DA6FC026E479558E4475677E9AA9E3050E2765694DFC81F56E880B96E7160C980DD98EDD3DFFFFFFFFFFFFFFFFF";
        let g_hex = "02";

        Self {
            n: BigUint::parse_bytes(n_hex.as_bytes(), 16).unwrap(),
            g: BigUint::parse_bytes(g_hex.as_bytes(), 16).unwrap(),
        }
    }

    fn generate_keys(&self) -> (BigUint, Vec<u8>) {
        let mut rng = rand::thread_rng();
        let client_secret = rng.gen_biguint_below(&self.n);
        let client_public = self.g.modpow(&client_secret, &self.n);
        let client_public_bytes = pad_to_n_bytes(client_public.to_bytes_be(), 512); // 4096 bits = 512 bytes
        (client_secret, client_public_bytes)
    }

    fn compute_proof(
        &self,
        identity: &[u8],
        password: &[u8],
        salt: &[u8],
        client_secret: &BigUint,
        client_public: &[u8],
        server_public: &[u8],
    ) -> crate::models::error::Result<Vec<u8>> {
        // H(N) XOR H(g)
        let h_n = Sha256::digest(&self.n.to_bytes_be());
        let h_g = Sha256::digest(&self.g.to_bytes_be());
        let h_xor: Vec<u8> = h_n.iter().zip(h_g.iter()).map(|(a, b)| a ^ b).collect();

        // H(identity)
        let h_identity = Sha256::digest(identity);

        // Compute shared key
        let k = compute_k(&self.n, &self.g);
        let u = compute_u(client_public, server_public);
        let x = compute_x(identity, password, salt);

        let server_b = BigUint::from_bytes_be(server_public);
        let v = self.g.modpow(&x, &self.n);
        let kv = (&k * &v) % &self.n;
        let diff = if server_b >= kv {
            &server_b - &kv
        } else {
            &self.n - (&kv - &server_b)
        };
        let ux = &u * &x;
        let aux = client_secret + &ux;
        let session_key = diff.modpow(&aux, &self.n);
        let session_key_hash = Sha256::digest(&session_key.to_bytes_be());

        // M1 = H(H(N) XOR H(g) | H(identity) | salt | A | B | session_key)
        let mut hasher = Sha256::new();
        hasher.update(&h_xor);
        hasher.update(&h_identity);
        hasher.update(salt);
        hasher.update(client_public);
        hasher.update(server_public);
        hasher.update(&session_key_hash);

        Ok(hasher.finalize().to_vec())
    }
}

fn pad_to_n_bytes(bytes: Vec<u8>, n: usize) -> Vec<u8> {
    if bytes.len() >= n {
        bytes
    } else {
        let mut padded = vec![0u8; n - bytes.len()];
        padded.extend(bytes);
        padded
    }
}

fn compute_k(n: &BigUint, g: &BigUint) -> BigUint {
    let mut hasher = Sha256::new();
    hasher.update(&n.to_bytes_be());
    hasher.update(&pad_to_n_bytes(g.to_bytes_be(), 512));
    BigUint::from_bytes_be(&hasher.finalize())
}

fn compute_u(client_public: &[u8], server_public: &[u8]) -> BigUint {
    let mut hasher = Sha256::new();
    hasher.update(client_public);
    hasher.update(server_public);
    BigUint::from_bytes_be(&hasher.finalize())
}

fn compute_x(identity: &[u8], password: &[u8], salt: &[u8]) -> BigUint {
    let mut hasher = Sha256::new();
    hasher.update(identity);
    hasher.update(b":");
    hasher.update(password);
    let h1 = hasher.finalize();

    let mut hasher = Sha256::new();
    hasher.update(salt);
    hasher.update(&h1);
    BigUint::from_bytes_be(&hasher.finalize())
}
use uuid::Uuid;

/// SRP authentication implementation for Ente API
pub struct AuthClient<'a> {
    api: &'a ApiClient,
}

impl<'a> AuthClient<'a> {
    pub fn new(api: &'a ApiClient) -> Self {
        Self { api }
    }

    /// Get SRP attributes for a user by email
    pub async fn get_srp_attributes(&self, email: &str) -> Result<SrpAttributes> {
        let url = format!("/users/srp/attributes?email={}", urlencoding::encode(email));
        let response: GetSrpAttributesResponse = self.api.get(&url, None).await?;
        Ok(response.attributes)
    }

    /// Create SRP session - first step of SRP authentication
    pub async fn create_srp_session(
        &self,
        srp_user_id: &Uuid,
        client_public: &[u8],
    ) -> Result<CreateSrpSessionResponse> {
        let request = CreateSrpSessionRequest {
            srp_user_id: srp_user_id.to_string(),
            srp_a: STANDARD.encode(client_public),
        };

        self.api
            .post("/users/srp/create-session", &request, None)
            .await
    }

    /// Verify SRP session - final step of SRP authentication
    pub async fn verify_srp_session(
        &self,
        srp_user_id: &Uuid,
        session_id: &Uuid,
        client_proof: &[u8],
    ) -> Result<AuthResponse> {
        let request = VerifySrpSessionRequest {
            srp_user_id: srp_user_id.to_string(),
            session_id: session_id.to_string(),
            srp_m1: STANDARD.encode(client_proof),
        };

        self.api
            .post("/users/srp/verify-session", &request, None)
            .await
    }

    /// Complete SRP authentication flow
    pub async fn login_with_srp(
        &self,
        email: &str,
        password: &str,
    ) -> Result<(AuthResponse, Vec<u8>)> {
        // Step 1: Get SRP attributes
        let srp_attrs = self.get_srp_attributes(email).await?;

        // Step 2: Derive key encryption key from password
        let key_enc_key = derive_argon_key(
            password,
            &srp_attrs.kek_salt,
            srp_attrs.mem_limit as u32,
            srp_attrs.ops_limit as u32,
        )?;

        // Step 3: Derive login key
        let login_key = derive_login_key(&key_enc_key)?;

        // Step 4: Initialize SRP client using the same approach as Go
        let srp_salt = STANDARD.decode(&srp_attrs.srp_salt)?;
        let identity = srp_attrs.srp_user_id.to_string();

        // Create SRP client (matching Go's srp.NewClient)
        let srp_client = SimpleSrpClient::new();
        let (client_secret, client_public) = srp_client.generate_keys();

        // Step 5: Create SRP session
        let session = self
            .create_srp_session(&srp_attrs.srp_user_id, &client_public)
            .await?;

        // Step 6: Process server's public key and generate proof
        let server_public = STANDARD.decode(&session.srp_b)?;
        let client_proof = srp_client.compute_proof(
            identity.as_bytes(),
            &login_key,
            &srp_salt,
            &client_secret,
            &client_public,
            &server_public,
        )?;

        // Step 7: Verify session with proof
        let auth_response = self
            .verify_srp_session(&srp_attrs.srp_user_id, &session.session_id, &client_proof)
            .await?;

        // TODO: Verify server proof if provided
        // if let Some(srp_m2) = &auth_response.srp_m2 {
        //     let server_proof = STANDARD.decode(srp_m2)?;
        //     // Verify server proof
        // }

        Ok((auth_response, key_enc_key))
    }

    /// Send OTP for email verification
    pub async fn send_login_otp(&self, email: &str) -> Result<()> {
        let request = SendOtpRequest {
            email: email.to_string(),
            purpose: "login".to_string(),
        };

        let _: serde_json::Value = self.api.post("/users/ott", &request, None).await?;
        Ok(())
    }

    /// Verify email with OTP
    pub async fn verify_email(&self, email: &str, otp: &str) -> Result<AuthResponse> {
        let request = VerifyEmailRequest {
            email: email.to_string(),
            ott: otp.to_string(),
        };

        self.api.post("/users/verify-email", &request, None).await
    }

    /// Verify TOTP for two-factor authentication
    pub async fn verify_totp(&self, session_id: &str, code: &str) -> Result<AuthResponse> {
        let request = VerifyTotpRequest {
            session_id: session_id.to_string(),
            code: code.to_string(),
        };

        self.api
            .post("/users/two-factor/verify", &request, None)
            .await
    }

    /// Check passkey verification status
    pub async fn check_passkey_status(&self, session_id: &str) -> Result<AuthResponse> {
        let url = format!(
            "/users/two-factor/passkeys/get-token?sessionID={}",
            session_id
        );
        self.api.get(&url, None).await
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::crypto::{derive_argon_key, derive_login_key};

    #[test]
    fn test_login_key_derivation() {
        // Test that login key derivation matches expected output
        let password = "test_password";
        let salt = b"test_salt_16bytes";

        let key = derive_argon_key(password, &STANDARD.encode(salt), 4, 3).unwrap();
        assert_eq!(key.len(), 32);

        let login_key = derive_login_key(&key).unwrap();
        assert_eq!(login_key.len(), 32);
    }
}

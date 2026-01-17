#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod commands;

fn main() {
    tauri::Builder::default()
        .manage(commands::SrpState::default())
        .invoke_handler(tauri::generate_handler![
            commands::crypto_init,
            commands::crypto_generate_key,
            commands::crypto_encrypt_box,
            commands::crypto_decrypt_box,
            commands::crypto_encrypt_blob,
            commands::crypto_decrypt_blob,
            commands::auth_derive_srp_credentials,
            commands::auth_decrypt_secrets,
            commands::auth_decrypt_keys_only,
            commands::srp_session_new,
            commands::srp_session_public_a,
            commands::srp_session_compute_m1,
            commands::srp_session_verify_m2,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

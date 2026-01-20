#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod commands;

fn main() {
    tauri::Builder::default()
        .manage(commands::SrpState::default())
        .manage(commands::LlmState::default())
        .manage(commands::ChatDbState::default())
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
            commands::chat_db_list_sessions,
            commands::chat_db_get_session,
            commands::chat_db_create_session,
            commands::chat_db_update_session_title,
            commands::chat_db_delete_session,
            commands::chat_db_get_messages,
            commands::chat_db_insert_message,
            commands::chat_db_update_message_text,
            commands::llm_init_backend,
            commands::llm_load_model,
            commands::llm_create_context,
            commands::llm_free_context,
            commands::llm_free_model,
            commands::llm_generate_chat_stream,
            commands::llm_cancel,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn file_download_url(api_base_url: &str, file_id: i64) -> String {
    ente_core::urls::file_download_url(api_base_url, file_id)
}

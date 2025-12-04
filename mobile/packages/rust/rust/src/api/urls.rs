use flutter_rust_bridge::frb;

#[frb(sync)]
pub fn file_download_url(api_base_url: String, file_id: i64) -> String {
    ente_core::urls::file_download_url(&api_base_url, file_id)
}

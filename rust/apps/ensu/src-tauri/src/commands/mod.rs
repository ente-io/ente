pub(crate) mod chat_db;
mod common;
pub(crate) mod crypto;
pub(crate) mod fs;
pub(crate) mod inference;
pub(crate) mod secure_storage;
pub(crate) mod system;

use tauri::AppHandle;

use crate::logging;

pub fn cleanup_for_exit(app: &AppHandle) {
    logging::log("App", "cleanup_for_exit start");
    inference::clear_for_exit(app);
    chat_db::clear_for_exit(app);
    logging::log("App", "cleanup_for_exit complete");
}

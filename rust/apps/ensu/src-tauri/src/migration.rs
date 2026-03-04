//! Migrate legacy WebKit data after an origin-scheme change.
//!
//! When upgrading from Tauri v1 to v2, the WebView origin scheme on macOS
//! changes from `http://localhost` to `tauri://localhost`. WebKit stores data
//! in origin-specific subdirectories under the same app-level WebKit folder,
//! so old localStorage and IndexedDB become invisible to the new origin.
//!
//! This module copies IndexedDB databases from old origin-hash directories
//! into the current one before the webview fully initializes.

use std::fs;
use std::path::{Path, PathBuf};

/// App directory names to search (current bundle ID + old names from v1).
const APP_NAMES: &[&str] = &["io.ente.ensu", "ensu-tauri", "Ensu", "ensu"];

/// Migrate legacy WebKit data if needed. Safe to call multiple times; it is a
/// no-op once the migration marker exists.
pub fn migrate_legacy_webkit_data() {
    #[cfg(target_os = "macos")]
    macos::migrate();

    #[cfg(target_os = "linux")]
    linux::migrate();
}

// ---------------------------------------------------------------------------
// macOS
// ---------------------------------------------------------------------------

#[cfg(target_os = "macos")]
mod macos {
    use super::*;

    pub fn migrate() {
        let home = match dirs::home_dir() {
            Some(h) => h,
            None => return,
        };
        let webkit_dir = home.join("Library/WebKit");
        migrate_webkit_dir(&webkit_dir);
    }
}

// ---------------------------------------------------------------------------
// Linux
// ---------------------------------------------------------------------------

#[cfg(target_os = "linux")]
mod linux {
    use super::*;

    pub fn migrate() {
        let home = match dirs::home_dir() {
            Some(h) => h,
            None => return,
        };
        let data_home = std::env::var("XDG_DATA_HOME")
            .map(PathBuf::from)
            .unwrap_or_else(|_| home.join(".local/share"));
        migrate_webkit_dir(&data_home);
    }
}

// ---------------------------------------------------------------------------
// Shared implementation
// ---------------------------------------------------------------------------

/// The main migration logic, shared across platforms.
///
/// Searches for old origin-hash directories (from before the scheme change)
/// within the same app directory, as well as in directories from older app
/// names. Copies any IndexedDB databases that are missing from the current
/// origin into it.
fn migrate_webkit_dir(base_dir: &Path) {
    // Find the current origin-hash directory. This is the one the webview
    // created for the current origin (tauri://localhost in v2).
    let current_app_dir = base_dir.join(APP_NAMES[0]); // io.ente.ensu
    let default_dir = current_app_dir.join("WebsiteData").join("Default");
    if !default_dir.exists() {
        return;
    }

    // Find the current (newest) origin-hash that the v2 webview uses.
    let current_data_dir = match find_current_origin_dir(&default_dir) {
        Some(d) => d,
        None => return,
    };

    // Check migration marker.
    let marker = current_data_dir.join(".ensu_legacy_migrated");
    if marker.exists() {
        return;
    }

    let mut migrated = false;

    // 1. Check OTHER origin-hash directories within the same app directory.
    //    This handles the scheme change (http → tauri) within io.ente.ensu.
    migrated |= migrate_from_sibling_origins(&default_dir, &current_data_dir);

    // 2. Check old app name directories (ensu-tauri, Ensu, ensu).
    if !migrated {
        for name in &APP_NAMES[1..] {
            let old_app_dir = base_dir.join(name);
            let old_default = old_app_dir.join("WebsiteData").join("Default");
            if !old_default.exists() {
                continue;
            }
            if migrate_from_all_origins(&old_default, &current_data_dir) {
                eprintln!(
                    "[ensu migration] Migrated IndexedDB from {}",
                    old_app_dir.display()
                );
                migrated = true;
                break;
            }
        }
    }

    // Write marker (even if nothing was migrated) to avoid repeated scans.
    let _ = fs::write(&marker, if migrated { "1" } else { "0" });
}

/// The "current" origin directory is the one the v2 webview writes to.
/// When there are multiple origin-hash dirs (old http + new tauri), we pick
/// the one whose `origin` file contains "tauri". If there's only one, use it.
fn find_current_origin_dir(default_dir: &Path) -> Option<PathBuf> {
    let mut dirs: Vec<PathBuf> = fs::read_dir(default_dir)
        .ok()?
        .flatten()
        .filter(|e| e.path().is_dir())
        .map(|e| {
            let name = e.file_name();
            default_dir.join(&name).join(&name)
        })
        .filter(|p| p.exists())
        .collect();

    if dirs.is_empty() {
        return None;
    }
    if dirs.len() == 1 {
        return Some(dirs.remove(0));
    }

    // Multiple origins — prefer the one with "tauri" in the origin file.
    for dir in &dirs {
        let origin_file = dir.join("origin");
        if let Ok(bytes) = fs::read(&origin_file) {
            if bytes.windows(5).any(|w| w == b"tauri") {
                return Some(dir.clone());
            }
        }
    }

    // Fallback: pick the most recently modified one.
    dirs.sort_by_key(|d| {
        fs::metadata(d)
            .and_then(|m| m.modified())
            .unwrap_or(std::time::SystemTime::UNIX_EPOCH)
    });
    dirs.pop()
}

/// Copy IndexedDB databases from sibling origin-hash dirs (within the same
/// app directory) into the current origin dir.
fn migrate_from_sibling_origins(default_dir: &Path, current_data_dir: &Path) -> bool {
    let current_hash = match current_data_dir.parent().and_then(|p| p.file_name()) {
        Some(h) => h.to_owned(),
        None => return false,
    };

    let mut migrated = false;
    let entries = match fs::read_dir(default_dir) {
        Ok(e) => e,
        Err(_) => return false,
    };

    for entry in entries.flatten() {
        if !entry.path().is_dir() {
            continue;
        }
        let name = entry.file_name();
        if name == current_hash {
            continue; // Skip the current origin.
        }
        let old_data_dir = default_dir.join(&name).join(&name);
        if !old_data_dir.exists() {
            continue;
        }
        migrated |= copy_indexeddb_dirs(&old_data_dir, current_data_dir);
        migrated |= copy_localstorage_keys(&old_data_dir, current_data_dir);
    }

    if migrated {
        eprintln!("[ensu migration] Migrated data from old origin within same app dir");
    }
    migrated
}

/// Copy IndexedDB databases from ALL origin-hash dirs in an old app directory.
fn migrate_from_all_origins(old_default_dir: &Path, current_data_dir: &Path) -> bool {
    let mut migrated = false;
    let entries = match fs::read_dir(old_default_dir) {
        Ok(e) => e,
        Err(_) => return false,
    };

    for entry in entries.flatten() {
        if !entry.path().is_dir() {
            continue;
        }
        let name = entry.file_name();
        let old_data_dir = old_default_dir.join(&name).join(&name);
        if !old_data_dir.exists() {
            continue;
        }
        migrated |= copy_indexeddb_dirs(&old_data_dir, current_data_dir);
        migrated |= copy_localstorage_keys(&old_data_dir, current_data_dir);
    }
    migrated
}

/// Copy IndexedDB database directories from old to new. Each database is a
/// subdirectory named by a SHA-256 hash of the database name. We only copy
/// directories that don't already exist in the destination.
fn copy_indexeddb_dirs(old_data_dir: &Path, new_data_dir: &Path) -> bool {
    let old_idb = old_data_dir.join("IndexedDB");
    let new_idb = new_data_dir.join("IndexedDB");
    if !old_idb.exists() {
        return false;
    }

    let entries = match fs::read_dir(&old_idb) {
        Ok(e) => e,
        Err(_) => return false,
    };

    let mut copied = false;
    for entry in entries.flatten() {
        let path = entry.path();
        if !path.is_dir() {
            continue;
        }
        let name = entry.file_name();
        let dest = new_idb.join(&name);
        if dest.exists() {
            continue;
        }
        if copy_dir_recursive(&path, &dest).is_ok() {
            eprintln!(
                "[ensu migration] Copied IndexedDB {:?}",
                name.to_string_lossy()
            );
            copied = true;
        }
    }
    copied
}

/// Copy chat-related localStorage keys from the old origin's
/// localstorage.sqlite3 into the new origin's localstorage.sqlite3.
///
/// This runs in the Tauri setup hook BEFORE the event loop starts, so the
/// webview hasn't opened the new SQLite file yet — no lock contention.
fn copy_localstorage_keys(old_data_dir: &Path, new_data_dir: &Path) -> bool {
    let old_ls = old_data_dir.join("LocalStorage").join("localstorage.sqlite3");
    let new_ls = new_data_dir.join("LocalStorage").join("localstorage.sqlite3");
    if !old_ls.exists() || !new_ls.exists() {
        return false;
    }

    let old_conn = match rusqlite::Connection::open_with_flags(
        &old_ls,
        rusqlite::OpenFlags::SQLITE_OPEN_READ_ONLY,
    ) {
        Ok(c) => c,
        Err(_) => return false,
    };

    let new_conn = match rusqlite::Connection::open(&new_ls) {
        Ok(c) => c,
        Err(_) => return false,
    };

    // Keys we care about migrating.
    let keys = [
        "ensu.chatKey.local",
        "ensu.chat.store.v1",
        "ensu.chat.branchSelections.v1",
    ];

    let mut copied = false;
    for key in &keys {
        let value: Option<String> = old_conn
            .query_row(
                "SELECT value FROM ItemTable WHERE key = ?1",
                [key],
                |row| row.get(0),
            )
            .ok()
            .filter(|v: &String| !v.is_empty());

        if let Some(value) = value {
            // Only copy if the key doesn't already exist in new.
            let exists: bool = new_conn
                .query_row(
                    "SELECT 1 FROM ItemTable WHERE key = ?1",
                    [key],
                    |_| Ok(true),
                )
                .unwrap_or(false);

            if !exists {
                let _ = new_conn.execute(
                    "INSERT INTO ItemTable (key, value) VALUES (?1, ?2)",
                    rusqlite::params![key, value],
                );
                eprintln!("[ensu migration] Copied localStorage key: {key}");
                copied = true;
            }
        }
    }
    copied
}

/// Recursively copy a directory.
fn copy_dir_recursive(src: &Path, dst: &Path) -> std::io::Result<()> {
    fs::create_dir_all(dst)?;
    for entry in fs::read_dir(src)? {
        let entry = entry?;
        let src_path = entry.path();
        let dst_path = dst.join(entry.file_name());
        if src_path.is_dir() {
            copy_dir_recursive(&src_path, &dst_path)?;
        } else {
            fs::copy(&src_path, &dst_path)?;
        }
    }
    Ok(())
}

//! Migrate legacy WebKit data from old Tauri v1 directories to the new v2
//! directory.
//!
//! When upgrading from Tauri v1 to v2, the WebKit data directory on macOS
//! changes from `~/Library/WebKit/<ProductName>/` to
//! `~/Library/WebKit/<BundleIdentifier>/`. This means localStorage and
//! IndexedDB data from old app versions become invisible.
//!
//! This module copies the old data into the new directory before the webview
//! initializes, so the frontend sees it seamlessly.

use std::fs;
use std::path::{Path, PathBuf};

/// Old app names used in Tauri v1 builds. The first match wins.
const OLD_APP_NAMES: &[&str] = &["ensu-tauri", "Ensu", "ensu"];

/// Current bundle identifier (Tauri v2).
const CURRENT_BUNDLE_ID: &str = "io.ente.ensu";

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
        let new_app_dir = webkit_dir.join(CURRENT_BUNDLE_ID);

        // Find the new origin-hash data directory.
        let new_data_dir = match find_origin_data_dir(&new_app_dir) {
            Some(d) => d,
            None => return, // New directory doesn't exist yet (first run)
        };

        // Check migration marker.
        let marker = new_data_dir.join(".ensu_legacy_migrated");
        if marker.exists() {
            return;
        }

        // Try each old candidate.
        for name in OLD_APP_NAMES {
            let old_app_dir = webkit_dir.join(name);
            if !old_app_dir.exists() {
                continue;
            }
            let old_data_dir = match find_origin_data_dir(&old_app_dir) {
                Some(d) => d,
                None => continue,
            };

            // Copy IndexedDB databases that don't already exist in new.
            if copy_indexeddb_dirs(&old_data_dir, &new_data_dir) {
                eprintln!(
                    "[ensu migration] Migrated IndexedDB from {} to {}",
                    old_app_dir.display(),
                    new_app_dir.display()
                );
                let _ = fs::write(&marker, "1");
                return;
            }
        }

        // Even if nothing was migrated, write marker to avoid repeated scans.
        let _ = fs::write(&marker, "0");
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

        let new_app_dir = data_home.join(CURRENT_BUNDLE_ID);

        let new_data_dir = match find_origin_data_dir(&new_app_dir) {
            Some(d) => d,
            None => return,
        };

        let marker = new_data_dir.join(".ensu_legacy_migrated");
        if marker.exists() {
            return;
        }

        for name in OLD_APP_NAMES {
            let old_app_dir = data_home.join(name);
            if !old_app_dir.exists() {
                continue;
            }
            let old_data_dir = match find_origin_data_dir(&old_app_dir) {
                Some(d) => d,
                None => continue,
            };

            if copy_indexeddb_dirs(&old_data_dir, &new_data_dir) {
                eprintln!(
                    "[ensu migration] Migrated IndexedDB from {} to {}",
                    old_app_dir.display(),
                    new_app_dir.display()
                );
                let _ = fs::write(&marker, "1");
                return;
            }
        }

        let _ = fs::write(&marker, "0");
    }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

/// Find the origin-hash data directory inside a WebKit app directory.
///
/// Structure: `<app>/WebsiteData/Default/<hash>/<hash>/`
///
/// Returns the inner `<hash>/<hash>/` path if found.
fn find_origin_data_dir(app_dir: &Path) -> Option<PathBuf> {
    let default_dir = app_dir.join("WebsiteData").join("Default");
    if !default_dir.exists() {
        return None;
    }
    // The first (and usually only) subdirectory is the origin hash.
    let hash_name = fs::read_dir(&default_dir)
        .ok()?
        .flatten()
        .find(|e| e.path().is_dir())?
        .file_name();
    let inner = default_dir.join(&hash_name).join(&hash_name);
    if inner.exists() {
        Some(inner)
    } else {
        None
    }
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
            continue; // Already have this database
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

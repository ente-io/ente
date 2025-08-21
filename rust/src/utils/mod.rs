use dirs;
use std::path::PathBuf;

/// Get the CLI configuration directory
pub fn get_cli_config_dir() -> crate::Result<PathBuf> {
    // Check environment variable first
    if let Ok(config_dir) = std::env::var("ENTE_CLI_CONFIG_DIR") {
        return Ok(PathBuf::from(config_dir));
    }

    // For backward compatibility
    if let Ok(config_dir) = std::env::var("ENTE_CLI_CONFIG_PATH") {
        return Ok(PathBuf::from(config_dir));
    }

    // Default to ~/.ente
    let home_dir = dirs::home_dir()
        .ok_or_else(|| crate::Error::Generic("Could not determine home directory".into()))?;

    let cli_path = home_dir.join(".ente");

    // Create directory if it doesn't exist
    if !cli_path.exists() {
        std::fs::create_dir_all(&cli_path)?;
    }

    Ok(cli_path)
}

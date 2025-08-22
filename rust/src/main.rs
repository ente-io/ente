use clap::Parser;
use ente_rs::{
    Result,
    cli::{Cli, Commands},
    storage::Storage,
};

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize logger
    env_logger::init();

    // Initialize libsodium
    ente_rs::crypto::init()?;
    
    // Initialize storage
    let config_dir = ente_rs::utils::get_cli_config_dir()?;
    let db_path = config_dir.join("ente.db");
    let _storage = Storage::new(&db_path)?;

    // Parse CLI arguments
    let cli = Cli::parse();

    // Handle commands
    match cli.command {
        Commands::Version => {
            println!("ente-rs version {}", ente_rs::cli::version::VERSION);
        }
        Commands::Account(_account_cmd) => {
            // TODO: Implement account commands
            println!("Account command not yet implemented");
        }
        Commands::Export(_export_cmd) => {
            // TODO: Implement export command
            println!("Export command not yet implemented");
        }
    }

    Ok(())
}

use clap::Parser;
use ente_rs::{
    Result,
    cli::{Cli, Commands},
    commands,
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
    let storage = Storage::new(&db_path)?;

    // Parse CLI arguments
    let cli = Cli::parse();

    // Handle commands
    match cli.command {
        Commands::Version => {
            println!("ente-rs version {}", ente_rs::cli::version::VERSION);
        }
        Commands::Account(account_cmd) => {
            commands::account::handle_account_command(account_cmd, &storage).await?;
        }
        Commands::Export(export_cmd) => {
            commands::export::run_export(export_cmd.account).await?;
        }
        Commands::Sync(sync_cmd) => {
            commands::sync::run_sync(sync_cmd.account, sync_cmd.metadata_only, sync_cmd.full)
                .await?;
        }
    }

    Ok(())
}

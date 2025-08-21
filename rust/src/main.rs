use clap::Parser;
use ente_rs::{
    Result,
    cli::{Cli, Commands},
};

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize logger
    env_logger::init();

    // Initialize libsodium
    ente_rs::crypto::init()?;

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

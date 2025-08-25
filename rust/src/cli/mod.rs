use clap::{Parser, Subcommand};

pub mod account;
pub mod export;
pub mod sync;
pub mod version;

#[derive(Parser)]
#[command(name = "ente")]
#[command(about = "CLI tool for exporting your photos from ente.io", long_about = None)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    /// Manage account settings
    Account(account::AccountCommand),

    /// Export photos and files
    Export(export::ExportCommand),

    /// Sync collections and file metadata
    Sync(sync::SyncCommand),

    /// Print version information
    Version,
}

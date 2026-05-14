use clap::{Parser, Subcommand};

pub mod account;
pub mod export;
pub mod paste;
pub mod version;

#[derive(Parser)]
#[command(name = "ente")]
#[command(about = "CLI tool for exporting your photos from Ente", long_about = None)]
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

    /// Create and consume encrypted pastes
    Paste(paste::PasteCommand),

    /// Print version information
    Version,
}

use clap::{Args, Subcommand};
use std::path::PathBuf;

#[derive(Args)]
pub struct PasteCommand {
    #[command(subcommand)]
    pub command: PasteSubcommands,
}

#[derive(Subcommand)]
pub enum PasteSubcommands {
    /// Create a one-time encrypted paste
    Create {
        /// Text to paste. If omitted, stdin is used when piped.
        #[arg(value_name = "TEXT", conflicts_with = "file")]
        text: Option<String>,

        /// Read paste text from a file. Use '-' for stdin.
        #[arg(short, long)]
        file: Option<PathBuf>,

        /// API endpoint
        #[arg(long, default_value = "https://api.ente.com")]
        endpoint: String,

        /// Public paste origin used for the generated link
        #[arg(long, default_value = "https://paste.ente.com")]
        paste_origin: String,
    },

    /// Consume a one-time encrypted paste
    #[command(alias = "read")]
    Consume {
        /// Paste URL or access token
        link_or_token: String,

        /// Fragment key when passing only an access token
        #[arg(long)]
        key: Option<String>,

        /// API endpoint
        #[arg(long, default_value = "https://api.ente.com")]
        endpoint: String,
    },
}

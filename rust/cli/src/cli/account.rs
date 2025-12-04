use clap::{Args, Subcommand};

#[derive(Args)]
pub struct AccountCommand {
    #[command(subcommand)]
    pub command: AccountSubcommands,
}

#[derive(Subcommand)]
pub enum AccountSubcommands {
    /// List configured accounts
    List,

    /// Login into existing account
    Add {
        /// Email address (optional - will prompt if not provided)
        #[arg(long)]
        email: Option<String>,

        /// Password (optional - will prompt if not provided)
        #[arg(long)]
        password: Option<String>,

        /// Specify the app (photos, locker, auth)
        #[arg(long, default_value = "photos")]
        app: String,

        /// API endpoint (defaults to https://api.ente.io)
        #[arg(long, default_value = "https://api.ente.io")]
        endpoint: String,

        /// Export directory path
        #[arg(long)]
        export_dir: Option<String>,
    },

    /// Update an existing account's export directory
    Update {
        /// Email address of the account
        #[arg(long)]
        email: String,

        /// Export directory path
        #[arg(long)]
        dir: String,

        /// Specify the app (photos, locker, auth)
        #[arg(long, default_value = "photos")]
        app: String,
    },

    /// Get token for an account for a specific app
    GetToken {
        /// Email address of the account
        #[arg(long)]
        email: String,

        /// Specify the app (photos, locker, auth)
        #[arg(long, default_value = "photos")]
        app: String,
    },
}

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
    Add,
    
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
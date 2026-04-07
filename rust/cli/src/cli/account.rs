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
    #[command(alias = "login")]
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

        /// Email verification code for email-MFA accounts
        #[arg(long)]
        otp: Option<String>,

        /// TOTP code to use if login requires two-factor verification
        #[arg(long)]
        totp_code: Option<String>,

        /// Preferred second-factor method when multiple are available (totp or passkey)
        #[arg(long)]
        second_factor: Option<String>,
    },

    /// Create a new account via email verification, key setup, and SRP registration
    #[command(alias = "signup")]
    Create {
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

        /// Signup email verification code
        #[arg(long)]
        otp: Option<String>,

        /// Referral/source string to pass during verify-email
        #[arg(long)]
        source: Option<String>,

        /// Enable TOTP two-factor immediately after signup
        #[arg(long)]
        setup_2fa: bool,

        /// TOTP code to use when enabling two-factor
        #[arg(long)]
        totp_code: Option<String>,

        /// Print the recovery key after signup
        #[arg(long)]
        show_recovery_key: bool,
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

    /// Enable TOTP two-factor for an existing account
    #[command(name = "two-factor", alias = "2fa")]
    TwoFactor {
        /// Email address of the account
        #[arg(long)]
        email: String,

        /// Specify the app (photos, locker, auth)
        #[arg(long, default_value = "photos")]
        app: String,

        /// TOTP code to use for enabling two-factor
        #[arg(long)]
        totp_code: Option<String>,

        /// Print the recovery key after enabling two-factor
        #[arg(long)]
        show_recovery_key: bool,
    },
}

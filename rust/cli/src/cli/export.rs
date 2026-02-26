use clap::Args;

#[derive(Args)]
pub struct ExportCommand {
    /// Email of specific account to export (exports all if not specified)
    #[arg(long)]
    pub account: Option<String>,

    /// Include shared albums (pass --shared=false to exclude)
    #[arg(long, default_value_t = true, action = clap::ArgAction::Set)]
    pub shared: bool,

    /// Include hidden albums (pass --hidden=false to exclude)
    #[arg(long, default_value_t = true, action = clap::ArgAction::Set)]
    pub hidden: bool,

    /// Comma-separated list of album names to export
    #[arg(long, value_delimiter = ',')]
    pub albums: Option<Vec<String>>,

    /// Comma-separated list of account emails to export from
    #[arg(long, value_delimiter = ',')]
    pub emails: Option<Vec<String>>,
}

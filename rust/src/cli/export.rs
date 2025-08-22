use clap::Args;

#[derive(Args)]
pub struct ExportCommand {
    /// Email of specific account to export (exports all if not specified)
    #[arg(long)]
    pub account: Option<String>,
    
    /// Include shared albums (pass --shared=false to exclude)
    #[arg(long, default_value = "true")]
    pub shared: bool,

    /// Include hidden albums (pass --hidden=false to exclude)
    #[arg(long, default_value = "true")]
    pub hidden: bool,

    /// Comma-separated list of album names to export
    #[arg(long, value_delimiter = ',')]
    pub albums: Option<Vec<String>>,

    /// Comma-separated list of emails to export files shared with
    #[arg(long, value_delimiter = ',')]
    pub emails: Option<Vec<String>>,
}

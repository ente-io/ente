use clap::Args;

#[derive(Args)]
pub struct SyncCommand {
    /// Email of the account to sync (optional, syncs all if not specified)
    #[arg(long)]
    pub account: Option<String>,

    /// Only sync metadata, don't download files
    #[arg(long)]
    pub metadata_only: bool,

    /// Force full sync instead of incremental
    #[arg(long)]
    pub full: bool,
}

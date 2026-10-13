mod api;
mod args;
mod auth;
mod core_db;
mod db;
mod home;
mod login;
mod output;
mod password;
mod paste;
mod photos;
mod vault;

use std::{
    io::{Read, Write},
    path::Path,
};

use anyhow::{Context, Result, bail, ensure};
use clap::{Arg, ArgAction, CommandFactory, FromArgMatches};
use ente_core::{b64, crypto::Key};
use serde::de::DeserializeOwned;
use serde_json::json;
use zeroize::Zeroizing;

use args::{AccountCommand, App, Cli, Command, KeyCommand, LockerCommand, Options, VaultCommand};
use output::AccountView;
use vault::{Account, State, Vault};

#[tokio::main]
async fn main() {
    let mut command = Cli::command().subcommand_required(false).arg(
        Arg::new("help-all")
            .long("help-all")
            .action(ArgAction::SetTrue)
            .help("Print help for all commands"),
    );
    let matches = command.get_matches_mut();
    let result = if matches.get_flag("help-all") {
        command.build();
        print_all_help(&mut command, &mut std::io::stdout().lock())
    } else {
        let cli = Cli::from_arg_matches(&matches)
            .unwrap_or_else(|error| error.format(&mut command).exit());
        run(cli).await
    };
    if let Err(error) = result {
        eprintln!("Error: {error:#}");
        std::process::exit(1);
    }
}

fn print_all_help(command: &mut clap::Command, output: &mut impl Write) -> Result<()> {
    writeln!(
        output,
        "=== {} ===",
        command.get_bin_name().unwrap_or_else(|| command.get_name())
    )?;
    writeln!(output, "{}", command.render_long_help())?;
    let mut children: Vec<_> = command
        .get_subcommands_mut()
        .filter(|child| !child.is_hide_set() && child.get_name() != "help")
        .collect();
    children.sort_by(|a, b| {
        (a.get_display_order(), a.get_name()).cmp(&(b.get_display_order(), b.get_name()))
    });
    for child in children {
        print_all_help(child, output)?;
    }
    Ok(())
}

async fn run(cli: Cli) -> Result<()> {
    let Cli { options, command } = cli;
    match command {
        Command::Photos { selector, command } => {
            photos::run(command, selector.account.as_deref(), &options).await
        }
        Command::Locker {
            selector,
            command: LockerCommand::Api(args),
        } => api::run(App::Locker, args, selector.account.as_deref(), &options).await,
        Command::Auth { selector, command } => {
            auth::run(command, selector.account.as_deref(), &options).await
        }
        Command::Paste { command } => paste::run(command, &options).await,
        Command::Account { command } => account_command(command, &options).await,
        Command::Vault {
            command:
                VaultCommand::Key {
                    command: KeyCommand::Generate,
                },
        } => vault_key(options.json),
    }
}

fn vault_key(json_output: bool) -> Result<()> {
    let key = Zeroizing::new(b64::encode(Key::generate().as_bytes()));
    if json_output {
        output::json(&json!({ "key": key.as_str() }))
    } else {
        writeln!(std::io::stdout(), "{}", key.as_str()).map_err(Into::into)
    }
}

async fn account_command(command: AccountCommand, options: &Options) -> Result<()> {
    match command {
        AccountCommand::Login(args) => {
            ensure!(!options.offline, "login requires network access");
            let app = args.app;
            let (state, index) = login::login(args, options).await?;
            let account = AccountView::new(&state.accounts[index], state.selected);
            if options.json {
                output::json(&json!({ "account": account, "app": app }))
            } else {
                output::account(&account)
            }
        }
        AccountCommand::List => {
            let state = State::load()?;
            let accounts: Vec<_> = state
                .accounts
                .iter()
                .map(|a| AccountView::new(a, state.selected))
                .collect();
            if options.json {
                output::json(&accounts)
            } else {
                output::accounts(&accounts)
            }
        }
        AccountCommand::View { name } => {
            let state = State::load()?;
            let index = state.resolve(name.as_deref())?;
            output_account(state, index, options.json)
        }
        AccountCommand::Token { name, app } => {
            let state = State::load()?;
            let index = state.resolve(name.as_deref())?;
            let token = Zeroizing::new(b64::encode_url_safe(state.accounts[index].token(app)?));
            if options.json {
                output::json(&json!({ "token": token.as_str() }))
            } else {
                writeln!(std::io::stdout(), "{}", token.as_str()).map_err(Into::into)
            }
        }
        AccountCommand::Switch { name } => {
            let mut vault = Vault::open()?;
            let state = &mut vault.state;
            let index = state.named(&name)?;
            let selected = Some(state.accounts[index].storage_id);
            if state.selected != selected {
                state.selected = selected;
                vault.save()?;
            }
            output_account(vault.into_state(), index, options.json)
        }
        AccountCommand::Rename { name, new_name } => {
            let mut vault = Vault::open()?;
            let state = &mut vault.state;
            let index = state.named(&name)?;
            if name != new_name {
                state.check_name(&new_name)?;
                state.accounts[index].name = new_name;
                vault.save()?;
            }
            output_account(vault.into_state(), index, options.json)
        }
        AccountCommand::Logout { name, app, local } => {
            ensure!(
                !options.offline || local,
                "logging out on the server requires network access; use --local to forget the account on this device"
            );
            let mut vault = Vault::open()?;
            let index = vault.state.resolve(name.as_deref())?;
            let account = &vault.state.accounts[index];
            let name = account.name.clone();
            let apps = match app {
                Some(app) => vec![app],
                None => account.sessions.keys().copied().collect(),
            };
            let home = home::try_lock_account(account.storage_id)?;
            let removal = if account
                .sessions
                .keys()
                .all(|saved| app.is_none_or(|app| *saved == app))
            {
                Some(home.for_removal()?)
            } else {
                None
            };
            if !local {
                for (completed, app) in apps.iter().enumerate() {
                    if let Err(error) = api::logout(&vault.state.accounts[index], *app).await {
                        if completed > 0 {
                            vault.save()?;
                        }
                        let remaining = vault.state.accounts[index]
                            .sessions
                            .keys()
                            .copied()
                            .collect::<Vec<_>>();
                        bail!(
                            "cannot log out of {} for {name:?}: {error:#}. Still logged in: {}. Retry when the server is reachable, or use --local to forget the account on this device.",
                            app.display_name(),
                            app_names(&remaining),
                        );
                    }
                    vault.state.accounts[index].sessions.remove(app);
                }
            } else {
                vault.state.accounts[index].sessions.clear();
            }
            let removed = vault.state.accounts[index]
                .sessions
                .is_empty()
                .then(|| remove_account(&mut vault.state, index));
            vault.save()?;
            if let Some(removal) = removal {
                removal.remove()?;
            }
            let state = vault.into_state();
            let account = AccountView::new(
                removed.as_ref().unwrap_or_else(|| &state.accounts[index]),
                state.selected,
            );
            let message = if removed.is_none() {
                format!("Logged out of {} for {name:?}.", app_names(&apps))
            } else if local && !apps.is_empty() {
                format!("Removed account {name:?} from this device. Server logout was skipped.")
            } else if apps.is_empty() {
                format!("Removed account {name:?} from this device.")
            } else {
                format!(
                    "Logged out of {}. Removed account {name:?} from this device.",
                    app_names(&apps)
                )
            };
            let result = match app {
                Some(app) => json!({ "account": account, "app": app, "remoteLogout": !local }),
                None => json!({ "account": account, "apps": apps, "remoteLogout": !local }),
            };
            output::action(options.json, &result, &message)
        }
    }
}

fn remove_account(state: &mut State, index: usize) -> Account {
    let account = state.accounts.remove(index);
    if state.selected == Some(account.storage_id) {
        state.selected = None;
    }
    account
}

fn app_names(apps: &[App]) -> String {
    let names = apps
        .iter()
        .map(|app| app.display_name())
        .collect::<Vec<_>>();
    match names.as_slice() {
        [] => String::new(),
        [name] => (*name).to_owned(),
        [first, second] => format!("{first} and {second}"),
        [first, middle @ .., last] => {
            format!("{first}, {}, and {last}", middle.join(", "))
        }
    }
}

fn output_account(state: State, index: usize, json_output: bool) -> Result<()> {
    let account = AccountView::new(&state.accounts[index], state.selected);
    if json_output {
        output::json(&account)
    } else {
        output::account(&account)
    }
}

fn read_input(path: &Path, limit: u64) -> Result<Zeroizing<Vec<u8>>> {
    let mut bytes = Zeroizing::new(Vec::new());
    if path == Path::new("-") {
        std::io::stdin()
            .take(limit)
            .read_to_end(&mut bytes)
            .context("cannot read stdin")?;
    } else {
        std::fs::File::open(path)
            .with_context(|| format!("cannot open {}", path.display()))?
            .take(limit)
            .read_to_end(&mut bytes)
            .with_context(|| format!("cannot read {}", path.display()))?;
    }
    Ok(bytes)
}

fn parse_json<T: DeserializeOwned>(bytes: &[u8]) -> Result<T> {
    serde_json::from_slice(bytes).map_err(|error| {
        anyhow::anyhow!(
            "invalid JSON at line {}, column {}",
            error.line(),
            error.column()
        )
    })
}

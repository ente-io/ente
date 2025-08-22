#![allow(dead_code)]

use crate::{
    Result,
    models::account::{Account, AccountSecrets, App},
};
use rusqlite::{Connection, OptionalExtension, Row, params};
use std::time::{SystemTime, UNIX_EPOCH};

pub struct AccountStore<'a> {
    conn: &'a Connection,
}

impl<'a> AccountStore<'a> {
    pub fn new(conn: &'a Connection) -> Self {
        Self { conn }
    }

    /// Add a new account
    pub fn add(&self, account: &Account) -> Result<i64> {
        let now = current_timestamp();

        self.conn.execute(
            "INSERT INTO accounts (email, user_id, app, export_dir, created_at, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
            params![
                account.email,
                account.user_id,
                format!("{:?}", account.app).to_lowercase(),
                account.export_dir,
                now,
                now
            ],
        )?;

        Ok(self.conn.last_insert_rowid())
    }

    /// Get an account by email and app
    pub fn get(&self, email: &str, app: App) -> Result<Option<Account>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, email, user_id, app, export_dir FROM accounts 
             WHERE email = ?1 AND app = ?2",
        )?;

        let account = stmt
            .query_row(params![email, format!("{app:?}").to_lowercase()], |row| {
                row_to_account(row)
            })
            .optional()?;

        Ok(account)
    }

    /// List all accounts
    pub fn list(&self) -> Result<Vec<Account>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, email, user_id, app, export_dir FROM accounts 
             ORDER BY email, app",
        )?;

        let accounts = stmt
            .query_map([], row_to_account)?
            .collect::<std::result::Result<Vec<_>, _>>()?;

        Ok(accounts)
    }

    /// Update account export directory
    pub fn update_export_dir(&self, email: &str, app: App, export_dir: &str) -> Result<()> {
        let now = current_timestamp();

        self.conn.execute(
            "UPDATE accounts SET export_dir = ?1, updated_at = ?2 
             WHERE email = ?3 AND app = ?4",
            params![export_dir, now, email, format!("{app:?}").to_lowercase()],
        )?;

        Ok(())
    }

    /// Delete an account
    pub fn delete(&self, account_id: i64) -> Result<()> {
        self.conn
            .execute("DELETE FROM accounts WHERE id = ?1", params![account_id])?;
        Ok(())
    }

    /// Store account secrets (encrypted)
    pub fn store_secrets(&self, account_id: i64, secrets: &AccountSecrets) -> Result<()> {
        let now = current_timestamp();

        self.conn.execute(
            "INSERT OR REPLACE INTO secrets 
             (account_id, token, master_key, secret_key, public_key, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
            params![
                account_id,
                &secrets.token,
                &secrets.master_key,
                &secrets.secret_key,
                &secrets.public_key,
                now
            ],
        )?;

        Ok(())
    }

    /// Get account secrets
    pub fn get_secrets(&self, account_id: i64) -> Result<Option<AccountSecrets>> {
        let mut stmt = self.conn.prepare(
            "SELECT token, master_key, secret_key, public_key FROM secrets 
             WHERE account_id = ?1",
        )?;

        let secrets = stmt
            .query_row(params![account_id], |row| {
                Ok(AccountSecrets {
                    token: row.get(0)?,
                    master_key: row.get(1)?,
                    secret_key: row.get(2)?,
                    public_key: row.get(3)?,
                })
            })
            .optional()?;

        Ok(secrets)
    }
}

fn row_to_account(row: &Row) -> rusqlite::Result<Account> {
    let app_str: String = row.get(3)?;
    let app = match app_str.as_str() {
        "photos" => App::Photos,
        "locker" => App::Locker,
        "auth" => App::Auth,
        _ => App::Photos, // Default fallback
    };

    Ok(Account {
        id: row.get(0)?,
        email: row.get(1)?,
        user_id: row.get(2)?,
        app,
        export_dir: row.get(4)?,
    })
}

fn current_timestamp() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs() as i64
}

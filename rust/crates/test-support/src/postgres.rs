use postgresql_embedded::Settings;
use postgresql_embedded::blocking::PostgreSQL;

use crate::{
    TestResult,
    net::{LOCAL_HOST, free_port},
};

const DATABASE: &str = "ente_test";

/// A temporary local Postgres, torn down on drop.
pub struct Postgres {
    inner: PostgreSQL,
}

impl Postgres {
    pub fn host(&self) -> &str {
        &self.inner.settings().host
    }

    pub fn port(&self) -> u16 {
        self.inner.settings().port
    }

    pub fn username(&self) -> &str {
        &self.inner.settings().username
    }

    pub fn password(&self) -> &str {
        &self.inner.settings().password
    }

    pub fn database(&self) -> &str {
        DATABASE
    }
}

pub fn start() -> TestResult<Postgres> {
    let settings = Settings {
        temporary: true,
        host: LOCAL_HOST.to_string(),
        port: free_port()?,
        ..Settings::default()
    };
    let mut inner = PostgreSQL::new(settings);
    inner.setup()?;
    inner.start()?;
    inner.create_database(DATABASE)?;
    Ok(Postgres { inner })
}

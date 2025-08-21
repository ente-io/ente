use crate::Result;
use sled::Db;
use std::path::Path;

pub struct Storage {
    db: Db,
}

impl Storage {
    pub fn new<P: AsRef<Path>>(path: P) -> Result<Self> {
        let db = sled::open(path)?;
        Ok(Self { db })
    }
    
    // TODO: Implement storage methods
}
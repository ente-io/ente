use flutter_rust_bridge::frb;
use usearch::{ffi::Matches, Index, IndexOptions, MetricKind, ScalarKind};

use std::error::Error;
use std::path::PathBuf;

#[frb(opaque)]
pub struct VectorDB {
    index: Index,
    path: PathBuf,
}

impl VectorDB {
    #[frb(sync)]
    pub fn new(file_path: &str, dimensions: usize) -> Result<Self, Box<dyn Error>> {
        let path = PathBuf::from(file_path);
        let file_exists = path.try_exists().unwrap_or(false);

        let mut options = IndexOptions::default();
        options.dimensions = dimensions;
        options.metric = MetricKind::IP;
        options.quantization = ScalarKind::F32;
        options.connectivity = 0; // auto
        options.expansion_add = 0; // auto
        options.expansion_search = 0; // auto

        let index = Index::new(&options)?;
        index.reserve(1000)?;

        let db = Self { index, path };

        if file_exists {
            println!("Loading index from disk.");
            db.index.load(file_path)?;
        } else {
            println!("Creating new index.");
            db.save_index()?;
        }
        Ok(db)
    }

    fn save_index(&self) -> Result<(), Box<dyn Error>> {
        // Ensure directory exists
        if let Some(parent) = self.path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        self.index.save(self.path.to_str().unwrap())?;
        Ok(())
    }

    fn ensure_capacity(&self, margin: usize) -> Result<(), Box<dyn Error>> {
        let current_size = self.index.size();
        let capacity = self.index.capacity();
        if current_size + margin >= capacity {
            self.index.reserve(current_size + margin)?;
        }
        Ok(())
    }

    pub fn add_vector(&mut self, key: u64, vector: &Vec<f32>) -> Result<(), Box<dyn Error>> {
        self.ensure_capacity(1)?;
        self.index.add(key, vector)?;
        self.save_index()?;
        Ok(())
    }

    pub fn bulk_add_vectors(
        &mut self,
        keys: Vec<u64>,
        vectors: &Vec<Vec<f32>>,
    ) -> Result<(), Box<dyn Error>> {
        self.ensure_capacity(keys.len())?;
        for (key, vector) in keys.iter().zip(vectors.iter()) {
            self.index.add(*key, vector)?;
        }
        self.save_index()?;
        Ok(())
    }

    pub fn search_vectors(
        &self,
        query: &Vec<f32>,
        count: usize,
    ) -> Result<Matches, Box<dyn Error>> {
        Ok(self.index.search(query, count)?)
    }

    pub fn get_vector(&self, key: u64) -> Result<Vec<f32>, Box<dyn Error>> {
        let mut vector: Vec<f32> = vec![0.0; self.index.dimensions()];
        self.index.get(key, &mut vector)?;
        Ok(vector)
    }

    pub fn remove_vector(&mut self, key: u64) -> Result<usize, Box<dyn Error>> {
        let removed_count = self.index.remove(key)?;
        self.save_index()?;
        Ok(removed_count)
    }

    pub fn reset_index(&mut self) -> Result<(), Box<dyn Error>> {
        self.index.reset()?;
        self.save_index()?;
        Ok(())
    }

    pub fn delete_index(self) -> Result<(), Box<dyn Error>> {
        if self.path.exists() {
            std::fs::remove_file(&self.path)?;
        } else {
            println!("Index file does not exist.");
        }
        Ok(())
    }

    pub fn get_index_stats(self) -> (usize, usize, usize, usize, usize) {
        let size = self.index.size();
        let capacity = self.index.capacity();
        let dimensions = self.index.dimensions();
        let expansion_add = self.index.expansion_add();
        let expansion_search = self.index.expansion_search();

        (size, capacity, dimensions, expansion_add, expansion_search)
    }
}

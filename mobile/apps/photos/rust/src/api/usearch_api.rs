use flutter_rust_bridge::frb;
use usearch::{Index, IndexOptions, MetricKind, ScalarKind};

use std::path::PathBuf;

#[frb(opaque)]
pub struct VectorDB {
    index: Index,
    path: PathBuf,
}

impl VectorDB {
    #[frb(sync)]
    pub fn new(file_path: &str, dimensions: usize) -> Self {
        let path = PathBuf::from(file_path);
        let file_exists = path.try_exists().unwrap_or(false);

        let mut options = IndexOptions::default();
        options.dimensions = dimensions;
        options.metric = MetricKind::IP;
        options.quantization = ScalarKind::F32;
        options.connectivity = 0; // auto
        options.expansion_add = 0; // auto
        options.expansion_search = 0; // auto

        let index = Index::new(&options).expect("Failed to create index");
        index
            .reserve(1000)
            .expect("Failed to reserve space in index");

        let db = Self { index, path };

        if file_exists {
            println!("Loading index from disk.");
            db.index.load(file_path).expect("Failed to load index");
        } else {
            println!("Creating new index.");
            db.save_index();
        }
        db
    }

    fn save_index(&self) {
        // Ensure directory exists
        if let Some(parent) = self.path.parent() {
            std::fs::create_dir_all(parent).expect("Failed to create directory");
        }
        self.index
            .save(self.path.to_str().expect("Invalid path"))
            .expect("Failed to save index");
    }

    fn ensure_capacity(&self, margin: usize) {
        let current_size = self.index.size();
        let capacity = self.index.capacity();
        if current_size + margin + 1000 >= capacity {
            self.index
                .reserve(current_size + margin)
                .expect("Failed to reserve space in index");
        }
    }

    pub fn add_vector(&self, key: u64, vector: &Vec<f32>) {
        if self.contains_vector(key) {
            self.remove_vector(key);
        } else {
            self.ensure_capacity(1);
        }
        self.index.add(key, vector).expect("Failed to add vector");
        self.save_index();
    }

    pub fn bulk_add_vectors(&self, keys: Vec<u64>, vectors: &Vec<Vec<f32>>) {
        self.ensure_capacity(keys.len());
        for (key, vector) in keys.iter().zip(vectors.iter()) {
            if self.contains_vector(*key) {
                self.remove_vector(*key);
            }
            self.index
                .add(*key, vector)
                .expect("Failed to (bulk) add vector");
        }
        self.save_index();
    }

    pub fn search_vectors(
        &self,
        query: &Vec<f32>,
        count: usize,
        exact: bool,
    ) -> (Vec<u64>, Vec<f32>) {
        let matches = if exact {
            self.index
                .exact_search(query, count)
                .expect("Failed to exact search vectors")
        } else {
            self.index
                .search(query, count)
                .expect("Failed to search vectors")
        };
        (matches.keys, matches.distances)
    }

    pub fn bulk_search_vectors(
        &self,
        queries: &Vec<Vec<f32>>,
        count: usize,
        exact: bool,
    ) -> (Vec<Vec<u64>>, Vec<Vec<f32>>) {
        let mut keys = Vec::new();
        let mut distances = Vec::new();

        for query in queries {
            let (keys_result, distances_result) = self.search_vectors(query, count, exact);
            keys.push(keys_result);
            distances.push(distances_result);
        }
        (keys, distances)
    }

    pub fn bulk_search_keys(
        &self,
        potential_keys: &Vec<u64>,
        count: usize,
        exact: bool,
    ) -> (Vec<u64>, Vec<Vec<u64>>, Vec<Vec<f32>>) {
        // let max_contained_keys = potential_keys.len();
        let mut contained_keys = Vec::new();
        let mut queries = Vec::new();

        for key in potential_keys {
            let contains: bool = self.index.contains(*key);
            if contains {
                let embedding = self.get_vector(*key);
                contained_keys.push(*key);
                queries.push(embedding);
            }
        }

        let mut closeby_keys = Vec::new();
        let mut distances = Vec::new();
        for query in &queries {
            let (keys_result, distances_result) = self.search_vectors(query, count, exact);
            closeby_keys.push(keys_result);
            distances.push(distances_result);
        }
        if contained_keys.len() != closeby_keys.len() {
            panic!("The number of contained keys does not match the number of keys");
        }
        (contained_keys, closeby_keys, distances)
    }

    /// Check if a vector with the given key exists in the index.
    /// `true` if the index contains the vector with the given key, `false` otherwise.
    pub fn contains_vector(&self, key: u64) -> bool {
        self.index.contains(key)
    }

    pub fn get_vector(&self, key: u64) -> Vec<f32> {
        let mut vector: Vec<f32> = vec![0.0; self.index.dimensions()];
        self.index
            .get(key, &mut vector)
            .expect("Failed to get vector");
        vector
    }

    pub fn bulk_get_vectors(&self, keys: Vec<u64>) -> Vec<Vec<f32>> {
        let mut vectors = Vec::new();
        for key in keys {
            let vector = self.get_vector(key);
            vectors.push(vector);
        }
        vectors
    }

    pub fn remove_vector(&self, key: u64) -> usize {
        let removed_count = self.index.remove(key).expect("Failed to remove vector");
        self.save_index();
        removed_count
    }

    pub fn bulk_remove_vectors(&self, keys: Vec<u64>) -> usize {
        let mut removed_count = 0;
        for key in keys {
            removed_count += self
                .index
                .remove(key)
                .expect("Failed to (bulk) remove vector");
        }
        self.save_index();
        removed_count
    }

    pub fn reset_index(&self) {
        self.index.reset().expect("Failed to reset index");
        self.index
            .reserve(1000)
            .expect("Failed to reserve space in index");
        self.save_index();
    }

    pub fn delete_index(self) {
        if self.path.exists() {
            std::fs::remove_file(&self.path).expect("Failed to delete index file");
        } else {
            println!("Index file does not exist.");
        }
    }

    pub fn get_index_stats(&self) -> (usize, usize, usize, usize, usize, usize, usize) {
        let size = self.index.size();
        let capacity = self.index.capacity();
        let dimensions = self.index.dimensions();

        let file_size = self.index.serialized_length();
        let memory_usage = self.index.memory_usage();

        let expansion_add = self.index.expansion_add();
        let expansion_search = self.index.expansion_search();

        (
            size,
            capacity,
            dimensions,
            file_size,
            memory_usage,
            expansion_add,
            expansion_search,
        )
    }
}

use usearch::{Index, IndexOptions, MetricKind, ScalarKind};

// Create DB index
fn create_index() -> Index {
    let mut options = IndexOptions::default();
    options.dimensions = 192; // Set the number of dimensions for vectors
    options.metric = MetricKind::Cos; // Use cosine similarity for distance measurement
    options.quantization = ScalarKind::F32; // Use 32-bit floating point numbers
    options.connectivity = 0; // zero for auto
    options.expansion_add = 0; // zero for auto
    options.expansion_search = 0; // zero for auto

    let index = Index::new(&options).expect("Failed to create index.");
    index.reserve(1000).expect("Failed to reserve capacity.");
    index
}

// Get the DB
fn get_index(file_path: &str) -> Index {
    let file_exists: bool = std::path::Path::new(file_path).try_exists().unwrap();
    let index = create_index();
    if file_exists {
        let index = load_index(index, file_path);
        index
    } else {
        save_index(&index, file_path);
        index
    }
}

// Save to disk
fn save_index(index: &Index, file_path: &str) {
    index.save(file_path).expect("Failed to save index.");
}

// Load from disk
fn load_index(index: Index, file_path: &str) -> Index {
    index.load(file_path).expect("Failed to load index.");
    index
}

// Changes to DB index
fn ensure_capacity(index: &Index, margin: usize) {
    let current_size = index.size();
    let capacity = index.capacity();
    if current_size + margin >= capacity {
        index
            .reserve(current_size + margin)
            .expect("Failed to reserve capacity.");
    }
}

pub fn get_index_stats(index_path: &str) -> (usize, usize, usize, usize, usize) {
    let index = get_index(index_path);
    let size = index.size();
    let capacity = index.capacity();
    let dimensions = index.dimensions();
    let expansion_add = index.expansion_add();
    let expansion_search = index.expansion_search();

    (size, capacity, dimensions, expansion_add, expansion_search)
}

// Add to index
pub fn add_vector(index_path: &str, key: u64, vector: &Vec<f32>) {
    let index = get_index(index_path);
    ensure_capacity(&index, 1);
    index.add(key, vector).expect("Failed to add vector.");
    save_index(&index, index_path);
}

// Bulk add to index
pub fn bulk_add_vectors(index_path: &str, keys: Vec<u64>, vectors: &Vec<Vec<f32>>) {
    let index = get_index(index_path);
    ensure_capacity(&index, keys.len());
    for (key, vector) in keys.iter().zip(vectors.iter()) {
        index.add(*key, vector).expect("Failed to add vector.");
    }
    save_index(&index, index_path);
}

// Search in index
pub fn search_vectors(index_path: &str, query: &Vec<f32>, count: usize) -> (Vec<u64>, Vec<f32>) {
    let index: Index = get_index(index_path);
    let results = index.search(query, count).expect("Search failed.");

    (results.keys, results.distances)
}

// Read from index
pub fn get_vector(index_path: &str, key: u64) -> Vec<f32> {
    let index = get_index(index_path);
    let mut vector: Vec<f32> = vec![0.0; index.dimensions()];
    let _ = index
        .get(key, &mut vector)
        .expect("Failed to export vector.");

    vector
}

// Delete from index
pub fn remove_vector(index_path: &str, key: u64) -> usize {
    let index = get_index(index_path);
    let removed_count = index.remove(key).expect("Failed to remove vector.");
    save_index(&index, index_path);

    removed_count
}

// Reset index
pub fn reset_index(index_path: &str) {
    let index = get_index(index_path);
    index.reset().expect("Failed to clear index.");

    save_index(&index, index_path);
}

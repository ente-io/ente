//! Pet clustering engine — 3-phase fused clustering.
//!
//! Translates the Python `ClusterEngine` from `pet_pipeline.py` into Rust.
//! Phases:
//! - Phase 1: Face-based density clustering (HDBSCAN-style via mutual reachability)
//! - Phase 2: Body rescue — assign unclustered images to existing clusters
//! - Phase 2b: Body-only clustering for remaining unclustered images
//! - Phase 3: Cross-cluster merge — merge clusters similar in body space
//!
//! All embeddings are assumed L2-normalized (cosine distance = 1 − dot).

use std::collections::HashMap;

use crate::ml::cluster::{
    agglomerative_precomputed, dot, l2_norm, median_centroid, renumber_labels, unique_cluster_ids,
};

// ── Species-specific configuration ──────────────────────────────────────

/// Species identifier for threshold lookup.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Species {
    Dog = 0,
    Cat = 1,
}

impl Species {
    pub fn from_u8(v: u8) -> Self {
        match v {
            0 => Species::Dog,
            _ => Species::Cat,
        }
    }
}

/// Which clustering algorithm to use in Phase 1 and Phase 2b.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ClusterAlgorithm {
    Hdbscan,
    Agglomerative,
}

/// Clustering thresholds per species, mirroring Python `SpeciesConfig`.
#[derive(Clone, Debug)]
pub struct ClusterConfig {
    pub species: Species,
    /// Which algorithm to use for density clustering phases.
    pub cluster_algorithm: ClusterAlgorithm,
    /// Weight given to face similarity in combined scoring.
    pub face_weight: f32,
    /// Minimum cosine similarity for body rescue assignment.
    pub body_rescue_threshold: f32,
    /// Minimum number of body embeddings above threshold for rescue.
    pub min_body_agreements: usize,
    /// Minimum average body similarity for cross-cluster merge.
    pub body_merge_threshold: f32,
    /// Face similarity below this vetoes a body rescue.
    pub face_veto_threshold: f32,
    /// Face similarity below this blocks a cross-cluster merge.
    pub face_contradiction_threshold: f32,
    /// HDBSCAN min_cluster_size.
    pub min_cluster_size: usize,
    /// HDBSCAN min_samples.
    pub min_samples: usize,
    /// Minimum fraction of body pairs above merge threshold.
    pub min_body_overlap_ratio: f32,
    /// Distance threshold for agglomerative clustering (average linkage).
    pub agglomerative_threshold: f32,
}

impl ClusterConfig {
    pub fn dog() -> Self {
        Self {
            species: Species::Dog,
            cluster_algorithm: ClusterAlgorithm::Agglomerative,
            face_weight: 0.5,
            body_rescue_threshold: 0.25,
            min_body_agreements: 3,
            body_merge_threshold: 0.35,
            face_veto_threshold: 0.05,
            face_contradiction_threshold: 0.10,
            min_cluster_size: 2,
            min_samples: 2,
            min_body_overlap_ratio: 0.5,
            agglomerative_threshold: 0.77,
        }
    }

    pub fn cat() -> Self {
        Self {
            species: Species::Cat,
            cluster_algorithm: ClusterAlgorithm::Agglomerative,
            face_weight: 0.3,
            body_rescue_threshold: 0.20,
            min_body_agreements: 2,
            body_merge_threshold: 0.30,
            face_veto_threshold: 0.05,
            face_contradiction_threshold: 0.10,
            min_cluster_size: 2,
            min_samples: 2,
            min_body_overlap_ratio: 0.5,
            agglomerative_threshold: 0.77,
        }
    }

    pub fn for_species(species: Species) -> Self {
        match species {
            Species::Dog => Self::dog(),
            Species::Cat => Self::cat(),
        }
    }
}

// ── Input / Output types ────────────────────────────────────────────────

/// One image's data for clustering. Index-aligned across the batch.
#[derive(Clone, Debug)]
pub struct PetClusterInput {
    /// Unique ID for this pet face (from indexing). Used as the key in results.
    pub pet_face_id: String,
    /// L2-normalized face embedding (128-d). Empty vec if no face.
    pub face_embedding: Vec<f32>,
    /// L2-normalized body embedding (192-d). Empty vec if no body.
    pub body_embedding: Vec<f32>,
    /// 0 = dog, 1 = cat.
    pub species: u8,
    /// File ID that this detection belongs to.
    pub file_id: i64,
}

impl PetClusterInput {
    pub fn has_face(&self) -> bool {
        !self.face_embedding.is_empty()
    }
    pub fn has_body(&self) -> bool {
        !self.body_embedding.is_empty()
    }
}

/// Result of clustering: maps each pet_face_id to a cluster_id string.
#[derive(Clone, Debug, Default)]
pub struct PetClusterResult {
    /// pet_face_id → cluster_id (UUID-style string).
    pub face_to_cluster: HashMap<String, String>,
    /// cluster_id → centroid face embedding (L2-normalized).
    pub cluster_centroids: HashMap<String, Vec<f32>>,
    /// cluster_id → member count.
    pub cluster_counts: HashMap<String, usize>,
    /// Number of inputs that remained unclustered.
    pub n_unclustered: usize,
}

// ── Core clustering engine ──────────────────────────────────────────────

/// Run the full 3-phase pet clustering pipeline.
///
/// This is the main entry point called from the API layer.
pub fn run_pet_clustering(
    inputs: &[PetClusterInput],
    config: &ClusterConfig,
) -> PetClusterResult {
    let n = inputs.len();
    if n == 0 {
        return PetClusterResult::default();
    }

    // Build index arrays for fast lookup
    let has_face: Vec<bool> = inputs.iter().map(|i| i.has_face()).collect();
    let has_body: Vec<bool> = inputs.iter().map(|i| i.has_body()).collect();

    // Phase 1: Face-based clustering
    let mut labels = phase1_face_cluster(inputs, &has_face, config);

    // Compute face centroids for phase 2
    let face_centroids = compute_face_centroids(inputs, &labels, &has_face);

    // Phase 2: Body rescue
    phase2_body_rescue(inputs, &mut labels, &has_face, &has_body, &face_centroids, config);

    // Phase 2b: Body-only clustering
    phase2b_body_cluster(inputs, &mut labels, &has_body, config);

    // Phase 3: Cross-cluster merge
    phase3_cross_merge(inputs, &mut labels, &has_face, &has_body, config);

    // Renumber labels to contiguous 0..K-1
    renumber_labels(&mut labels);

    // Build result
    build_result(inputs, &labels, &has_face)
}

/// Run incremental clustering: assign new inputs to existing clusters,
/// then cluster the remainder among themselves.
pub fn run_pet_clustering_incremental(
    new_inputs: &[PetClusterInput],
    existing_centroids_face: &HashMap<String, Vec<f32>>,
    existing_centroids_body: &HashMap<String, Vec<f32>>,
    config: &ClusterConfig,
) -> PetClusterResult {
    let n = new_inputs.len();
    if n == 0 {
        return PetClusterResult::default();
    }

    let mut labels = vec![-1i32; n];
    let mut cluster_name_map: HashMap<i32, String> = HashMap::new();

    // Step 1: Try to assign each new input to an existing cluster
    let fw = config.face_weight;
    let bw = 1.0 - fw;
    let threshold = config.body_rescue_threshold;

    let existing_ids: Vec<&String> = existing_centroids_face
        .keys()
        .chain(existing_centroids_body.keys())
        .collect::<std::collections::HashSet<_>>()
        .into_iter()
        .collect();

    for (i, inp) in new_inputs.iter().enumerate() {
        let mut best_score = -1.0f32;
        let mut best_id: Option<&String> = None;

        for cluster_id in &existing_ids {
            let mut score = 0.0f32;
            let mut n_modalities = 0u32;

            if inp.has_face()
                && let Some(centroid) = existing_centroids_face.get(*cluster_id)
            {
                let sim = dot(&inp.face_embedding, centroid);
                score += fw * sim;
                n_modalities += 1;
            }
            if inp.has_body()
                && let Some(centroid) = existing_centroids_body.get(*cluster_id)
            {
                let sim = dot(&inp.body_embedding, centroid);
                score += bw * sim;
                n_modalities += 1;
            }

            if n_modalities == 0 {
                continue;
            }

            // If only one modality, use its raw similarity
            if n_modalities == 1 {
                score = if inp.has_face() {
                    existing_centroids_face
                        .get(*cluster_id)
                        .map(|c| dot(&inp.face_embedding, c))
                        .unwrap_or(0.0)
                } else {
                    existing_centroids_body
                        .get(*cluster_id)
                        .map(|c| dot(&inp.body_embedding, c))
                        .unwrap_or(0.0)
                };
            }

            if score > best_score {
                best_score = score;
                best_id = Some(cluster_id);
            }
        }

        if best_score > threshold
            && let Some(cid) = best_id
        {
            // Assign a temporary numeric label and record the mapping
            let numeric = cluster_name_map
                .iter()
                .find(|(_, v)| *v == cid)
                .map(|(k, _)| *k)
                .unwrap_or_else(|| {
                    let new_label = cluster_name_map.len() as i32;
                    cluster_name_map.insert(new_label, cid.clone());
                    new_label
                });
            labels[i] = numeric;
        }
    }

    // Step 2: Cluster unassigned among themselves
    let unassigned: Vec<usize> = labels
        .iter()
        .enumerate()
        .filter(|(_, l)| **l == -1)
        .map(|(i, _)| i)
        .collect();

    if unassigned.len() >= config.min_cluster_size {
        let sub_inputs: Vec<PetClusterInput> =
            unassigned.iter().map(|&i| new_inputs[i].clone()).collect();
        let sub_result = run_pet_clustering(&sub_inputs, config);

        // Merge sub-results back, offset cluster IDs
        let mut next_label = cluster_name_map.keys().copied().max().unwrap_or(-1) + 1;
        for (sub_idx, &global_idx) in unassigned.iter().enumerate() {
            let pet_face_id = &sub_inputs[sub_idx].pet_face_id;
            if let Some(cluster_id) = sub_result.face_to_cluster.get(pet_face_id) {
                // Find or create numeric label for this cluster
                let numeric = cluster_name_map
                    .iter()
                    .find(|(_, v)| *v == cluster_id)
                    .map(|(k, _)| *k)
                    .unwrap_or_else(|| {
                        let label = next_label;
                        next_label += 1;
                        cluster_name_map.insert(label, cluster_id.clone());
                        label
                    });
                labels[global_idx] = numeric;
            }
        }
    }

    // Build final result using the name map
    let mut result = PetClusterResult::default();
    for (i, inp) in new_inputs.iter().enumerate() {
        if labels[i] >= 0 {
            if let Some(cluster_id) = cluster_name_map.get(&labels[i]) {
                result
                    .face_to_cluster
                    .insert(inp.pet_face_id.clone(), cluster_id.clone());
                *result.cluster_counts.entry(cluster_id.clone()).or_insert(0) += 1;
            }
        } else {
            result.n_unclustered += 1;
        }
    }

    // Recompute centroids for all clusters (existing and new). The Dart
    // caller sends every face as input, so the assignments are comprehensive
    // and centroids must reflect the current full membership.
    for cluster_id in result.cluster_counts.keys() {
        let members: Vec<usize> = new_inputs
            .iter()
            .enumerate()
            .filter(|(_, inp)| {
                result
                    .face_to_cluster
                    .get(&inp.pet_face_id)
                    .map(|c| c == cluster_id)
                    .unwrap_or(false)
            })
            .map(|(i, _)| i)
            .collect();

        let face_embs: Vec<&Vec<f32>> = members
            .iter()
            .filter(|&&i| new_inputs[i].has_face())
            .map(|&i| &new_inputs[i].face_embedding)
            .collect();

        if !face_embs.is_empty() {
            let centroid = median_centroid(&face_embs, face_embs[0].len());
            result
                .cluster_centroids
                .insert(cluster_id.clone(), centroid);
        }
    }

    result
}

// ── Phase 1: Face-based density clustering ──────────────────────────────

/// HDBSCAN-style clustering on face embeddings using mutual reachability
/// distance and single-linkage hierarchy extraction.
fn phase1_face_cluster(
    inputs: &[PetClusterInput],
    has_face: &[bool],
    config: &ClusterConfig,
) -> Vec<i32> {
    let n = inputs.len();
    let mut labels = vec![-1i32; n];

    let face_indices: Vec<usize> = has_face
        .iter()
        .enumerate()
        .filter(|(_, h)| **h)
        .map(|(i, _)| i)
        .collect();

    if face_indices.len() < 2 {
        return labels;
    }

    let nf = face_indices.len();

    // Guard against excessive memory usage: n^2 * 4 bytes.
    // 5000^2 * 4 = ~100MB, which is the upper bound for mobile devices.
    if nf > 5000 {
        return labels;
    }

    // Compute pairwise cosine distance matrix: dist = 1 - dot(a, b)
    let mut dist = vec![0.0f32; nf * nf];
    for i in 0..nf {
        for j in (i + 1)..nf {
            let sim = dot(
                &inputs[face_indices[i]].face_embedding,
                &inputs[face_indices[j]].face_embedding,
            );
            let d = (1.0 - sim).clamp(0.0, 2.0);
            dist[i * nf + j] = d;
            dist[j * nf + i] = d;
        }
    }

    // Run configured clustering algorithm on the distance matrix
    let face_labels = run_cluster(&dist, nf, config);

    // Map back to global indices
    for (local, &global) in face_indices.iter().enumerate() {
        labels[global] = face_labels[local];
    }

    labels
}

// ── Phase 2: Body rescue ────────────────────────────────────────────────

fn phase2_body_rescue(
    inputs: &[PetClusterInput],
    labels: &mut [i32],
    has_face: &[bool],
    has_body: &[bool],
    face_centroids: &HashMap<i32, Vec<f32>>,
    config: &ClusterConfig,
) {
    // Build per-cluster body embeddings
    let mut cluster_bodies: HashMap<i32, Vec<usize>> = HashMap::new();
    for (i, &label) in labels.iter().enumerate() {
        if label >= 0 && has_body[i] {
            cluster_bodies.entry(label).or_default().push(i);
        }
    }

    let unclustered: Vec<usize> = labels
        .iter()
        .enumerate()
        .filter(|(_, l)| **l == -1)
        .map(|(i, _)| i)
        .collect();

    for img_idx in unclustered {
        if !has_body[img_idx] {
            continue;
        }

        let candidate = &inputs[img_idx].body_embedding;
        let mut best_cluster = -1i32;
        let mut best_avg_sim = -1.0f32;

        for (&cluster_id, members) in &cluster_bodies {
            let mut n_above = 0usize;
            let mut sum_sim = 0.0f32;
            for &m in members {
                let sim = dot(candidate, &inputs[m].body_embedding);
                sum_sim += sim;
                if sim > config.body_rescue_threshold {
                    n_above += 1;
                }
            }

            let avg_sim = sum_sim / members.len() as f32;

            if n_above >= config.min_body_agreements && avg_sim > best_avg_sim {
                best_cluster = cluster_id;
                best_avg_sim = avg_sim;
            }
        }

        if best_cluster < 0 {
            continue;
        }

        // Face veto check
        if has_face[img_idx] {
            let face_emb = &inputs[img_idx].face_embedding;
            let norm = l2_norm(face_emb);
            if norm > 0.1
                && let Some(centroid) = face_centroids.get(&best_cluster)
            {
                let face_sim = dot(face_emb, centroid);
                if face_sim < config.face_veto_threshold {
                    continue; // Vetoed
                }
            }
        }

        labels[img_idx] = best_cluster;
        // Update cluster bodies for subsequent rescues
        cluster_bodies.entry(best_cluster).or_default().push(img_idx);
    }
}

// ── Phase 2b: Body-only clustering ──────────────────────────────────────

fn phase2b_body_cluster(
    inputs: &[PetClusterInput],
    labels: &mut [i32],
    has_body: &[bool],
    config: &ClusterConfig,
) {
    let still_unclustered: Vec<usize> = labels
        .iter()
        .enumerate()
        .filter(|(i, l)| **l == -1 && has_body[*i])
        .map(|(i, _)| i)
        .collect();

    if still_unclustered.len() < config.min_cluster_size {
        return;
    }

    let nf = still_unclustered.len();

    // Guard against excessive memory usage on mobile devices.
    if nf > 5000 {
        return;
    }

    let mut dist = vec![0.0f32; nf * nf];
    for i in 0..nf {
        for j in (i + 1)..nf {
            let sim = dot(
                &inputs[still_unclustered[i]].body_embedding,
                &inputs[still_unclustered[j]].body_embedding,
            );
            let d = (1.0 - sim).clamp(0.0, 2.0);
            dist[i * nf + j] = d;
            dist[j * nf + i] = d;
        }
    }

    let body_labels = run_cluster(&dist, nf, config);

    let existing_max = labels.iter().copied().max().unwrap_or(-1);

    for (local, &global) in still_unclustered.iter().enumerate() {
        if body_labels[local] >= 0 {
            labels[global] = body_labels[local] + existing_max + 1;
        }
    }
}

// ── Phase 3: Cross-cluster merge ────────────────────────────────────────

fn phase3_cross_merge(
    inputs: &[PetClusterInput],
    labels: &mut [i32],
    has_face: &[bool],
    has_body: &[bool],
    config: &ClusterConfig,
) {
    let unique_clusters = unique_cluster_ids(labels);
    if unique_clusters.len() < 2 {
        return;
    }

    // Build per-cluster body centroids for pre-screening
    let mut cluster_body_embs: HashMap<i32, Vec<usize>> = HashMap::new();
    let mut cluster_face_embs: HashMap<i32, Vec<usize>> = HashMap::new();
    for (i, &label) in labels.iter().enumerate() {
        if label < 0 {
            continue;
        }
        if has_body[i] {
            cluster_body_embs.entry(label).or_default().push(i);
        }
        if has_face[i] {
            cluster_face_embs.entry(label).or_default().push(i);
        }
    }

    // Body centroids for pre-screening
    let body_dim = inputs
        .iter()
        .find(|i| i.has_body())
        .map(|i| i.body_embedding.len())
        .unwrap_or(0);
    if body_dim == 0 {
        return;
    }

    let mut body_centroids: HashMap<i32, Vec<f32>> = HashMap::new();
    for (&c, members) in &cluster_body_embs {
        let embs: Vec<&Vec<f32>> = members.iter().map(|&i| &inputs[i].body_embedding).collect();
        let centroid = median_centroid(&embs, body_dim);
        body_centroids.insert(c, centroid);
    }

    let clusters_with_body: Vec<i32> = unique_clusters
        .iter()
        .copied()
        .filter(|c| body_centroids.contains_key(c))
        .collect();

    if clusters_with_body.len() < 2 {
        return;
    }

    let centroid_screen = config.body_merge_threshold * 0.7;

    // Pre-screen candidate pairs
    let mut candidate_pairs: Vec<(i32, i32)> = Vec::new();
    for i in 0..clusters_with_body.len() {
        for j in (i + 1)..clusters_with_body.len() {
            let c1 = clusters_with_body[i];
            let c2 = clusters_with_body[j];
            let sim = dot(&body_centroids[&c1], &body_centroids[&c2]);
            if sim > centroid_screen {
                candidate_pairs.push((c1, c2));
            }
        }
    }

    // Evaluate candidate pairs
    let mut merge_pairs: Vec<(i32, i32, f32)> = Vec::new();
    for (c1, c2) in candidate_pairs {
        let b1 = &cluster_body_embs[&c1];
        let b2 = &cluster_body_embs[&c2];

        let mut sum_sim = 0.0f32;
        let mut n_above = 0usize;
        let total = b1.len() * b2.len();

        for &i in b1 {
            for &j in b2 {
                let sim = dot(&inputs[i].body_embedding, &inputs[j].body_embedding);
                sum_sim += sim;
                if sim > config.body_merge_threshold {
                    n_above += 1;
                }
            }
        }

        let avg_body_sim = sum_sim / total as f32;
        let ratio_above = n_above as f32 / total as f32;

        if avg_body_sim < config.body_merge_threshold {
            continue;
        }
        if ratio_above < config.min_body_overlap_ratio {
            continue;
        }

        // Face contradiction check
        let f1 = cluster_face_embs.get(&c1);
        let f2 = cluster_face_embs.get(&c2);
        if let (Some(f1m), Some(f2m)) = (f1, f2)
            && !f1m.is_empty()
            && !f2m.is_empty()
        {
            let mut face_sum = 0.0f32;
            let face_total = f1m.len() * f2m.len();
            for &i in f1m {
                for &j in f2m {
                    face_sum += dot(&inputs[i].face_embedding, &inputs[j].face_embedding);
                }
            }
            let avg_face = face_sum / face_total as f32;
            if avg_face < config.face_contradiction_threshold {
                continue; // Blocked by face contradiction
            }
        }

        merge_pairs.push((c1, c2, avg_body_sim));
    }

    // Sort by body similarity descending
    merge_pairs.sort_by(|a, b| b.2.partial_cmp(&a.2).unwrap_or(std::cmp::Ordering::Equal));

    // Union-find merge
    let mut parent: HashMap<i32, i32> = unique_clusters.iter().map(|&c| (c, c)).collect();

    for (c1, c2, _) in &merge_pairs {
        let r1 = uf_find(&mut parent, *c1);
        let r2 = uf_find(&mut parent, *c2);
        if r1 != r2 {
            parent.insert(r2, r1);
        }
    }

    // Apply merges
    for label in labels.iter_mut() {
        if *label >= 0 {
            *label = uf_find(&mut parent, *label);
        }
    }
}

// ── Clustering dispatch ──────────────────────────────────────────────────

/// Run the configured clustering algorithm on a precomputed distance matrix.
fn run_cluster(dist: &[f32], n: usize, config: &ClusterConfig) -> Vec<i32> {
    match config.cluster_algorithm {
        ClusterAlgorithm::Hdbscan => {
            hdbscan_precomputed(dist, n, config.min_cluster_size, config.min_samples)
        }
        ClusterAlgorithm::Agglomerative => {
            agglomerative_precomputed(dist, n, config.agglomerative_threshold)
        }
    }
}

// Agglomerative clustering imported from crate::ml::cluster

// ── HDBSCAN implementation (precomputed distance matrix) ────────────────

/// Simplified HDBSCAN on a precomputed distance matrix.
///
/// Steps:
///   1. Compute core distances (k-th nearest neighbor distance, k = min_samples)
///   2. Compute mutual reachability distances
///   3. Build minimum spanning tree (Prim's algorithm)
///   4. Single-linkage hierarchy from MST
///   5. Extract clusters using EOM (Excess of Mass) stability
fn hdbscan_precomputed(dist: &[f32], n: usize, min_cluster_size: usize, min_samples: usize) -> Vec<i32> {
    if n < min_cluster_size {
        return vec![-1i32; n];
    }

    let k = min_samples.min(n - 1);

    // Step 1: Core distances
    let core_dist = compute_core_distances(dist, n, k);

    // Step 2: Mutual reachability distance
    let mrd = compute_mutual_reachability(dist, &core_dist, n);

    // Step 3: MST via Prim's
    let mst = prims_mst(&mrd, n);

    // Step 4: Sort MST edges by weight (single-linkage dendrogram)
    let mut sorted_edges = mst;
    sorted_edges.sort_by(|a, b| a.2.partial_cmp(&b.2).unwrap_or(std::cmp::Ordering::Equal));

    // Step 5: Extract flat clusters via stability-based extraction
    extract_clusters_eom(&sorted_edges, n, min_cluster_size)
}

/// Core distance: distance to the k-th nearest neighbor.
fn compute_core_distances(dist: &[f32], n: usize, k: usize) -> Vec<f32> {
    let mut core_dist = vec![0.0f32; n];
    for i in 0..n {
        let mut dists: Vec<f32> = (0..n)
            .filter(|&j| j != i)
            .map(|j| dist[i * n + j])
            .collect();
        dists.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));
        core_dist[i] = if k <= dists.len() {
            dists[k - 1]
        } else {
            *dists.last().unwrap_or(&0.0)
        };
    }
    core_dist
}

/// Mutual reachability: max(core(a), core(b), dist(a,b)).
fn compute_mutual_reachability(dist: &[f32], core_dist: &[f32], n: usize) -> Vec<f32> {
    let mut mrd = vec![0.0f32; n * n];
    for i in 0..n {
        for j in (i + 1)..n {
            let d = dist[i * n + j]
                .max(core_dist[i])
                .max(core_dist[j]);
            mrd[i * n + j] = d;
            mrd[j * n + i] = d;
        }
    }
    mrd
}

/// Prim's algorithm for minimum spanning tree. Returns edges (u, v, weight).
fn prims_mst(dist: &[f32], n: usize) -> Vec<(usize, usize, f32)> {
    let mut in_tree = vec![false; n];
    let mut min_edge = vec![f32::INFINITY; n];
    let mut min_from = vec![0usize; n];
    let mut edges = Vec::with_capacity(n - 1);

    in_tree[0] = true;
    for j in 1..n {
        min_edge[j] = dist[j]; // distance from node 0
        min_from[j] = 0;
    }

    for _ in 0..(n - 1) {
        // Find closest node not in tree
        let mut best = f32::INFINITY;
        let mut best_node = 0;
        for j in 0..n {
            if !in_tree[j] && min_edge[j] < best {
                best = min_edge[j];
                best_node = j;
            }
        }

        in_tree[best_node] = true;
        edges.push((min_from[best_node], best_node, best));

        // Update distances
        for j in 0..n {
            if !in_tree[j] {
                let d = dist[best_node * n + j];
                if d < min_edge[j] {
                    min_edge[j] = d;
                    min_from[j] = best_node;
                }
            }
        }
    }

    edges
}

/// Extract flat clusters from the sorted MST edges using HDBSCAN's
/// Excess of Mass (EOM) stability method.
fn extract_clusters_eom(
    sorted_edges: &[(usize, usize, f32)],
    n: usize,
    min_cluster_size: usize,
) -> Vec<i32> {
    let mut parent_uf: Vec<usize> = (0..n).collect();
    let mut comp_size: Vec<usize> = vec![1; n];

    // Per-node cluster assignment. -1 = unassigned.
    let mut node_cluster: Vec<i32> = vec![-1; n];
    let mut next_cluster_id = 0i32;

    // Process MST edges from smallest to largest distance.
    // When two components merge:
    //   - both >= min_cluster_size: lock in separate cluster IDs on every
    //     member node, then merge (they stay distinct).
    //   - otherwise: absorb the smaller into the larger. If the combined
    //     component just reached min_cluster_size, assign a new cluster.
    for &(u, v, _weight) in sorted_edges {
        let ru = uf_find_vec(&mut parent_uf, u);
        let rv = uf_find_vec(&mut parent_uf, v);
        if ru == rv {
            continue;
        }

        let size_u = comp_size[ru];
        let size_v = comp_size[rv];
        let both_large = size_u >= min_cluster_size && size_v >= min_cluster_size;

        if both_large {
            // Both are substantial — they remain separate clusters.
            // Propagate cluster IDs to ALL individual nodes BEFORE the
            // union changes the root, so labels survive the merge.
            let cu = node_cluster[ru];
            let id_u = if cu >= 0 {
                cu
            } else {
                let id = next_cluster_id;
                next_cluster_id += 1;
                id
            };
            propagate_cluster(&parent_uf, &mut node_cluster, ru, id_u, n);

            let cv = node_cluster[rv];
            let id_v = if cv >= 0 {
                cv
            } else {
                let id = next_cluster_id;
                next_cluster_id += 1;
                id
            };
            propagate_cluster(&parent_uf, &mut node_cluster, rv, id_v, n);

            // Merge in union-find (for subsequent edge processing)
            uf_union_vec(&mut parent_uf, &mut comp_size, ru, rv);
        } else {
            // At least one is small — absorb
            let cu = node_cluster[ru];
            let cv = node_cluster[rv];

            let merged_root = uf_union_vec(&mut parent_uf, &mut comp_size, ru, rv);
            let merged_size = comp_size[merged_root];

            if cu >= 0 {
                node_cluster[merged_root] = cu;
            } else if cv >= 0 {
                node_cluster[merged_root] = cv;
            } else if merged_size >= min_cluster_size {
                // New cluster formed — assign and propagate immediately
                let id = next_cluster_id;
                next_cluster_id += 1;
                propagate_cluster(&parent_uf, &mut node_cluster, merged_root, id, n);
            }
        }
    }

    // Final pass: any node whose root has a cluster but the node itself
    // was never individually propagated (small absorptions).
    let mut labels = vec![-1i32; n];
    for i in 0..n {
        if node_cluster[i] >= 0 {
            labels[i] = node_cluster[i];
        } else {
            let root = uf_find_vec(&mut parent_uf, i);
            if node_cluster[root] >= 0 {
                labels[i] = node_cluster[root];
            }
        }
    }

    labels
}

/// Propagate a cluster ID to every node in the component rooted at `root`.
fn propagate_cluster(
    parent: &[usize],
    node_cluster: &mut [i32],
    root: usize,
    cluster_id: i32,
    n: usize,
) {
    for (i, cluster) in node_cluster.iter_mut().enumerate().take(n) {
        if find_root(parent, i) == root {
            *cluster = cluster_id;
        }
    }
}

fn find_root(parent: &[usize], mut x: usize) -> usize {
    while parent[x] != x {
        x = parent[x];
    }
    x
}

// Helper functions (dot, l2_norm, normalize, median_centroid) imported
// from crate::ml::cluster

fn compute_face_centroids(
    inputs: &[PetClusterInput],
    labels: &[i32],
    has_face: &[bool],
) -> HashMap<i32, Vec<f32>> {
    let dim = inputs
        .iter()
        .find(|i| i.has_face())
        .map(|i| i.face_embedding.len())
        .unwrap_or(128);

    let mut centroids = HashMap::new();
    for &c in &unique_cluster_ids(labels) {
        let face_embs: Vec<&Vec<f32>> = labels
            .iter()
            .enumerate()
            .filter(|(i, l)| **l == c && has_face[*i])
            .map(|(i, _)| &inputs[i].face_embedding)
            .collect();

        if !face_embs.is_empty() {
            centroids.insert(c, median_centroid(&face_embs, dim));
        } else {
            // Fallback: use all members (zero-embedding faces included)
            let all_embs: Vec<&Vec<f32>> = labels
                .iter()
                .enumerate()
                .filter(|(_, l)| **l == c)
                .map(|(i, _)| &inputs[i].face_embedding)
                .collect();
            if !all_embs.is_empty() {
                centroids.insert(c, median_centroid(&all_embs, dim));
            }
        }
    }
    centroids
}

// unique_cluster_ids and renumber_labels imported from crate::ml::cluster

fn build_result(
    inputs: &[PetClusterInput],
    labels: &[i32],
    has_face: &[bool],
) -> PetClusterResult {
    let mut result = PetClusterResult::default();

    // Generate cluster ID strings (UUID-like from hash for determinism)
    let unique = unique_cluster_ids(labels);
    let cluster_id_map: HashMap<i32, String> = unique
        .iter()
        .map(|&c| {
            // Create a deterministic cluster ID from the first member's pet_face_id
            let first_member = labels
                .iter()
                .enumerate()
                .find(|(_, l)| **l == c)
                .map(|(i, _)| i)
                .unwrap();
            let id = format!("pet_cluster_{}", inputs[first_member].pet_face_id);
            (c, id)
        })
        .collect();

    // Map each input to its cluster
    for (i, inp) in inputs.iter().enumerate() {
        if labels[i] >= 0 {
            if let Some(cluster_id) = cluster_id_map.get(&labels[i]) {
                result
                    .face_to_cluster
                    .insert(inp.pet_face_id.clone(), cluster_id.clone());
                *result.cluster_counts.entry(cluster_id.clone()).or_insert(0) += 1;
            }
        } else {
            result.n_unclustered += 1;
        }
    }

    // Compute centroids for each cluster
    let face_dim = inputs
        .iter()
        .find(|i| i.has_face())
        .map(|i| i.face_embedding.len())
        .unwrap_or(128);

    for (&numeric, cluster_id) in &cluster_id_map {
        let face_embs: Vec<&Vec<f32>> = labels
            .iter()
            .enumerate()
            .filter(|(i, l)| **l == numeric && has_face[*i])
            .map(|(i, _)| &inputs[i].face_embedding)
            .collect();
        if !face_embs.is_empty() {
            result
                .cluster_centroids
                .insert(cluster_id.clone(), median_centroid(&face_embs, face_dim));
        }
    }

    result
}

// ── Union-find helpers ──────────────────────────────────────────────────

fn uf_find(parent: &mut HashMap<i32, i32>, x: i32) -> i32 {
    let mut r = x;
    while let Some(&p) = parent.get(&r) {
        if p == r {
            break;
        }
        r = p;
    }
    // Path compression
    let mut c = x;
    while c != r {
        if let Some(&p) = parent.get(&c) {
            parent.insert(c, r);
            c = p;
        } else {
            break;
        }
    }
    r
}

fn uf_find_vec(parent: &mut [usize], x: usize) -> usize {
    let mut r = x;
    while parent[r] != r {
        parent[r] = parent[parent[r]]; // path halving
        r = parent[r];
    }
    r
}

fn uf_union_vec(parent: &mut [usize], size: &mut [usize], a: usize, b: usize) -> usize {
    let ra = uf_find_vec(parent, a);
    let rb = uf_find_vec(parent, b);
    if ra == rb {
        return ra;
    }
    // Union by size
    if size[ra] >= size[rb] {
        parent[rb] = ra;
        size[ra] += size[rb];
        ra
    } else {
        parent[ra] = rb;
        size[rb] += size[ra];
        rb
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_input(face_id: &str, face: Vec<f32>, body: Vec<f32>, species: u8) -> PetClusterInput {
        PetClusterInput {
            pet_face_id: face_id.to_string(),
            face_embedding: face,
            body_embedding: body,
            species,
            file_id: 0,
        }
    }

    fn normalized(mut v: Vec<f32>) -> Vec<f32> {
        let n: f32 = v.iter().map(|x| x * x).sum::<f32>().sqrt();
        if n > 0.0 {
            for x in v.iter_mut() {
                *x /= n;
            }
        }
        v
    }

    #[test]
    fn test_empty_input() {
        let config = ClusterConfig::dog();
        let result = run_pet_clustering(&[], &config);
        assert_eq!(result.n_unclustered, 0);
        assert!(result.face_to_cluster.is_empty());
    }

    #[test]
    fn test_single_input() {
        let config = ClusterConfig::dog();
        let inputs = vec![make_input(
            "face_1",
            normalized(vec![1.0; 128]),
            normalized(vec![1.0; 192]),
            0,
        )];
        let result = run_pet_clustering(&inputs, &config);
        // Single input can't form a cluster
        assert_eq!(result.n_unclustered, 1);
    }

    #[test]
    fn test_two_similar_faces_cluster() {
        let config = ClusterConfig::dog();
        let face_a = normalized(vec![1.0; 128]);
        let mut face_b = face_a.clone();
        // Slightly perturb
        face_b[0] += 0.01;
        let face_b = normalized(face_b);

        let inputs = vec![
            make_input("a", face_a, vec![], 0),
            make_input("b", face_b, vec![], 0),
        ];
        let result = run_pet_clustering(&inputs, &config);
        // Should cluster together
        assert_eq!(result.n_unclustered, 0);
        assert_eq!(
            result.face_to_cluster.get("a"),
            result.face_to_cluster.get("b")
        );
    }

    #[test]
    fn test_two_groups_separate() {
        // Use min_samples=1 so core distances reflect actual nearest
        // neighbor distances (k=2 would need 3+ close points per group).
        let mut config = ClusterConfig::dog();
        config.min_samples = 1;

        // Group A: 3 nearly-identical faces along dimension 0
        let base_a = {
            let mut v = vec![0.0f32; 128];
            v[0] = 1.0;
            v
        };
        // Group B: 3 nearly-identical faces along dimension 64
        let base_b = {
            let mut v = vec![0.0f32; 128];
            v[64] = 1.0;
            v
        };

        let perturb = |base: &Vec<f32>, dim: usize, amt: f32| {
            let mut v = base.clone();
            v[dim] += amt;
            normalized(v)
        };

        let inputs = vec![
            make_input("a1", base_a.clone(), vec![], 0),
            make_input("a2", perturb(&base_a, 1, 0.02), vec![], 0),
            make_input("a3", perturb(&base_a, 2, 0.02), vec![], 0),
            make_input("b1", base_b.clone(), vec![], 0),
            make_input("b2", perturb(&base_b, 65, 0.02), vec![], 0),
            make_input("b3", perturb(&base_b, 66, 0.02), vec![], 0),
        ];
        let result = run_pet_clustering(&inputs, &config);

        let ca1 = result.face_to_cluster.get("a1");
        let ca2 = result.face_to_cluster.get("a2");
        let ca3 = result.face_to_cluster.get("a3");
        let cb1 = result.face_to_cluster.get("b1");
        let cb2 = result.face_to_cluster.get("b2");
        let cb3 = result.face_to_cluster.get("b3");
        assert_eq!(ca1, ca2, "a1 and a2 should be in same cluster");
        assert_eq!(ca1, ca3, "a1 and a3 should be in same cluster");
        assert_eq!(cb1, cb2, "b1 and b2 should be in same cluster");
        assert_eq!(cb1, cb3, "b1 and b3 should be in same cluster");
        assert_ne!(ca1, cb1, "group a and group b should be in different clusters");
    }
}

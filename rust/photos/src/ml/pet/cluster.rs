//! Pet clustering engine — 3-phase fused clustering.
//!
//! Phases:
//! - Phase 1: Face-based agglomerative clustering (average linkage)
//! - Phase 2: Body rescue — assign unclustered images to existing clusters
//! - Phase 2b: Body-only clustering for remaining unclustered images
//! - Phase 3: Cross-cluster merge — merge clusters similar in body space
//!
//! All embeddings are assumed L2-normalized (cosine distance = 1 − dot).

use std::collections::HashMap;

use crate::ml::cluster::{
    agglomerative_precomputed, dot, mean_centroid, renumber_labels, unique_cluster_ids,
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

/// Run face-only pet clustering (agglomerative average linkage).
///
/// This is the main entry point called from the API layer.
pub fn run_pet_clustering(inputs: &[PetClusterInput], config: &ClusterConfig) -> PetClusterResult {
    let n = inputs.len();
    if n == 0 {
        return PetClusterResult::default();
    }

    let has_face: Vec<bool> = inputs.iter().map(|i| i.has_face()).collect();

    // Phase 1: Face-based agglomerative clustering
    let mut labels = phase1_face_cluster(inputs, &has_face, config);

    // Renumber labels to contiguous 0..K-1
    renumber_labels(&mut labels);

    // Phase 2: body rescue — assign unclustered (no face) inputs to existing clusters
    phase2_body_rescue(inputs, &mut labels, &has_face, config);

    // Phase 2b: body-only clustering for remaining unclustered
    phase2b_body_only_cluster(inputs, &mut labels, config);

    // Phase 3: cross-cluster merge via body similarity
    phase3_cross_cluster_merge(inputs, &mut labels, &has_face, config);
    renumber_labels(&mut labels);

    // Build result
    build_result(inputs, &labels, &has_face)
}

/// Run incremental face-only clustering: assign new inputs to existing
/// face clusters by centroid similarity, then cluster the remainder.
pub fn run_pet_clustering_incremental(
    new_inputs: &[PetClusterInput],
    existing_centroids_face: &HashMap<String, Vec<f32>>,
    _existing_centroids_body: &HashMap<String, Vec<f32>>,
    config: &ClusterConfig,
) -> PetClusterResult {
    let n = new_inputs.len();
    if n == 0 {
        return PetClusterResult::default();
    }

    let mut labels = vec![-1i32; n];
    let mut cluster_name_map: HashMap<i32, String> = HashMap::new();

    // Step 1: Try to assign each new face to the closest existing cluster
    let threshold = config.agglomerative_threshold;

    for (i, inp) in new_inputs.iter().enumerate() {
        if !inp.has_face() {
            continue;
        }

        let mut best_sim = -1.0f32;
        let mut best_id: Option<&String> = None;

        for (cluster_id, centroid) in existing_centroids_face {
            let sim = dot(&inp.face_embedding, centroid);
            if sim > best_sim {
                best_sim = sim;
                best_id = Some(cluster_id);
            }
        }

        // Assign if similarity > (1 - threshold), i.e. distance < threshold
        if best_sim > (1.0 - threshold)
            && let Some(cid) = best_id
        {
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

        let mut next_label = cluster_name_map.keys().copied().max().unwrap_or(-1) + 1;
        for (sub_idx, &global_idx) in unassigned.iter().enumerate() {
            let pet_face_id = &sub_inputs[sub_idx].pet_face_id;
            if let Some(cluster_id) = sub_result.face_to_cluster.get(pet_face_id) {
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

    // Build final result
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

    // Recompute face centroids
    for cluster_id in result.cluster_counts.keys() {
        let face_embs: Vec<&Vec<f32>> = new_inputs
            .iter()
            .filter(|inp| {
                result
                    .face_to_cluster
                    .get(&inp.pet_face_id)
                    .map(|c| c == cluster_id)
                    .unwrap_or(false)
                    && inp.has_face()
            })
            .map(|inp| &inp.face_embedding)
            .collect();

        if !face_embs.is_empty() {
            let centroid = mean_centroid(&face_embs, face_embs[0].len());
            result
                .cluster_centroids
                .insert(cluster_id.clone(), centroid);
        }
    }

    result
}

// ── Phase 1: Face-based agglomerative clustering ────────────────────────

/// Agglomerative clustering (average linkage) on face embeddings.
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

// ── Phase 2: Body rescue ─────────────────────────────────────────────────

/// For each input that is unclustered (label == -1) and has a body embedding,
/// try to assign it to an existing cluster based on body similarity.
///
/// For each candidate cluster, count how many cluster members have body
/// similarity > `config.body_rescue_threshold`. If that count >= `config.min_body_agreements`,
/// the cluster is a rescue candidate. If the input also has a face, check face veto:
/// if dot(input.face, cluster face centroid) < `config.face_veto_threshold`, skip.
/// Assign to the cluster with the most body agreements (tie-break by avg body similarity).
fn phase2_body_rescue(
    inputs: &[PetClusterInput],
    labels: &mut [i32],
    has_face: &[bool],
    config: &ClusterConfig,
) {
    let cluster_ids = unique_cluster_ids(labels);
    if cluster_ids.is_empty() {
        return;
    }

    // Collect unclustered indices that have body embeddings
    let unclustered: Vec<usize> = labels
        .iter()
        .enumerate()
        .filter(|(i, l)| **l == -1 && inputs[*i].has_body())
        .map(|(i, _)| i)
        .collect();

    if unclustered.is_empty() {
        return;
    }

    // Precompute per-cluster: body embeddings of members, and face centroid
    let face_dim = inputs
        .iter()
        .find(|i| i.has_face())
        .map(|i| i.face_embedding.len())
        .unwrap_or(128);

    for &ui in &unclustered {
        let mut best_cluster: Option<i32> = None;
        let mut best_agreements: usize = 0;
        let mut best_avg_sim: f32 = -1.0;

        for &cid in &cluster_ids {
            // Collect body embeddings of cluster members
            let cluster_bodies: Vec<&Vec<f32>> = labels
                .iter()
                .enumerate()
                .filter(|(i, l)| **l == cid && inputs[*i].has_body())
                .map(|(i, _)| &inputs[i].body_embedding)
                .collect();

            if cluster_bodies.is_empty() {
                continue;
            }

            // Count agreements: how many cluster bodies have similarity > threshold
            let mut agreements = 0usize;
            let mut total_sim = 0.0f32;
            for cb in &cluster_bodies {
                let sim = dot(&inputs[ui].body_embedding, cb);
                if sim > config.body_rescue_threshold {
                    agreements += 1;
                }
                total_sim += sim;
            }

            if agreements < config.min_body_agreements {
                continue;
            }

            // Face veto: if the unclustered input has a face, check against cluster face centroid
            if has_face[ui] {
                let cluster_face_embs: Vec<&Vec<f32>> = labels
                    .iter()
                    .enumerate()
                    .filter(|(i, l)| **l == cid && has_face[*i])
                    .map(|(i, _)| &inputs[i].face_embedding)
                    .collect();

                if !cluster_face_embs.is_empty() {
                    let centroid = mean_centroid(&cluster_face_embs, face_dim);
                    let face_sim = dot(&inputs[ui].face_embedding, &centroid);
                    if face_sim < config.face_veto_threshold {
                        continue; // face veto
                    }
                }
            }

            let avg_sim = total_sim / cluster_bodies.len() as f32;

            // Pick cluster with most agreements, break ties by avg body similarity
            if agreements > best_agreements
                || (agreements == best_agreements && avg_sim > best_avg_sim)
            {
                best_cluster = Some(cid);
                best_agreements = agreements;
                best_avg_sim = avg_sim;
            }
        }

        if let Some(cid) = best_cluster {
            labels[ui] = cid;
        }
    }
}

// ── Phase 2b: Body-only clustering ───────────────────────────────────────

/// Cluster still-unclustered inputs that have body embeddings among themselves,
/// using the same clustering algorithm as Phase 1 but on body embeddings.
fn phase2b_body_only_cluster(
    inputs: &[PetClusterInput],
    labels: &mut [i32],
    config: &ClusterConfig,
) {
    // Collect still-unclustered indices that have body embeddings
    let body_indices: Vec<usize> = labels
        .iter()
        .enumerate()
        .filter(|(i, l)| **l == -1 && inputs[*i].has_body())
        .map(|(i, _)| i)
        .collect();

    if body_indices.len() < 2 {
        return;
    }

    let nb = body_indices.len();

    // Guard against excessive memory
    if nb > 5000 {
        return;
    }

    // Compute pairwise cosine distance matrix on body embeddings
    let mut dist = vec![0.0f32; nb * nb];
    for i in 0..nb {
        for j in (i + 1)..nb {
            let sim = dot(
                &inputs[body_indices[i]].body_embedding,
                &inputs[body_indices[j]].body_embedding,
            );
            let d = (1.0 - sim).clamp(0.0, 2.0);
            dist[i * nb + j] = d;
            dist[j * nb + i] = d;
        }
    }

    // Run clustering on body distance matrix
    let body_labels = run_cluster(&dist, nb, config);

    // Find the next available label to avoid collision with existing clusters
    let max_existing = labels.iter().copied().max().unwrap_or(-1);
    let offset = if max_existing >= 0 {
        max_existing + 1
    } else {
        0
    };

    // Map body cluster labels back to global labels
    for (local, &global) in body_indices.iter().enumerate() {
        if body_labels[local] >= 0 {
            labels[global] = body_labels[local] + offset;
        }
    }
}

// ── Phase 3: Cross-cluster merge ─────────────────────────────────────────

/// Merge clusters that are similar in body embedding space.
///
/// For each pair of clusters: compute average body similarity between all
/// body-bearing members. If avg > `body_merge_threshold` and the fraction
/// of pairs above threshold >= `min_body_overlap_ratio`, merge.
/// But if average face similarity between clusters < `face_contradiction_threshold`,
/// do NOT merge (face contradiction veto).
fn phase3_cross_cluster_merge(
    inputs: &[PetClusterInput],
    labels: &mut [i32],
    has_face: &[bool],
    config: &ClusterConfig,
) {
    let cluster_ids = unique_cluster_ids(labels);
    if cluster_ids.len() < 2 {
        return;
    }

    let n = labels.len();
    let face_dim = inputs
        .iter()
        .find(|i| i.has_face())
        .map(|i| i.face_embedding.len())
        .unwrap_or(128);

    // Union-find for merging clusters
    let num_clusters = cluster_ids.len();
    let mut uf_parent: Vec<usize> = (0..num_clusters).collect();
    let mut uf_size: Vec<usize> = vec![1; num_clusters];

    // Map cluster_id -> index in cluster_ids for union-find
    let cid_to_idx: HashMap<i32, usize> = cluster_ids
        .iter()
        .enumerate()
        .map(|(idx, &cid)| (cid, idx))
        .collect();

    // Check each pair of clusters
    for i in 0..num_clusters {
        for j in (i + 1)..num_clusters {
            let ci = cluster_ids[i];
            let cj = cluster_ids[j];

            // Check if already merged via union-find
            let ri = uf_find_vec(&mut uf_parent, i);
            let rj = uf_find_vec(&mut uf_parent, j);
            if ri == rj {
                continue;
            }

            // Collect body embeddings for each cluster
            let bodies_i: Vec<&Vec<f32>> = labels
                .iter()
                .enumerate()
                .filter(|(idx, l)| **l == ci && inputs[*idx].has_body())
                .map(|(idx, _)| &inputs[idx].body_embedding)
                .collect();

            let bodies_j: Vec<&Vec<f32>> = labels
                .iter()
                .enumerate()
                .filter(|(idx, l)| **l == cj && inputs[*idx].has_body())
                .map(|(idx, _)| &inputs[idx].body_embedding)
                .collect();

            if bodies_i.is_empty() || bodies_j.is_empty() {
                continue;
            }

            // Compute average body similarity and fraction above threshold
            let total_pairs = bodies_i.len() * bodies_j.len();
            let mut total_sim = 0.0f32;
            let mut above_threshold = 0usize;

            for bi in &bodies_i {
                for bj in &bodies_j {
                    let sim = dot(bi, bj);
                    total_sim += sim;
                    if sim > config.body_merge_threshold {
                        above_threshold += 1;
                    }
                }
            }

            let avg_body_sim = total_sim / total_pairs as f32;
            let overlap_ratio = above_threshold as f32 / total_pairs as f32;

            if avg_body_sim <= config.body_merge_threshold
                || overlap_ratio < config.min_body_overlap_ratio
            {
                continue;
            }

            // Face contradiction check: if both clusters have face embeddings,
            // compute average face similarity. If too low, don't merge.
            let faces_i: Vec<&Vec<f32>> = labels
                .iter()
                .enumerate()
                .filter(|(idx, l)| **l == ci && has_face[*idx])
                .map(|(idx, _)| &inputs[idx].face_embedding)
                .collect();

            let faces_j: Vec<&Vec<f32>> = labels
                .iter()
                .enumerate()
                .filter(|(idx, l)| **l == cj && has_face[*idx])
                .map(|(idx, _)| &inputs[idx].face_embedding)
                .collect();

            if !faces_i.is_empty() && !faces_j.is_empty() {
                let centroid_i = mean_centroid(&faces_i, face_dim);
                let centroid_j = mean_centroid(&faces_j, face_dim);
                let face_sim = dot(&centroid_i, &centroid_j);
                if face_sim < config.face_contradiction_threshold {
                    continue; // face contradiction veto
                }
            }

            // Merge clusters via union-find
            uf_union_vec(&mut uf_parent, &mut uf_size, ri, rj);
        }
    }

    // Apply merges: map each cluster's label to its union-find root's cluster id
    let mut root_to_label: HashMap<usize, i32> = HashMap::new();
    for (idx, &_cid) in cluster_ids.iter().enumerate() {
        let root = uf_find_vec(&mut uf_parent, idx);
        root_to_label.entry(root).or_insert(cluster_ids[root]);
    }

    // Update labels
    for label in labels.iter_mut().take(n) {
        if *label >= 0 {
            if let Some(&idx) = cid_to_idx.get(label) {
                let root = uf_find_vec(&mut uf_parent, idx);
                *label = *root_to_label.get(&root).unwrap_or(label);
            }
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
pub(crate) fn hdbscan_precomputed(
    dist: &[f32],
    n: usize,
    min_cluster_size: usize,
    min_samples: usize,
) -> Vec<i32> {
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
            let d = dist[i * n + j].max(core_dist[i]).max(core_dist[j]);
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

// Helper functions (dot, l2_norm, normalize, mean_centroid) imported
// from crate::ml::cluster

// unique_cluster_ids and renumber_labels imported from crate::ml::cluster

fn build_result(inputs: &[PetClusterInput], labels: &[i32], has_face: &[bool]) -> PetClusterResult {
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
                .insert(cluster_id.clone(), mean_centroid(&face_embs, face_dim));
        }
    }

    result
}

// ── Union-find helpers ──────────────────────────────────────────────────

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
        assert_ne!(
            ca1, cb1,
            "group a and group b should be in different clusters"
        );
    }

    // ── Body rescue cost/benefit tests ──────────────────────────────────
    //
    // KEY INSIGHT: After Phase 1 (agglomerative face clustering), ALL inputs
    // with face embeddings get a label >= 0 — even singletons. So body rescue
    // (Phase 2) only helps inputs with NO face embedding at all (label == -1).
    //
    // The three body-related phases help in distinct ways:
    //   Phase 2  (body rescue): assigns no-face images to face-based clusters
    //   Phase 2b (body-only):   clusters no-face images among themselves
    //   Phase 3  (cross-merge): merges separate face clusters using body similarity

    /// Strip all body embeddings from inputs to isolate face-only clustering.
    fn strip_bodies(inputs: &[PetClusterInput]) -> Vec<PetClusterInput> {
        inputs
            .iter()
            .map(|i| PetClusterInput {
                pet_face_id: i.pet_face_id.clone(),
                face_embedding: i.face_embedding.clone(),
                body_embedding: vec![],
                species: i.species,
                file_id: i.file_id,
            })
            .collect()
    }

    fn make_input_with_file(
        face_id: &str,
        face: Vec<f32>,
        body: Vec<f32>,
        species: u8,
        file_id: i64,
    ) -> PetClusterInput {
        PetClusterInput {
            pet_face_id: face_id.to_string(),
            face_embedding: face,
            body_embedding: body,
            species,
            file_id,
        }
    }

    /// Make a face embedding clustered around a base direction.
    /// `base_dim` is the dominant dimension, `noise_scale` adds jitter.
    fn make_face(base_dim: usize, noise_seed: u32) -> Vec<f32> {
        let mut v = vec![0.0f32; 128];
        v[base_dim] = 1.0;
        // Deterministic small perturbation
        let noise_dim = ((noise_seed * 7 + 3) % 128) as usize;
        v[noise_dim] += 0.02 * (noise_seed as f32 + 1.0) * 0.1;
        normalized(v)
    }

    /// Make a body embedding clustered around a base direction.
    fn make_body(base_dim: usize, noise_seed: u32) -> Vec<f32> {
        let mut v = vec![0.0f32; 192];
        v[base_dim] = 1.0;
        let noise_dim = ((noise_seed * 11 + 5) % 192) as usize;
        v[noise_dim] += 0.02 * (noise_seed as f32 + 1.0) * 0.1;
        normalized(v)
    }

    // ── Test 1: Body rescue assigns no-face image to face cluster ───────

    #[test]
    fn test_body_rescue_assigns_faceless_image_to_cluster() {
        // 3 images with faces + bodies form a cluster in Phase 1.
        // 1 image has NO face but has a matching body.
        //
        // With bodies: body rescue assigns the faceless image to the cluster.
        // Without bodies: faceless image stays unclustered.

        let config = ClusterConfig::dog();
        let body_a = make_body(10, 0);

        let inputs = vec![
            make_input("a1", make_face(0, 0), body_a.clone(), 0),
            make_input("a2", make_face(0, 1), body_a.clone(), 0),
            make_input("a3", make_face(0, 2), body_a.clone(), 0),
            // No face, only body
            make_input("no_face", vec![], body_a.clone(), 0),
        ];

        let with_bodies = run_pet_clustering(&inputs, &config);
        let without_bodies = run_pet_clustering(&strip_bodies(&inputs), &config);

        // Without bodies: no_face has no face, so it's unclustered
        assert!(
            !without_bodies.face_to_cluster.contains_key("no_face"),
            "Without bodies, faceless image should be unclustered"
        );

        // With bodies: no_face should be rescued into cluster A
        let ca1 = with_bodies.face_to_cluster.get("a1");
        let c_no_face = with_bodies.face_to_cluster.get("no_face");
        assert!(ca1.is_some(), "a1 should be clustered");
        assert_eq!(
            ca1, c_no_face,
            "Body rescue should assign faceless image to matching cluster"
        );

        println!(
            "RESCUE: without_bodies={} unclustered, with_bodies={} unclustered",
            without_bodies.n_unclustered, with_bodies.n_unclustered
        );
    }

    // ── Test 2: Faceless orphan rescued into correct cluster ────────────

    #[test]
    fn test_body_rescue_picks_correct_cluster() {
        // Pet A: 3 faces in dim 0, bodies in dim 10
        // Pet B: 3 faces in dim 64, bodies in dim 10 (same body region!)
        // Orphan: weak face, body matches dim 10
        //
        // Body rescue might want to assign orphan to A or B (both have
        // similar bodies), but face veto should block if orphan's face
        // clearly contradicts the cluster's face centroid.

        let mut config = ClusterConfig::dog();
        config.min_samples = 1;

        let body_a = make_body(10, 0);
        let body_b = make_body(80, 0);

        let inputs = vec![
            make_input("a1", make_face(0, 0), body_a.clone(), 0),
            make_input("a2", make_face(0, 1), body_a.clone(), 0),
            make_input("a3", make_face(0, 2), body_a.clone(), 0),
            make_input("b1", make_face(64, 0), body_b.clone(), 0),
            make_input("b2", make_face(64, 1), body_b.clone(), 0),
            make_input("b3", make_face(64, 2), body_b.clone(), 0),
            // Faceless, body matches cluster A
            make_input("orphan", vec![], body_a.clone(), 0),
        ];

        let result = run_pet_clustering(&inputs, &config);

        let ca1 = result.face_to_cluster.get("a1");
        let cb1 = result.face_to_cluster.get("b1");
        let c_orphan = result.face_to_cluster.get("orphan");

        assert_ne!(ca1, cb1, "Clusters A and B should remain separate");
        assert_eq!(
            ca1, c_orphan,
            "Faceless orphan should be rescued into cluster A (matching body)"
        );
    }

    // ── Test 3: Insufficient body agreements blocks rescue ──────────────

    #[test]
    fn test_body_rescue_needs_min_agreements() {
        // Dog config requires min_body_agreements=3.
        // Cluster with only 2 body members should NOT rescue a faceless image.

        let config = ClusterConfig::dog();
        assert_eq!(config.min_body_agreements, 3);

        let body_a = make_body(10, 0);
        let inputs = vec![
            make_input("a1", make_face(0, 0), body_a.clone(), 0),
            make_input("a2", make_face(0, 1), body_a.clone(), 0),
            // Faceless with matching body — but only 2 cluster body members
            make_input("orphan", vec![], body_a.clone(), 0),
        ];

        let result = run_pet_clustering(&inputs, &config);

        let ca1 = result.face_to_cluster.get("a1");
        let c_orphan = result.face_to_cluster.get("orphan");

        assert_ne!(
            ca1, c_orphan,
            "Orphan should not be rescued with only 2 body agreements (need 3)"
        );
    }

    // ── Test 4: Cat needs fewer agreements than dog ─────────────────────

    #[test]
    fn test_cat_rescue_needs_fewer_agreements() {
        // Cat: min_body_agreements=2, Dog: min_body_agreements=3.
        // With exactly 2 body members, cat should rescue but dog should not.

        let dog_config = ClusterConfig::dog();
        let cat_config = ClusterConfig::cat();

        let body = make_body(10, 0);

        // Dog: 2 face+body members + 1 faceless with matching body
        let dog_inputs = vec![
            make_input("a1", make_face(0, 0), body.clone(), 0),
            make_input("a2", make_face(0, 1), body.clone(), 0),
            make_input("orphan", vec![], body.clone(), 0),
        ];

        // Cat: same structure
        let cat_inputs = vec![
            make_input("a1", make_face(0, 0), body.clone(), 1),
            make_input("a2", make_face(0, 1), body.clone(), 1),
            make_input("orphan", vec![], body.clone(), 1),
        ];

        let dog_result = run_pet_clustering(&dog_inputs, &dog_config);
        let cat_result = run_pet_clustering(&cat_inputs, &cat_config);

        let dog_rescued = dog_result.face_to_cluster.get("orphan")
            == dog_result.face_to_cluster.get("a1")
            && dog_result.face_to_cluster.contains_key("a1");

        let cat_rescued = cat_result.face_to_cluster.get("orphan")
            == cat_result.face_to_cluster.get("a1")
            && cat_result.face_to_cluster.contains_key("a1");

        assert!(
            !dog_rescued,
            "Dog should NOT rescue with only 2 body agreements"
        );
        assert!(cat_rescued, "Cat SHOULD rescue with 2 body agreements");
    }

    // ── Test 5: Body-only inputs (no face) go through Phase 2b ──────────

    #[test]
    fn test_body_only_inputs_cluster_via_phase2b() {
        // Inputs with body but NO face can only cluster in Phase 2b.
        // Without body phases, they'd all be unclustered.

        let config = ClusterConfig::dog();

        let inputs = vec![
            make_input("x1", vec![], make_body(10, 0), 0),
            make_input("x2", vec![], make_body(10, 1), 0),
            make_input("x3", vec![], make_body(10, 2), 0),
            make_input("y1", vec![], make_body(80, 0), 0),
            make_input("y2", vec![], make_body(80, 1), 0),
            make_input("y3", vec![], make_body(80, 2), 0),
        ];

        let with_bodies = run_pet_clustering(&inputs, &config);
        let without_bodies = run_pet_clustering(&strip_bodies(&inputs), &config);

        // Without bodies: all faceless, all stay unclustered
        assert_eq!(
            without_bodies.n_unclustered, 6,
            "Without body embeddings, all faceless inputs should be unclustered"
        );

        // With bodies: Phase 2b should form clusters
        assert!(
            with_bodies.n_unclustered < 6,
            "Phase 2b should cluster some body-only inputs (got {} unclustered)",
            with_bodies.n_unclustered
        );

        // Check group coherence
        let cx1 = with_bodies.face_to_cluster.get("x1");
        let cx2 = with_bodies.face_to_cluster.get("x2");
        let cy1 = with_bodies.face_to_cluster.get("y1");
        let cy2 = with_bodies.face_to_cluster.get("y2");

        if cx1.is_some() && cy1.is_some() {
            assert_eq!(cx1, cx2, "x1 and x2 should be in same cluster");
            assert_eq!(cy1, cy2, "y1 and y2 should be in same cluster");
            assert_ne!(cx1, cy1, "Group X and Y should be separate");
        }

        println!(
            "Phase 2b: {} unclustered (from 6 faceless inputs)",
            with_bodies.n_unclustered
        );
    }

    // ── Test 6: Comparative cost/benefit across a mixed scenario ────────

    #[test]
    fn test_body_rescue_cost_benefit_analysis() {
        // Simulate a realistic scenario:
        //   Pet A: 5 good faces + bodies, 3 weak faces + matching bodies
        //   Pet B: 4 good faces + bodies, 2 weak faces + matching bodies
        //   Strays: 2 random faces, no bodies
        //
        // Measure: how many more correct assignments does body rescue give?

        let mut config = ClusterConfig::dog();
        config.min_samples = 1;
        let mut inputs = Vec::new();
        let mut ground_truth: HashMap<String, &str> = HashMap::new();

        // Pet A: 5 faces with bodies
        for i in 0..5u32 {
            let id = format!("a_face_{}", i);
            inputs.push(make_input_with_file(
                &id,
                make_face(0, i),
                make_body(10, i),
                0,
                100 + i as i64,
            ));
            ground_truth.insert(id, "A");
        }
        // Pet A: 3 faceless with bodies (camera caught body only)
        for i in 0..3u32 {
            let id = format!("a_body_{}", i);
            inputs.push(make_input_with_file(
                &id,
                vec![],
                make_body(10, i + 50),
                0,
                200 + i as i64,
            ));
            ground_truth.insert(id, "A");
        }

        // Pet B: 4 faces with bodies
        for i in 0..4u32 {
            let id = format!("b_face_{}", i);
            inputs.push(make_input_with_file(
                &id,
                make_face(64, i),
                make_body(80, i),
                0,
                300 + i as i64,
            ));
            ground_truth.insert(id, "B");
        }
        // Pet B: 2 faceless with bodies
        for i in 0..2u32 {
            let id = format!("b_body_{}", i);
            inputs.push(make_input_with_file(
                &id,
                vec![],
                make_body(80, i + 50),
                0,
                400 + i as i64,
            ));
            ground_truth.insert(id, "B");
        }

        let with_bodies = run_pet_clustering(&inputs, &config);
        let without_bodies = run_pet_clustering(&strip_bodies(&inputs), &config);

        // Evaluate accuracy
        fn eval_accuracy(
            result: &PetClusterResult,
            ground_truth: &HashMap<String, &str>,
        ) -> (usize, usize, usize) {
            // For each pair of inputs that share ground truth, check if
            // they're in the same cluster (true positive) or not.
            let ids: Vec<&String> = ground_truth.keys().collect();
            let mut correct_same = 0usize;
            let mut wrong_same = 0usize;
            let mut correct_diff = 0usize;

            for i in 0..ids.len() {
                for j in (i + 1)..ids.len() {
                    let gt_same = ground_truth[ids[i]] == ground_truth[ids[j]]
                        && ground_truth[ids[i]] != "stray";
                    let c_i = result.face_to_cluster.get(ids[i].as_str());
                    let c_j = result.face_to_cluster.get(ids[j].as_str());
                    let clustered_same = c_i.is_some() && c_i == c_j;

                    if gt_same && clustered_same {
                        correct_same += 1;
                    } else if !gt_same && clustered_same {
                        wrong_same += 1;
                    } else if !gt_same && !clustered_same {
                        correct_diff += 1;
                    }
                }
            }
            (correct_same, wrong_same, correct_diff)
        }

        let (tp_with, fp_with, _tn_with) = eval_accuracy(&with_bodies, &ground_truth);
        let (tp_without, fp_without, _tn_without) = eval_accuracy(&without_bodies, &ground_truth);

        println!("=== BODY PHASES COST/BENEFIT ===");
        println!(
            "WITHOUT bodies: TP={}, FP={}, unclustered={}",
            tp_without, fp_without, without_bodies.n_unclustered
        );
        println!(
            "WITH    bodies: TP={}, FP={}, unclustered={}",
            tp_with, fp_with, with_bodies.n_unclustered
        );
        println!(
            "DELTA: TP+{}, FP+{}, unclustered-{}",
            tp_with.saturating_sub(tp_without),
            fp_with.saturating_sub(fp_without),
            without_bodies
                .n_unclustered
                .saturating_sub(with_bodies.n_unclustered),
        );

        // Body phases should increase true positives (more correct pairings)
        assert!(
            tp_with >= tp_without,
            "Body phases should not reduce correct pairs ({} < {})",
            tp_with,
            tp_without,
        );

        // Body phases should not introduce many false positives
        assert!(
            fp_with <= fp_without + 2,
            "Body phases should not cause many wrong merges ({} >> {})",
            fp_with,
            fp_without,
        );
    }

    // ── Test 7: Phase 3 cross-cluster merge via body similarity ────────

    #[test]
    fn test_cross_cluster_merge_unifies_body_similar_clusters() {
        // Same pet photographed from two very different angles:
        // face group 1 and face group 2 don't cluster in Phase 1,
        // but their bodies are very similar -> Phase 3 should merge.

        let mut config = ClusterConfig::dog();
        config.min_samples = 1;
        // Lower merge threshold to make the test more robust
        config.body_merge_threshold = 0.30;
        config.face_contradiction_threshold = -1.0; // disable face contradiction

        // Two face groups that won't cluster (orthogonal face embeddings)
        // but identical body embeddings
        let shared_body = make_body(10, 0);

        let inputs = vec![
            make_input("front1", make_face(0, 0), shared_body.clone(), 0),
            make_input("front2", make_face(0, 1), shared_body.clone(), 0),
            make_input("front3", make_face(0, 2), shared_body.clone(), 0),
            make_input("back1", make_face(64, 10), shared_body.clone(), 0),
            make_input("back2", make_face(64, 11), shared_body.clone(), 0),
            make_input("back3", make_face(64, 12), shared_body.clone(), 0),
        ];

        let with_merge = run_pet_clustering(&inputs, &config);
        let without_merge = run_pet_clustering(&strip_bodies(&inputs), &config);

        let front_cluster = with_merge.face_to_cluster.get("front1");
        let back_cluster = with_merge.face_to_cluster.get("back1");
        let front_without = without_merge.face_to_cluster.get("front1");
        let back_without = without_merge.face_to_cluster.get("back1");

        println!(
            "Cross-merge: with_merge front={:?} back={:?}",
            front_cluster, back_cluster
        );
        println!(
            "Cross-merge: without    front={:?} back={:?}",
            front_without, back_without
        );

        // Without merge: should be 2 separate clusters
        assert_ne!(
            front_without, back_without,
            "Without Phase 3, face groups should remain separate"
        );

        // With merge: Phase 3 should unify them
        assert_eq!(
            front_cluster, back_cluster,
            "Phase 3 should merge clusters with similar bodies"
        );
    }

    // ── Test 8: Face contradiction blocks cross-cluster merge ───────────

    #[test]
    fn test_face_contradiction_blocks_merge() {
        // Two DIFFERENT pets with similar bodies but different faces.
        // Phase 3 should NOT merge them because face contradiction fires.

        let mut config = ClusterConfig::dog();
        config.min_samples = 1;
        config.body_merge_threshold = 0.20;
        // Face contradiction enabled (default 0.10)

        let shared_body = make_body(10, 0);

        let inputs = vec![
            // Pet A: face in dim 0
            make_input("a1", make_face(0, 0), shared_body.clone(), 0),
            make_input("a2", make_face(0, 1), shared_body.clone(), 0),
            make_input("a3", make_face(0, 2), shared_body.clone(), 0),
            // Pet B: face in dim 64 (orthogonal = sim ~0, well below 0.10)
            make_input("b1", make_face(64, 10), shared_body.clone(), 0),
            make_input("b2", make_face(64, 11), shared_body.clone(), 0),
            make_input("b3", make_face(64, 12), shared_body.clone(), 0),
        ];

        let result = run_pet_clustering(&inputs, &config);

        let ca = result.face_to_cluster.get("a1");
        let cb = result.face_to_cluster.get("b1");

        assert_ne!(
            ca, cb,
            "Face contradiction should block merge of different pets with similar bodies"
        );
    }

    // ── Test 9: Computational cost scaling ──────────────────────────────

    #[test]
    fn test_body_rescue_cost_scales_linearly() {
        // Body rescue is O(unclustered * clustered * body_members_per_cluster).
        // Verify it completes in reasonable time for moderate input sizes.

        let config = ClusterConfig::dog();
        let mut inputs = Vec::new();
        // 50 faces+bodies that will cluster in Phase 1
        for i in 0..50u32 {
            inputs.push(make_input_with_file(
                &format!("c_{}", i),
                make_face(0, i),
                make_body(10, i),
                0,
                i as i64,
            ));
        }
        // 20 faceless+body that need rescue via Phase 2
        for i in 0..20u32 {
            inputs.push(make_input_with_file(
                &format!("u_{}", i),
                vec![],
                make_body(10, i + 500),
                0,
                1000 + i as i64,
            ));
        }

        let start = std::time::Instant::now();
        let result = run_pet_clustering(&inputs, &config);
        let elapsed = start.elapsed();

        println!(
            "Cost: 70 inputs (50 face+body, 20 body-only) -> {:?}, {} unclustered",
            elapsed, result.n_unclustered
        );

        assert!(
            elapsed.as_secs() < 2,
            "Clustering took too long: {:?}",
            elapsed
        );

        // Most body-only inputs should have been rescued
        assert!(
            result.n_unclustered <= 5,
            "Too many still unclustered: {} (expected most rescued)",
            result.n_unclustered
        );
    }
}

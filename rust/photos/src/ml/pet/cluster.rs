//! Pet clustering engine — face-based agglomerative clustering.
//!
//! Clusters pet face embeddings using average-linkage agglomerative
//! clustering with species-specific distance thresholds.
//!
//! All embeddings are assumed L2-normalized (cosine distance = 1 − dot).

use crate::vector_db::VectorDB;
use std::collections::{HashMap, HashSet};

unsafe extern "C" {
    fn simsimd_dot_f32(a: *const f32, b: *const f32, n: u64, d: *mut f64);
}

pub(crate) fn simsimd_dot_product(a: &[f32], b: &[f32]) -> f32 {
    debug_assert_eq!(a.len(), b.len());
    let mut score = 0.0_f64;
    unsafe {
        simsimd_dot_f32(a.as_ptr(), b.as_ptr(), a.len() as u64, &mut score);
    }
    score as f32
}

pub(crate) fn simsimd_cosine_distance(a: &[f32], b: &[f32]) -> f32 {
    1.0 - simsimd_dot_product(a, b)
}

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

/// Clustering thresholds per species.
#[derive(Clone, Debug)]
pub struct ClusterConfig {
    pub species: Species,
    /// Minimum number of faces to form a cluster.
    pub min_cluster_size: usize,
    /// Distance threshold for agglomerative clustering (average linkage).
    /// Lower = tighter clusters, higher = more permissive merging.
    pub agglomerative_threshold: f32,
    /// Maximum number of exemplar embeddings to store per cluster.
    /// Used for multi-exemplar incremental matching.
    pub max_exemplars: usize,
}

impl ClusterConfig {
    pub fn dog() -> Self {
        Self {
            species: Species::Dog,
            min_cluster_size: 2,
            agglomerative_threshold: 0.45,
            max_exemplars: 5,
        }
    }

    pub fn cat() -> Self {
        Self {
            species: Species::Cat,
            min_cluster_size: 2,
            agglomerative_threshold: 0.75,
            max_exemplars: 5,
        }
    }

    pub fn for_species(species: Species) -> Self {
        match species {
            Species::Dog => Self::dog(),
            Species::Cat => Self::cat(),
        }
    }

    fn exemplar_energy_margin(&self) -> f32 {
        0.02
    }

    fn cluster_assignment_margin(&self) -> f32 {
        0.03
    }

    fn greedy_face_threshold(&self) -> f32 {
        match self.species {
            Species::Dog => 0.32,
            Species::Cat => 0.52,
        }
    }

    fn greedy_body_threshold(&self) -> f32 {
        match self.species {
            Species::Dog => 0.30,
            Species::Cat => 0.40,
        }
    }

    fn greedy_combined_threshold(&self) -> f32 {
        match self.species {
            Species::Dog => 0.30,
            Species::Cat => 0.46,
        }
    }

    fn body_distance_weight(&self) -> (f32, f32) {
        (0.75, 0.25)
    }

    fn hac_sample_size(&self) -> usize {
        128
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
    /// L2-normalized body embedding. Empty vec if no body.
    pub body_embedding: Vec<f32>,
    /// 0 = dog, 1 = cat.
    pub species: u8,
    /// File ID that this detection belongs to.
    pub file_id: i64,
}

#[derive(Clone, Debug)]
pub struct PetClusterIndexInput {
    pub pet_face_id: String,
    pub vector_id: u64,
    pub species: u8,
    pub file_id: i64,
}

impl PetClusterInput {
    pub fn face_only(
        pet_face_id: String,
        face_embedding: Vec<f32>,
        species: u8,
        file_id: i64,
    ) -> Self {
        Self {
            pet_face_id,
            face_embedding,
            body_embedding: Vec::new(),
            species,
            file_id,
        }
    }

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
    /// cluster_id → diverse exemplar embeddings (real faces, not averaged).
    /// Used for multi-exemplar incremental matching.
    pub cluster_exemplars: HashMap<String, Vec<Vec<f32>>>,
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

    // Face-based agglomerative clustering
    let mut labels = phase1_face_cluster(inputs, &has_face, config);
    renumber_labels(&mut labels);

    build_result(inputs, &labels, &has_face, config)
}

pub fn run_pet_clustering_from_vdb(
    inputs: &[PetClusterIndexInput],
    vdb: &VectorDB,
    config: &ClusterConfig,
) -> Result<PetClusterResult, String> {
    if inputs.is_empty() {
        return Ok(PetClusterResult::default());
    }

    let allowed_keys: Vec<u64> = inputs.iter().map(|i| i.vector_id).collect();
    let mut key_to_position = HashMap::with_capacity(inputs.len());
    for (idx, input) in inputs.iter().enumerate() {
        key_to_position.insert(input.vector_id, idx);
    }

    let mut vector_cache: HashMap<u64, Vec<f32>> = HashMap::with_capacity(inputs.len());
    let mut materialized_inputs = Vec::with_capacity(inputs.len());
    let mut clusters: Vec<GreedyCluster> = Vec::new();
    let mut assigned_cluster: Vec<Option<usize>> = vec![None; inputs.len()];

    for (idx, input) in inputs.iter().enumerate() {
        let face_embedding = get_cached_vector(vdb, input.vector_id, &mut vector_cache)?;
        let observation = PetClusterInput {
            pet_face_id: input.pet_face_id.clone(),
            face_embedding: face_embedding.clone(),
            body_embedding: Vec::new(),
            species: input.species,
            file_id: input.file_id,
        };
        materialized_inputs.push(observation.clone());

        let (neighbor_keys, _) = vdb.approx_filtered_search_vectors_within_distance(
            &face_embedding,
            &allowed_keys,
            32,
            config.greedy_face_threshold(),
        )?;

        let mut candidate_clusters: Vec<usize> = Vec::new();
        for key in neighbor_keys {
            if key == input.vector_id {
                continue;
            }
            let Some(&neighbor_idx) = key_to_position.get(&key) else {
                continue;
            };
            if neighbor_idx >= idx {
                continue;
            }
            if let Some(cluster_idx) = assigned_cluster[neighbor_idx]
                && !candidate_clusters.contains(&cluster_idx)
            {
                candidate_clusters.push(cluster_idx);
            }
        }

        let mut best_idx = None;
        let mut best_dist = f32::INFINITY;
        let mut second_best_dist = f32::INFINITY;
        for &cluster_idx in &candidate_clusters {
            let dist = greedy_cluster_distance(&observation, &clusters[cluster_idx], config);
            if dist < best_dist {
                second_best_dist = best_dist;
                best_dist = dist;
                best_idx = Some(cluster_idx);
            } else if dist < second_best_dist {
                second_best_dist = dist;
            }
        }

        let has_clear_winner = candidate_clusters.len() <= 1
            || (second_best_dist - best_dist) > config.cluster_assignment_margin();
        let cluster_idx = if best_dist.is_finite() && has_clear_winner {
            if let Some(cluster_idx) = best_idx {
                clusters[cluster_idx].add_member(idx, &observation);
                cluster_idx
            } else {
                let cluster_idx = clusters.len();
                clusters.push(GreedyCluster::new(idx, &observation));
                cluster_idx
            }
        } else {
            let cluster_idx = clusters.len();
            clusters.push(GreedyCluster::new(idx, &observation));
            cluster_idx
        };
        assigned_cluster[idx] = Some(cluster_idx);
    }

    median_linkage_merge(&mut clusters, &materialized_inputs, config);

    let mut labels = vec![-1i32; materialized_inputs.len()];
    for (cluster_idx, cluster) in clusters.iter().enumerate() {
        if cluster.members.len() < config.min_cluster_size {
            continue;
        }
        for &member_idx in &cluster.members {
            labels[member_idx] = cluster_idx as i32;
        }
    }
    renumber_labels(&mut labels);

    let has_face = vec![true; materialized_inputs.len()];
    Ok(build_result(
        &materialized_inputs,
        &labels,
        &has_face,
        config,
    ))
}

/// Run incremental face-only clustering: assign new inputs to existing
/// face clusters by centroid similarity, then cluster the remainder.
///
/// Uses a relaxed threshold for centroid matching (centroid is an average
/// that doesn't represent any individual face perfectly, so it needs more
/// slack than pairwise comparisons in batch mode).
pub fn run_pet_clustering_incremental(
    new_inputs: &[PetClusterInput],
    existing_centroids_face: &HashMap<String, Vec<f32>>,
    config: &ClusterConfig,
) -> PetClusterResult {
    let n = new_inputs.len();
    if n == 0 {
        return PetClusterResult::default();
    }

    let mut labels = vec![-1i32; n];
    let mut cluster_name_map: HashMap<i32, String> = HashMap::new();

    // Step 1: Try to assign each new face to the closest existing cluster.
    // Use a relaxed threshold: centroids are averages that drift from
    // individual members, so we allow 15% more distance than batch mode.
    let centroid_threshold = config.agglomerative_threshold * 1.15;
    let min_sim = 1.0 - centroid_threshold;

    for (i, inp) in new_inputs.iter().enumerate() {
        if !inp.has_face() {
            continue;
        }

        let mut best_sim = -1.0f32;
        let mut second_best_sim = -1.0f32;
        let mut best_id: Option<&String> = None;

        for (cluster_id, centroid) in existing_centroids_face {
            let sim = simsimd_dot_product(&inp.face_embedding, centroid);
            if sim > best_sim {
                second_best_sim = best_sim;
                best_sim = sim;
                best_id = Some(cluster_id);
            } else if sim > second_best_sim {
                second_best_sim = sim;
            }
        }

        // Assign if:
        // 1. Distance to best centroid is below relaxed threshold
        // 2. Best is clearly better than second-best (margin > 0.05)
        //    to avoid ambiguous assignments
        let has_clear_winner =
            existing_centroids_face.len() <= 1 || (best_sim - second_best_sim) > 0.05;

        if best_sim > min_sim
            && has_clear_winner
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

/// Run incremental clustering using multi-exemplar matching.
///
/// Instead of comparing new faces against a single mean centroid per cluster,
/// this compares against multiple real exemplar embeddings. A face matches a
/// cluster if it is similar enough to ANY exemplar in that cluster.
///
/// Benefits over centroid matching:
/// - No "centroid drift" — exemplars are real embeddings that don't degrade.
/// - Captures cluster shape (e.g., front vs. profile views of the same pet).
/// - No need for the 1.15× threshold relaxation hack.
pub fn run_pet_clustering_incremental_with_exemplars(
    new_inputs: &[PetClusterInput],
    existing_exemplars: &HashMap<String, Vec<Vec<f32>>>,
    config: &ClusterConfig,
) -> PetClusterResult {
    let n = new_inputs.len();
    if n == 0 {
        return PetClusterResult::default();
    }

    let mut labels = vec![-1i32; n];
    let mut cluster_name_map: HashMap<i32, String> = HashMap::new();

    // Step 1: Match each new face against all exemplars of each cluster.
    // No threshold relaxation needed — we're comparing against real faces.
    let min_sim = 1.0 - config.agglomerative_threshold;

    for (i, inp) in new_inputs.iter().enumerate() {
        if !inp.has_face() {
            continue;
        }

        let mut best_sim = f32::NEG_INFINITY;
        let mut second_best_sim = f32::NEG_INFINITY;
        let mut best_id: Option<&String> = None;

        let mut best_energy = f32::NEG_INFINITY;
        let mut second_best_energy = f32::NEG_INFINITY;

        for (cluster_id, exemplars) in existing_exemplars {
            let (cluster_sim, cluster_energy) =
                exemplar_cluster_score(&inp.face_embedding, exemplars, min_sim);

            if cluster_energy > best_energy
                || (cluster_energy == best_energy && cluster_sim > best_sim)
            {
                second_best_energy = best_energy;
                second_best_sim = best_sim;
                best_energy = cluster_energy;
                best_sim = cluster_sim;
                best_id = Some(cluster_id);
            } else if cluster_energy > second_best_energy
                || (cluster_energy == second_best_energy && cluster_sim > second_best_sim)
            {
                second_best_energy = cluster_energy;
                second_best_sim = cluster_sim;
            }
        }

        // Apple-like "gallery assignment": use multiple exemplars as votes.
        // A cluster wins if it has the strongest exemplar support ("energy"),
        // while still requiring at least one exemplar to exceed the hard match
        // threshold so we do not force low-confidence assignments.
        let has_clear_winner = existing_exemplars.len() <= 1
            || (best_energy - second_best_energy) > config.exemplar_energy_margin()
            || (best_sim - second_best_sim) > 0.05;

        if best_sim > min_sim
            && best_energy.is_finite()
            && best_energy > 0.0
            && has_clear_winner
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
    let face_dim = new_inputs
        .iter()
        .find(|i| i.has_face())
        .map(|i| i.face_embedding.len())
        .unwrap_or(128);

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

    // Compute centroids and exemplars from the new faces in each cluster
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
            result
                .cluster_centroids
                .insert(cluster_id.clone(), mean_centroid(&face_embs, face_dim));
            result.cluster_exemplars.insert(
                cluster_id.clone(),
                select_exemplars(&face_embs, config.max_exemplars, face_dim),
            );
        }
    }

    result
}

// ── Phase 1: Conservative greedy micro-clusters + HAC merge ─────────────

/// Build conservative micro-clusters, then grow them with face-only HAC.
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

    let mut clusters = greedy_microclusters(inputs, &face_indices, config);
    if clusters.is_empty() {
        return labels;
    }

    median_linkage_merge(&mut clusters, inputs, config);

    for (cluster_idx, cluster) in clusters.iter().enumerate() {
        if cluster.members.len() < config.min_cluster_size {
            continue;
        }
        for &global_idx in &cluster.members {
            labels[global_idx] = cluster_idx as i32;
        }
    }

    labels
}

fn greedy_microclusters(
    inputs: &[PetClusterInput],
    face_indices: &[usize],
    config: &ClusterConfig,
) -> Vec<GreedyCluster> {
    let mut clusters: Vec<GreedyCluster> = Vec::new();

    for &global_idx in face_indices {
        let observation = &inputs[global_idx];
        let mut best_idx = None;
        let mut best_dist = f32::INFINITY;
        let mut second_best_dist = f32::INFINITY;

        for (cluster_idx, cluster) in clusters.iter().enumerate() {
            let dist = greedy_cluster_distance(observation, cluster, config);
            if dist < best_dist {
                second_best_dist = best_dist;
                best_dist = dist;
                best_idx = Some(cluster_idx);
            } else if dist < second_best_dist {
                second_best_dist = dist;
            }
        }

        let has_clear_winner = clusters.len() <= 1
            || (second_best_dist - best_dist) > config.cluster_assignment_margin();
        if best_dist.is_finite()
            && has_clear_winner
            && let Some(cluster_idx) = best_idx
        {
            clusters[cluster_idx].add_member(global_idx, observation);
        } else {
            clusters.push(GreedyCluster::new(global_idx, observation));
        }
    }

    clusters
}

fn greedy_cluster_distance(
    observation: &PetClusterInput,
    cluster: &GreedyCluster,
    config: &ClusterConfig,
) -> f32 {
    let face_dist = if observation.has_face() && cluster.face_count > 0 {
        simsimd_cosine_distance(&observation.face_embedding, &cluster.face_centroid)
    } else {
        f32::INFINITY
    };

    let body_dist = if observation.has_body() && cluster.body_count > 0 {
        simsimd_cosine_distance(&observation.body_embedding, &cluster.body_centroid)
    } else {
        f32::INFINITY
    };

    if face_dist.is_finite() {
        if body_dist.is_finite() && body_dist <= config.greedy_body_threshold() {
            let (alpha, beta) = config.body_distance_weight();
            let combined = alpha * face_dist + beta * body_dist;
            if combined <= config.greedy_combined_threshold() {
                return face_dist.min(combined);
            }
        }
        if face_dist <= config.greedy_face_threshold() {
            face_dist
        } else {
            f32::INFINITY
        }
    } else if body_dist <= config.greedy_body_threshold() {
        body_dist
    } else {
        f32::INFINITY
    }
}

fn median_linkage_merge(
    clusters: &mut Vec<GreedyCluster>,
    inputs: &[PetClusterInput],
    config: &ClusterConfig,
) {
    loop {
        let mut best_pair = None;
        let mut best_dist = f32::INFINITY;

        for i in 0..clusters.len() {
            for j in (i + 1)..clusters.len() {
                let dist = sampled_median_face_distance(&clusters[i], &clusters[j], inputs, config);
                if dist < best_dist {
                    best_dist = dist;
                    best_pair = Some((i, j));
                }
            }
        }

        let Some((left, right)) = best_pair else {
            break;
        };
        if best_dist > config.agglomerative_threshold {
            break;
        }

        let other = clusters.remove(right);
        clusters[left].merge(other);
    }
}

fn sampled_median_face_distance(
    left: &GreedyCluster,
    right: &GreedyCluster,
    inputs: &[PetClusterInput],
    config: &ClusterConfig,
) -> f32 {
    let total_pairs = left.members.len() * right.members.len();
    if total_pairs == 0 {
        return f32::INFINITY;
    }

    let mut distances = Vec::with_capacity(total_pairs.min(config.hac_sample_size()));
    if total_pairs <= config.hac_sample_size() {
        for &li in &left.members {
            for &ri in &right.members {
                distances.push(face_distance(
                    &inputs[li].face_embedding,
                    &inputs[ri].face_embedding,
                ));
            }
        }
    } else {
        let sample_size = config.hac_sample_size();
        let mut state =
            ((left.members[0] as u64) << 32) ^ (right.members[0] as u64) ^ (total_pairs as u64);
        for _ in 0..sample_size {
            state = state.wrapping_mul(6364136223846793005).wrapping_add(1);
            let li = left.members[(state as usize) % left.members.len()];
            state = state.wrapping_mul(6364136223846793005).wrapping_add(1);
            let ri = right.members[(state as usize) % right.members.len()];
            distances.push(face_distance(
                &inputs[li].face_embedding,
                &inputs[ri].face_embedding,
            ));
        }
    }

    distances.sort_by(|a, b| a.total_cmp(b));
    distances[distances.len() / 2]
}

fn face_distance(left: &[f32], right: &[f32]) -> f32 {
    simsimd_cosine_distance(left, right)
}

fn get_cached_vector(
    vdb: &VectorDB,
    key: u64,
    cache: &mut HashMap<u64, Vec<f32>>,
) -> Result<Vec<f32>, String> {
    if let Some(vector) = cache.get(&key) {
        return Ok(vector.clone());
    }

    let vector = vdb.get_vector(key)?;
    cache.insert(key, vector.clone());
    Ok(vector)
}

fn exemplar_cluster_score(
    face_embedding: &[f32],
    exemplars: &[Vec<f32>],
    min_sim: f32,
) -> (f32, f32) {
    let mut similarities: Vec<f32> = exemplars
        .iter()
        .map(|ex| simsimd_dot_product(face_embedding, ex))
        .collect();
    if similarities.is_empty() {
        return (f32::NEG_INFINITY, f32::NEG_INFINITY);
    }

    similarities.sort_by(|a, b| b.total_cmp(a));
    let best_sim = similarities[0];
    let energy = similarities
        .iter()
        .take(3)
        .map(|sim| (sim - min_sim).max(0.0))
        .sum();

    (best_sim, energy)
}

struct GreedyCluster {
    members: Vec<usize>,
    face_count: usize,
    body_count: usize,
    face_centroid: Vec<f32>,
    body_centroid: Vec<f32>,
}

impl GreedyCluster {
    fn new(first_idx: usize, observation: &PetClusterInput) -> Self {
        Self {
            members: vec![first_idx],
            face_count: usize::from(observation.has_face()),
            body_count: usize::from(observation.has_body()),
            face_centroid: observation.face_embedding.clone(),
            body_centroid: observation.body_embedding.clone(),
        }
    }

    fn add_member(&mut self, idx: usize, observation: &PetClusterInput) {
        self.members.push(idx);
        if observation.has_face() {
            if self.face_count == 0 {
                self.face_centroid = observation.face_embedding.clone();
            } else {
                update_running_mean(
                    &mut self.face_centroid,
                    &observation.face_embedding,
                    self.face_count,
                );
            }
            self.face_count += 1;
        }
        if observation.has_body() {
            if self.body_count == 0 {
                self.body_centroid = observation.body_embedding.clone();
            } else {
                update_running_mean(
                    &mut self.body_centroid,
                    &observation.body_embedding,
                    self.body_count,
                );
            }
            self.body_count += 1;
        }
    }

    fn merge(&mut self, other: Self) {
        self.members.extend(other.members);
        if other.face_count > 0 {
            if self.face_count == 0 {
                self.face_centroid = other.face_centroid;
                self.face_count = other.face_count;
            } else {
                merge_running_means(
                    &mut self.face_centroid,
                    self.face_count,
                    &other.face_centroid,
                    other.face_count,
                );
                self.face_count += other.face_count;
            }
        }
        if other.body_count > 0 {
            if self.body_count == 0 {
                self.body_centroid = other.body_centroid;
                self.body_count = other.body_count;
            } else {
                merge_running_means(
                    &mut self.body_centroid,
                    self.body_count,
                    &other.body_centroid,
                    other.body_count,
                );
                self.body_count += other.body_count;
            }
        }
    }
}

fn update_running_mean(mean: &mut [f32], sample: &[f32], previous_count: usize) {
    let prev = previous_count as f32;
    let next = prev + 1.0;
    for (m, s) in mean.iter_mut().zip(sample.iter()) {
        *m = ((*m * prev) + *s) / next;
    }
}

fn merge_running_means(
    mean: &mut [f32],
    left_count: usize,
    other_mean: &[f32],
    right_count: usize,
) {
    let left = left_count as f32;
    let right = right_count as f32;
    let total = left + right;
    for (m, o) in mean.iter_mut().zip(other_mean.iter()) {
        *m = ((*m * left) + (*o * right)) / total;
    }
}

fn l2_norm(v: &[f32]) -> f32 {
    simsimd_dot_product(v, v).sqrt()
}

fn normalize(v: &mut [f32]) {
    let norm = l2_norm(v);
    if norm > 1e-8 {
        for value in v.iter_mut() {
            *value /= norm;
        }
    }
}

pub(crate) fn select_exemplars(embs: &[&Vec<f32>], k: usize, dim: usize) -> Vec<Vec<f32>> {
    let n = embs.len();
    if n == 0 {
        return Vec::new();
    }
    if n <= k {
        return embs.iter().map(|embedding| (*embedding).clone()).collect();
    }

    let centroid = mean_centroid(embs, dim);
    let mut selected: Vec<usize> = Vec::with_capacity(k);

    let first = (0..n)
        .max_by(|&left, &right| {
            simsimd_dot_product(embs[left], &centroid)
                .partial_cmp(&simsimd_dot_product(embs[right], &centroid))
                .unwrap_or(std::cmp::Ordering::Equal)
        })
        .unwrap();
    selected.push(first);

    while selected.len() < k {
        let best = (0..n)
            .filter(|idx| !selected.contains(idx))
            .min_by(|&left, &right| {
                let max_sim_left = selected
                    .iter()
                    .map(|&selected_idx| simsimd_dot_product(embs[left], embs[selected_idx]))
                    .fold(f32::NEG_INFINITY, f32::max);
                let max_sim_right = selected
                    .iter()
                    .map(|&selected_idx| simsimd_dot_product(embs[right], embs[selected_idx]))
                    .fold(f32::NEG_INFINITY, f32::max);
                max_sim_left
                    .partial_cmp(&max_sim_right)
                    .unwrap_or(std::cmp::Ordering::Equal)
            })
            .unwrap();
        selected.push(best);
    }

    selected.iter().map(|&idx| embs[idx].clone()).collect()
}

pub(crate) fn mean_centroid(embs: &[&Vec<f32>], dim: usize) -> Vec<f32> {
    if embs.is_empty() {
        return vec![0.0; dim];
    }

    let mut centroid = vec![0.0f32; dim];
    for embedding in embs {
        for (idx, &value) in embedding.iter().enumerate() {
            if idx < dim {
                centroid[idx] += value;
            }
        }
    }

    let count = embs.len() as f32;
    for value in &mut centroid {
        *value /= count;
    }
    normalize(&mut centroid);
    centroid
}

pub(crate) fn unique_cluster_ids(labels: &[i32]) -> Vec<i32> {
    let mut ids: Vec<i32> = labels
        .iter()
        .copied()
        .filter(|&label| label >= 0)
        .collect::<HashSet<_>>()
        .into_iter()
        .collect();
    ids.sort_unstable();
    ids
}

pub(crate) fn renumber_labels(labels: &mut [i32]) {
    let unique = unique_cluster_ids(labels);
    let mapping: HashMap<i32, i32> = unique
        .iter()
        .enumerate()
        .map(|(new, &old)| (old, new as i32))
        .collect();
    for label in labels.iter_mut() {
        if *label >= 0
            && let Some(&new) = mapping.get(label)
        {
            *label = new;
        }
    }
}

fn build_result(
    inputs: &[PetClusterInput],
    labels: &[i32],
    has_face: &[bool],
    config: &ClusterConfig,
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

    // Compute centroids and exemplars for each cluster
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
            result.cluster_exemplars.insert(
                cluster_id.clone(),
                select_exemplars(&face_embs, config.max_exemplars, face_dim),
            );
        }
    }

    result
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_input(face_id: &str, face: Vec<f32>, species: u8) -> PetClusterInput {
        PetClusterInput {
            pet_face_id: face_id.to_string(),
            face_embedding: face,
            body_embedding: Vec::new(),
            species,
            file_id: 0,
        }
    }

    /// Make a face embedding clustered around a base direction.
    fn make_face(base_dim: usize, noise_seed: u32) -> Vec<f32> {
        let mut v = vec![0.0f32; 128];
        v[base_dim] = 1.0;
        for k in 0..10u32 {
            let dim = (noise_seed.wrapping_mul(7).wrapping_add(k * 13 + 3) % 128) as usize;
            let t = (noise_seed as f32 * 0.618 + k as f32 * 1.377).sin();
            v[dim] += t * 0.35;
        }
        normalized(v)
    }

    #[allow(dead_code)]
    fn perturb(base: &[f32], dim: usize, amount: f32) -> Vec<f32> {
        let mut v = base.to_vec();
        let idx = dim % v.len();
        v[idx] += amount;
        normalized(v)
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
        let inputs = vec![make_input("face_1", normalized(vec![1.0; 128]), 0)];
        let result = run_pet_clustering(&inputs, &config);
        // Single input can't form a cluster
        assert_eq!(result.n_unclustered, 1);
    }

    #[test]
    fn test_two_similar_faces_cluster() {
        let config = ClusterConfig::dog();
        // HDBSCAN needs density contrast — provide 2 groups
        let mut inputs: Vec<_> = (0..5)
            .map(|i| make_input(&format!("a{}", i), make_face(0, i), 0))
            .collect();
        // Second group so HDBSCAN sees density contrast
        for i in 0..5 {
            inputs.push(make_input(&format!("b{}", i), make_face(64, i + 100), 0));
        }

        let result = run_pet_clustering(&inputs, &config);
        let c0 = result.face_to_cluster.get("a0");
        assert!(c0.is_some(), "a0 should be clustered");
        for i in 1..5 {
            assert_eq!(
                c0,
                result.face_to_cluster.get(&format!("a{}", i)),
                "a{} should be in same cluster as a0",
                i
            );
        }
        // Groups should be separate
        assert_ne!(
            result.face_to_cluster.get("a0"),
            result.face_to_cluster.get("b0"),
            "Group A and B should be separate"
        );
    }

    #[test]
    fn test_two_groups_separate() {
        let config = ClusterConfig::dog();

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
            make_input("a1", base_a.clone(), 0),
            make_input("a2", perturb(&base_a, 1, 0.02), 0),
            make_input("a3", perturb(&base_a, 2, 0.02), 0),
            make_input("b1", base_b.clone(), 0),
            make_input("b2", perturb(&base_b, 65, 0.02), 0),
            make_input("b3", perturb(&base_b, 66, 0.02), 0),
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

    /// Simulate the real app flow:
    /// ONE:   Batch cluster initial faces → creates clusters + centroids
    /// TWO:   New faces arrive → incremental assigns to existing clusters
    /// THREE: More faces arrive → incremental assigns again
    #[test]
    fn test_incremental_one_two_three() {
        let config = ClusterConfig::dog();

        // ── ONE: Initial batch of 10 faces (2 dogs, 5 each) ──
        let mut batch_inputs = Vec::new();
        for i in 0..5u32 {
            batch_inputs.push(make_input(&format!("dogA_{}", i), make_face(0, i), 0));
        }
        for i in 0..5u32 {
            batch_inputs.push(make_input(
                &format!("dogB_{}", i),
                make_face(64, i + 100),
                0,
            ));
        }

        let batch_result = run_pet_clustering(&batch_inputs, &config);

        // Verify batch: 2 clusters, 0 unclustered
        let ca = batch_result.face_to_cluster.get("dogA_0");
        let cb = batch_result.face_to_cluster.get("dogB_0");
        assert!(ca.is_some(), "ONE: dogA_0 should be clustered");
        assert!(cb.is_some(), "ONE: dogB_0 should be clustered");
        assert_ne!(ca, cb, "ONE: dog A and dog B should be separate clusters");

        // All A's in same cluster
        for i in 1..5 {
            assert_eq!(
                ca,
                batch_result.face_to_cluster.get(&format!("dogA_{}", i)),
                "ONE: dogA_{} should be in same cluster as dogA_0",
                i
            );
        }
        // All B's in same cluster
        for i in 1..5 {
            assert_eq!(
                cb,
                batch_result.face_to_cluster.get(&format!("dogB_{}", i)),
                "ONE: dogB_{} should be in same cluster as dogB_0",
                i
            );
        }

        let cluster_a_id = ca.unwrap().clone();
        let cluster_b_id = cb.unwrap().clone();

        println!(
            "ONE: {} clusters, {} unclustered, A={}, B={}",
            batch_result.cluster_counts.len(),
            batch_result.n_unclustered,
            cluster_a_id,
            cluster_b_id
        );

        // Extract centroids (simulating what Dart stores in VDB)
        let centroids = batch_result.cluster_centroids.clone();
        assert!(
            centroids.contains_key(&cluster_a_id),
            "ONE: centroid for cluster A should exist"
        );
        assert!(
            centroids.contains_key(&cluster_b_id),
            "ONE: centroid for cluster B should exist"
        );

        // ── TWO: 4 new faces arrive (2 for each dog) ──
        let new_faces_two = vec![
            make_input("dogA_new1", make_face(0, 50), 0),
            make_input("dogA_new2", make_face(0, 51), 0),
            make_input("dogB_new1", make_face(64, 150), 0),
            make_input("dogB_new2", make_face(64, 151), 0),
        ];

        let incr_result_two = run_pet_clustering_incremental(&new_faces_two, &centroids, &config);

        println!(
            "TWO: {} assigned, {} unclustered, clusters={:?}",
            incr_result_two.face_to_cluster.len(),
            incr_result_two.n_unclustered,
            incr_result_two.cluster_counts
        );

        // dogA new faces should go to cluster A
        let ca_new1 = incr_result_two.face_to_cluster.get("dogA_new1");
        let ca_new2 = incr_result_two.face_to_cluster.get("dogA_new2");
        assert_eq!(
            ca_new1,
            Some(&cluster_a_id),
            "TWO: dogA_new1 should be assigned to cluster A"
        );
        assert_eq!(
            ca_new2,
            Some(&cluster_a_id),
            "TWO: dogA_new2 should be assigned to cluster A"
        );

        // dogB new faces should go to cluster B
        let cb_new1 = incr_result_two.face_to_cluster.get("dogB_new1");
        let cb_new2 = incr_result_two.face_to_cluster.get("dogB_new2");
        assert_eq!(
            cb_new1,
            Some(&cluster_b_id),
            "TWO: dogB_new1 should be assigned to cluster B"
        );
        assert_eq!(
            cb_new2,
            Some(&cluster_b_id),
            "TWO: dogB_new2 should be assigned to cluster B"
        );

        assert_eq!(
            incr_result_two.n_unclustered, 0,
            "TWO: all new faces should be assigned"
        );

        // ── THREE: 3 more faces (2 dog A, 1 completely new dog C) ──
        let new_faces_three = vec![
            make_input("dogA_new3", make_face(0, 52), 0),
            make_input("dogA_new4", make_face(0, 53), 0),
            // Dog C: new identity, dim 32 (not matching A or B)
            make_input("dogC_0", make_face(32, 200), 0),
        ];

        let incr_result_three =
            run_pet_clustering_incremental(&new_faces_three, &centroids, &config);

        println!(
            "THREE: {} assigned, {} unclustered, clusters={:?}",
            incr_result_three.face_to_cluster.len(),
            incr_result_three.n_unclustered,
            incr_result_three.cluster_counts
        );

        // Dog A faces should still go to cluster A
        assert_eq!(
            incr_result_three.face_to_cluster.get("dogA_new3"),
            Some(&cluster_a_id),
            "THREE: dogA_new3 should be assigned to cluster A"
        );
        assert_eq!(
            incr_result_three.face_to_cluster.get("dogA_new4"),
            Some(&cluster_a_id),
            "THREE: dogA_new4 should be assigned to cluster A"
        );

        // Dog C should NOT be assigned to A or B (it's a new identity)
        let cc = incr_result_three.face_to_cluster.get("dogC_0");
        if let Some(cid) = cc {
            assert_ne!(cid, &cluster_a_id, "THREE: dogC should not be in cluster A");
            assert_ne!(cid, &cluster_b_id, "THREE: dogC should not be in cluster B");
            println!("THREE: dogC_0 created new cluster {}", cid);
        } else {
            println!("THREE: dogC_0 stayed unclustered (only 1 face, expected)");
        }
    }

    /// Test incremental with a face that's borderline between two clusters.
    /// The margin check should prevent ambiguous assignment.
    #[test]
    fn test_incremental_ambiguous_face_stays_unassigned() {
        let config = ClusterConfig::dog();

        // Batch: 2 clusters
        let mut batch_inputs = Vec::new();
        for i in 0..5u32 {
            batch_inputs.push(make_input(&format!("a{}", i), make_face(0, i), 0));
        }
        for i in 0..5u32 {
            batch_inputs.push(make_input(&format!("b{}", i), make_face(64, i + 100), 0));
        }

        let batch_result = run_pet_clustering(&batch_inputs, &config);
        let centroids = batch_result.cluster_centroids.clone();

        // Create a face that's equidistant from both centroids
        // (halfway between dim 0 and dim 64)
        let mut ambiguous = vec![0.0f32; 128];
        ambiguous[0] = 1.0;
        ambiguous[64] = 1.0;
        let ambiguous = normalized(ambiguous);

        let new_faces = vec![make_input("ambiguous", ambiguous, 0)];

        let result = run_pet_clustering_incremental(&new_faces, &centroids, &config);

        println!(
            "AMBIGUOUS: assigned={:?}, unclustered={}",
            result.face_to_cluster.get("ambiguous"),
            result.n_unclustered
        );

        // Should either be unassigned or in its own new cluster — NOT in A or B
        let cluster_a = batch_result.face_to_cluster.get("a0").unwrap();
        let cluster_b = batch_result.face_to_cluster.get("b0").unwrap();

        if let Some(assigned) = result.face_to_cluster.get("ambiguous") {
            assert_ne!(
                assigned, cluster_a,
                "Ambiguous face should not be forced into cluster A"
            );
            assert_ne!(
                assigned, cluster_b,
                "Ambiguous face should not be forced into cluster B"
            );
        }
    }

    /// Test incremental handles faceless (body-only) inputs.
    #[test]
    fn test_incremental_faceless_stays_unassigned() {
        let config = ClusterConfig::dog();

        // Batch: 2 clusters
        let mut batch_inputs = Vec::new();
        for i in 0..5u32 {
            batch_inputs.push(make_input(&format!("a{}", i), make_face(0, i), 0));
        }
        for i in 0..5u32 {
            batch_inputs.push(make_input(&format!("b{}", i), make_face(64, i + 100), 0));
        }

        let batch_result = run_pet_clustering(&batch_inputs, &config);
        let centroids = batch_result.cluster_centroids.clone();

        // Faceless input — can't match against face centroids
        let new_faces = vec![make_input("no_face", vec![], 0)];

        let result = run_pet_clustering_incremental(&new_faces, &centroids, &config);

        assert_eq!(
            result.n_unclustered, 1,
            "Faceless input should be unclustered in incremental mode"
        );
    }

    /// Exemplar-based incremental: same ONE→TWO→THREE flow but using
    /// multi-exemplar matching instead of centroid matching.
    #[test]
    fn test_incremental_exemplars_one_two_three() {
        let config = ClusterConfig::dog();

        // ── ONE: Batch cluster 10 faces (2 dogs, 5 each) ──
        let mut batch_inputs = Vec::new();
        for i in 0..5u32 {
            batch_inputs.push(make_input(&format!("dogA_{}", i), make_face(0, i), 0));
        }
        for i in 0..5u32 {
            batch_inputs.push(make_input(
                &format!("dogB_{}", i),
                make_face(64, i + 100),
                0,
            ));
        }

        let batch_result = run_pet_clustering(&batch_inputs, &config);

        let ca = batch_result.face_to_cluster.get("dogA_0");
        let cb = batch_result.face_to_cluster.get("dogB_0");
        assert!(ca.is_some());
        assert!(cb.is_some());
        assert_ne!(ca, cb);

        let cluster_a_id = ca.unwrap().clone();
        let cluster_b_id = cb.unwrap().clone();

        // Verify exemplars were computed
        let exemplars = batch_result.cluster_exemplars.clone();
        assert!(
            exemplars.contains_key(&cluster_a_id),
            "ONE: exemplars for cluster A should exist"
        );
        assert!(
            exemplars.contains_key(&cluster_b_id),
            "ONE: exemplars for cluster B should exist"
        );
        assert!(
            exemplars[&cluster_a_id].len() <= config.max_exemplars,
            "ONE: exemplar count should not exceed max_exemplars"
        );

        println!(
            "ONE (exemplars): A has {} exemplars, B has {} exemplars",
            exemplars[&cluster_a_id].len(),
            exemplars[&cluster_b_id].len()
        );

        // ── TWO: 4 new faces, using exemplar matching ──
        let new_faces_two = vec![
            make_input("dogA_new1", make_face(0, 50), 0),
            make_input("dogA_new2", make_face(0, 51), 0),
            make_input("dogB_new1", make_face(64, 150), 0),
            make_input("dogB_new2", make_face(64, 151), 0),
        ];

        let incr_result_two =
            run_pet_clustering_incremental_with_exemplars(&new_faces_two, &exemplars, &config);

        println!(
            "TWO (exemplars): {} assigned, {} unclustered",
            incr_result_two.face_to_cluster.len(),
            incr_result_two.n_unclustered,
        );

        assert_eq!(
            incr_result_two.face_to_cluster.get("dogA_new1"),
            Some(&cluster_a_id),
            "TWO: dogA_new1 should be assigned to cluster A"
        );
        assert_eq!(
            incr_result_two.face_to_cluster.get("dogA_new2"),
            Some(&cluster_a_id),
            "TWO: dogA_new2 should be assigned to cluster A"
        );
        assert_eq!(
            incr_result_two.face_to_cluster.get("dogB_new1"),
            Some(&cluster_b_id),
            "TWO: dogB_new1 should be assigned to cluster B"
        );
        assert_eq!(
            incr_result_two.face_to_cluster.get("dogB_new2"),
            Some(&cluster_b_id),
            "TWO: dogB_new2 should be assigned to cluster B"
        );
        assert_eq!(incr_result_two.n_unclustered, 0);

        // ── THREE: 3 more faces (2 dog A, 1 new dog C) ──
        let new_faces_three = vec![
            make_input("dogA_new3", make_face(0, 52), 0),
            make_input("dogA_new4", make_face(0, 53), 0),
            make_input("dogC_0", make_face(32, 200), 0),
        ];

        let incr_result_three =
            run_pet_clustering_incremental_with_exemplars(&new_faces_three, &exemplars, &config);

        println!(
            "THREE (exemplars): {} assigned, {} unclustered",
            incr_result_three.face_to_cluster.len(),
            incr_result_three.n_unclustered,
        );

        assert_eq!(
            incr_result_three.face_to_cluster.get("dogA_new3"),
            Some(&cluster_a_id),
            "THREE: dogA_new3 should be assigned to cluster A"
        );
        assert_eq!(
            incr_result_three.face_to_cluster.get("dogA_new4"),
            Some(&cluster_a_id),
            "THREE: dogA_new4 should be assigned to cluster A"
        );

        // Dog C should NOT be in cluster A or B
        let cc = incr_result_three.face_to_cluster.get("dogC_0");
        if let Some(cid) = cc {
            assert_ne!(cid, &cluster_a_id);
            assert_ne!(cid, &cluster_b_id);
            println!("THREE (exemplars): dogC_0 created new cluster {}", cid);
        } else {
            println!("THREE (exemplars): dogC_0 stayed unclustered (only 1 face)");
        }
    }

    /// Verify that batch clustering produces exemplars for all clusters.
    #[test]
    fn test_batch_produces_exemplars() {
        let config = ClusterConfig::dog();

        let mut inputs = Vec::new();
        for i in 0..8u32 {
            inputs.push(make_input(&format!("a{}", i), make_face(0, i), 0));
        }
        for i in 0..8u32 {
            inputs.push(make_input(&format!("b{}", i), make_face(64, i + 100), 0));
        }

        let result = run_pet_clustering(&inputs, &config);

        // Every cluster with a centroid should also have exemplars
        for cid in result.cluster_centroids.keys() {
            assert!(
                result.cluster_exemplars.contains_key(cid),
                "Cluster {} should have exemplars",
                cid
            );
            let exs = &result.cluster_exemplars[cid];
            assert!(!exs.is_empty(), "Exemplars should not be empty");
            assert!(
                exs.len() <= config.max_exemplars,
                "Should not exceed max_exemplars"
            );
            // Each exemplar should be 128-d
            for ex in exs {
                assert_eq!(ex.len(), 128);
            }
        }
    }

    #[test]
    fn test_two_stage_batch_merges_microclusters_back_together() {
        let config = ClusterConfig::dog();

        let a_left = normalized({
            let mut v = vec![0.0f32; 128];
            v[0] = 1.0;
            v[1] = 0.65;
            v
        });
        let a_right = normalized({
            let mut v = vec![0.0f32; 128];
            v[0] = 1.0;
            v[2] = 0.65;
            v
        });
        let b_left = normalized({
            let mut v = vec![0.0f32; 128];
            v[64] = 1.0;
            v[65] = 0.65;
            v
        });
        let b_right = normalized({
            let mut v = vec![0.0f32; 128];
            v[64] = 1.0;
            v[66] = 0.65;
            v
        });

        let inputs = vec![
            make_input("a_left_0", a_left.clone(), 0),
            make_input("a_left_1", perturb(&a_left, 3, 0.03), 0),
            make_input("a_right_0", a_right.clone(), 0),
            make_input("a_right_1", perturb(&a_right, 4, 0.03), 0),
            make_input("b_left_0", b_left.clone(), 0),
            make_input("b_left_1", perturb(&b_left, 67, 0.03), 0),
            make_input("b_right_0", b_right.clone(), 0),
            make_input("b_right_1", perturb(&b_right, 68, 0.03), 0),
        ];

        let result = run_pet_clustering(&inputs, &config);

        let a_cluster = result.face_to_cluster.get("a_left_0").unwrap();
        let b_cluster = result.face_to_cluster.get("b_left_0").unwrap();

        assert_eq!(a_cluster, result.face_to_cluster.get("a_right_0").unwrap());
        assert_eq!(a_cluster, result.face_to_cluster.get("a_right_1").unwrap());
        assert_eq!(b_cluster, result.face_to_cluster.get("b_right_0").unwrap());
        assert_eq!(b_cluster, result.face_to_cluster.get("b_right_1").unwrap());
        assert_ne!(a_cluster, b_cluster);
        assert_eq!(result.cluster_counts[a_cluster], 4);
        assert_eq!(result.cluster_counts[b_cluster], 4);
    }
}

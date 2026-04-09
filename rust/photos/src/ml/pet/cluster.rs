//! Pet clustering engine — face-based agglomerative clustering.
//!
//! Clusters pet face embeddings using average-linkage agglomerative
//! clustering with species-specific distance thresholds.
//!
//! All embeddings are assumed L2-normalized (cosine distance = 1 − dot).

use std::collections::HashMap;

use crate::ml::cluster::{
    agglomerative_precomputed_min_size, dot, mean_centroid, renumber_labels, select_exemplars,
    unique_cluster_ids,
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
            agglomerative_threshold: 0.625,
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
}

// ── Input / Output types ────────────────────────────────────────────────

/// One image's data for clustering. Index-aligned across the batch.
#[derive(Clone, Debug)]
pub struct PetClusterInput {
    /// Unique ID for this pet face (from indexing). Used as the key in results.
    pub pet_face_id: String,
    /// L2-normalized face embedding (128-d). Empty vec if no face.
    pub face_embedding: Vec<f32>,
    /// 0 = dog, 1 = cat.
    pub species: u8,
    /// File ID that this detection belongs to.
    pub file_id: i64,
}

impl PetClusterInput {
    pub fn has_face(&self) -> bool {
        !self.face_embedding.is_empty()
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
            let sim = dot(&inp.face_embedding, centroid);
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

        for (cluster_id, exemplars) in existing_exemplars {
            // Best similarity to ANY exemplar in this cluster
            let cluster_sim = exemplars
                .iter()
                .map(|ex| dot(&inp.face_embedding, ex))
                .fold(f32::NEG_INFINITY, f32::max);

            if cluster_sim > best_sim {
                second_best_sim = best_sim;
                best_sim = cluster_sim;
                best_id = Some(cluster_id);
            } else if cluster_sim > second_best_sim {
                second_best_sim = cluster_sim;
            }
        }

        // Assign if:
        // 1. Similarity to best exemplar exceeds threshold
        // 2. Clear winner (margin > 0.05) to avoid ambiguous assignments
        let has_clear_winner = existing_exemplars.len() <= 1 || (best_sim - second_best_sim) > 0.05;

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
    let face_labels = agglomerative_precomputed_min_size(
        &dist,
        nf,
        config.agglomerative_threshold,
        config.min_cluster_size,
    );

    // Map back to global indices
    for (local, &global) in face_indices.iter().enumerate() {
        labels[global] = face_labels[local];
    }

    labels
}

// Helper functions (dot, l2_norm, normalize, mean_centroid) imported
// from crate::ml::cluster

// unique_cluster_ids and renumber_labels imported from crate::ml::cluster

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
}

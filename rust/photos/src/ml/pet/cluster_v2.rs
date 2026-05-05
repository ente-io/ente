//! Pet clustering V2.
//!
//! This module keeps the current production-facing types from `cluster.rs`,
//! but implements a new two-pass clustering strategy inspired by the Apple
//! Photos writeup:
//!
//! 1. A conservative greedy first pass builds small micro-clusters by
//!    querying `VectorDB` for nearby candidates and assigning by nearest
//!    already-seen neighbor cluster.
//! 2. A second pass uses face-only exemplar HAC to merge those micro-clusters
//!    across broader boundaries.
//!
//! This module intentionally exposes only the direct-`VectorDB` flow for the
//! first pass. It is optimized for face embeddings only.

use std::collections::HashMap;
use std::time::{Duration, Instant};

use crate::ml::pet::cluster::{
    ClusterConfig, PetClusterIndexInput, PetClusterResult, renumber_labels, select_exemplars,
    simsimd_cosine_distance, unique_cluster_ids,
};
use crate::vector_db::VectorDB;

/// Run V2 clustering while using `VectorDB` directly in the first pass to
/// fetch candidate neighbors for each observation.
pub fn run_pet_clustering_from_vdb_v2(
    inputs: &[PetClusterIndexInput],
    vdb: &VectorDB,
    config: &ClusterConfig,
) -> Result<PetClusterResult, String> {
    run_pet_clustering_from_vdb_v2_with_stats(inputs, vdb, config).map(|(result, _)| result)
}

#[derive(Clone, Copy, Debug, Default)]
#[cfg_attr(not(test), allow(dead_code))]
struct V2TimingStats {
    first_pass: Duration,
    second_pass: Duration,
}

fn run_pet_clustering_from_vdb_v2_with_stats(
    inputs: &[PetClusterIndexInput],
    vdb: &VectorDB,
    config: &ClusterConfig,
) -> Result<(PetClusterResult, V2TimingStats), String> {
    if inputs.is_empty() {
        return Ok((PetClusterResult::default(), V2TimingStats::default()));
    }

    let mut key_to_position = HashMap::with_capacity(inputs.len());
    for (idx, input) in inputs.iter().enumerate() {
        key_to_position.insert(input.vector_id, idx);
    }

    let mut vector_cache: HashMap<u64, Vec<f32>> = HashMap::with_capacity(inputs.len());
    let mut materialized_inputs = Vec::with_capacity(inputs.len());
    let mut clusters: Vec<GreedyMicroCluster> = Vec::new();
    let mut assigned_cluster: Vec<Option<usize>> = vec![None; inputs.len()];

    let first_pass_start = Instant::now();
    for (idx, input) in inputs.iter().enumerate() {
        let face_embedding = get_cached_vector(vdb, input.vector_id, &mut vector_cache)?;
        let observation = FaceObservation {
            pet_face_id: input.pet_face_id.clone(),
            face_embedding,
        };
        materialized_inputs.push(observation.clone());

        let (neighbor_keys, neighbor_distances) =
            vdb.search_vectors(&observation.face_embedding, 10, false)?;

        let mut candidate_clusters: Vec<(usize, f32)> = Vec::new();
        for (key, distance) in neighbor_keys
            .into_iter()
            .zip(neighbor_distances.into_iter())
        {
            if key == input.vector_id {
                continue;
            }
            if !distance.is_finite() || distance > greedy_face_threshold(config) {
                continue;
            }
            let Some(&neighbor_idx) = key_to_position.get(&key) else {
                continue;
            };
            if neighbor_idx >= idx {
                continue;
            }
            if let Some(cluster_idx) = assigned_cluster[neighbor_idx] {
                if let Some((_, best_dist)) = candidate_clusters
                    .iter_mut()
                    .find(|(existing_cluster, _)| *existing_cluster == cluster_idx)
                {
                    *best_dist = best_dist.min(distance);
                } else {
                    candidate_clusters.push((cluster_idx, distance));
                }
            }
        }

        let cluster_idx = assign_to_greedy_cluster(idx, &candidate_clusters, &mut clusters, config);
        assigned_cluster[idx] = Some(cluster_idx);
    }
    let first_pass_time = first_pass_start.elapsed();

    let second_pass_start = Instant::now();
    exemplar_hac_merge_v2(&mut clusters, &materialized_inputs, config);
    let second_pass_time = second_pass_start.elapsed();

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
    Ok((
        build_result_v2(&materialized_inputs, &labels, &has_face, config),
        V2TimingStats {
            first_pass: first_pass_time,
            second_pass: second_pass_time,
        },
    ))
}

fn assign_to_greedy_cluster(
    idx: usize,
    candidate_clusters: &[(usize, f32)],
    clusters: &mut Vec<GreedyMicroCluster>,
    config: &ClusterConfig,
) -> usize {
    let mut best_idx = None;
    let mut best_dist = f32::INFINITY;
    let mut second_best_dist = f32::INFINITY;

    for &(cluster_idx, dist) in candidate_clusters {
        if dist < best_dist {
            second_best_dist = best_dist;
            best_dist = dist;
            best_idx = Some(cluster_idx);
        } else if dist < second_best_dist {
            second_best_dist = dist;
        }
    }

    let has_clear_winner = candidate_clusters.len() <= 1
        || (second_best_dist - best_dist) > cluster_assignment_margin(config);
    if best_dist.is_finite()
        && best_dist <= greedy_face_threshold(config)
        && has_clear_winner
        && let Some(cluster_idx) = best_idx
    {
        clusters[cluster_idx].add_member(idx, config.max_exemplars);
        cluster_idx
    } else {
        let cluster_idx = clusters.len();
        clusters.push(GreedyMicroCluster::new(idx, config.max_exemplars));
        cluster_idx
    }
}

fn exemplar_hac_merge_v2(
    clusters: &mut Vec<GreedyMicroCluster>,
    inputs: &[FaceObservation],
    config: &ClusterConfig,
) {
    loop {
        let mut best_pair = None;
        let mut best_dist = f32::INFINITY;

        for left in 0..clusters.len() {
            for right in (left + 1)..clusters.len() {
                let dist = exemplar_cluster_distance_v2(&clusters[left], &clusters[right], inputs);
                if dist < best_dist {
                    best_dist = dist;
                    best_pair = Some((left, right));
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
        clusters[left].merge(other, config.max_exemplars);
    }
}

fn exemplar_cluster_distance_v2(
    left: &GreedyMicroCluster,
    right: &GreedyMicroCluster,
    inputs: &[FaceObservation],
) -> f32 {
    if left.exemplar_member_indices.is_empty() || right.exemplar_member_indices.is_empty() {
        return f32::INFINITY;
    }

    let mut distances = Vec::with_capacity(
        left.exemplar_member_indices.len() * right.exemplar_member_indices.len(),
    );
    for &li in &left.exemplar_member_indices {
        for &ri in &right.exemplar_member_indices {
            distances.push(face_distance_v2(
                &inputs[li].face_embedding,
                &inputs[ri].face_embedding,
            ));
        }
    }
    if distances.is_empty() {
        return f32::INFINITY;
    }

    distances.sort_by(|a, b| a.total_cmp(b));
    if distances.len() == 1 {
        distances[0]
    } else {
        (distances[0] + distances[1]) / 2.0
    }
}

fn face_distance_v2(left: &[f32], right: &[f32]) -> f32 {
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

fn build_result_v2(
    inputs: &[FaceObservation],
    labels: &[i32],
    has_face: &[bool],
    config: &ClusterConfig,
) -> PetClusterResult {
    let mut result = PetClusterResult::default();

    let unique = unique_cluster_ids(labels);
    let cluster_id_map: HashMap<i32, String> = unique
        .iter()
        .map(|&cluster| {
            let first_member = labels
                .iter()
                .enumerate()
                .find(|(_, label)| **label == cluster)
                .map(|(idx, _)| idx)
                .unwrap();
            let cluster_id = format!("pet_cluster_{}", inputs[first_member].pet_face_id);
            (cluster, cluster_id)
        })
        .collect();

    for (idx, input) in inputs.iter().enumerate() {
        if labels[idx] >= 0 {
            if let Some(cluster_id) = cluster_id_map.get(&labels[idx]) {
                result
                    .face_to_cluster
                    .insert(input.pet_face_id.clone(), cluster_id.clone());
                *result.cluster_counts.entry(cluster_id.clone()).or_insert(0) += 1;
            }
        } else {
            result.n_unclustered += 1;
        }
    }

    let face_dim = inputs
        .iter()
        .find(|input| !input.face_embedding.is_empty())
        .map(|input| input.face_embedding.len())
        .unwrap_or(128);

    for (&cluster_label, cluster_id) in &cluster_id_map {
        let face_embs: Vec<&Vec<f32>> = labels
            .iter()
            .enumerate()
            .filter(|(idx, label)| **label == cluster_label && has_face[*idx])
            .map(|(idx, _)| &inputs[idx].face_embedding)
            .collect();
        if !face_embs.is_empty() {
            result.cluster_exemplars.insert(
                cluster_id.clone(),
                select_exemplars(&face_embs, config.max_exemplars, face_dim),
            );
        }
    }

    result
}

#[derive(Clone)]
struct FaceObservation {
    pet_face_id: String,
    face_embedding: Vec<f32>,
}

struct GreedyMicroCluster {
    members: Vec<usize>,
    exemplar_member_indices: Vec<usize>,
}

impl GreedyMicroCluster {
    fn new(first_idx: usize, max_exemplars: usize) -> Self {
        let members = vec![first_idx];
        Self {
            exemplar_member_indices: deterministic_exemplar_sample(&members, max_exemplars),
            members,
        }
    }

    fn add_member(&mut self, idx: usize, max_exemplars: usize) {
        self.members.push(idx);
        self.refresh_exemplars(max_exemplars);
    }

    fn merge(&mut self, other: Self, max_exemplars: usize) {
        self.members.extend(other.members);
        self.refresh_exemplars(max_exemplars);
    }

    fn refresh_exemplars(&mut self, max_exemplars: usize) {
        self.exemplar_member_indices = deterministic_exemplar_sample(&self.members, max_exemplars);
    }
}

fn deterministic_exemplar_sample(members: &[usize], max_exemplars: usize) -> Vec<usize> {
    if max_exemplars == 0 || members.is_empty() {
        return Vec::new();
    }
    if members.len() <= max_exemplars {
        let mut all_members = members.to_vec();
        all_members.sort_unstable();
        return all_members;
    }

    let mut sample = members.to_vec();
    let mut state = exemplar_seed(members);
    for i in 0..max_exemplars {
        let remaining = sample.len() - i;
        let swap_idx = i + ((next_prng_u64(&mut state) as usize) % remaining);
        sample.swap(i, swap_idx);
    }
    sample.truncate(max_exemplars);
    sample.sort_unstable();
    sample
}

fn exemplar_seed(members: &[usize]) -> u64 {
    let mut sorted = members.to_vec();
    sorted.sort_unstable();
    let mut state = 0x9E37_79B9_7F4A_7C15u64;
    for &member in &sorted {
        let mixed = (member as u64).wrapping_add(0x517C_C1B7_2722_0A95u64);
        state ^= mixed
            .wrapping_add(0x9E37_79B9_7F4A_7C15u64)
            .wrapping_add(state << 6)
            .wrapping_add(state >> 2);
    }
    state
}

fn next_prng_u64(state: &mut u64) -> u64 {
    *state = state
        .wrapping_mul(6364136223846793005)
        .wrapping_add(1442695040888963407);
    *state
}

fn greedy_face_threshold(config: &ClusterConfig) -> f32 {
    match config.species {
        crate::ml::pet::cluster::Species::Dog => 0.32,
        crate::ml::pet::cluster::Species::Cat => 0.52,
    }
}

fn cluster_assignment_margin(_config: &ClusterConfig) -> f32 {
    0.03
}

#[cfg(test)]
mod tests {
    use std::time::Instant;

    use tempfile::tempdir;

    use super::*;
    use crate::ml::pet::cluster::{self, Species};

    fn normalize(values: &[f32]) -> Vec<f32> {
        let norm = values.iter().map(|value| value * value).sum::<f32>().sqrt();
        values.iter().map(|value| value / norm).collect()
    }

    fn test_config() -> ClusterConfig {
        ClusterConfig::for_species(Species::Dog)
    }

    fn build_test_vdb(
        vectors: Vec<Vec<f32>>,
        species: Species,
    ) -> (tempfile::TempDir, VectorDB, Vec<PetClusterIndexInput>) {
        let dir = tempdir().expect("tempdir");
        let index_path = dir.path().join("pet_faces.usearch");
        let index_path = index_path.to_str().expect("index path").to_string();
        let mut vdb = VectorDB::new(&index_path, vectors[0].len()).expect("vector db");
        let keys: Vec<u64> = (0..vectors.len()).map(|idx| idx as u64 + 1).collect();
        vdb.bulk_add_vectors(keys.clone(), &vectors)
            .expect("bulk add vectors");
        let inputs = keys
            .into_iter()
            .enumerate()
            .map(|(idx, key)| PetClusterIndexInput {
                pet_face_id: format!("pet_face_{idx}"),
                vector_id: key,
                species: species as u8,
                file_id: idx as i64,
            })
            .collect();
        (dir, vdb, inputs)
    }

    fn face(id: usize, embedding: Vec<f32>) -> FaceObservation {
        FaceObservation {
            pet_face_id: format!("face_{id}"),
            face_embedding: embedding,
        }
    }

    fn synthetic_embeddings(
        clusters: usize,
        members_per_cluster: usize,
        dimensions: usize,
    ) -> Vec<Vec<f32>> {
        let mut vectors = Vec::with_capacity(clusters * members_per_cluster);
        for cluster_idx in 0..clusters {
            let mut base = vec![0.0; dimensions];
            base[cluster_idx % dimensions] = 1.0;
            if dimensions > 1 {
                base[(cluster_idx * 7 + 3) % dimensions] = 0.25;
            }
            let base = normalize(&base);
            for member_idx in 0..members_per_cluster {
                let mut sample = base.clone();
                let mut state = exemplar_seed(&[cluster_idx, member_idx, dimensions]);
                for value in &mut sample {
                    let noise =
                        ((next_prng_u64(&mut state) >> 40) as f32 / (1u32 << 24) as f32) - 0.5;
                    *value += noise * 0.02;
                }
                vectors.push(normalize(&sample));
            }
        }
        vectors
    }

    #[test]
    fn nearest_neighbor_first_pass_clusters_obvious_same_dog_faces() {
        let vectors = vec![
            normalize(&[1.0, 0.0, 0.0, 0.0]),
            normalize(&[0.0, 1.0, 0.0, 0.0]),
            normalize(&[0.99, 0.04, 0.0, 0.0]),
            normalize(&[0.02, 0.99, 0.0, 0.0]),
        ];
        let (_dir, vdb, inputs) = build_test_vdb(vectors, Species::Dog);

        let (result, _stats) =
            run_pet_clustering_from_vdb_v2_with_stats(&inputs, &vdb, &test_config())
                .expect("v2 clustering");

        assert_eq!(result.n_unclustered, 0);
        assert_eq!(result.cluster_counts.len(), 2);
        assert_eq!(
            result.face_to_cluster["pet_face_0"],
            result.face_to_cluster["pet_face_2"]
        );
        assert_eq!(
            result.face_to_cluster["pet_face_1"],
            result.face_to_cluster["pet_face_3"]
        );
        assert_ne!(
            result.face_to_cluster["pet_face_0"],
            result.face_to_cluster["pet_face_1"]
        );
    }

    #[test]
    fn ambiguous_nearest_neighbor_margin_stays_split() {
        let config = test_config();
        let mut clusters = vec![
            GreedyMicroCluster::new(0, config.max_exemplars),
            GreedyMicroCluster::new(1, config.max_exemplars),
        ];

        let assigned = assign_to_greedy_cluster(2, &[(0, 0.10), (1, 0.09)], &mut clusters, &config);

        assert_eq!(assigned, 2);
        assert_eq!(clusters.len(), 3);
        assert_eq!(clusters[2].members, vec![2]);
    }

    #[test]
    fn second_pass_merges_split_same_dog_micro_clusters() {
        let config = test_config();
        let inputs = vec![
            face(0, normalize(&[1.0, 0.0, 0.0])),
            face(1, normalize(&[0.99, 0.03, 0.0])),
            face(2, normalize(&[0.98, 0.05, 0.0])),
            face(3, normalize(&[0.97, 0.07, 0.0])),
        ];
        let mut clusters = vec![
            GreedyMicroCluster::new(0, config.max_exemplars),
            GreedyMicroCluster::new(2, config.max_exemplars),
        ];
        clusters[0].add_member(1, config.max_exemplars);
        clusters[1].add_member(3, config.max_exemplars);

        exemplar_hac_merge_v2(&mut clusters, &inputs, &config);

        assert_eq!(clusters.len(), 1);
        assert_eq!(clusters[0].members.len(), 4);
    }

    #[test]
    fn second_pass_rejects_different_dogs_when_only_one_pair_is_close() {
        let config = test_config();
        let inputs = vec![
            face(0, normalize(&[1.0, 0.0, 0.0])),
            face(1, normalize(&[1.0, 0.0, 0.0])),
            face(2, normalize(&[0.0, 1.0, 0.0])),
        ];
        let mut clusters = vec![
            GreedyMicroCluster::new(0, config.max_exemplars),
            GreedyMicroCluster::new(1, config.max_exemplars),
        ];
        clusters[1].add_member(2, config.max_exemplars);

        let pair_score = exemplar_cluster_distance_v2(&clusters[0], &clusters[1], &inputs);
        exemplar_hac_merge_v2(&mut clusters, &inputs, &config);

        assert!(pair_score > config.agglomerative_threshold);
        assert_eq!(clusters.len(), 2);
    }

    #[test]
    fn deterministic_exemplar_sampling_is_stable() {
        let members = vec![9, 2, 7, 5, 1, 4, 3];

        let first = deterministic_exemplar_sample(&members, 5);
        let second = deterministic_exemplar_sample(&members, 5);

        assert_eq!(first, second);
        assert_eq!(first.len(), 5);
    }

    #[test]
    fn build_result_v2_returns_exemplars_without_centroids() {
        let config = test_config();
        let inputs = vec![
            face(0, normalize(&[1.0, 0.0, 0.0])),
            face(1, normalize(&[0.99, 0.03, 0.0])),
            face(2, normalize(&[0.0, 1.0, 0.0])),
            face(3, normalize(&[0.02, 0.99, 0.0])),
        ];
        let labels = vec![0, 0, 1, 1];
        let has_face = vec![true; inputs.len()];

        let result = build_result_v2(&inputs, &labels, &has_face, &config);

        assert!(result.cluster_centroids.is_empty());
        assert_eq!(result.cluster_counts.len(), 2);
        assert_eq!(result.cluster_exemplars.len(), 2);
        assert_eq!(result.face_to_cluster.len(), 4);
    }

    #[test]
    #[ignore]
    fn benchmark_v2_against_current_app_path_on_seeded_synthetic_embeddings() {
        let config = test_config();
        let vectors = synthetic_embeddings(20, 50, 128);
        let (_dir, vdb, inputs) = build_test_vdb(vectors, Species::Dog);

        let baseline_start = Instant::now();
        let baseline =
            cluster::run_pet_clustering_from_vdb(&inputs, &vdb, &config).expect("baseline");
        let baseline_total = baseline_start.elapsed();

        let (v2, stats) =
            run_pet_clustering_from_vdb_v2_with_stats(&inputs, &vdb, &config).expect("v2");
        let v2_total = stats.first_pass + stats.second_pass;

        println!(
            "baseline_total_ms={} baseline_assigned={} baseline_unclustered={} v2_first_pass_ms={} v2_second_pass_ms={} v2_total_ms={} v2_assigned={} v2_unclustered={}",
            baseline_total.as_millis(),
            baseline.face_to_cluster.len(),
            baseline.n_unclustered,
            stats.first_pass.as_millis(),
            stats.second_pass.as_millis(),
            v2_total.as_millis(),
            v2.face_to_cluster.len(),
            v2.n_unclustered,
        );
    }
}

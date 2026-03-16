//! Shared clustering algorithms for face and pet pipelines.
//!
//! Contains agglomerative clustering (average linkage) and helper functions
//! used by both human face and pet clustering.

use std::collections::HashMap;

// ── Agglomerative clustering (average linkage, precomputed) ─────────────

/// Hierarchical agglomerative clustering with average linkage on a
/// precomputed distance matrix. Cuts the dendrogram at `threshold`.
///
/// Mirrors Python's `sklearn.cluster.AgglomerativeClustering(
///     metric="precomputed", linkage="average", distance_threshold=threshold)`.
pub fn agglomerative_precomputed(dist: &[f32], n: usize, threshold: f32) -> Vec<i32> {
    if n == 0 {
        return vec![];
    }
    if n == 1 {
        return vec![0];
    }

    let mut clusters: Vec<Option<Vec<usize>>> = (0..n).map(|i| Some(vec![i])).collect();
    let mut active: Vec<usize> = (0..n).collect();

    let mut cdist: Vec<f32> = dist.to_vec();
    let cap = n;

    loop {
        if active.len() < 2 {
            break;
        }

        let mut best_d = f32::INFINITY;
        let mut best_i = 0;
        let mut best_j = 0;
        for ai in 0..active.len() {
            for aj in (ai + 1)..active.len() {
                let ci = active[ai];
                let cj = active[aj];
                let d = cdist[ci * cap + cj];
                if d < best_d {
                    best_d = d;
                    best_i = ai;
                    best_j = aj;
                }
            }
        }

        if best_d > threshold {
            break;
        }

        let ci = active[best_i];
        let cj = active[best_j];

        let size_i = clusters[ci].as_ref().unwrap().len();
        let size_j = clusters[cj].as_ref().unwrap().len();
        let merged_size = size_i + size_j;

        // Average-linkage update: d(i∪j, k) = (size_i*d(i,k) + size_j*d(j,k)) / merged
        for &ck in &active {
            if ck == ci || ck == cj {
                continue;
            }
            let d_ik = cdist[ci.min(ck) * cap + ci.max(ck)];
            let d_jk = cdist[cj.min(ck) * cap + cj.max(ck)];
            let new_d = (size_i as f32 * d_ik + size_j as f32 * d_jk) / merged_size as f32;
            let (lo, hi) = (ci.min(ck), ci.max(ck));
            cdist[lo * cap + hi] = new_d;
            cdist[hi * cap + lo] = new_d;
        }

        let cj_members = clusters[cj].take().unwrap();
        clusters[ci].as_mut().unwrap().extend(cj_members);

        active.remove(best_j);
    }

    let mut labels = vec![-1i32; n];
    let mut next_label = 0i32;
    for &ci in &active {
        if let Some(members) = &clusters[ci] {
            for &m in members {
                labels[m] = next_label;
            }
            next_label += 1;
        }
    }

    labels
}

// ── Helper functions ────────────────────────────────────────────────────

pub fn dot(a: &[f32], b: &[f32]) -> f32 {
    a.iter().zip(b.iter()).map(|(x, y)| x * y).sum()
}

pub fn l2_norm(v: &[f32]) -> f32 {
    dot(v, v).sqrt()
}

pub fn normalize(v: &mut [f32]) {
    let n = l2_norm(v);
    if n > 1e-8 {
        for x in v.iter_mut() {
            *x /= n;
        }
    }
}

/// Compute L2-normalized median centroid from a list of embeddings.
pub fn median_centroid(embs: &[&Vec<f32>], dim: usize) -> Vec<f32> {
    if embs.is_empty() {
        return vec![0.0; dim];
    }
    let mut centroid = vec![0.0f32; dim];
    for d in 0..dim {
        let mut vals: Vec<f32> = embs.iter().map(|e| e[d]).collect();
        vals.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));
        let mid = vals.len() / 2;
        centroid[d] = if vals.len().is_multiple_of(2) {
            (vals[mid - 1] + vals[mid]) / 2.0
        } else {
            vals[mid]
        };
    }
    normalize(&mut centroid);
    centroid
}

/// Compute L2-normalized mean centroid from a list of embeddings.
pub fn mean_centroid(embs: &[&Vec<f32>], dim: usize) -> Vec<f32> {
    if embs.is_empty() {
        return vec![0.0; dim];
    }
    let mut centroid = vec![0.0f32; dim];
    for emb in embs {
        for (i, &v) in emb.iter().enumerate() {
            if i < dim {
                centroid[i] += v;
            }
        }
    }
    let count = embs.len() as f32;
    for v in centroid.iter_mut() {
        *v /= count;
    }
    normalize(&mut centroid);
    centroid
}

pub fn unique_cluster_ids(labels: &[i32]) -> Vec<i32> {
    let mut ids: Vec<i32> = labels
        .iter()
        .copied()
        .filter(|&l| l >= 0)
        .collect::<std::collections::HashSet<_>>()
        .into_iter()
        .collect();
    ids.sort();
    ids
}

pub fn renumber_labels(labels: &mut [i32]) {
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

// ── Human face clustering ───────────────────────────────────────────────

/// Maximum faces for the n² distance matrix (~100MB at 5000).
const MAX_FACES_FOR_MATRIX: usize = 5000;

/// Input for human face clustering.
#[derive(Clone, Debug)]
pub struct FaceClusterInput {
    pub face_id: String,
    pub embedding: Vec<f32>,
    pub existing_cluster_id: String,
    pub rejected_cluster_ids: Vec<String>,
}

/// Result of human face clustering.
#[derive(Clone, Debug, Default)]
pub struct FaceClusterResult {
    pub face_to_cluster: HashMap<String, String>,
    pub cluster_centroids: HashMap<String, Vec<f32>>,
    pub cluster_counts: HashMap<String, usize>,
    pub n_unclustered: usize,
}

/// Run batch agglomerative clustering on human face embeddings.
///
/// Returns None if the input exceeds the memory guard (caller should
/// fall back to a different algorithm).
pub fn run_face_clustering(
    inputs: &[FaceClusterInput],
    threshold: f32,
) -> Option<FaceClusterResult> {
    let n = inputs.len();
    if n == 0 {
        return Some(FaceClusterResult::default());
    }

    // Separate already-clustered from new faces
    let mut clustered_indices: Vec<usize> = Vec::new();
    let mut new_indices: Vec<usize> = Vec::new();
    for (i, inp) in inputs.iter().enumerate() {
        if inp.existing_cluster_id.is_empty() {
            new_indices.push(i);
        } else {
            clustered_indices.push(i);
        }
    }

    // Only new (unclustered) faces go through agglomerative
    let unclustered_count = new_indices.len();
    if unclustered_count == 0 {
        // Everything is already clustered — just return existing assignments
        let mut result = FaceClusterResult::default();
        for i in &clustered_indices {
            result.face_to_cluster.insert(
                inputs[*i].face_id.clone(),
                inputs[*i].existing_cluster_id.clone(),
            );
        }
        return Some(result);
    }

    // All faces (clustered + unclustered) participate in distance computation
    // so new faces can be assigned to existing clusters
    let all_count = n;
    if all_count > MAX_FACES_FOR_MATRIX {
        return None; // Too large, let Dart handle it
    }

    // Build pairwise cosine distance matrix
    let mut dist = vec![0.0f32; all_count * all_count];
    for i in 0..all_count {
        for j in (i + 1)..all_count {
            let sim = dot(&inputs[i].embedding, &inputs[j].embedding);
            let d = (1.0 - sim).clamp(0.0, 2.0);
            dist[i * all_count + j] = d;
            dist[j * all_count + i] = d;
        }
    }

    // Run agglomerative on all faces
    let mut labels = agglomerative_precomputed(&dist, all_count, threshold);

    // Renumber to contiguous labels
    renumber_labels(&mut labels);

    // Apply rejected cluster constraints: if a face is assigned to a cluster
    // that contains faces whose cluster_id is in the face's rejected list,
    // eject it to a singleton.
    let mut next_label = labels.iter().copied().max().unwrap_or(-1) + 1;

    // Build label → existing cluster_id mapping (from already-clustered faces)
    let mut label_to_existing: HashMap<i32, String> = HashMap::new();
    for &i in &clustered_indices {
        if labels[i] >= 0 {
            label_to_existing
                .entry(labels[i])
                .or_insert_with(|| inputs[i].existing_cluster_id.clone());
        }
    }

    // Check rejections
    for &i in &new_indices {
        if labels[i] < 0 || inputs[i].rejected_cluster_ids.is_empty() {
            continue;
        }
        if let Some(existing_id) = label_to_existing.get(&labels[i])
            && inputs[i].rejected_cluster_ids.contains(existing_id)
        {
            labels[i] = next_label;
            next_label += 1;
        }
    }

    // Build result
    let unique = unique_cluster_ids(&labels);
    let dim = inputs
        .first()
        .map(|i| i.embedding.len())
        .unwrap_or(128);

    // Map numeric labels to string cluster IDs
    let mut label_to_cluster_id: HashMap<i32, String> = HashMap::new();

    // First, map labels that contain already-clustered faces to their existing IDs
    for &i in &clustered_indices {
        if labels[i] >= 0 {
            label_to_cluster_id
                .entry(labels[i])
                .or_insert_with(|| inputs[i].existing_cluster_id.clone());
        }
    }

    // Then, assign new cluster IDs for labels without existing IDs,
    // using the first member's face_id for collision resistance.
    for &c in &unique {
        label_to_cluster_id.entry(c).or_insert_with(|| {
            let first_member = inputs
                .iter()
                .enumerate()
                .find(|(i, _)| labels[*i] == c)
                .map(|(_, inp)| inp.face_id.as_str())
                .unwrap_or("unknown");
            format!("cluster_{first_member}")
        });
    }

    let mut result = FaceClusterResult::default();

    for (i, inp) in inputs.iter().enumerate() {
        if labels[i] >= 0 {
            if let Some(cluster_id) = label_to_cluster_id.get(&labels[i]) {
                result
                    .face_to_cluster
                    .insert(inp.face_id.clone(), cluster_id.clone());
                *result.cluster_counts.entry(cluster_id.clone()).or_insert(0) += 1;
            }
        } else {
            result.n_unclustered += 1;
        }
    }

    // Compute centroids (mean, L2-normalized)
    for (&numeric, cluster_id) in &label_to_cluster_id {
        let embs: Vec<&Vec<f32>> = labels
            .iter()
            .enumerate()
            .filter(|(_, l)| **l == numeric)
            .map(|(i, _)| &inputs[i].embedding)
            .collect();
        if !embs.is_empty() {
            result
                .cluster_centroids
                .insert(cluster_id.clone(), mean_centroid(&embs, dim));
        }
    }

    Some(result)
}

/// Run incremental face clustering: assign new faces to existing clusters,
/// then cluster the remainder among themselves.
pub fn run_face_clustering_incremental(
    new_inputs: &[FaceClusterInput],
    existing_centroids: &HashMap<String, Vec<f32>>,
    existing_counts: &HashMap<String, usize>,
    threshold: f32,
) -> Option<FaceClusterResult> {
    let n = new_inputs.len();
    if n == 0 {
        return Some(FaceClusterResult::default());
    }

    let mut result = FaceClusterResult::default();
    let mut unassigned: Vec<usize> = Vec::new();

    // Step 1: Pin faces that already have a cluster assignment, then try
    // to assign genuinely new faces to the closest existing centroid.
    for (i, inp) in new_inputs.iter().enumerate() {
        // Preserve existing assignments from prior clustering runs.
        if !inp.existing_cluster_id.is_empty() {
            result
                .face_to_cluster
                .insert(inp.face_id.clone(), inp.existing_cluster_id.clone());
            *result
                .cluster_counts
                .entry(inp.existing_cluster_id.clone())
                .or_insert(0) += 1;
            continue;
        }

        let mut best_sim = -1.0f32;
        let mut best_id: Option<&String> = None;

        for (cluster_id, centroid) in existing_centroids {
            // Skip rejected clusters
            if inp.rejected_cluster_ids.contains(cluster_id) {
                continue;
            }
            let sim = dot(&inp.embedding, centroid);
            if sim > best_sim {
                best_sim = sim;
                best_id = Some(cluster_id);
            }
        }

        let dist = 1.0 - best_sim;
        if dist < threshold {
            if let Some(cid) = best_id {
                result
                    .face_to_cluster
                    .insert(inp.face_id.clone(), cid.clone());
                *result.cluster_counts.entry(cid.clone()).or_insert(0) += 1;
            }
        } else {
            unassigned.push(i);
        }
    }

    // Step 2: Cluster unassigned among themselves
    if unassigned.len() >= 2 && unassigned.len() <= MAX_FACES_FOR_MATRIX {
        let sub_inputs: Vec<FaceClusterInput> = unassigned
            .iter()
            .map(|&i| {
                let mut inp = new_inputs[i].clone();
                inp.existing_cluster_id = String::new();
                inp
            })
            .collect();

        if let Some(sub_result) = run_face_clustering(&sub_inputs, threshold) {
            for (face_id, cluster_id) in sub_result.face_to_cluster {
                result.face_to_cluster.insert(face_id, cluster_id.clone());
                *result.cluster_counts.entry(cluster_id).or_insert(0) += 1;
            }
            for (cluster_id, centroid) in sub_result.cluster_centroids {
                result.cluster_centroids.insert(cluster_id, centroid);
            }
        }
    } else if unassigned.len() == 1 {
        // Single unassigned face gets its own cluster
        let inp = &new_inputs[unassigned[0]];
        let cid = format!("cluster_{}", &inp.face_id);
        result.face_to_cluster.insert(inp.face_id.clone(), cid.clone());
        result.cluster_centroids.insert(cid.clone(), inp.embedding.clone());
        result.cluster_counts.insert(cid, 1);
    } else {
        result.n_unclustered = unassigned.len();
    }

    // Step 3: Compute centroids for all clusters. For clusters that already
    // have a historical centroid+count, merge via weighted average so that
    // bucketed callers don't overwrite prior state with partial-bucket data.
    let dim = new_inputs
        .first()
        .map(|i| i.embedding.len())
        .unwrap_or(128);
    let all_cluster_ids: Vec<String> = result.cluster_counts.keys().cloned().collect();
    for cluster_id in &all_cluster_ids {
        let embs: Vec<&Vec<f32>> = new_inputs
            .iter()
            .filter(|inp| {
                result
                    .face_to_cluster
                    .get(&inp.face_id)
                    .map(|c| c == cluster_id)
                    .unwrap_or(false)
            })
            .map(|inp| &inp.embedding)
            .collect();
        if embs.is_empty() {
            continue;
        }
        let new_centroid = mean_centroid(&embs, dim);
        let new_count = embs.len();

        let merged = if let Some(old_centroid) = existing_centroids.get(cluster_id) {
            let old_count = existing_counts.get(cluster_id).copied().unwrap_or(0);
            if old_count > 0 && old_centroid.len() == dim {
                // Weighted average of old centroid and new members
                let total = (old_count + new_count) as f32;
                let mut merged = vec![0.0f32; dim];
                for i in 0..dim {
                    merged[i] =
                        (old_centroid[i] * old_count as f32 + new_centroid[i] * new_count as f32)
                            / total;
                }
                normalize(&mut merged);
                merged
            } else {
                new_centroid
            }
        } else {
            new_centroid
        };

        result.cluster_centroids.insert(cluster_id.clone(), merged);
    }

    Some(result)
}

#[cfg(test)]
mod tests {
    use super::*;

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
    fn test_agglomerative_empty() {
        let labels = agglomerative_precomputed(&[], 0, 0.5);
        assert!(labels.is_empty());
    }

    #[test]
    fn test_agglomerative_single() {
        let labels = agglomerative_precomputed(&[0.0], 1, 0.5);
        assert_eq!(labels, vec![0]);
    }

    #[test]
    fn test_face_clustering_two_similar() {
        let a = normalized(vec![1.0; 128]);
        let mut b = a.clone();
        b[0] += 0.01;
        let b = normalized(b);

        let inputs = vec![
            FaceClusterInput {
                face_id: "a".to_string(),
                embedding: a,
                existing_cluster_id: String::new(),
                rejected_cluster_ids: vec![],
            },
            FaceClusterInput {
                face_id: "b".to_string(),
                embedding: b,
                existing_cluster_id: String::new(),
                rejected_cluster_ids: vec![],
            },
        ];

        let result = run_face_clustering(&inputs, 0.24).unwrap();
        assert_eq!(result.n_unclustered, 0);
        assert_eq!(
            result.face_to_cluster.get("a"),
            result.face_to_cluster.get("b"),
        );
    }

    #[test]
    fn test_face_clustering_two_different() {
        let a = normalized({
            let mut v = vec![0.0f32; 128];
            v[0] = 1.0;
            v
        });
        let b = normalized({
            let mut v = vec![0.0f32; 128];
            v[64] = 1.0;
            v
        });

        let inputs = vec![
            FaceClusterInput {
                face_id: "a".to_string(),
                embedding: a,
                existing_cluster_id: String::new(),
                rejected_cluster_ids: vec![],
            },
            FaceClusterInput {
                face_id: "b".to_string(),
                embedding: b,
                existing_cluster_id: String::new(),
                rejected_cluster_ids: vec![],
            },
        ];

        let result = run_face_clustering(&inputs, 0.24).unwrap();
        assert_ne!(
            result.face_to_cluster.get("a"),
            result.face_to_cluster.get("b"),
        );
    }

    #[test]
    fn test_rejected_cluster_respected() {
        let a = normalized(vec![1.0; 128]);
        let mut b = a.clone();
        b[0] += 0.01;
        let b = normalized(b);

        let inputs = vec![
            FaceClusterInput {
                face_id: "a".to_string(),
                embedding: a,
                existing_cluster_id: "existing_cluster".to_string(),
                rejected_cluster_ids: vec![],
            },
            FaceClusterInput {
                face_id: "b".to_string(),
                embedding: b,
                existing_cluster_id: String::new(),
                rejected_cluster_ids: vec!["existing_cluster".to_string()],
            },
        ];

        let result = run_face_clustering(&inputs, 0.24).unwrap();
        // b should NOT be in the same cluster as a due to rejection
        assert_ne!(
            result.face_to_cluster.get("a"),
            result.face_to_cluster.get("b"),
        );
    }
}

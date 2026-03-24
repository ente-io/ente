//! Shared clustering algorithms used by the pet pipeline.
//!
//! Contains agglomerative clustering (average linkage) and helper functions.

use std::collections::HashMap;

// ── Agglomerative clustering (average linkage, precomputed) ─────────────

/// Hierarchical agglomerative clustering with average linkage on a
/// precomputed distance matrix. Cuts the dendrogram at `threshold`.
///
/// Mirrors Python's `sklearn.cluster.AgglomerativeClustering(
///     metric="precomputed", linkage="average", distance_threshold=threshold)`.
pub fn agglomerative_precomputed(dist: &[f32], n: usize, threshold: f32) -> Vec<i32> {
    agglomerative_precomputed_min_size(dist, n, threshold, 1)
}

/// Same as [agglomerative_precomputed] but clusters smaller than
/// `min_cluster_size` are marked as noise (-1).
pub fn agglomerative_precomputed_min_size(
    dist: &[f32],
    n: usize,
    threshold: f32,
    min_cluster_size: usize,
) -> Vec<i32> {
    if n == 0 {
        return vec![];
    }
    if n == 1 {
        return if min_cluster_size <= 1 {
            vec![0]
        } else {
            vec![-1]
        };
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
            if members.len() >= min_cluster_size {
                for &m in members {
                    labels[m] = next_label;
                }
                next_label += 1;
            }
            // else: too small, stays -1 (noise)
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

#[cfg(test)]
mod tests {
    use super::*;

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
}

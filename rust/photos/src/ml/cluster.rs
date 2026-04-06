//! Shared clustering algorithms used by the pet pipeline.
//!
//! Contains agglomerative clustering (average linkage) and helper functions.

use std::cmp::Ordering;
use std::collections::BinaryHeap;
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
    agglomerative_precomputed_min_size_heap(dist, n, threshold, min_cluster_size)
}

/// Naive exact average-linkage agglomerative clustering.
///
/// This retains the original O(n^3)-like merge selection logic for
/// verification and benchmarking. Production code should use
/// [agglomerative_precomputed_min_size], which now routes to the optimized
/// heap-based exact implementation.
pub fn agglomerative_precomputed_min_size_naive(
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
        if let Some(members) = &clusters[ci]
            && members.len() >= min_cluster_size
        {
            for &m in members {
                labels[m] = next_label;
            }
            next_label += 1;
        }
    }

    labels
}

/// Optimized exact average-linkage agglomerative clustering using
/// lazy nearest-neighbor tracking plus a heap of best merge candidates.
///
/// This keeps the same distance-matrix representation as
/// [agglomerative_precomputed_min_size], but avoids a full O(n^2) scan
/// for the best merge on every iteration.
pub fn agglomerative_precomputed_min_size_heap(
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
    let mut active = vec![true; n];
    let mut sizes = vec![1usize; n];
    let mut cdist: Vec<f32> = dist.to_vec();
    let cap = n;

    let mut nearest: Vec<Option<(usize, f32)>> = vec![None; n];
    let mut heap = BinaryHeap::new();

    for i in 0..n {
        if let Some((j, d)) = recompute_nearest(i, &active, &cdist, cap) {
            nearest[i] = Some((j, d));
            heap.push(Candidate {
                dist: d,
                from: i,
                to: j,
            });
        }
    }

    let mut active_count = n;
    while active_count >= 2 {
        let Some(Candidate {
            dist: best_d,
            from: ci,
            to: cj,
        }) = heap.pop()
        else {
            break;
        };

        if !active[ci] || !active[cj] {
            continue;
        }
        if let Some((n_to, n_dist)) = nearest[ci] {
            if n_to != cj || !same_distance(n_dist, best_d) {
                continue;
            }
        } else {
            continue;
        }

        if best_d > threshold {
            break;
        }

        let size_i = sizes[ci];
        let size_j = sizes[cj];
        let merged_size = size_i + size_j;

        for ck in 0..n {
            if !active[ck] || ck == ci || ck == cj {
                continue;
            }
            let d_ik = cdist[ci * cap + ck];
            let d_jk = cdist[cj * cap + ck];
            let new_d = (size_i as f32 * d_ik + size_j as f32 * d_jk) / merged_size as f32;
            cdist[ci * cap + ck] = new_d;
            cdist[ck * cap + ci] = new_d;
        }

        let cj_members = clusters[cj].take().unwrap();
        clusters[ci].as_mut().unwrap().extend(cj_members);
        active[cj] = false;
        nearest[cj] = None;
        sizes[ci] = merged_size;
        active_count -= 1;

        if let Some((to, d)) = recompute_nearest(ci, &active, &cdist, cap) {
            nearest[ci] = Some((to, d));
            heap.push(Candidate {
                dist: d,
                from: ci,
                to,
            });
        } else {
            nearest[ci] = None;
        }

        for ck in 0..n {
            if !active[ck] || ck == ci {
                continue;
            }

            let should_recompute = match nearest[ck] {
                None => true,
                Some((to, d)) => to == ci || to == cj || cdist[ck * cap + ci] < d,
            };

            if should_recompute {
                if let Some((to, d)) = recompute_nearest(ck, &active, &cdist, cap) {
                    nearest[ck] = Some((to, d));
                    heap.push(Candidate {
                        dist: d,
                        from: ck,
                        to,
                    });
                } else {
                    nearest[ck] = None;
                }
            }
        }
    }

    let mut labels = vec![-1i32; n];
    let mut next_label = 0i32;
    for ci in 0..n {
        if active[ci]
            && let Some(members) = &clusters[ci]
            && members.len() >= min_cluster_size
        {
            for &m in members {
                labels[m] = next_label;
            }
            next_label += 1;
        }
    }

    labels
}

#[derive(Clone, Copy, Debug)]
struct Candidate {
    dist: f32,
    from: usize,
    to: usize,
}

impl PartialEq for Candidate {
    fn eq(&self, other: &Self) -> bool {
        self.from == other.from && self.to == other.to && same_distance(self.dist, other.dist)
    }
}

impl Eq for Candidate {}

impl PartialOrd for Candidate {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for Candidate {
    fn cmp(&self, other: &Self) -> Ordering {
        other
            .dist
            .total_cmp(&self.dist)
            .then_with(|| other.from.cmp(&self.from))
            .then_with(|| other.to.cmp(&self.to))
    }
}

fn recompute_nearest(i: usize, active: &[bool], cdist: &[f32], cap: usize) -> Option<(usize, f32)> {
    if !active[i] {
        return None;
    }

    let mut best: Option<(usize, f32)> = None;
    for j in 0..active.len() {
        if !active[j] || i == j {
            continue;
        }
        let d = cdist[i * cap + j];
        match best {
            None => best = Some((j, d)),
            Some((best_j, best_d)) => {
                if d < best_d || (same_distance(d, best_d) && j < best_j) {
                    best = Some((j, d));
                }
            }
        }
    }
    best
}

fn same_distance(a: f32, b: f32) -> bool {
    (a - b).abs() <= 1e-7
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

/// Select up to `k` diverse exemplars from a set of embeddings.
///
/// Uses greedy farthest-first traversal:
/// 1. Start with the embedding closest to the mean centroid (most typical).
/// 2. Repeatedly add the embedding farthest from all already-selected exemplars.
///
/// This gives good coverage of the cluster's shape without storing every member.
pub fn select_exemplars(embs: &[&Vec<f32>], k: usize, dim: usize) -> Vec<Vec<f32>> {
    let n = embs.len();
    if n == 0 {
        return Vec::new();
    }
    if n <= k {
        return embs.iter().map(|e| (*e).clone()).collect();
    }

    let centroid = mean_centroid(embs, dim);

    let mut selected: Vec<usize> = Vec::with_capacity(k);

    // First exemplar: closest to the centroid (most representative)
    let first = (0..n)
        .max_by(|&a, &b| {
            dot(embs[a], &centroid)
                .partial_cmp(&dot(embs[b], &centroid))
                .unwrap_or(std::cmp::Ordering::Equal)
        })
        .unwrap();
    selected.push(first);

    // Greedy farthest-first: pick the point whose nearest selected exemplar
    // is as far away as possible (maximises diversity).
    while selected.len() < k {
        let best = (0..n)
            .filter(|i| !selected.contains(i))
            .min_by(|&a, &b| {
                // max similarity to any selected exemplar
                let max_sim_a = selected
                    .iter()
                    .map(|&s| dot(embs[a], embs[s]))
                    .fold(f32::NEG_INFINITY, f32::max);
                let max_sim_b = selected
                    .iter()
                    .map(|&s| dot(embs[b], embs[s]))
                    .fold(f32::NEG_INFINITY, f32::max);
                // lower max-similarity = farther = more diverse
                max_sim_a
                    .partial_cmp(&max_sim_b)
                    .unwrap_or(std::cmp::Ordering::Equal)
            })
            .unwrap();
        selected.push(best);
    }

    selected.iter().map(|&i| embs[i].clone()).collect()
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

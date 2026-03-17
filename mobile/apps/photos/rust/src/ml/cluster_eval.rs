//! Clustering algorithm evaluation: threshold sweeps and algorithm comparison.
//!
//! Generates synthetic L2-normalized embeddings with known ground truth, then
//! evaluates agglomerative clustering and HDBSCAN across various scenarios.
//!
//! Run with: `cargo test cluster_eval -- --nocapture`

#[cfg(test)]
mod tests {
    use crate::ml::cluster::{agglomerative_precomputed, dot, normalize};
    use crate::ml::pet::cluster::{
        hdbscan_precomputed, run_pet_clustering, ClusterAlgorithm, ClusterConfig, PetClusterInput,
    };
    use std::collections::HashMap;

    // ── Deterministic PRNG (xorshift64*) ─────────────────────────────────

    struct Rng {
        state: u64,
    }

    impl Rng {
        fn new(seed: u64) -> Self {
            Self {
                state: if seed == 0 { 1 } else { seed },
            }
        }

        fn next_u64(&mut self) -> u64 {
            self.state ^= self.state << 13;
            self.state ^= self.state >> 7;
            self.state ^= self.state << 17;
            self.state.wrapping_mul(0x2545F4914F6CDD1D)
        }

        fn next_f64(&mut self) -> f64 {
            (self.next_u64() >> 11) as f64 / (1u64 << 53) as f64
        }

        /// Standard normal via Box-Muller transform.
        fn gaussian(&mut self) -> f32 {
            let u1 = self.next_f64().max(1e-15);
            let u2 = self.next_f64();
            ((-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()) as f32
        }

        fn shuffle<T>(&mut self, slice: &mut [T]) {
            for i in (1..slice.len()).rev() {
                let j = (self.next_u64() as usize) % (i + 1);
                slice.swap(i, j);
            }
        }
    }

    // ── Synthetic data generation ─────────────────────────────────────────

    fn random_unit_vec(rng: &mut Rng, dim: usize) -> Vec<f32> {
        let mut v: Vec<f32> = (0..dim).map(|_| rng.gaussian()).collect();
        normalize(&mut v);
        v
    }

    fn perturbed_vec(rng: &mut Rng, center: &[f32], noise_std: f32) -> Vec<f32> {
        let mut v: Vec<f32> = center
            .iter()
            .map(|&c| c + rng.gaussian() * noise_std)
            .collect();
        normalize(&mut v);
        v
    }

    struct Dataset {
        embeddings: Vec<Vec<f32>>,
        true_labels: Vec<i32>,
        desc: String,
    }

    fn gen_equal_clusters(
        seed: u64,
        dim: usize,
        n_clusters: usize,
        pts_per_cluster: usize,
        noise_std: f32,
        desc: &str,
    ) -> Dataset {
        gen_variable_clusters(
            seed,
            dim,
            &vec![pts_per_cluster; n_clusters],
            noise_std,
            desc,
        )
    }

    fn gen_variable_clusters(
        seed: u64,
        dim: usize,
        sizes: &[usize],
        noise_std: f32,
        desc: &str,
    ) -> Dataset {
        let mut rng = Rng::new(seed);
        let centers: Vec<Vec<f32>> = (0..sizes.len())
            .map(|_| random_unit_vec(&mut rng, dim))
            .collect();

        let mut embs = Vec::new();
        let mut labels = Vec::new();
        for (ci, (&sz, center)) in sizes.iter().zip(centers.iter()).enumerate() {
            for _ in 0..sz {
                embs.push(perturbed_vec(&mut rng, center, noise_std));
                labels.push(ci as i32);
            }
        }

        let n = embs.len();
        let mut idx: Vec<usize> = (0..n).collect();
        rng.shuffle(&mut idx);
        let embs2: Vec<Vec<f32>> = idx.iter().map(|&i| embs[i].clone()).collect();
        let labels2: Vec<i32> = idx.iter().map(|&i| labels[i]).collect();

        Dataset {
            embeddings: embs2,
            true_labels: labels2,
            desc: desc.to_string(),
        }
    }

    /// Generate data with outlier/noise points not belonging to any cluster.
    fn gen_with_noise(
        seed: u64,
        dim: usize,
        n_clusters: usize,
        pts_per_cluster: usize,
        noise_std: f32,
        n_noise: usize,
        desc: &str,
    ) -> Dataset {
        let mut rng = Rng::new(seed);
        let centers: Vec<Vec<f32>> = (0..n_clusters)
            .map(|_| random_unit_vec(&mut rng, dim))
            .collect();

        let mut embs = Vec::new();
        let mut labels = Vec::new();
        for (ci, center) in centers.iter().enumerate() {
            for _ in 0..pts_per_cluster {
                embs.push(perturbed_vec(&mut rng, center, noise_std));
                labels.push(ci as i32);
            }
        }
        // Add pure random noise points (no cluster)
        for _ in 0..n_noise {
            embs.push(random_unit_vec(&mut rng, dim));
            labels.push(-1); // noise ground truth
        }

        let n = embs.len();
        let mut idx: Vec<usize> = (0..n).collect();
        rng.shuffle(&mut idx);
        Dataset {
            embeddings: idx.iter().map(|&i| embs[i].clone()).collect(),
            true_labels: idx.iter().map(|&i| labels[i]).collect(),
            desc: desc.to_string(),
        }
    }

    // ── Metrics ───────────────────────────────────────────────────────────

    #[derive(Clone)]
    struct Metrics {
        ari: f64,
        nmi: f64,
        precision: f64,
        recall: f64,
        f1: f64,
        n_clusters: usize,
        n_noise: usize,
    }

    /// Evaluate clustering quality. Points with pred_label == -1 are excluded
    /// from pairwise metrics (but counted as noise). Ground-truth -1 labels
    /// (true noise) are also excluded.
    fn eval(true_labels: &[i32], pred_labels: &[i32]) -> Metrics {
        assert_eq!(true_labels.len(), pred_labels.len());
        let n = true_labels.len();
        let n_noise = pred_labels.iter().filter(|&&l| l < 0).count();

        // Include only points that have both a true cluster AND a predicted cluster
        let valid: Vec<usize> = (0..n)
            .filter(|&i| pred_labels[i] >= 0 && true_labels[i] >= 0)
            .collect();
        let nv = valid.len();

        let mut pred_ids = std::collections::HashSet::new();
        for &i in &valid {
            pred_ids.insert(pred_labels[i]);
        }
        let n_clusters = pred_ids.len();

        if nv < 2 {
            return Metrics {
                ari: 0.0,
                nmi: 0.0,
                precision: 0.0,
                recall: 0.0,
                f1: 0.0,
                n_clusters: 0,
                n_noise,
            };
        }

        let (mut tp, mut fp, mut fn_, mut tn) = (0u64, 0u64, 0u64, 0u64);
        for i in 0..nv {
            for j in (i + 1)..nv {
                let (vi, vj) = (valid[i], valid[j]);
                match (
                    true_labels[vi] == true_labels[vj],
                    pred_labels[vi] == pred_labels[vj],
                ) {
                    (true, true) => tp += 1,
                    (false, true) => fp += 1,
                    (true, false) => fn_ += 1,
                    (false, false) => tn += 1,
                }
            }
        }

        let precision = if tp + fp > 0 {
            tp as f64 / (tp + fp) as f64
        } else {
            0.0
        };
        let recall = if tp + fn_ > 0 {
            tp as f64 / (tp + fn_) as f64
        } else {
            0.0
        };
        let f1 = if precision + recall > 0.0 {
            2.0 * precision * recall / (precision + recall)
        } else {
            0.0
        };

        // ARI: Hubert & Arabie from pairwise counts
        let ari = {
            let num = 2.0 * (tp as f64 * tn as f64 - fp as f64 * fn_ as f64);
            let den = (tp + fp) as f64 * (fp + tn) as f64
                + (tp + fn_) as f64 * (fn_ + tn) as f64;
            if den.abs() < 1e-12 {
                0.0
            } else {
                num / den
            }
        };

        // NMI
        let t_valid: Vec<i32> = valid.iter().map(|&i| true_labels[i]).collect();
        let p_valid: Vec<i32> = valid.iter().map(|&i| pred_labels[i]).collect();
        let nmi = compute_nmi(&t_valid, &p_valid);

        Metrics {
            ari,
            nmi,
            precision,
            recall,
            f1,
            n_clusters,
            n_noise,
        }
    }

    fn compute_nmi(t: &[i32], p: &[i32]) -> f64 {
        let n = t.len() as f64;
        if n < 2.0 {
            return 0.0;
        }

        let mut tc: HashMap<i32, f64> = HashMap::new();
        let mut pc: HashMap<i32, f64> = HashMap::new();
        let mut jc: HashMap<(i32, i32), f64> = HashMap::new();
        for (&ti, &pi) in t.iter().zip(p.iter()) {
            *tc.entry(ti).or_default() += 1.0;
            *pc.entry(pi).or_default() += 1.0;
            *jc.entry((ti, pi)).or_default() += 1.0;
        }

        let h_t: f64 = tc
            .values()
            .map(|&c| {
                let p = c / n;
                -p * p.ln()
            })
            .sum();
        let h_p: f64 = pc
            .values()
            .map(|&c| {
                let p = c / n;
                -p * p.ln()
            })
            .sum();
        if h_t < 1e-12 || h_p < 1e-12 {
            return 0.0;
        }

        let mi: f64 = jc
            .iter()
            .map(|(&(ti, pi), &nij)| {
                if nij < 1e-12 {
                    return 0.0;
                }
                (nij / n) * (nij * n / (tc[&ti] * pc[&pi])).ln()
            })
            .sum();

        2.0 * mi / (h_t + h_p)
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    fn build_dist_matrix(embs: &[Vec<f32>]) -> Vec<f32> {
        let n = embs.len();
        let mut dist = vec![0.0f32; n * n];
        for i in 0..n {
            for j in (i + 1)..n {
                let sim: f32 = dot(&embs[i], &embs[j]);
                let d = (1.0 - sim).clamp(0.0, 2.0);
                dist[i * n + j] = d;
                dist[j * n + i] = d;
            }
        }
        dist
    }

    /// Print intra- and inter-cluster distance statistics for a dataset.
    fn print_distance_stats(data: &Dataset) {
        let n = data.embeddings.len();
        let mut intra_dists = Vec::new();
        let mut inter_dists = Vec::new();
        for i in 0..n {
            for j in (i + 1)..n {
                if data.true_labels[i] < 0 || data.true_labels[j] < 0 {
                    continue;
                }
                let d = 1.0 - dot(&data.embeddings[i], &data.embeddings[j]);
                if data.true_labels[i] == data.true_labels[j] {
                    intra_dists.push(d);
                } else {
                    inter_dists.push(d);
                }
            }
        }
        intra_dists.sort_by(|a, b| a.partial_cmp(b).unwrap());
        inter_dists.sort_by(|a, b| a.partial_cmp(b).unwrap());

        let stats = |v: &[f32]| -> (f32, f32, f32, f32, f32) {
            if v.is_empty() {
                return (0.0, 0.0, 0.0, 0.0, 0.0);
            }
            let min = v[0];
            let max = v[v.len() - 1];
            let mean = v.iter().sum::<f32>() / v.len() as f32;
            let p5 = v[(v.len() as f32 * 0.05) as usize];
            let p95 = v[((v.len() as f32 * 0.95) as usize).min(v.len() - 1)];
            (min, p5, mean, p95, max)
        };

        let (imin, ip5, imean, ip95, imax) = stats(&intra_dists);
        let (emin, ep5, emean, ep95, emax) = stats(&inter_dists);
        eprintln!("  Intra-cluster dist: min={:.4} p5={:.4} mean={:.4} p95={:.4} max={:.4} (n={})",
            imin, ip5, imean, ip95, imax, intra_dists.len());
        eprintln!("  Inter-cluster dist: min={:.4} p5={:.4} mean={:.4} p95={:.4} max={:.4} (n={})",
            emin, ep5, emean, ep95, emax, inter_dists.len());

        // Ideal threshold range
        if !intra_dists.is_empty() && !inter_dists.is_empty() {
            eprintln!(
                "  Ideal threshold range: ({:.4}, {:.4})",
                imax, emin
            );
        }
    }

    fn print_header(title: &str) {
        eprintln!("\n{}", "=".repeat(100));
        eprintln!("  {}", title);
        eprintln!("{}", "=".repeat(100));
    }

    fn print_table_header() {
        eprintln!(
            "  {:<28} | {:>4} | {:>5} | {:>7} | {:>7} | {:>7} | {:>7} | {:>7}",
            "Config", "K", "Noise", "ARI", "NMI", "Prec", "Recall", "F1"
        );
        eprintln!("  {}", "-".repeat(92));
    }

    fn print_row(label: &str, m: &Metrics, mark: &str) {
        eprintln!(
            "  {:<28} | {:>4} | {:>5} | {:>7.4} | {:>7.4} | {:>7.4} | {:>7.4} | {:>7.4}{}",
            label,
            m.n_clusters,
            m.n_noise,
            m.ari,
            m.nmi,
            m.precision,
            m.recall,
            m.f1,
            mark
        );
    }

    /// Run a threshold sweep and return (best_threshold, best_metrics, all_results).
    fn sweep_agglom(
        data: &Dataset,
        thresholds: &[f32],
    ) -> (f32, Metrics, Vec<(f32, Metrics)>) {
        let n = data.embeddings.len();
        let dist = build_dist_matrix(&data.embeddings);

        let mut best_f1 = -1.0f64;
        let mut best_t = 0.0f32;
        let mut best_m = Metrics {
            ari: 0.0,
            nmi: 0.0,
            precision: 0.0,
            recall: 0.0,
            f1: 0.0,
            n_clusters: 0,
            n_noise: 0,
        };
        let mut results = Vec::new();

        for &t in thresholds {
            let pred = agglomerative_precomputed(&dist, n, t);
            let m = eval(&data.true_labels, &pred);
            if m.f1 > best_f1 {
                best_f1 = m.f1;
                best_t = t;
                best_m = m.clone();
            }
            results.push((t, m));
        }

        (best_t, best_m, results)
    }

    fn sweep_hdbscan(
        data: &Dataset,
        params: &[(usize, usize)],
    ) -> Vec<((usize, usize), Metrics)> {
        let n = data.embeddings.len();
        let dist = build_dist_matrix(&data.embeddings);

        params
            .iter()
            .map(|&(mcs, ms)| {
                let pred = hdbscan_precomputed(&dist, n, mcs, ms);
                let m = eval(&data.true_labels, &pred);
                ((mcs, ms), m)
            })
            .collect()
    }

    fn thresholds(start: f32, end: f32, step: f32) -> Vec<f32> {
        let mut v = Vec::new();
        let mut t = start;
        while t <= end + 1e-6 {
            v.push((t * 1000.0).round() / 1000.0);
            t += step;
        }
        v
    }

    // ══════════════════════════════════════════════════════════════════════
    // ADDITIONAL CLUSTERING ALGORITHMS
    // ══════════════════════════════════════════════════════════════════════

    // ── Single-linkage agglomerative ──────────────────────────────────────

    /// Single-linkage: merge the two clusters with the smallest minimum
    /// pairwise distance. Distance update: d(i∪j, k) = min(d(i,k), d(j,k)).
    fn single_linkage_precomputed(dist: &[f32], n: usize, threshold: f32) -> Vec<i32> {
        if n == 0 {
            return vec![];
        }
        if n == 1 {
            return vec![0];
        }

        let mut active: Vec<usize> = (0..n).collect();
        let mut members: Vec<Option<Vec<usize>>> = (0..n).map(|i| Some(vec![i])).collect();
        let mut cdist = dist.to_vec();

        loop {
            if active.len() < 2 {
                break;
            }
            let mut best_d = f32::INFINITY;
            let mut bi = 0;
            let mut bj = 0;
            for ai in 0..active.len() {
                for aj in (ai + 1)..active.len() {
                    let d = cdist[active[ai] * n + active[aj]];
                    if d < best_d {
                        best_d = d;
                        bi = ai;
                        bj = aj;
                    }
                }
            }
            if best_d > threshold {
                break;
            }
            let (ci, cj) = (active[bi], active[bj]);
            // Single-linkage: d(merged, k) = min(d(ci,k), d(cj,k))
            for &ck in &active {
                if ck == ci || ck == cj {
                    continue;
                }
                let new_d = cdist[ci * n + ck].min(cdist[cj * n + ck]);
                cdist[ci * n + ck] = new_d;
                cdist[ck * n + ci] = new_d;
            }
            let cj_members = members[cj].take().unwrap();
            members[ci].as_mut().unwrap().extend(cj_members);
            active.remove(bj);
        }

        let mut labels = vec![-1i32; n];
        let mut next_label = 0i32;
        for &ci in &active {
            if let Some(m) = &members[ci] {
                for &idx in m {
                    labels[idx] = next_label;
                }
                next_label += 1;
            }
        }
        labels
    }

    // ── Complete-linkage agglomerative ────────────────────────────────────

    /// Complete-linkage: merge closest clusters, where cluster distance is
    /// the maximum pairwise distance. d(i∪j, k) = max(d(i,k), d(j,k)).
    fn complete_linkage_precomputed(dist: &[f32], n: usize, threshold: f32) -> Vec<i32> {
        if n == 0 {
            return vec![];
        }
        if n == 1 {
            return vec![0];
        }

        let mut active: Vec<usize> = (0..n).collect();
        let mut members: Vec<Option<Vec<usize>>> = (0..n).map(|i| Some(vec![i])).collect();
        let mut cdist = dist.to_vec();

        loop {
            if active.len() < 2 {
                break;
            }
            let mut best_d = f32::INFINITY;
            let mut bi = 0;
            let mut bj = 0;
            for ai in 0..active.len() {
                for aj in (ai + 1)..active.len() {
                    let d = cdist[active[ai] * n + active[aj]];
                    if d < best_d {
                        best_d = d;
                        bi = ai;
                        bj = aj;
                    }
                }
            }
            if best_d > threshold {
                break;
            }
            let (ci, cj) = (active[bi], active[bj]);
            // Complete-linkage: d(merged, k) = max(d(ci,k), d(cj,k))
            for &ck in &active {
                if ck == ci || ck == cj {
                    continue;
                }
                let new_d = cdist[ci * n + ck].max(cdist[cj * n + ck]);
                cdist[ci * n + ck] = new_d;
                cdist[ck * n + ci] = new_d;
            }
            let cj_members = members[cj].take().unwrap();
            members[ci].as_mut().unwrap().extend(cj_members);
            active.remove(bj);
        }

        let mut labels = vec![-1i32; n];
        let mut next_label = 0i32;
        for &ci in &active {
            if let Some(m) = &members[ci] {
                for &idx in m {
                    labels[idx] = next_label;
                }
                next_label += 1;
            }
        }
        labels
    }

    // ── Ward's linkage agglomerative ─────────────────────────────────────

    /// Ward's method on precomputed distances. Uses Lance-Williams formula:
    /// d²(i∪j, k) = ((n_i+n_k)*d²(i,k) + (n_j+n_k)*d²(j,k) - n_k*d²(i,j))
    ///              / (n_i + n_j + n_k)
    fn ward_linkage_precomputed(dist: &[f32], n: usize, threshold: f32) -> Vec<i32> {
        if n == 0 {
            return vec![];
        }
        if n == 1 {
            return vec![0];
        }

        let mut active: Vec<usize> = (0..n).collect();
        let mut sizes: Vec<usize> = vec![1; n];
        let mut members: Vec<Option<Vec<usize>>> = (0..n).map(|i| Some(vec![i])).collect();
        // Work with squared distances
        let mut cdist: Vec<f32> = dist.iter().map(|&d| d * d).collect();

        loop {
            if active.len() < 2 {
                break;
            }
            let mut best_d = f32::INFINITY;
            let mut bi = 0;
            let mut bj = 0;
            for ai in 0..active.len() {
                for aj in (ai + 1)..active.len() {
                    let d = cdist[active[ai] * n + active[aj]];
                    if d < best_d {
                        best_d = d;
                        bi = ai;
                        bj = aj;
                    }
                }
            }
            // Compare sqrt of squared distance to threshold
            if best_d.sqrt() > threshold {
                break;
            }
            let (ci, cj) = (active[bi], active[bj]);
            let ni = sizes[ci] as f32;
            let nj = sizes[cj] as f32;
            let d_ij_sq = cdist[ci * n + cj];

            for &ck in &active {
                if ck == ci || ck == cj {
                    continue;
                }
                let nk = sizes[ck] as f32;
                let d_ik_sq = cdist[ci * n + ck];
                let d_jk_sq = cdist[cj * n + ck];
                let new_d_sq = ((ni + nk) * d_ik_sq + (nj + nk) * d_jk_sq - nk * d_ij_sq)
                    / (ni + nj + nk);
                let new_d_sq = new_d_sq.max(0.0);
                cdist[ci * n + ck] = new_d_sq;
                cdist[ck * n + ci] = new_d_sq;
            }
            sizes[ci] += sizes[cj];
            let cj_members = members[cj].take().unwrap();
            members[ci].as_mut().unwrap().extend(cj_members);
            active.remove(bj);
        }

        let mut labels = vec![-1i32; n];
        let mut next_label = 0i32;
        for &ci in &active {
            if let Some(m) = &members[ci] {
                for &idx in m {
                    labels[idx] = next_label;
                }
                next_label += 1;
            }
        }
        labels
    }

    // ── DBSCAN ───────────────────────────────────────────────────────────

    /// Classic DBSCAN on a precomputed distance matrix.
    /// Points with >= min_pts neighbors within epsilon are core points.
    /// Connected core points form clusters. Non-core points within epsilon
    /// of a core point are border points (assigned to that cluster).
    fn dbscan_precomputed(dist: &[f32], n: usize, epsilon: f32, min_pts: usize) -> Vec<i32> {
        if n == 0 {
            return vec![];
        }

        let mut labels = vec![-1i32; n];
        let mut visited = vec![false; n];
        let mut cluster_id = 0i32;

        for i in 0..n {
            if visited[i] {
                continue;
            }
            visited[i] = true;

            let neighbors = region_query(dist, n, i, epsilon);
            if neighbors.len() < min_pts {
                // Noise point (may become border later)
                continue;
            }

            // Core point — start a new cluster
            labels[i] = cluster_id;
            let mut queue = neighbors;
            let mut qi = 0;
            while qi < queue.len() {
                let j = queue[qi];
                qi += 1;

                if !visited[j] {
                    visited[j] = true;
                    let j_neighbors = region_query(dist, n, j, epsilon);
                    if j_neighbors.len() >= min_pts {
                        // j is also core — expand
                        for &k in &j_neighbors {
                            if !queue.contains(&k) {
                                queue.push(k);
                            }
                        }
                    }
                }
                if labels[j] == -1 {
                    labels[j] = cluster_id;
                }
            }
            cluster_id += 1;
        }
        labels
    }

    fn region_query(dist: &[f32], n: usize, point: usize, epsilon: f32) -> Vec<usize> {
        (0..n)
            .filter(|&j| j != point && dist[point * n + j] <= epsilon)
            .collect()
    }

    // ── Spherical K-Means ────────────────────────────────────────────────

    /// K-means on L2-normalized embeddings (cosine distance).
    /// Centroids are re-normalized after each update.
    fn spherical_kmeans(
        embs: &[Vec<f32>],
        k: usize,
        rng: &mut Rng,
        max_iter: usize,
    ) -> Vec<i32> {
        let n = embs.len();
        if n == 0 || k == 0 {
            return vec![-1i32; n];
        }
        if k >= n {
            return (0..n as i32).collect();
        }

        let dim = embs[0].len();

        // K-means++ initialization
        let mut centroids: Vec<Vec<f32>> = Vec::with_capacity(k);
        let first = (rng.next_u64() as usize) % n;
        centroids.push(embs[first].clone());

        for _ in 1..k {
            // Compute distance to nearest centroid for each point
            let mut dists: Vec<f64> = embs
                .iter()
                .map(|e| {
                    centroids
                        .iter()
                        .map(|c| (1.0 - dot(e, c) as f64).max(0.0))
                        .fold(f64::INFINITY, f64::min)
                })
                .collect();

            let total: f64 = dists.iter().sum();
            if total < 1e-15 {
                // Degenerate — pick random
                let idx = (rng.next_u64() as usize) % n;
                centroids.push(embs[idx].clone());
                continue;
            }

            // Weighted random selection
            for d in &mut dists {
                *d /= total;
            }
            let r = rng.next_f64();
            let mut cumsum = 0.0;
            let mut chosen = n - 1;
            for (i, &d) in dists.iter().enumerate() {
                cumsum += d;
                if cumsum >= r {
                    chosen = i;
                    break;
                }
            }
            centroids.push(embs[chosen].clone());
        }

        let mut labels = vec![0i32; n];

        for _iter in 0..max_iter {
            // Assignment step: each point to nearest centroid
            let mut changed = false;
            for (i, emb) in embs.iter().enumerate() {
                let mut best_sim = f32::NEG_INFINITY;
                let mut best_k = 0i32;
                for (ki, centroid) in centroids.iter().enumerate() {
                    let sim = dot(emb, centroid);
                    if sim > best_sim {
                        best_sim = sim;
                        best_k = ki as i32;
                    }
                }
                if labels[i] != best_k {
                    labels[i] = best_k;
                    changed = true;
                }
            }

            if !changed {
                break;
            }

            // Update step: recompute centroids as normalized mean
            for ki in 0..k {
                let mut new_centroid = vec![0.0f32; dim];
                let mut count = 0usize;
                for (i, emb) in embs.iter().enumerate() {
                    if labels[i] == ki as i32 {
                        for (d, &v) in new_centroid.iter_mut().zip(emb.iter()) {
                            *d += v;
                        }
                        count += 1;
                    }
                }
                if count > 0 {
                    normalize(&mut new_centroid);
                    centroids[ki] = new_centroid;
                }
            }
        }

        labels
    }

    /// Run spherical k-means multiple times with different seeds and return
    /// the result with the best total within-cluster similarity.
    fn spherical_kmeans_best(
        embs: &[Vec<f32>],
        k: usize,
        seed: u64,
        n_runs: usize,
    ) -> Vec<i32> {
        let mut best_labels = vec![0i32; embs.len()];
        let mut best_score = f64::NEG_INFINITY;

        for run in 0..n_runs {
            let mut rng = Rng::new(seed + run as u64 * 1000);
            let labels = spherical_kmeans(embs, k, &mut rng, 100);

            // Score: sum of cosine similarities to assigned centroid
            let dim = embs[0].len();
            let mut centroids: Vec<Vec<f32>> = vec![vec![0.0f32; dim]; k];
            let mut counts = vec![0usize; k];
            for (i, emb) in embs.iter().enumerate() {
                let ki = labels[i] as usize;
                for (d, &v) in centroids[ki].iter_mut().zip(emb.iter()) {
                    *d += v;
                }
                counts[ki] += 1;
            }
            for ci in &mut centroids {
                normalize(ci);
            }

            let score: f64 = embs
                .iter()
                .enumerate()
                .map(|(i, emb)| dot(emb, &centroids[labels[i] as usize]) as f64)
                .sum();

            if score > best_score {
                best_score = score;
                best_labels = labels;
            }
        }

        best_labels
    }

    // ── Chinese Whispers ─────────────────────────────────────────────────

    /// Chinese Whispers graph-based clustering. Builds a similarity graph
    /// with edges where cosine_similarity > edge_threshold, then propagates
    /// labels iteratively.
    fn chinese_whispers(
        embs: &[Vec<f32>],
        edge_threshold: f32,
        n_iterations: usize,
        rng: &mut Rng,
    ) -> Vec<i32> {
        let n = embs.len();
        if n == 0 {
            return vec![];
        }

        // Build adjacency list with similarities above threshold
        let mut adj: Vec<Vec<(usize, f32)>> = vec![Vec::new(); n];
        for i in 0..n {
            for j in (i + 1)..n {
                let sim = dot(&embs[i], &embs[j]);
                if sim > edge_threshold {
                    adj[i].push((j, sim));
                    adj[j].push((i, sim));
                }
            }
        }

        // Initialize: each node gets its own label
        let mut labels: Vec<i32> = (0..n as i32).collect();

        // Iterate
        for _ in 0..n_iterations {
            let mut order: Vec<usize> = (0..n).collect();
            rng.shuffle(&mut order);

            for &i in &order {
                if adj[i].is_empty() {
                    continue;
                }
                // Find the label with highest total weighted vote
                let mut votes: HashMap<i32, f32> = HashMap::new();
                for &(j, sim) in &adj[i] {
                    *votes.entry(labels[j]).or_default() += sim;
                }
                if let Some((&best_label, _)) = votes.iter().max_by(|a, b| {
                    a.1.partial_cmp(b.1)
                        .unwrap_or(std::cmp::Ordering::Equal)
                }) {
                    labels[i] = best_label;
                }
            }
        }

        // Renumber labels to contiguous 0..K-1
        let mut label_map: HashMap<i32, i32> = HashMap::new();
        let mut next = 0i32;
        for l in &mut labels {
            let entry = label_map.entry(*l).or_insert_with(|| {
                let id = next;
                next += 1;
                id
            });
            *l = *entry;
        }

        labels
    }

    // ── Spectral Clustering (simplified) ─────────────────────────────────

    /// Simplified spectral clustering using normalized Laplacian.
    /// 1. Build similarity matrix (cosine sim, thresholded)
    /// 2. Compute normalized Laplacian
    /// 3. Use power iteration to find top-k eigenvectors
    /// 4. Run k-means on the spectral embedding
    fn spectral_clustering(
        embs: &[Vec<f32>],
        k: usize,
        sim_threshold: f32,
        seed: u64,
    ) -> Vec<i32> {
        let n = embs.len();
        if n == 0 || k == 0 {
            return vec![];
        }
        if n <= k {
            return (0..n as i32).collect();
        }

        // Build similarity matrix (only keep edges above threshold)
        let mut sim_matrix = vec![0.0f32; n * n];
        for i in 0..n {
            for j in (i + 1)..n {
                let s = dot(&embs[i], &embs[j]);
                if s > sim_threshold {
                    sim_matrix[i * n + j] = s;
                    sim_matrix[j * n + i] = s;
                }
            }
        }

        // Degree matrix D_ii = sum of row i
        let degrees: Vec<f32> = (0..n)
            .map(|i| (0..n).map(|j| sim_matrix[i * n + j]).sum())
            .collect();

        // D^{-1/2}
        let d_inv_sqrt: Vec<f32> = degrees
            .iter()
            .map(|&d| if d > 1e-10 { 1.0 / d.sqrt() } else { 0.0 })
            .collect();

        // Normalized similarity: D^{-1/2} * W * D^{-1/2}
        // We want the top-k eigenvectors of this (which correspond to clusters)
        let mut norm_sim = vec![0.0f32; n * n];
        for i in 0..n {
            for j in 0..n {
                norm_sim[i * n + j] = d_inv_sqrt[i] * sim_matrix[i * n + j] * d_inv_sqrt[j];
            }
        }

        // Power iteration to find k dominant eigenvectors
        let mut rng = Rng::new(seed);
        let mut eigenvecs: Vec<Vec<f32>> = Vec::with_capacity(k);

        for _ki in 0..k {
            // Random initial vector
            let mut v: Vec<f32> = (0..n).map(|_| rng.gaussian()).collect();
            let mut norm: f32 = v.iter().map(|x| x * x).sum::<f32>().sqrt();
            if norm > 1e-10 {
                for x in &mut v {
                    *x /= norm;
                }
            }

            // Power iteration (with deflation)
            for _ in 0..50 {
                // Matrix-vector multiply: w = norm_sim * v
                let mut w = vec![0.0f32; n];
                for i in 0..n {
                    for j in 0..n {
                        w[i] += norm_sim[i * n + j] * v[j];
                    }
                }

                // Deflate: remove projections onto previous eigenvectors
                for prev in &eigenvecs {
                    let proj: f32 = w.iter().zip(prev.iter()).map(|(a, b)| a * b).sum();
                    for (wi, pi) in w.iter_mut().zip(prev.iter()) {
                        *wi -= proj * pi;
                    }
                }

                // Normalize
                norm = w.iter().map(|x| x * x).sum::<f32>().sqrt();
                if norm > 1e-10 {
                    for x in &mut w {
                        *x /= norm;
                    }
                }
                v = w;
            }

            eigenvecs.push(v);
        }

        // Build spectral embedding: each point gets a k-dimensional vector
        let spectral_embs: Vec<Vec<f32>> = (0..n)
            .map(|i| {
                let mut se: Vec<f32> = eigenvecs.iter().map(|ev| ev[i]).collect();
                // Row-normalize
                let row_norm: f32 = se.iter().map(|x| x * x).sum::<f32>().sqrt();
                if row_norm > 1e-10 {
                    for x in &mut se {
                        *x /= row_norm;
                    }
                }
                se
            })
            .collect();

        // Run k-means on spectral embedding
        spherical_kmeans_best(&spectral_embs, k, seed + 999, 5)
    }

    // ── Algorithm runner enum for clean comparison ────────────────────────

    #[derive(Clone)]
    enum AlgoConfig {
        AgglomAverage(f32),
        AgglomSingle(f32),
        AgglomComplete(f32),
        AgglomWard(f32),
        Hdbscan(usize, usize),
        Dbscan(f32, usize),
        SphericalKmeans(usize),
        ChineseWhispers(f32),
        Spectral(usize, f32),
    }

    impl AlgoConfig {
        fn name(&self) -> String {
            match self {
                Self::AgglomAverage(t) => format!("Agglom-Avg(t={:.2})", t),
                Self::AgglomSingle(t) => format!("Agglom-Single(t={:.2})", t),
                Self::AgglomComplete(t) => format!("Agglom-Complete(t={:.2})", t),
                Self::AgglomWard(t) => format!("Agglom-Ward(t={:.2})", t),
                Self::Hdbscan(mcs, ms) => format!("HDBSCAN(mcs={},ms={})", mcs, ms),
                Self::Dbscan(eps, mp) => format!("DBSCAN(e={:.2},mp={})", eps, mp),
                Self::SphericalKmeans(k) => format!("Sph-KMeans(k={})", k),
                Self::ChineseWhispers(t) => format!("ChineseWhisp(t={:.2})", t),
                Self::Spectral(k, t) => format!("Spectral(k={},t={:.2})", k, t),
            }
        }

        fn run(&self, embs: &[Vec<f32>], dist: &[f32], n: usize, seed: u64) -> Vec<i32> {
            match self {
                Self::AgglomAverage(t) => agglomerative_precomputed(dist, n, *t),
                Self::AgglomSingle(t) => single_linkage_precomputed(dist, n, *t),
                Self::AgglomComplete(t) => complete_linkage_precomputed(dist, n, *t),
                Self::AgglomWard(t) => ward_linkage_precomputed(dist, n, *t),
                Self::Hdbscan(mcs, ms) => hdbscan_precomputed(dist, n, *mcs, *ms),
                Self::Dbscan(eps, mp) => dbscan_precomputed(dist, n, *eps, *mp),
                Self::SphericalKmeans(k) => spherical_kmeans_best(embs, *k, seed, 10),
                Self::ChineseWhispers(t) => {
                    let mut rng = Rng::new(seed);
                    chinese_whispers(embs, *t, 30, &mut rng)
                }
                Self::Spectral(k, t) => spectral_clustering(embs, *k, *t, seed),
            }
        }
    }

    /// Run all algorithm configs on a dataset and print comparison table.
    fn run_algo_comparison(data: &Dataset, configs: &[AlgoConfig], seed: u64) {
        let n = data.embeddings.len();
        let dist = build_dist_matrix(&data.embeddings);

        print_header(&data.desc);
        print_distance_stats(data);
        print_table_header();

        let mut best_f1 = -1.0f64;
        let mut best_name = String::new();

        for cfg in configs {
            let pred = cfg.run(&data.embeddings, &dist, n, seed);
            let m = eval(&data.true_labels, &pred);
            let mark = if m.f1 > best_f1 { "  <- BEST" } else { "" };
            if m.f1 > best_f1 {
                best_f1 = m.f1;
                best_name = cfg.name();
            }
            print_row(&cfg.name(), &m, mark);
        }

        eprintln!("\n  Winner: {} (F1={:.4})", best_name, best_f1);
    }

    // ══════════════════════════════════════════════════════════════════════
    // THRESHOLD SWEEP TESTS
    // ══════════════════════════════════════════════════════════════════════

    /// High-quality face embeddings (like MobileFaceNet for human faces).
    /// Expected: optimal threshold around 0.10-0.20, matching production 0.24.
    #[test]
    fn threshold_sweep_face_high_quality() {
        let data = gen_equal_clusters(
            42,
            128,
            5,
            20,
            0.04,
            "High-quality face (128-d, sigma=0.04, 5x20)",
        );

        print_header(&data.desc);
        print_distance_stats(&data);

        let ts = thresholds(0.02, 0.60, 0.02);
        let (best_t, best_m, results) = sweep_agglom(&data, &ts);

        print_table_header();
        for (t, m) in &results {
            let mark = if (*t - best_t).abs() < 1e-6 {
                "  <- BEST"
            } else {
                ""
            };
            print_row(&format!("t={:.2}", t), m, mark);
        }
        eprintln!(
            "\n  Best: t={:.2} F1={:.4} | Production: 0.24",
            best_t, best_m.f1
        );

        assert!(
            best_m.f1 > 0.90,
            "Best F1 should be >0.90 for well-separated data"
        );
    }

    /// Medium-quality face embeddings — moderate noise.
    /// Tests whether threshold 0.24 is still reasonable.
    #[test]
    fn threshold_sweep_face_moderate() {
        let data = gen_equal_clusters(
            123,
            128,
            5,
            20,
            0.08,
            "Moderate face (128-d, sigma=0.08, 5x20)",
        );

        print_header(&data.desc);
        print_distance_stats(&data);

        let ts = thresholds(0.05, 0.80, 0.02);
        let (best_t, best_m, results) = sweep_agglom(&data, &ts);

        print_table_header();
        for (t, m) in &results {
            let mark = if (*t - best_t).abs() < 1e-6 {
                "  <- BEST"
            } else {
                ""
            };
            print_row(&format!("t={:.2}", t), m, mark);
        }
        eprintln!(
            "\n  Best: t={:.2} F1={:.4} | Production: 0.24",
            best_t, best_m.f1
        );

        assert!(best_m.f1 > 0.80, "Best F1 should be >0.80");
    }

    /// Pet face embeddings (BYOL model) — wider intra-cluster spread.
    /// Expected: optimal threshold much higher than human faces (~0.60-0.80).
    #[test]
    fn threshold_sweep_pet_face() {
        let data = gen_equal_clusters(
            7,
            128,
            5,
            15,
            0.15,
            "Pet face BYOL-like (128-d, sigma=0.15, 5x15)",
        );

        print_header(&data.desc);
        print_distance_stats(&data);

        let ts = thresholds(0.10, 1.20, 0.02);
        let (best_t, best_m, results) = sweep_agglom(&data, &ts);

        print_table_header();
        for (t, m) in &results {
            let mark = if (*t - best_t).abs() < 1e-6 {
                "  <- BEST"
            } else {
                ""
            };
            print_row(&format!("t={:.2}", t), m, mark);
        }
        eprintln!(
            "\n  Best: t={:.2} F1={:.4} | Production: 0.77",
            best_t, best_m.f1
        );

        assert!(best_m.f1 > 0.70, "Best F1 should be >0.70 for pet data");
    }

    /// Body embeddings — 192-d, moderate noise.
    #[test]
    fn threshold_sweep_body_192d() {
        let data = gen_equal_clusters(
            99,
            192,
            5,
            15,
            0.10,
            "Body embeddings (192-d, sigma=0.10, 5x15)",
        );

        print_header(&data.desc);
        print_distance_stats(&data);

        let ts = thresholds(0.10, 1.00, 0.02);
        let (best_t, best_m, results) = sweep_agglom(&data, &ts);

        print_table_header();
        for (t, m) in &results {
            let mark = if (*t - best_t).abs() < 1e-6 {
                "  <- BEST"
            } else {
                ""
            };
            print_row(&format!("t={:.2}", t), m, mark);
        }
        eprintln!(
            "\n  Best: t={:.2} F1={:.4} | Production: 0.77",
            best_t, best_m.f1
        );

        assert!(best_m.f1 > 0.70, "Best F1 should be >0.70");
    }

    /// Imbalanced cluster sizes: some large, some small.
    #[test]
    fn threshold_sweep_imbalanced() {
        let data = gen_variable_clusters(
            55,
            128,
            &[50, 50, 50, 5, 5, 5],
            0.08,
            "Imbalanced (128-d, sigma=0.08, sizes=[50,50,50,5,5,5])",
        );

        print_header(&data.desc);
        print_distance_stats(&data);

        let ts = thresholds(0.05, 0.80, 0.02);
        let (best_t, best_m, results) = sweep_agglom(&data, &ts);

        print_table_header();
        for (t, m) in &results {
            let mark = if (*t - best_t).abs() < 1e-6 {
                "  <- BEST"
            } else {
                ""
            };
            print_row(&format!("t={:.2}", t), m, mark);
        }
        eprintln!("\n  Best: t={:.2} F1={:.4}", best_t, best_m.f1);

        assert!(best_m.f1 > 0.80, "Best F1 should be >0.80");
    }

    /// Many small clusters — simulating a user with many different pets.
    #[test]
    fn threshold_sweep_many_small_clusters() {
        let data = gen_equal_clusters(
            13,
            128,
            15,
            5,
            0.06,
            "Many small clusters (128-d, sigma=0.06, 15x5)",
        );

        print_header(&data.desc);
        print_distance_stats(&data);

        let ts = thresholds(0.02, 0.60, 0.02);
        let (best_t, best_m, results) = sweep_agglom(&data, &ts);

        print_table_header();
        for (t, m) in &results {
            let mark = if (*t - best_t).abs() < 1e-6 {
                "  <- BEST"
            } else {
                ""
            };
            print_row(&format!("t={:.2}", t), m, mark);
        }
        eprintln!("\n  Best: t={:.2} F1={:.4}", best_t, best_m.f1);

        assert!(
            best_m.f1 > 0.80,
            "Best F1 should be >0.80 for well-separated clusters"
        );
    }

    // ══════════════════════════════════════════════════════════════════════
    // ALGORITHM COMPARISON TESTS
    // ══════════════════════════════════════════════════════════════════════

    /// Compare agglomerative (various thresholds) vs HDBSCAN (various params)
    /// on moderate-quality face embeddings.
    #[test]
    fn algo_compare_face_moderate() {
        let data = gen_equal_clusters(
            200,
            128,
            5,
            20,
            0.08,
            "Algo compare: moderate face (128-d, sigma=0.08, 5x20)",
        );

        print_header(&data.desc);
        print_distance_stats(&data);

        // Find best agglomerative threshold first
        let ts = thresholds(0.05, 0.80, 0.01);
        let (best_t, _, _) = sweep_agglom(&data, &ts);

        let n = data.embeddings.len();
        let dist = build_dist_matrix(&data.embeddings);

        print_table_header();

        // Agglomerative at key thresholds
        let agglom_ts = [0.15, 0.20, 0.24, 0.30, 0.40, best_t];
        let mut best_f1 = 0.0f64;
        let mut best_label = String::new();
        for &t in &agglom_ts {
            let pred = agglomerative_precomputed(&dist, n, t);
            let m = eval(&data.true_labels, &pred);
            let label = if (t - best_t).abs() < 1e-6 {
                format!("Agglom(t={:.2},BEST)", t)
            } else {
                format!("Agglom(t={:.2})", t)
            };
            let mark = if m.f1 > best_f1 { "  <- BEST" } else { "" };
            if m.f1 > best_f1 {
                best_f1 = m.f1;
                best_label = label.clone();
            }
            print_row(&label, &m, mark);
        }

        eprintln!("  {}", "-".repeat(92));

        // HDBSCAN with various parameters
        let hdb_params = [
            (2, 1),
            (2, 2),
            (3, 2),
            (3, 3),
            (5, 2),
            (5, 3),
            (5, 5),
        ];
        for &(mcs, ms) in &hdb_params {
            let pred = hdbscan_precomputed(&dist, n, mcs, ms);
            let m = eval(&data.true_labels, &pred);
            let label = format!("HDBSCAN(mcs={},ms={})", mcs, ms);
            let mark = if m.f1 > best_f1 { "  <- BEST" } else { "" };
            if m.f1 > best_f1 {
                best_f1 = m.f1;
                best_label = label.clone();
            }
            print_row(&label, &m, mark);
        }

        eprintln!("\n  Winner: {} (F1={:.4})", best_label, best_f1);
        assert!(best_f1 > 0.70, "At least one algorithm should achieve F1>0.70");
    }

    /// Compare algorithms on pet-quality embeddings (higher noise).
    #[test]
    fn algo_compare_pet_face() {
        let data = gen_equal_clusters(
            300,
            128,
            5,
            15,
            0.15,
            "Algo compare: pet face (128-d, sigma=0.15, 5x15)",
        );

        print_header(&data.desc);
        print_distance_stats(&data);

        let ts = thresholds(0.10, 1.10, 0.01);
        let (best_t, _, _) = sweep_agglom(&data, &ts);

        let n = data.embeddings.len();
        let dist = build_dist_matrix(&data.embeddings);

        print_table_header();

        let agglom_ts = [0.40, 0.50, 0.60, 0.70, 0.77, 0.85, 0.95, best_t];
        let mut best_f1 = 0.0f64;
        let mut best_label = String::new();
        for &t in &agglom_ts {
            let pred = agglomerative_precomputed(&dist, n, t);
            let m = eval(&data.true_labels, &pred);
            let label = if (t - best_t).abs() < 1e-6 {
                format!("Agglom(t={:.2},OPT)", t)
            } else if (t - 0.77).abs() < 1e-6 {
                format!("Agglom(t={:.2},PROD)", t)
            } else {
                format!("Agglom(t={:.2})", t)
            };
            let mark = if m.f1 > best_f1 { "  <- BEST" } else { "" };
            if m.f1 > best_f1 {
                best_f1 = m.f1;
                best_label = label.clone();
            }
            print_row(&label, &m, mark);
        }

        eprintln!("  {}", "-".repeat(92));

        let hdb_params = [(2, 1), (2, 2), (3, 2), (3, 3), (5, 2), (5, 5)];
        for &(mcs, ms) in &hdb_params {
            let pred = hdbscan_precomputed(&dist, n, mcs, ms);
            let m = eval(&data.true_labels, &pred);
            let label = format!("HDBSCAN(mcs={},ms={})", mcs, ms);
            let mark = if m.f1 > best_f1 { "  <- BEST" } else { "" };
            if m.f1 > best_f1 {
                best_f1 = m.f1;
                best_label = label.clone();
            }
            print_row(&label, &m, mark);
        }

        eprintln!("\n  Winner: {} (F1={:.4})", best_label, best_f1);
    }

    /// Compare algorithms on imbalanced cluster sizes.
    #[test]
    fn algo_compare_imbalanced() {
        let data = gen_variable_clusters(
            400,
            128,
            &[50, 50, 50, 5, 5, 3, 3],
            0.08,
            "Algo compare: imbalanced (128-d, sigma=0.08, sizes=[50,50,50,5,5,3,3])",
        );

        print_header(&data.desc);
        print_distance_stats(&data);

        let ts = thresholds(0.05, 0.80, 0.01);
        let (best_t, _, _) = sweep_agglom(&data, &ts);

        let n = data.embeddings.len();
        let dist = build_dist_matrix(&data.embeddings);

        print_table_header();

        let agglom_ts = [0.20, 0.24, 0.30, 0.40, best_t];
        let mut best_f1 = 0.0f64;
        let mut best_label = String::new();
        for &t in &agglom_ts {
            let pred = agglomerative_precomputed(&dist, n, t);
            let m = eval(&data.true_labels, &pred);
            let label = if (t - best_t).abs() < 1e-6 {
                format!("Agglom(t={:.2},OPT)", t)
            } else {
                format!("Agglom(t={:.2})", t)
            };
            let mark = if m.f1 > best_f1 { "  <- BEST" } else { "" };
            if m.f1 > best_f1 {
                best_f1 = m.f1;
                best_label = label.clone();
            }
            print_row(&label, &m, mark);
        }

        eprintln!("  {}", "-".repeat(92));

        // HDBSCAN — test with small min_cluster_size to capture small clusters
        let hdb_params = [(2, 1), (2, 2), (3, 2), (3, 3), (5, 2), (5, 3)];
        for &(mcs, ms) in &hdb_params {
            let pred = hdbscan_precomputed(&dist, n, mcs, ms);
            let m = eval(&data.true_labels, &pred);
            let label = format!("HDBSCAN(mcs={},ms={})", mcs, ms);
            let mark = if m.f1 > best_f1 { "  <- BEST" } else { "" };
            if m.f1 > best_f1 {
                best_f1 = m.f1;
                best_label = label.clone();
            }
            print_row(&label, &m, mark);
        }

        eprintln!("\n  Winner: {} (F1={:.4})", best_label, best_f1);
    }

    /// Compare algorithms on many small clusters.
    #[test]
    fn algo_compare_many_small() {
        let data = gen_equal_clusters(
            500,
            128,
            15,
            5,
            0.06,
            "Algo compare: many small (128-d, sigma=0.06, 15x5)",
        );

        print_header(&data.desc);
        print_distance_stats(&data);

        let ts = thresholds(0.02, 0.60, 0.01);
        let (best_t, _, _) = sweep_agglom(&data, &ts);

        let n = data.embeddings.len();
        let dist = build_dist_matrix(&data.embeddings);

        print_table_header();

        let agglom_ts = [0.10, 0.15, 0.20, 0.24, 0.30, best_t];
        let mut best_f1 = 0.0f64;
        let mut best_label = String::new();
        for &t in &agglom_ts {
            let pred = agglomerative_precomputed(&dist, n, t);
            let m = eval(&data.true_labels, &pred);
            let label = if (t - best_t).abs() < 1e-6 {
                format!("Agglom(t={:.2},OPT)", t)
            } else {
                format!("Agglom(t={:.2})", t)
            };
            let mark = if m.f1 > best_f1 { "  <- BEST" } else { "" };
            if m.f1 > best_f1 {
                best_f1 = m.f1;
                best_label = label.clone();
            }
            print_row(&label, &m, mark);
        }

        eprintln!("  {}", "-".repeat(92));

        let hdb_params = [(2, 1), (2, 2), (3, 1), (3, 2), (5, 2), (5, 3)];
        for &(mcs, ms) in &hdb_params {
            let pred = hdbscan_precomputed(&dist, n, mcs, ms);
            let m = eval(&data.true_labels, &pred);
            let label = format!("HDBSCAN(mcs={},ms={})", mcs, ms);
            let mark = if m.f1 > best_f1 { "  <- BEST" } else { "" };
            if m.f1 > best_f1 {
                best_f1 = m.f1;
                best_label = label.clone();
            }
            print_row(&label, &m, mark);
        }

        eprintln!("\n  Winner: {} (F1={:.4})", best_label, best_f1);
    }

    /// Compare algorithms on data with noise/outlier points.
    #[test]
    fn algo_compare_with_noise() {
        let data = gen_with_noise(
            600,
            128,
            5,
            20,
            0.08,
            15,
            "Algo compare: with noise (128-d, sigma=0.08, 5x20 + 15 noise)",
        );

        print_header(&data.desc);
        print_distance_stats(&data);

        let ts = thresholds(0.05, 0.80, 0.01);
        let (best_t, _, _) = sweep_agglom(&data, &ts);

        let n = data.embeddings.len();
        let dist = build_dist_matrix(&data.embeddings);

        print_table_header();

        let agglom_ts = [0.20, 0.24, 0.30, 0.40, best_t];
        let mut best_f1 = 0.0f64;
        let mut best_label = String::new();
        for &t in &agglom_ts {
            let pred = agglomerative_precomputed(&dist, n, t);
            let m = eval(&data.true_labels, &pred);
            let label = if (t - best_t).abs() < 1e-6 {
                format!("Agglom(t={:.2},OPT)", t)
            } else {
                format!("Agglom(t={:.2})", t)
            };
            let mark = if m.f1 > best_f1 { "  <- BEST" } else { "" };
            if m.f1 > best_f1 {
                best_f1 = m.f1;
                best_label = label.clone();
            }
            print_row(&label, &m, mark);
        }

        eprintln!("  {}", "-".repeat(92));

        // HDBSCAN should handle noise better (assigns noise points as -1)
        let hdb_params = [(2, 1), (2, 2), (3, 2), (3, 3), (5, 2), (5, 3)];
        for &(mcs, ms) in &hdb_params {
            let pred = hdbscan_precomputed(&dist, n, mcs, ms);
            let m = eval(&data.true_labels, &pred);
            let label = format!("HDBSCAN(mcs={},ms={})", mcs, ms);
            let mark = if m.f1 > best_f1 { "  <- BEST" } else { "" };
            if m.f1 > best_f1 {
                best_f1 = m.f1;
                best_label = label.clone();
            }
            print_row(&label, &m, mark);
        }

        eprintln!("\n  Winner: {} (F1={:.4})", best_label, best_f1);
        eprintln!(
            "  Note: HDBSCAN can assign noise as -1, agglomerative assigns everything."
        );
    }

    // ══════════════════════════════════════════════════════════════════════
    // FULL PET PIPELINE COMPARISON
    // ══════════════════════════════════════════════════════════════════════

    /// Compare agglomerative vs HDBSCAN in the full 3-phase pet pipeline.
    #[test]
    fn pet_pipeline_agglom_vs_hdbscan() {
        let mut rng = Rng::new(777);
        let n_clusters = 5;
        let pts_per = 12;
        let face_noise = 0.15;
        let body_noise = 0.10;

        // Generate cluster centers
        let face_centers: Vec<Vec<f32>> = (0..n_clusters)
            .map(|_| random_unit_vec(&mut rng, 128))
            .collect();
        let body_centers: Vec<Vec<f32>> = (0..n_clusters)
            .map(|_| random_unit_vec(&mut rng, 192))
            .collect();

        let mut inputs = Vec::new();
        let mut true_labels = Vec::new();
        for ci in 0..n_clusters {
            for pi in 0..pts_per {
                let face = perturbed_vec(&mut rng, &face_centers[ci], face_noise);
                let body = perturbed_vec(&mut rng, &body_centers[ci], body_noise);
                inputs.push(PetClusterInput {
                    pet_face_id: format!("pet_{ci}_{pi}"),
                    face_embedding: face,
                    body_embedding: body,
                    species: 0,
                    file_id: (ci * pts_per + pi) as i64,
                });
                true_labels.push(ci as i32);
            }
        }

        // Shuffle
        let n = inputs.len();
        let mut idx: Vec<usize> = (0..n).collect();
        rng.shuffle(&mut idx);
        let inputs: Vec<PetClusterInput> = idx.iter().map(|&i| inputs[i].clone()).collect();
        let true_labels: Vec<i32> = idx.iter().map(|&i| true_labels[i]).collect();

        print_header("Pet Pipeline: Agglomerative vs HDBSCAN (5 clusters, face+body)");
        print_table_header();

        let mut best_f1 = 0.0f64;
        let mut best_label = String::new();

        // Test agglomerative at various thresholds
        for &t in &[0.50, 0.60, 0.70, 0.77, 0.85, 0.95] {
            let mut config = ClusterConfig::dog();
            config.cluster_algorithm = ClusterAlgorithm::Agglomerative;
            config.agglomerative_threshold = t;
            let result = run_pet_clustering(&inputs, &config);

            // Map result to predicted labels
            let pred: Vec<i32> = map_pet_result(&inputs, &result);
            let m = eval(&true_labels, &pred);
            let label = if (t - 0.77).abs() < 1e-6 {
                format!("Agglom(t={:.2},PROD)", t)
            } else {
                format!("Agglom(t={:.2})", t)
            };
            let mark = if m.f1 > best_f1 { "  <- BEST" } else { "" };
            if m.f1 > best_f1 {
                best_f1 = m.f1;
                best_label = label.clone();
            }
            print_row(&label, &m, mark);
        }

        eprintln!("  {}", "-".repeat(92));

        // Test HDBSCAN with various parameters
        for &(mcs, ms) in &[(2, 1), (2, 2), (3, 2), (3, 3), (5, 2), (5, 3)] {
            let mut config = ClusterConfig::dog();
            config.cluster_algorithm = ClusterAlgorithm::Hdbscan;
            config.min_cluster_size = mcs;
            config.min_samples = ms;
            let result = run_pet_clustering(&inputs, &config);

            let pred: Vec<i32> = map_pet_result(&inputs, &result);
            let m = eval(&true_labels, &pred);
            let label = format!("HDBSCAN(mcs={},ms={})", mcs, ms);
            let mark = if m.f1 > best_f1 { "  <- BEST" } else { "" };
            if m.f1 > best_f1 {
                best_f1 = m.f1;
                best_label = label.clone();
            }
            print_row(&label, &m, mark);
        }

        eprintln!("\n  Winner: {} (F1={:.4})", best_label, best_f1);
    }

    /// Compare algorithms on a mixed modality scenario:
    /// some pets have face+body, some only face, some only body.
    #[test]
    fn pet_pipeline_mixed_modality() {
        let mut rng = Rng::new(888);
        let n_clusters = 4;
        let pts_per = 15;
        let face_noise = 0.15;
        let body_noise = 0.10;

        let face_centers: Vec<Vec<f32>> = (0..n_clusters)
            .map(|_| random_unit_vec(&mut rng, 128))
            .collect();
        let body_centers: Vec<Vec<f32>> = (0..n_clusters)
            .map(|_| random_unit_vec(&mut rng, 192))
            .collect();

        let mut inputs = Vec::new();
        let mut true_labels = Vec::new();
        for ci in 0..n_clusters {
            for pi in 0..pts_per {
                let modality = pi % 3; // 0: both, 1: face-only, 2: body-only
                let face = if modality != 2 {
                    perturbed_vec(&mut rng, &face_centers[ci], face_noise)
                } else {
                    vec![]
                };
                let body = if modality != 1 {
                    perturbed_vec(&mut rng, &body_centers[ci], body_noise)
                } else {
                    vec![]
                };
                inputs.push(PetClusterInput {
                    pet_face_id: format!("pet_{ci}_{pi}"),
                    face_embedding: face,
                    body_embedding: body,
                    species: 0,
                    file_id: (ci * pts_per + pi) as i64,
                });
                true_labels.push(ci as i32);
            }
        }

        let n = inputs.len();
        let mut idx: Vec<usize> = (0..n).collect();
        rng.shuffle(&mut idx);
        let inputs: Vec<PetClusterInput> = idx.iter().map(|&i| inputs[i].clone()).collect();
        let true_labels: Vec<i32> = idx.iter().map(|&i| true_labels[i]).collect();

        print_header("Pet Pipeline Mixed Modality: face+body / face-only / body-only");
        print_table_header();

        let mut best_f1 = 0.0f64;
        let mut best_label = String::new();

        for &t in &[0.50, 0.60, 0.70, 0.77, 0.85, 0.95] {
            let mut config = ClusterConfig::dog();
            config.cluster_algorithm = ClusterAlgorithm::Agglomerative;
            config.agglomerative_threshold = t;
            let result = run_pet_clustering(&inputs, &config);
            let pred = map_pet_result(&inputs, &result);
            let m = eval(&true_labels, &pred);
            let label = if (t - 0.77).abs() < 1e-6 {
                format!("Agglom(t={:.2},PROD)", t)
            } else {
                format!("Agglom(t={:.2})", t)
            };
            let mark = if m.f1 > best_f1 { "  <- BEST" } else { "" };
            if m.f1 > best_f1 {
                best_f1 = m.f1;
                best_label = label.clone();
            }
            print_row(&label, &m, mark);
        }

        eprintln!("  {}", "-".repeat(92));

        for &(mcs, ms) in &[(2, 1), (2, 2), (3, 2), (3, 3), (5, 2)] {
            let mut config = ClusterConfig::dog();
            config.cluster_algorithm = ClusterAlgorithm::Hdbscan;
            config.min_cluster_size = mcs;
            config.min_samples = ms;
            let result = run_pet_clustering(&inputs, &config);
            let pred = map_pet_result(&inputs, &result);
            let m = eval(&true_labels, &pred);
            let label = format!("HDBSCAN(mcs={},ms={})", mcs, ms);
            let mark = if m.f1 > best_f1 { "  <- BEST" } else { "" };
            if m.f1 > best_f1 {
                best_f1 = m.f1;
                best_label = label.clone();
            }
            print_row(&label, &m, mark);
        }

        eprintln!("\n  Winner: {} (F1={:.4})", best_label, best_f1);
    }

    // ══════════════════════════════════════════════════════════════════════
    // COMPREHENSIVE SUMMARY
    // ══════════════════════════════════════════════════════════════════════

    /// Run all scenarios and print a single summary table showing optimal
    /// thresholds for each embedding type and which algorithm wins.
    #[test]
    fn summary_optimal_thresholds() {
        print_header("SUMMARY: Optimal thresholds and algorithm recommendations");

        let scenarios: Vec<(&str, Dataset, f32)> = vec![
            (
                "Human face (high-q)",
                gen_equal_clusters(1000, 128, 5, 25, 0.04, ""),
                0.24,
            ),
            (
                "Human face (moderate)",
                gen_equal_clusters(1001, 128, 5, 25, 0.08, ""),
                0.24,
            ),
            (
                "Pet face (BYOL-like)",
                gen_equal_clusters(1002, 128, 5, 20, 0.15, ""),
                0.77,
            ),
            (
                "Pet face (noisy)",
                gen_equal_clusters(1003, 128, 5, 20, 0.20, ""),
                0.77,
            ),
            (
                "Body 192-d (moderate)",
                gen_equal_clusters(1004, 192, 5, 20, 0.10, ""),
                0.77,
            ),
            (
                "Body 192-d (noisy)",
                gen_equal_clusters(1005, 192, 5, 20, 0.15, ""),
                0.77,
            ),
            (
                "Many clusters (15)",
                gen_equal_clusters(1006, 128, 15, 5, 0.08, ""),
                0.24,
            ),
            (
                "Imbalanced",
                gen_variable_clusters(1007, 128, &[50, 50, 8, 8, 3], 0.08, ""),
                0.24,
            ),
        ];

        eprintln!(
            "  {:<24} | {:>9} | {:>7} | {:>9} | {:>7} | {:>8} | {:>7}",
            "Scenario", "Best t", "F1", "Prod t", "F1", "Best HDB", "F1"
        );
        eprintln!("  {}", "-".repeat(95));

        for (name, data, prod_t) in &scenarios {
            // Agglomerative sweep
            let ts = thresholds(0.02, 1.20, 0.01);
            let (best_t, best_m, _) = sweep_agglom(data, &ts);

            // Production threshold
            let n = data.embeddings.len();
            let dist = build_dist_matrix(&data.embeddings);
            let prod_pred = agglomerative_precomputed(&dist, n, *prod_t);
            let prod_m = eval(&data.true_labels, &prod_pred);

            // Best HDBSCAN
            let hdb_params: Vec<(usize, usize)> = vec![
                (2, 1),
                (2, 2),
                (3, 2),
                (3, 3),
                (5, 2),
                (5, 3),
                (5, 5),
            ];
            let hdb_results = sweep_hdbscan(data, &hdb_params);
            let best_hdb = hdb_results
                .iter()
                .max_by(|a, b| a.1.f1.partial_cmp(&b.1.f1).unwrap())
                .unwrap();

            let hdb_label = format!("({},{})", best_hdb.0 .0, best_hdb.0 .1);

            eprintln!(
                "  {:<24} | {:>9.2} | {:>7.4} | {:>9.2} | {:>7.4} | {:>8} | {:>7.4}",
                name,
                best_t,
                best_m.f1,
                prod_t,
                prod_m.f1,
                hdb_label,
                best_hdb.1.f1
            );
        }

        eprintln!();
        eprintln!("  Legend: Best t = optimal agglomerative threshold, Prod t = current production");
        eprintln!("  Best HDB = best HDBSCAN (min_cluster_size, min_samples)");
    }

    // ── Helper: map pet clustering result to label vector ─────────────────

    // ══════════════════════════════════════════════════════════════════════
    // MULTI-ALGORITHM COMPARISON TESTS
    // ══════════════════════════════════════════════════════════════════════

    /// Head-to-head: all 9 algorithms on high-quality face embeddings.
    #[test]
    fn multi_algo_face_high_quality() {
        let data = gen_equal_clusters(
            2000,
            128,
            5,
            20,
            0.04,
            "Multi-algo: high-quality face (128-d, sigma=0.04, 5x20)",
        );
        let configs = vec![
            AlgoConfig::AgglomAverage(0.20),
            AlgoConfig::AgglomSingle(0.15),
            AlgoConfig::AgglomComplete(0.22),
            AlgoConfig::AgglomWard(0.25),
            AlgoConfig::Hdbscan(3, 2),
            AlgoConfig::Dbscan(0.20, 3),
            AlgoConfig::SphericalKmeans(5),
            AlgoConfig::ChineseWhispers(0.80),
            AlgoConfig::Spectral(5, 0.50),
        ];
        run_algo_comparison(&data, &configs, 2000);
    }

    /// Head-to-head: all algorithms on moderate face embeddings.
    #[test]
    fn multi_algo_face_moderate() {
        let data = gen_equal_clusters(
            2001,
            128,
            5,
            20,
            0.08,
            "Multi-algo: moderate face (128-d, sigma=0.08, 5x20)",
        );
        let configs = vec![
            AlgoConfig::AgglomAverage(0.52),
            AlgoConfig::AgglomSingle(0.40),
            AlgoConfig::AgglomComplete(0.55),
            AlgoConfig::AgglomWard(0.60),
            AlgoConfig::Hdbscan(3, 2),
            AlgoConfig::Hdbscan(5, 3),
            AlgoConfig::Dbscan(0.50, 3),
            AlgoConfig::Dbscan(0.55, 4),
            AlgoConfig::SphericalKmeans(5),
            AlgoConfig::ChineseWhispers(0.55),
            AlgoConfig::ChineseWhispers(0.45),
            AlgoConfig::Spectral(5, 0.30),
        ];
        run_algo_comparison(&data, &configs, 2001);
    }

    /// Head-to-head: all algorithms on pet-quality BYOL embeddings.
    #[test]
    fn multi_algo_pet_face() {
        let data = gen_equal_clusters(
            2002,
            128,
            5,
            15,
            0.15,
            "Multi-algo: pet face BYOL (128-d, sigma=0.15, 5x15)",
        );
        let configs = vec![
            AlgoConfig::AgglomAverage(0.77),
            AlgoConfig::AgglomAverage(0.85),
            AlgoConfig::AgglomSingle(0.65),
            AlgoConfig::AgglomComplete(0.85),
            AlgoConfig::AgglomComplete(0.90),
            AlgoConfig::AgglomWard(0.90),
            AlgoConfig::Hdbscan(2, 2),
            AlgoConfig::Hdbscan(3, 2),
            AlgoConfig::Dbscan(0.75, 2),
            AlgoConfig::Dbscan(0.80, 3),
            AlgoConfig::SphericalKmeans(5),
            AlgoConfig::ChineseWhispers(0.30),
            AlgoConfig::ChineseWhispers(0.20),
            AlgoConfig::Spectral(5, 0.10),
        ];
        run_algo_comparison(&data, &configs, 2002);
    }

    /// Head-to-head: all algorithms on imbalanced clusters.
    #[test]
    fn multi_algo_imbalanced() {
        let data = gen_variable_clusters(
            2003,
            128,
            &[50, 50, 50, 8, 8, 3, 3],
            0.08,
            "Multi-algo: imbalanced (128-d, sigma=0.08, [50,50,50,8,8,3,3])",
        );
        let n_clusters = 7;
        let configs = vec![
            AlgoConfig::AgglomAverage(0.55),
            AlgoConfig::AgglomSingle(0.42),
            AlgoConfig::AgglomComplete(0.58),
            AlgoConfig::AgglomWard(0.60),
            AlgoConfig::Hdbscan(3, 2),
            AlgoConfig::Hdbscan(5, 3),
            AlgoConfig::Dbscan(0.50, 3),
            AlgoConfig::Dbscan(0.55, 2),
            AlgoConfig::SphericalKmeans(n_clusters),
            AlgoConfig::ChineseWhispers(0.50),
            AlgoConfig::Spectral(n_clusters, 0.30),
        ];
        run_algo_comparison(&data, &configs, 2003);
    }

    /// Head-to-head: all algorithms on many small clusters.
    #[test]
    fn multi_algo_many_small() {
        let data = gen_equal_clusters(
            2004,
            128,
            15,
            5,
            0.06,
            "Multi-algo: many small (128-d, sigma=0.06, 15x5)",
        );
        let configs = vec![
            AlgoConfig::AgglomAverage(0.38),
            AlgoConfig::AgglomSingle(0.30),
            AlgoConfig::AgglomComplete(0.40),
            AlgoConfig::AgglomWard(0.45),
            AlgoConfig::Hdbscan(2, 2),
            AlgoConfig::Hdbscan(3, 2),
            AlgoConfig::Dbscan(0.35, 2),
            AlgoConfig::Dbscan(0.38, 3),
            AlgoConfig::SphericalKmeans(15),
            AlgoConfig::ChineseWhispers(0.65),
            AlgoConfig::Spectral(15, 0.40),
        ];
        run_algo_comparison(&data, &configs, 2004);
    }

    /// Head-to-head: all algorithms on data with noise/outlier points.
    #[test]
    fn multi_algo_with_noise() {
        let data = gen_with_noise(
            2005,
            128,
            5,
            20,
            0.08,
            15,
            "Multi-algo: with noise (128-d, sigma=0.08, 5x20 + 15 noise)",
        );
        let configs = vec![
            AlgoConfig::AgglomAverage(0.55),
            AlgoConfig::AgglomSingle(0.42),
            AlgoConfig::AgglomComplete(0.58),
            AlgoConfig::AgglomWard(0.60),
            AlgoConfig::Hdbscan(3, 2),
            AlgoConfig::Hdbscan(5, 3),
            AlgoConfig::Dbscan(0.50, 3),
            AlgoConfig::Dbscan(0.55, 4),
            AlgoConfig::SphericalKmeans(5),
            AlgoConfig::ChineseWhispers(0.50),
            AlgoConfig::Spectral(5, 0.30),
        ];
        run_algo_comparison(&data, &configs, 2005);
    }

    /// Head-to-head: body embeddings (192-d).
    #[test]
    fn multi_algo_body_192d() {
        let data = gen_equal_clusters(
            2006,
            192,
            5,
            15,
            0.10,
            "Multi-algo: body 192-d (sigma=0.10, 5x15)",
        );
        let configs = vec![
            AlgoConfig::AgglomAverage(0.70),
            AlgoConfig::AgglomAverage(0.77),
            AlgoConfig::AgglomSingle(0.55),
            AlgoConfig::AgglomComplete(0.75),
            AlgoConfig::AgglomWard(0.80),
            AlgoConfig::Hdbscan(3, 2),
            AlgoConfig::Dbscan(0.65, 3),
            AlgoConfig::Dbscan(0.70, 2),
            AlgoConfig::SphericalKmeans(5),
            AlgoConfig::ChineseWhispers(0.35),
            AlgoConfig::Spectral(5, 0.20),
        ];
        run_algo_comparison(&data, &configs, 2006);
    }

    /// Linkage comparison: sweep all 4 linkage methods across thresholds.
    #[test]
    fn linkage_comparison_sweep() {
        let data = gen_equal_clusters(
            3000,
            128,
            5,
            20,
            0.10,
            "Linkage sweep (128-d, sigma=0.10, 5x20)",
        );

        print_header(&data.desc);
        print_distance_stats(&data);

        let n = data.embeddings.len();
        let dist = build_dist_matrix(&data.embeddings);
        let ts = thresholds(0.10, 1.00, 0.05);

        let linkages: Vec<(&str, Box<dyn Fn(&[f32], usize, f32) -> Vec<i32>>)> = vec![
            (
                "Average",
                Box::new(|d: &[f32], n: usize, t: f32| agglomerative_precomputed(d, n, t)),
            ),
            (
                "Single",
                Box::new(|d: &[f32], n: usize, t: f32| single_linkage_precomputed(d, n, t)),
            ),
            (
                "Complete",
                Box::new(|d: &[f32], n: usize, t: f32| complete_linkage_precomputed(d, n, t)),
            ),
            (
                "Ward",
                Box::new(|d: &[f32], n: usize, t: f32| ward_linkage_precomputed(d, n, t)),
            ),
        ];

        for (name, cluster_fn) in &linkages {
            eprintln!("\n  --- {} Linkage ---", name);
            eprintln!(
                "  {:<12} | {:>4} | {:>5} | {:>7} | {:>7} | {:>7} | {:>7} | {:>7}",
                "Threshold", "K", "Noise", "ARI", "NMI", "Prec", "Recall", "F1"
            );
            eprintln!("  {}", "-".repeat(80));

            let mut best_f1 = -1.0f64;
            let mut best_t = 0.0f32;
            for &t in &ts {
                let pred = cluster_fn(&dist, n, t);
                let m = eval(&data.true_labels, &pred);
                let mark = if m.f1 > best_f1 { "  <- BEST" } else { "" };
                if m.f1 > best_f1 {
                    best_f1 = m.f1;
                    best_t = t;
                }
                print_row(&format!("t={:.2}", t), &m, mark);
            }
            eprintln!("  Best: t={:.2} F1={:.4}", best_t, best_f1);
        }
    }

    /// DBSCAN parameter sweep: epsilon and min_pts.
    #[test]
    fn dbscan_parameter_sweep() {
        let data = gen_equal_clusters(
            3001,
            128,
            5,
            20,
            0.08,
            "DBSCAN sweep (128-d, sigma=0.08, 5x20)",
        );

        print_header(&data.desc);
        print_distance_stats(&data);

        let n = data.embeddings.len();
        let dist = build_dist_matrix(&data.embeddings);

        print_table_header();

        let mut best_f1 = -1.0f64;
        let mut best_label = String::new();

        let epsilons = thresholds(0.20, 0.70, 0.05);
        let min_pts_vals = [2, 3, 4, 5];

        for &eps in &epsilons {
            for &mp in &min_pts_vals {
                let pred = dbscan_precomputed(&dist, n, eps, mp);
                let m = eval(&data.true_labels, &pred);
                let label = format!("eps={:.2},mp={}", eps, mp);
                let mark = if m.f1 > best_f1 { "  <- BEST" } else { "" };
                if m.f1 > best_f1 {
                    best_f1 = m.f1;
                    best_label = label.clone();
                }
                print_row(&label, &m, mark);
            }
        }
        eprintln!("\n  Best: {} (F1={:.4})", best_label, best_f1);
    }

    /// Chinese Whispers edge threshold sweep.
    #[test]
    fn chinese_whispers_sweep() {
        let data = gen_equal_clusters(
            3002,
            128,
            5,
            20,
            0.08,
            "Chinese Whispers sweep (128-d, sigma=0.08, 5x20)",
        );

        print_header(&data.desc);
        print_distance_stats(&data);

        print_table_header();

        let mut best_f1 = -1.0f64;
        let mut best_label = String::new();

        let thresholds_cw = thresholds(0.20, 0.80, 0.05);
        for &t in &thresholds_cw {
            let mut rng = Rng::new(3002);
            let pred = chinese_whispers(&data.embeddings, t, 30, &mut rng);
            let m = eval(&data.true_labels, &pred);
            let label = format!("edge_t={:.2}", t);
            let mark = if m.f1 > best_f1 { "  <- BEST" } else { "" };
            if m.f1 > best_f1 {
                best_f1 = m.f1;
                best_label = label.clone();
            }
            print_row(&label, &m, mark);
        }
        eprintln!("\n  Best: {} (F1={:.4})", best_label, best_f1);
    }

    /// Grand summary: best config for each algorithm across all scenarios.
    #[test]
    fn grand_summary_all_algorithms() {
        let scenarios: Vec<(&str, Dataset, usize)> = vec![
            (
                "Face high-q",
                gen_equal_clusters(5000, 128, 5, 20, 0.04, ""),
                5,
            ),
            (
                "Face moderate",
                gen_equal_clusters(5001, 128, 5, 20, 0.08, ""),
                5,
            ),
            (
                "Pet BYOL",
                gen_equal_clusters(5002, 128, 5, 15, 0.15, ""),
                5,
            ),
            (
                "Body 192-d",
                gen_equal_clusters(5003, 192, 5, 15, 0.10, ""),
                5,
            ),
            (
                "Many small",
                gen_equal_clusters(5004, 128, 15, 5, 0.06, ""),
                15,
            ),
            (
                "Imbalanced",
                gen_variable_clusters(5005, 128, &[50, 50, 8, 8, 3], 0.08, ""),
                5,
            ),
        ];

        print_header("GRAND SUMMARY: Best F1 per algorithm across scenarios");
        eprintln!(
            "  {:<16} | {:>10} | {:>10} | {:>10} | {:>10} | {:>10} | {:>10} | {:>10} | {:>10} | {:>10}",
            "Scenario", "Avg-Link", "Single", "Complete", "Ward", "HDBSCAN", "DBSCAN", "Sph-KM", "ChinWhisp", "Spectral"
        );
        eprintln!("  {}", "-".repeat(126));

        for (name, data, true_k) in &scenarios {
            let n = data.embeddings.len();
            let dist = build_dist_matrix(&data.embeddings);
            let ts = thresholds(0.05, 1.20, 0.02);

            // Best agglom average
            let avg_best = ts
                .iter()
                .map(|&t| {
                    let m = eval(&data.true_labels, &agglomerative_precomputed(&dist, n, t));
                    m.f1
                })
                .fold(0.0f64, f64::max);

            // Best single linkage
            let single_best = ts
                .iter()
                .map(|&t| {
                    let m = eval(
                        &data.true_labels,
                        &single_linkage_precomputed(&dist, n, t),
                    );
                    m.f1
                })
                .fold(0.0f64, f64::max);

            // Best complete linkage
            let complete_best = ts
                .iter()
                .map(|&t| {
                    let m = eval(
                        &data.true_labels,
                        &complete_linkage_precomputed(&dist, n, t),
                    );
                    m.f1
                })
                .fold(0.0f64, f64::max);

            // Best Ward
            let ward_best = ts
                .iter()
                .map(|&t| {
                    let m = eval(&data.true_labels, &ward_linkage_precomputed(&dist, n, t));
                    m.f1
                })
                .fold(0.0f64, f64::max);

            // Best HDBSCAN
            let hdb_params = [(2, 1), (2, 2), (3, 2), (3, 3), (5, 2), (5, 3), (5, 5)];
            let hdb_best = hdb_params
                .iter()
                .map(|&(mcs, ms)| {
                    let m = eval(
                        &data.true_labels,
                        &hdbscan_precomputed(&dist, n, mcs, ms),
                    );
                    m.f1
                })
                .fold(0.0f64, f64::max);

            // Best DBSCAN
            let eps_vals = thresholds(0.10, 1.00, 0.05);
            let mut dbscan_best = 0.0f64;
            for &eps in &eps_vals {
                for &mp in &[2usize, 3, 4, 5] {
                    let m = eval(
                        &data.true_labels,
                        &dbscan_precomputed(&dist, n, eps, mp),
                    );
                    dbscan_best = dbscan_best.max(m.f1);
                }
            }

            // Spherical K-means (use true k)
            let km_labels = spherical_kmeans_best(&data.embeddings, *true_k, 5000, 10);
            let km_f1 = eval(&data.true_labels, &km_labels).f1;

            // Chinese Whispers
            let cw_thresholds = thresholds(0.10, 0.80, 0.05);
            let cw_best = cw_thresholds
                .iter()
                .map(|&t| {
                    let mut rng = Rng::new(5000);
                    let m = eval(
                        &data.true_labels,
                        &chinese_whispers(&data.embeddings, t, 30, &mut rng),
                    );
                    m.f1
                })
                .fold(0.0f64, f64::max);

            // Spectral
            let spec_thresholds = [0.10, 0.20, 0.30, 0.40, 0.50];
            let spec_best = spec_thresholds
                .iter()
                .map(|&t| {
                    let m = eval(
                        &data.true_labels,
                        &spectral_clustering(&data.embeddings, *true_k, t, 5000),
                    );
                    m.f1
                })
                .fold(0.0f64, f64::max);

            eprintln!(
                "  {:<16} | {:>10.4} | {:>10.4} | {:>10.4} | {:>10.4} | {:>10.4} | {:>10.4} | {:>10.4} | {:>10.4} | {:>10.4}",
                name, avg_best, single_best, complete_best, ward_best,
                hdb_best, dbscan_best, km_f1, cw_best, spec_best
            );
        }

        eprintln!();
        eprintln!("  Note: K-means and Spectral use ground-truth k. Others auto-detect.");
        eprintln!("  Higher F1 = better. 1.0 = perfect clustering.");
    }

    // ── Helper: map pet clustering result to label vector ─────────────────

    fn map_pet_result(inputs: &[PetClusterInput], result: &crate::ml::pet::cluster::PetClusterResult) -> Vec<i32> {
        // Build cluster_id -> numeric label mapping
        let mut cluster_to_num: HashMap<String, i32> = HashMap::new();
        let mut next = 0i32;

        inputs
            .iter()
            .map(|inp| {
                if let Some(cid) = result.face_to_cluster.get(&inp.pet_face_id) {
                    let num = *cluster_to_num.entry(cid.clone()).or_insert_with(|| {
                        let n = next;
                        next += 1;
                        n
                    });
                    num
                } else {
                    -1
                }
            })
            .collect()
    }

    // ══════════════════════════════════════════════════════════════════════
    // DETAILED CLUSTER INSPECTION
    // ══════════════════════════════════════════════════════════════════════

    /// Named dataset: each point has a human-readable name and a true group.
    struct NamedDataset {
        names: Vec<String>,
        group_names: Vec<String>,
        embeddings: Vec<Vec<f32>>,
        true_labels: Vec<i32>,
        desc: String,
    }

    fn gen_named_clusters(
        seed: u64,
        dim: usize,
        group_names: &[&str],
        sizes: &[usize],
        noise_std: f32,
        desc: &str,
    ) -> NamedDataset {
        let mut rng = Rng::new(seed);
        let centers: Vec<Vec<f32>> = (0..group_names.len())
            .map(|_| random_unit_vec(&mut rng, dim))
            .collect();

        let mut names = Vec::new();
        let mut embeddings = Vec::new();
        let mut true_labels = Vec::new();
        let gnames: Vec<String> = group_names.iter().map(|s| s.to_string()).collect();

        for (gi, (&sz, center)) in sizes.iter().zip(centers.iter()).enumerate() {
            for pi in 0..sz {
                names.push(format!("{}_{:02}", group_names[gi], pi + 1));
                embeddings.push(perturbed_vec(&mut rng, center, noise_std));
                true_labels.push(gi as i32);
            }
        }

        // Shuffle
        let n = embeddings.len();
        let mut idx: Vec<usize> = (0..n).collect();
        rng.shuffle(&mut idx);

        NamedDataset {
            names: idx.iter().map(|&i| names[i].clone()).collect(),
            group_names: gnames,
            embeddings: idx.iter().map(|&i| embeddings[i].clone()).collect(),
            true_labels: idx.iter().map(|&i| true_labels[i]).collect(),
            desc: desc.to_string(),
        }
    }

    fn gen_named_with_noise(
        seed: u64,
        dim: usize,
        group_names: &[&str],
        sizes: &[usize],
        noise_std: f32,
        n_noise: usize,
        desc: &str,
    ) -> NamedDataset {
        let mut rng = Rng::new(seed);
        let centers: Vec<Vec<f32>> = (0..group_names.len())
            .map(|_| random_unit_vec(&mut rng, dim))
            .collect();

        let mut names = Vec::new();
        let mut embeddings = Vec::new();
        let mut true_labels = Vec::new();
        let mut gnames: Vec<String> = group_names.iter().map(|s| s.to_string()).collect();
        gnames.push("NOISE".to_string());

        for (gi, (&sz, center)) in sizes.iter().zip(centers.iter()).enumerate() {
            for pi in 0..sz {
                names.push(format!("{}_{:02}", group_names[gi], pi + 1));
                embeddings.push(perturbed_vec(&mut rng, center, noise_std));
                true_labels.push(gi as i32);
            }
        }
        let noise_label = group_names.len() as i32;
        for pi in 0..n_noise {
            names.push(format!("noise_{:02}", pi + 1));
            embeddings.push(random_unit_vec(&mut rng, dim));
            true_labels.push(noise_label);
        }

        let n = embeddings.len();
        let mut idx: Vec<usize> = (0..n).collect();
        rng.shuffle(&mut idx);

        NamedDataset {
            names: idx.iter().map(|&i| names[i].clone()).collect(),
            group_names: gnames,
            embeddings: idx.iter().map(|&i| embeddings[i].clone()).collect(),
            true_labels: idx.iter().map(|&i| true_labels[i]).collect(),
            desc: desc.to_string(),
        }
    }

    /// Compute per-cluster centroids from predicted labels.
    fn compute_centroids(embs: &[Vec<f32>], labels: &[i32]) -> HashMap<i32, Vec<f32>> {
        let dim = embs[0].len();
        let mut centroids: HashMap<i32, Vec<f32>> = HashMap::new();
        let mut counts: HashMap<i32, usize> = HashMap::new();

        for (i, emb) in embs.iter().enumerate() {
            if labels[i] < 0 {
                continue;
            }
            let c = centroids.entry(labels[i]).or_insert_with(|| vec![0.0f32; dim]);
            for (d, &v) in c.iter_mut().zip(emb.iter()) {
                *d += v;
            }
            *counts.entry(labels[i]).or_default() += 1;
        }

        for (label, c) in centroids.iter_mut() {
            let n = counts[label] as f32;
            for v in c.iter_mut() {
                *v /= n;
            }
            normalize(c);
        }
        centroids
    }

    /// Full inspection of one algorithm's result on a named dataset.
    fn inspect_clustering(
        data: &NamedDataset,
        pred_labels: &[i32],
        algo_name: &str,
    ) {
        let n = data.embeddings.len();
        let centroids = compute_centroids(&data.embeddings, pred_labels);

        // Build true-group centroids for distance analysis
        let true_centroids = compute_centroids(&data.embeddings, &data.true_labels);

        // Count unique predicted clusters
        let mut pred_clusters: Vec<i32> = pred_labels.iter().copied()
            .filter(|&l| l >= 0)
            .collect::<std::collections::HashSet<_>>()
            .into_iter().collect();
        pred_clusters.sort();

        let n_noise = pred_labels.iter().filter(|&&l| l < 0).count();
        let _n_correct: usize = (0..n)
            .filter(|&i| pred_labels[i] >= 0 && data.true_labels[i] >= 0)
            .count();

        eprintln!("\n  ┌─────────────────────────────────────────────────────────────────────────────────┐");
        eprintln!("  │ INSPECTION: {:<66}│", algo_name);
        eprintln!("  │ Dataset: {:<69}│", data.desc);
        eprintln!("  └─────────────────────────────────────────────────────────────────────────────────┘");

        // ── Per-cluster breakdown ──
        eprintln!("\n  --- Per-Cluster Members ---");

        // Map: for each predicted cluster, find the majority true label
        let mut cluster_majority: HashMap<i32, i32> = HashMap::new();
        for &pc in &pred_clusters {
            let mut true_counts: HashMap<i32, usize> = HashMap::new();
            for i in 0..n {
                if pred_labels[i] == pc {
                    *true_counts.entry(data.true_labels[i]).or_default() += 1;
                }
            }
            let (&maj_label, _) = true_counts.iter()
                .max_by_key(|(_, c)| **c).unwrap();
            cluster_majority.insert(pc, maj_label);
        }

        let mut total_correct = 0usize;
        let mut total_assigned = 0usize;
        let mut errors: Vec<(String, String, String, f32, f32)> = Vec::new(); // (name, true_group, assigned_cluster_group, dist_to_assigned, dist_to_correct)

        for &pc in &pred_clusters {
            let members: Vec<usize> = (0..n).filter(|&i| pred_labels[i] == pc).collect();
            let majority_true = cluster_majority[&pc];
            let majority_name = &data.group_names[majority_true as usize];

            // Compute purity
            let correct_count = members.iter()
                .filter(|&&i| data.true_labels[i] == majority_true)
                .count();
            let purity = correct_count as f64 / members.len() as f64;

            eprintln!("\n  Cluster {} (size={}, majority={}, purity={:.1}%):",
                pc, members.len(), majority_name, purity * 100.0);

            for &i in &members {
                let true_group = &data.group_names[data.true_labels[i] as usize];
                let is_correct = data.true_labels[i] == majority_true;
                let mark = if is_correct { "OK" } else { "XX" };

                // Distance to assigned cluster centroid
                let dist_assigned = if let Some(c) = centroids.get(&pc) {
                    1.0 - dot(&data.embeddings[i], c)
                } else {
                    f32::NAN
                };

                // Distance to true group centroid
                let dist_true = if let Some(c) = true_centroids.get(&data.true_labels[i]) {
                    1.0 - dot(&data.embeddings[i], c)
                } else {
                    f32::NAN
                };

                eprintln!("    [{}] {:<16} true={:<8} dist_to_here={:.4}  dist_to_own={:.4}",
                    mark, data.names[i], true_group, dist_assigned, dist_true);

                if is_correct {
                    total_correct += 1;
                } else {
                    errors.push((
                        data.names[i].clone(),
                        true_group.to_string(),
                        majority_name.to_string(),
                        dist_assigned,
                        dist_true,
                    ));
                }
                total_assigned += 1;
            }
        }

        // ── Unclustered points ──
        let unclustered: Vec<usize> = (0..n).filter(|&i| pred_labels[i] < 0).collect();
        if !unclustered.is_empty() {
            eprintln!("\n  UNCLUSTERED ({} points):", unclustered.len());
            for &i in &unclustered {
                let true_group = &data.group_names[data.true_labels[i] as usize];
                // Find nearest predicted cluster
                let mut nearest_cluster = -1i32;
                let mut nearest_dist = f32::INFINITY;
                for (&pc, centroid) in &centroids {
                    let d = 1.0 - dot(&data.embeddings[i], centroid);
                    if d < nearest_dist {
                        nearest_dist = d;
                        nearest_cluster = pc;
                    }
                }
                let nearest_name = if nearest_cluster >= 0 {
                    let maj = cluster_majority[&nearest_cluster];
                    data.group_names[maj as usize].as_str()
                } else {
                    "none"
                };
                eprintln!("    [--] {:<16} true={:<8} nearest_cluster={} ({}) dist={:.4}",
                    data.names[i], true_group, nearest_cluster, nearest_name, nearest_dist);
            }
        }

        // ── Confusion matrix ──
        let n_true_groups = data.group_names.len();
        let _n_pred_clusters = pred_clusters.len();

        eprintln!("\n  --- Confusion Matrix (rows=true, cols=predicted) ---");
        eprint!("  {:<10}", "");
        for &pc in &pred_clusters {
            let maj = cluster_majority[&pc];
            eprint!("  C{}({})", pc, &data.group_names[maj as usize][..std::cmp::min(3, data.group_names[maj as usize].len())]);
        }
        if n_noise > 0 {
            eprint!("  Noise");
        }
        eprintln!();

        for gi in 0..n_true_groups {
            eprint!("  {:<10}", &data.group_names[gi]);
            for &pc in &pred_clusters {
                let count = (0..n)
                    .filter(|&i| data.true_labels[i] == gi as i32 && pred_labels[i] == pc)
                    .count();
                eprint!("  {:>6}", count);
            }
            if n_noise > 0 {
                let noise_count = (0..n)
                    .filter(|&i| data.true_labels[i] == gi as i32 && pred_labels[i] < 0)
                    .count();
                eprint!("  {:>5}", noise_count);
            }
            eprintln!();
        }

        // ── Error analysis ──
        if !errors.is_empty() {
            eprintln!("\n  --- Error Analysis ({} misassigned) ---", errors.len());
            for (name, true_g, assigned_g, d_assigned, d_true) in &errors {
                let reason = if d_assigned < d_true {
                    "closer to wrong cluster"
                } else {
                    "farther from wrong cluster (linkage artifact)"
                };
                eprintln!("    {:<16} true={:<8} placed_in={:<8} d_here={:.4} d_own={:.4} ({})",
                    name, true_g, assigned_g, d_assigned, d_true, reason);
            }
        }

        // ── Unclustered error analysis (points that should be in a cluster but aren't) ──
        let unclustered_real: Vec<usize> = unclustered.iter().copied()
            .filter(|&i| {
                let tl = data.true_labels[i];
                // Is this a point from a real group (not noise)?
                tl < data.group_names.len() as i32 - 1
                    || !data.group_names.last().map(|s| s == "NOISE").unwrap_or(false)
            })
            .collect();

        let has_noise_group = data.group_names.last().map(|s| s == "NOISE").unwrap_or(false);
        if !unclustered_real.is_empty() && has_noise_group {
            let real_missed: Vec<usize> = unclustered.iter().copied()
                .filter(|&i| data.true_labels[i] < (data.group_names.len() - 1) as i32)
                .collect();
            let noise_caught: Vec<usize> = unclustered.iter().copied()
                .filter(|&i| data.true_labels[i] == (data.group_names.len() - 1) as i32)
                .collect();
            if !real_missed.is_empty() {
                eprintln!("\n  --- Real points incorrectly unclustered: {} ---", real_missed.len());
            }
            if !noise_caught.is_empty() {
                eprintln!("  --- Noise correctly identified: {}/{} ---", noise_caught.len(), n_noise);
            }
        }

        // ── Summary ──
        let accuracy = if total_assigned > 0 {
            total_correct as f64 / total_assigned as f64
        } else {
            0.0
        };

        let m = eval(&data.true_labels, pred_labels);

        eprintln!("\n  --- Summary ---");
        eprintln!("  Assigned: {}/{}  Correct: {}  Errors: {}  Unclustered: {}",
            total_assigned, n, total_correct, errors.len(), unclustered.len());
        eprintln!("  Cluster accuracy: {:.1}%  ({}/{} assigned to majority-correct cluster)",
            accuracy * 100.0, total_correct, total_assigned);
        eprintln!("  ARI={:.4}  NMI={:.4}  Pairwise-P={:.4}  Pairwise-R={:.4}  F1={:.4}",
            m.ari, m.nmi, m.precision, m.recall, m.f1);
        eprintln!("  Predicted {} clusters (true: {})", pred_clusters.len(),
            data.group_names.len() - if has_noise_group { 1 } else { 0 });
    }

    // ══════════════════════════════════════════════════════════════════════
    // INSPECTION TEST 1: Pet-quality embeddings (the hard case)
    // ══════════════════════════════════════════════════════════════════════

    #[test]
    fn inspect_pet_face_all_algos() {
        let data = gen_named_clusters(
            9000, 128,
            &["Buddy", "Luna", "Max", "Bella", "Charlie"],
            &[12, 12, 12, 12, 12],
            0.15,
            "5 pets, 12 photos each, BYOL-quality (sigma=0.15)",
        );

        let n = data.embeddings.len();
        let dist = build_dist_matrix(&data.embeddings);

        eprintln!("\n{}", "=".repeat(90));
        eprintln!("  MANUAL INSPECTION: Pet Face Clustering (BYOL-like, sigma=0.15)");
        eprintln!("  5 pets x 12 photos = 60 points, 128-d embeddings");
        eprintln!("{}", "=".repeat(90));

        // Print distance stats
        print_distance_stats(&Dataset {
            embeddings: data.embeddings.clone(),
            true_labels: data.true_labels.clone(),
            desc: String::new(),
        });

        // Run each candidate algorithm
        let configs: Vec<(&str, Vec<i32>)> = vec![
            ("Agglom-Avg t=0.77 (PROD)", agglomerative_precomputed(&dist, n, 0.77)),
            ("Agglom-Avg t=0.85", agglomerative_precomputed(&dist, n, 0.85)),
            ("Agglom-Avg t=0.90", agglomerative_precomputed(&dist, n, 0.90)),
            ("Agglom-Complete t=0.90", complete_linkage_precomputed(&dist, n, 0.90)),
            ("Agglom-Single t=0.65", single_linkage_precomputed(&dist, n, 0.65)),
            ("Agglom-Ward t=0.90", ward_linkage_precomputed(&dist, n, 0.90)),
            ("DBSCAN eps=0.80 mp=2", dbscan_precomputed(&dist, n, 0.80, 2)),
            ("DBSCAN eps=0.85 mp=3", dbscan_precomputed(&dist, n, 0.85, 3)),
            ("Chinese Whispers t=0.25", {
                let mut rng = Rng::new(9000);
                chinese_whispers(&data.embeddings, 0.25, 30, &mut rng)
            }),
            ("Sph-KMeans k=5", spherical_kmeans_best(&data.embeddings, 5, 9000, 10)),
        ];

        for (name, pred) in &configs {
            inspect_clustering(&data, pred, name);
        }

        // Print final comparison table
        eprintln!("\n  ┌─────────────────────────────────────────────────────────────────┐");
        eprintln!("  │ FINAL COMPARISON                                                │");
        eprintln!("  └─────────────────────────────────────────────────────────────────┘");
        eprintln!("  {:<30} | {:>4} | {:>5} | {:>6} | {:>7} | {:>7}",
            "Algorithm", "K", "Noise", "Acc%", "ARI", "F1");
        eprintln!("  {}", "-".repeat(75));

        for (name, pred) in &configs {
            let m = eval(&data.true_labels, pred);
            let assigned: usize = pred.iter().filter(|&&l| l >= 0).count();
            let correct = count_majority_correct(&data.true_labels, pred);
            let acc = if assigned > 0 { correct as f64 / assigned as f64 * 100.0 } else { 0.0 };
            eprintln!("  {:<30} | {:>4} | {:>5} | {:>5.1} | {:>7.4} | {:>7.4}",
                name, m.n_clusters, m.n_noise, acc, m.ari, m.f1);
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    // INSPECTION TEST 2: Imbalanced clusters
    // ══════════════════════════════════════════════════════════════════════

    #[test]
    fn inspect_imbalanced_all_algos() {
        let data = gen_named_clusters(
            9001, 128,
            &["DogA", "DogB", "CatX", "CatY", "Hamster"],
            &[30, 30, 8, 8, 3],
            0.08,
            "Imbalanced: 2 dogs(30), 2 cats(8), 1 hamster(3)",
        );

        let n = data.embeddings.len();
        let dist = build_dist_matrix(&data.embeddings);

        eprintln!("\n{}", "=".repeat(90));
        eprintln!("  MANUAL INSPECTION: Imbalanced Clusters");
        eprintln!("  DogA(30) + DogB(30) + CatX(8) + CatY(8) + Hamster(3) = 79 points");
        eprintln!("{}", "=".repeat(90));

        print_distance_stats(&Dataset {
            embeddings: data.embeddings.clone(),
            true_labels: data.true_labels.clone(),
            desc: String::new(),
        });

        let configs: Vec<(&str, Vec<i32>)> = vec![
            ("Agglom-Avg t=0.50", agglomerative_precomputed(&dist, n, 0.50)),
            ("Agglom-Avg t=0.55", agglomerative_precomputed(&dist, n, 0.55)),
            ("Agglom-Complete t=0.60", complete_linkage_precomputed(&dist, n, 0.60)),
            ("DBSCAN eps=0.50 mp=2", dbscan_precomputed(&dist, n, 0.50, 2)),
            ("DBSCAN eps=0.55 mp=3", dbscan_precomputed(&dist, n, 0.55, 3)),
            ("Chinese Whispers t=0.50", {
                let mut rng = Rng::new(9001);
                chinese_whispers(&data.embeddings, 0.50, 30, &mut rng)
            }),
            ("Sph-KMeans k=5", spherical_kmeans_best(&data.embeddings, 5, 9001, 10)),
        ];

        for (name, pred) in &configs {
            inspect_clustering(&data, pred, name);
        }

        eprintln!("\n  ┌─────────────────────────────────────────────────────────────────┐");
        eprintln!("  │ FINAL COMPARISON                                                │");
        eprintln!("  └─────────────────────────────────────────────────────────────────┘");
        eprintln!("  {:<30} | {:>4} | {:>5} | {:>6} | {:>7} | {:>7}",
            "Algorithm", "K", "Noise", "Acc%", "ARI", "F1");
        eprintln!("  {}", "-".repeat(75));

        for (name, pred) in &configs {
            let m = eval(&data.true_labels, pred);
            let assigned: usize = pred.iter().filter(|&&l| l >= 0).count();
            let correct = count_majority_correct(&data.true_labels, pred);
            let acc = if assigned > 0 { correct as f64 / assigned as f64 * 100.0 } else { 0.0 };
            eprintln!("  {:<30} | {:>4} | {:>5} | {:>5.1} | {:>7.4} | {:>7.4}",
                name, m.n_clusters, m.n_noise, acc, m.ari, m.f1);
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    // INSPECTION TEST 3: Data with noise/outliers
    // ══════════════════════════════════════════════════════════════════════

    #[test]
    fn inspect_with_noise_all_algos() {
        let data = gen_named_with_noise(
            9002, 128,
            &["Buddy", "Luna", "Max"],
            &[15, 15, 15],
            0.08,
            10,
            "3 pets(15 each) + 10 noise, sigma=0.08",
        );

        let n = data.embeddings.len();
        let dist = build_dist_matrix(&data.embeddings);

        eprintln!("\n{}", "=".repeat(90));
        eprintln!("  MANUAL INSPECTION: Clustering with Noise/Outliers");
        eprintln!("  Buddy(15) + Luna(15) + Max(15) + 10 noise = 55 points");
        eprintln!("{}", "=".repeat(90));

        // Only show distance stats for real points
        print_distance_stats(&Dataset {
            embeddings: data.embeddings.clone(),
            true_labels: data.true_labels.clone(),
            desc: String::new(),
        });

        let configs: Vec<(&str, Vec<i32>)> = vec![
            ("Agglom-Avg t=0.50", agglomerative_precomputed(&dist, n, 0.50)),
            ("Agglom-Avg t=0.55", agglomerative_precomputed(&dist, n, 0.55)),
            ("DBSCAN eps=0.45 mp=3", dbscan_precomputed(&dist, n, 0.45, 3)),
            ("DBSCAN eps=0.50 mp=3", dbscan_precomputed(&dist, n, 0.50, 3)),
            ("DBSCAN eps=0.50 mp=4", dbscan_precomputed(&dist, n, 0.50, 4)),
            ("Chinese Whispers t=0.50", {
                let mut rng = Rng::new(9002);
                chinese_whispers(&data.embeddings, 0.50, 30, &mut rng)
            }),
            ("Sph-KMeans k=3", spherical_kmeans_best(&data.embeddings, 3, 9002, 10)),
        ];

        for (name, pred) in &configs {
            inspect_clustering(&data, pred, name);
        }

        eprintln!("\n  ┌─────────────────────────────────────────────────────────────────┐");
        eprintln!("  │ FINAL COMPARISON                                                │");
        eprintln!("  └─────────────────────────────────────────────────────────────────┘");
        eprintln!("  {:<30} | {:>4} | {:>5} | {:>6} | {:>7} | {:>7}",
            "Algorithm", "K", "Noise", "Acc%", "ARI", "F1");
        eprintln!("  {}", "-".repeat(75));

        for (name, pred) in &configs {
            let m = eval(&data.true_labels, pred);
            let assigned: usize = pred.iter().filter(|&&l| l >= 0).count();
            let correct = count_majority_correct(&data.true_labels, pred);
            let acc = if assigned > 0 { correct as f64 / assigned as f64 * 100.0 } else { 0.0 };
            eprintln!("  {:<30} | {:>4} | {:>5} | {:>5.1} | {:>7.4} | {:>7.4}",
                name, m.n_clusters, m.n_noise, acc, m.ari, m.f1);
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    // INSPECTION TEST 4: Hardest case — overlapping pet embeddings
    // ══════════════════════════════════════════════════════════════════════

    #[test]
    fn inspect_hard_overlap() {
        let data = gen_named_clusters(
            9003, 128,
            &["Buddy", "Luna", "Max", "Bella"],
            &[10, 10, 10, 10],
            0.20,
            "4 pets, 10 photos each, HIGH noise (sigma=0.20)",
        );

        let n = data.embeddings.len();
        let dist = build_dist_matrix(&data.embeddings);

        eprintln!("\n{}", "=".repeat(90));
        eprintln!("  MANUAL INSPECTION: Hard Overlapping Clusters (sigma=0.20)");
        eprintln!("  4 pets x 10 photos = 40 points");
        eprintln!("{}", "=".repeat(90));

        print_distance_stats(&Dataset {
            embeddings: data.embeddings.clone(),
            true_labels: data.true_labels.clone(),
            desc: String::new(),
        });

        // Sweep to find best threshold for each linkage
        let ts = thresholds(0.30, 1.10, 0.01);
        let best_avg_t = ts.iter().copied()
            .max_by(|&a, &b| {
                let ma = eval(&data.true_labels, &agglomerative_precomputed(&dist, n, a));
                let mb = eval(&data.true_labels, &agglomerative_precomputed(&dist, n, b));
                ma.f1.partial_cmp(&mb.f1).unwrap()
            }).unwrap();
        let best_complete_t = ts.iter().copied()
            .max_by(|&a, &b| {
                let ma = eval(&data.true_labels, &complete_linkage_precomputed(&dist, n, a));
                let mb = eval(&data.true_labels, &complete_linkage_precomputed(&dist, n, b));
                ma.f1.partial_cmp(&mb.f1).unwrap()
            }).unwrap();

        let avg_opt_name = format!("Agglom-Avg t={:.2} (OPT)", best_avg_t);
        let complete_opt_name = format!("Agglom-Complete t={:.2} (OPT)", best_complete_t);

        let configs: Vec<(&str, Vec<i32>)> = vec![
            ("Agglom-Avg t=0.77 (PROD)", agglomerative_precomputed(&dist, n, 0.77)),
            (&avg_opt_name, agglomerative_precomputed(&dist, n, best_avg_t)),
            (&complete_opt_name, complete_linkage_precomputed(&dist, n, best_complete_t)),
            ("DBSCAN eps=0.75 mp=2", dbscan_precomputed(&dist, n, 0.75, 2)),
            ("DBSCAN eps=0.80 mp=2", dbscan_precomputed(&dist, n, 0.80, 2)),
            ("Chinese Whispers t=0.20", {
                let mut rng = Rng::new(9003);
                chinese_whispers(&data.embeddings, 0.20, 30, &mut rng)
            }),
            ("Sph-KMeans k=4", spherical_kmeans_best(&data.embeddings, 4, 9003, 10)),
        ];

        for (name, pred) in &configs {
            inspect_clustering(&data, pred, name);
        }

        eprintln!("\n  ┌─────────────────────────────────────────────────────────────────┐");
        eprintln!("  │ FINAL COMPARISON                                                │");
        eprintln!("  └─────────────────────────────────────────────────────────────────┘");
        eprintln!("  {:<35} | {:>4} | {:>5} | {:>6} | {:>7} | {:>7}",
            "Algorithm", "K", "Noise", "Acc%", "ARI", "F1");
        eprintln!("  {}", "-".repeat(80));

        for (name, pred) in &configs {
            let m = eval(&data.true_labels, pred);
            let assigned: usize = pred.iter().filter(|&&l| l >= 0).count();
            let correct = count_majority_correct(&data.true_labels, pred);
            let acc = if assigned > 0 { correct as f64 / assigned as f64 * 100.0 } else { 0.0 };
            eprintln!("  {:<35} | {:>4} | {:>5} | {:>5.1} | {:>7.4} | {:>7.4}",
                name, m.n_clusters, m.n_noise, acc, m.ari, m.f1);
        }
    }

    /// Count how many points are assigned to a cluster whose majority matches their true label.
    fn count_majority_correct(true_labels: &[i32], pred_labels: &[i32]) -> usize {
        let n = true_labels.len();
        // For each predicted cluster, find its majority true label
        let mut cluster_members: HashMap<i32, Vec<usize>> = HashMap::new();
        for i in 0..n {
            if pred_labels[i] >= 0 {
                cluster_members.entry(pred_labels[i]).or_default().push(i);
            }
        }

        let mut correct = 0usize;
        for (_, members) in &cluster_members {
            let mut counts: HashMap<i32, usize> = HashMap::new();
            for &i in members {
                *counts.entry(true_labels[i]).or_default() += 1;
            }
            let max_count = counts.values().copied().max().unwrap_or(0);
            correct += max_count;
        }
        correct
    }
}

//! Real-image clustering test.
//!
//! Loads actual pet face crops from disk, runs the ONNX embedding model,
//! then clusters the embeddings at multiple thresholds to find the optimal one.
//!
//! Expects:
//!   - Pre-cropped 224x224 RGB images in ~/Downloads/test_mix/
//!   - Naming: `{group}__{id}.png` where group is ground truth (00, 01, ...)
//!   - Dog face embedding model at ~/Downloads/models/dog_face_embedding128.onnx
//!
//! Run: `cargo test cluster_realimages -- --nocapture`

#[cfg(test)]
mod tests {
    use crate::ml::cluster::{agglomerative_precomputed, dot};
    use crate::ml::onnx;
    use crate::ml::pet::cluster::{
        run_pet_clustering, ClusterConfig, PetClusterInput,
    };
    use crate::ml::runtime::ExecutionProviderPolicy;
    use std::collections::HashMap;
    use std::path::Path;

    const TEST_MIX_DIR: &str = concat!(env!("HOME"), "/Downloads/test_mix");
    const DOG_FACE_MODEL: &str =
        concat!(env!("HOME"), "/Downloads/models/dog_face_embedding128.onnx");
    const CAT_FACE_MODEL: &str =
        concat!(env!("HOME"), "/Downloads/models/cat_face_embedding128.onnx");

    // ImageNet normalization
    const MEAN: [f32; 3] = [0.485, 0.456, 0.406];
    const STD: [f32; 3] = [0.229, 0.224, 0.225];

    struct ImageEntry {
        path: String,
        filename: String,
        group: String,
    }

    fn load_test_images() -> Option<Vec<ImageEntry>> {
        let dir = Path::new(TEST_MIX_DIR);
        if !dir.exists() {
            return None;
        }

        let mut entries: Vec<ImageEntry> = Vec::new();
        for entry in std::fs::read_dir(dir).ok()? {
            let entry = entry.ok()?;
            let filename = entry.file_name().to_string_lossy().to_string();
            if !filename.ends_with(".png") && !filename.ends_with(".jpg") {
                continue;
            }

            // Parse group from filename: "02__059359.png" -> group "02"
            // Files like "00.png" (no __) are group exemplars
            let group = if filename.contains("__") {
                filename.split("__").next().unwrap_or("unknown").to_string()
            } else {
                filename.split('.').next().unwrap_or("unknown").to_string()
            };

            entries.push(ImageEntry {
                path: entry.path().to_string_lossy().to_string(),
                filename,
                group,
            });
        }

        entries.sort_by(|a, b| a.filename.cmp(&b.filename));
        if entries.is_empty() {
            None
        } else {
            Some(entries)
        }
    }

    /// Load a 224x224 PNG/JPG, return ImageNet-normalized CHW f32 tensor.
    fn preprocess_image(path: &str) -> Option<Vec<f32>> {
        let img = image::open(path).ok()?.to_rgb8();
        let (w, h) = img.dimensions();

        // Resize to 224x224 if needed
        let img = if w != 224 || h != 224 {
            image::imageops::resize(&img, 224, 224, image::imageops::FilterType::Triangle)
        } else {
            img
        };

        let pixels = img.as_raw();
        let size = 224usize;
        let pixel_count = size * size;
        let mut output = vec![0.0f32; 3 * pixel_count];

        for y in 0..size {
            for x in 0..size {
                let src = (y * size + x) * 3;
                let dst = y * size + x;
                output[dst] = (pixels[src] as f32 / 255.0 - MEAN[0]) / STD[0];
                output[pixel_count + dst] = (pixels[src + 1] as f32 / 255.0 - MEAN[1]) / STD[1];
                output[2 * pixel_count + dst] = (pixels[src + 2] as f32 / 255.0 - MEAN[2]) / STD[2];
            }
        }

        Some(output)
    }

    fn normalize_embedding(emb: &mut [f32]) {
        let norm: f32 = emb.iter().map(|x| x * x).sum::<f32>().sqrt();
        if norm > 1e-12 {
            for x in emb.iter_mut() {
                *x /= norm;
            }
        }
    }

    /// Run the embedding model on a batch of preprocessed images.
    fn embed_batch(session: &ort::Session, images: &[Vec<f32>]) -> Vec<Vec<f32>> {
        let n = images.len();
        if n == 0 {
            return vec![];
        }
        let per_image = 3 * 224 * 224;
        let mut input = Vec::with_capacity(n * per_image);
        for img in images {
            input.extend_from_slice(img);
        }

        let (shape, output) = onnx::run_f32(session, input, [n as i64, 3, 224, 224])
            .expect("ONNX inference failed");

        let batch = shape[0] as usize;
        let emb_size = output.len() / batch;
        let mut embeddings = Vec::with_capacity(batch);
        for i in 0..batch {
            let mut emb = output[i * emb_size..(i + 1) * emb_size].to_vec();
            normalize_embedding(&mut emb);
            embeddings.push(emb);
        }
        embeddings
    }

    // ── Metrics ───────────────────────────────────────────────────────────

    fn eval_pairwise(true_labels: &[i32], pred_labels: &[i32]) -> (f64, f64, f64, usize, usize) {
        let n = true_labels.len();
        let valid: Vec<usize> = (0..n)
            .filter(|&i| pred_labels[i] >= 0 && true_labels[i] >= 0)
            .collect();
        let nv = valid.len();
        let n_noise = pred_labels.iter().filter(|&&l| l < 0).count();
        let n_clusters = {
            let mut s = std::collections::HashSet::new();
            for &i in &valid {
                s.insert(pred_labels[i]);
            }
            s.len()
        };

        if nv < 2 {
            return (0.0, 0.0, 0.0, n_clusters, n_noise);
        }

        let (mut tp, mut fp, mut fn_) = (0u64, 0u64, 0u64);
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
                    _ => {}
                }
            }
        }

        let prec = if tp + fp > 0 { tp as f64 / (tp + fp) as f64 } else { 0.0 };
        let recall = if tp + fn_ > 0 { tp as f64 / (tp + fn_) as f64 } else { 0.0 };
        let f1 = if prec + recall > 0.0 { 2.0 * prec * recall / (prec + recall) } else { 0.0 };
        (prec, recall, f1, n_clusters, n_noise)
    }

    // ══════════════════════════════════════════════════════════════════════

    #[test]
    fn realimages_embed_and_cluster() {
        // 1. Load images
        let entries = match load_test_images() {
            Some(e) => e,
            None => {
                eprintln!("\n  [SKIP] No images at {}", TEST_MIX_DIR);
                return;
            }
        };

        // Use cat model since test_mix contains cat face crops.
        // Change to DOG_FACE_MODEL if your images are dogs.
        let model_path = if Path::new(CAT_FACE_MODEL).exists() {
            CAT_FACE_MODEL
        } else if Path::new(DOG_FACE_MODEL).exists() {
            DOG_FACE_MODEL
        } else {
            eprintln!("\n  [SKIP] No model at {} or {}", DOG_FACE_MODEL, CAT_FACE_MODEL);
            return;
        };

        eprintln!("\n{}", "=".repeat(95));
        eprintln!("  REAL IMAGE CLUSTERING TEST");
        eprintln!("  Images: {} from {}", entries.len(), TEST_MIX_DIR);
        eprintln!("  Model: {}", model_path);
        eprintln!("{}", "=".repeat(95));

        // 2. Group info
        let mut groups: HashMap<String, Vec<usize>> = HashMap::new();
        for (i, entry) in entries.iter().enumerate() {
            groups.entry(entry.group.clone()).or_default().push(i);
        }
        let mut group_names: Vec<String> = groups.keys().cloned().collect();
        group_names.sort();

        eprintln!("\n  Ground truth groups:");
        for gn in &group_names {
            let members = &groups[gn];
            eprintln!("    Group '{}': {} images", gn, members.len());
        }

        // 3. Build ground-truth labels
        let group_to_label: HashMap<String, i32> = group_names
            .iter()
            .enumerate()
            .map(|(i, g)| (g.clone(), i as i32))
            .collect();
        let true_labels: Vec<i32> = entries
            .iter()
            .map(|e| *group_to_label.get(&e.group).unwrap_or(&-1))
            .collect();

        // 4. Preprocess images
        eprintln!("\n  Preprocessing images...");
        let mut preprocessed: Vec<Vec<f32>> = Vec::new();
        let mut valid_indices: Vec<usize> = Vec::new();
        for (i, entry) in entries.iter().enumerate() {
            match preprocess_image(&entry.path) {
                Some(tensor) => {
                    preprocessed.push(tensor);
                    valid_indices.push(i);
                }
                None => {
                    eprintln!("    WARN: Failed to load {}", entry.filename);
                }
            }
        }
        eprintln!("  Preprocessed {}/{} images", preprocessed.len(), entries.len());

        // 5. Run embedding model
        eprintln!("  Running embedding model...");
        let policy = ExecutionProviderPolicy {
            prefer_coreml: false,
            prefer_nnapi: false,
            prefer_xnnpack: false,
            allow_cpu_fallback: true,
        };
        let session = onnx::build_session(model_path, &policy)
            .expect("Failed to load ONNX model");

        let embeddings = embed_batch(&session, &preprocessed);
        let emb_dim = embeddings.first().map(|e| e.len()).unwrap_or(0);
        eprintln!("  Got {} embeddings of dimension {}", embeddings.len(), emb_dim);

        // Map back to original indices
        let valid_true_labels: Vec<i32> = valid_indices.iter().map(|&i| true_labels[i]).collect();
        let valid_entries: Vec<&ImageEntry> = valid_indices.iter().map(|&i| &entries[i]).collect();

        // 6. Distance statistics
        let n = embeddings.len();
        let mut intra = Vec::new();
        let mut inter = Vec::new();
        for i in 0..n {
            for j in (i + 1)..n {
                let d = 1.0 - dot(&embeddings[i], &embeddings[j]);
                if valid_true_labels[i] == valid_true_labels[j] {
                    intra.push(d);
                } else {
                    inter.push(d);
                }
            }
        }
        intra.sort_by(|a, b| a.partial_cmp(b).unwrap());
        inter.sort_by(|a, b| a.partial_cmp(b).unwrap());

        if !intra.is_empty() && !inter.is_empty() {
            let imean: f32 = intra.iter().sum::<f32>() / intra.len() as f32;
            let emean: f32 = inter.iter().sum::<f32>() / inter.len() as f32;
            let ip95 = intra[((intra.len() as f32 * 0.95) as usize).min(intra.len() - 1)];
            let ep5 = inter[((inter.len() as f32 * 0.05) as usize).min(inter.len() - 1)];
            eprintln!("\n  Distance statistics (cosine distance = 1 - dot):");
            eprintln!(
                "    Intra-cluster: min={:.4} mean={:.4} p95={:.4} max={:.4} (n={})",
                intra[0], imean, ip95, intra.last().unwrap(), intra.len()
            );
            eprintln!(
                "    Inter-cluster: min={:.4} p5={:.4} mean={:.4} max={:.4} (n={})",
                inter[0], ep5, emean, inter.last().unwrap(), inter.len()
            );
            eprintln!(
                "    Ideal threshold range: ({:.4}, {:.4})",
                intra.last().unwrap(), inter[0]
            );
        }

        // 7. Threshold sweep — agglomerative average linkage
        let dist = {
            let mut d = vec![0.0f32; n * n];
            for i in 0..n {
                for j in (i + 1)..n {
                    let sim = dot(&embeddings[i], &embeddings[j]);
                    let dv = (1.0 - sim).clamp(0.0, 2.0);
                    d[i * n + j] = dv;
                    d[j * n + i] = dv;
                }
            }
            d
        };

        eprintln!("\n  --- Agglomerative Average-Linkage Threshold Sweep ---");
        eprintln!(
            "  {:<12} | {:>4} | {:>5} | {:>7} | {:>7} | {:>7}",
            "Threshold", "K", "Noise", "Prec", "Recall", "F1"
        );
        eprintln!("  {}", "-".repeat(60));

        let thresholds: Vec<f32> = (10..=120).map(|i| i as f32 * 0.01).collect();
        let mut best_f1 = -1.0f64;
        let mut best_t = 0.0f32;

        for &t in &thresholds {
            let pred = agglomerative_precomputed(&dist, n, t);
            let (prec, recall, f1, k, noise) = eval_pairwise(&valid_true_labels, &pred);
            let mark = if f1 > best_f1 { "  <- BEST" } else { "" };
            if f1 > best_f1 {
                best_f1 = f1;
                best_t = t;
            }
            eprintln!(
                "  {:<12.2} | {:>4} | {:>5} | {:>7.4} | {:>7.4} | {:>7.4}{}",
                t, k, noise, prec, recall, f1, mark
            );
        }

        eprintln!("\n  BEST threshold: {:.2} (F1={:.4})", best_t, best_f1);
        eprintln!("  Production threshold: 0.85");

        // 8. Inspect clusters at best threshold
        let best_pred = agglomerative_precomputed(&dist, n, best_t);
        eprintln!("\n  --- Cluster Assignments at t={:.2} ---", best_t);

        let mut clusters: HashMap<i32, Vec<usize>> = HashMap::new();
        for (i, &label) in best_pred.iter().enumerate() {
            clusters.entry(label).or_default().push(i);
        }
        let mut sorted: Vec<(i32, Vec<usize>)> = clusters.into_iter().collect();
        sorted.sort_by(|a, b| b.1.len().cmp(&a.1.len()));

        for (cid, members) in &sorted {
            if *cid < 0 {
                continue;
            }
            let group_counts: HashMap<&str, usize> = {
                let mut m = HashMap::new();
                for &i in members {
                    *m.entry(valid_entries[i].group.as_str()).or_default() += 1;
                }
                m
            };
            let majority = group_counts
                .iter()
                .max_by_key(|(_, c)| **c)
                .map(|(g, _)| *g)
                .unwrap_or("?");
            let purity = *group_counts.get(majority).unwrap_or(&0) as f64 / members.len() as f64;
            let status = if purity >= 1.0 { "PURE" } else { "MIXED" };

            eprintln!(
                "\n  Cluster {} (size={}, majority='{}', purity={:.0}%) [{}]",
                cid,
                members.len(),
                majority,
                purity * 100.0,
                status
            );
            for &i in members {
                let mark = if valid_entries[i].group == majority { "OK" } else { "XX" };
                eprintln!(
                    "    [{}] {:<28} group='{}'",
                    mark, valid_entries[i].filename, valid_entries[i].group
                );
            }
        }

        // 9. Also test production threshold
        let prod_pred = agglomerative_precomputed(&dist, n, 0.85);
        let (p_prec, p_recall, p_f1, p_k, p_noise) =
            eval_pairwise(&valid_true_labels, &prod_pred);
        eprintln!("\n  --- Production (t=0.85) ---");
        eprintln!(
            "  K={} Noise={} Prec={:.4} Recall={:.4} F1={:.4}",
            p_k, p_noise, p_prec, p_recall, p_f1
        );

        // 10. Compare with full pet pipeline
        eprintln!("\n  --- Full 3-Phase Pet Pipeline ---");
        let inputs: Vec<PetClusterInput> = embeddings
            .iter()
            .enumerate()
            .map(|(i, emb)| PetClusterInput {
                pet_face_id: valid_entries[i].filename.clone(),
                face_embedding: emb.clone(),
                body_embedding: vec![],
                species: 0,
                file_id: i as i64,
            })
            .collect();

        for &t in &[0.77f32, 0.85, best_t] {
            let mut config = ClusterConfig::dog();
            config.agglomerative_threshold = t;
            let result = run_pet_clustering(&inputs, &config);

            let pred: Vec<i32> = {
                let mut id_map: HashMap<String, i32> = HashMap::new();
                let mut next = 0i32;
                inputs
                    .iter()
                    .map(|inp| {
                        if let Some(cid) = result.face_to_cluster.get(&inp.pet_face_id) {
                            *id_map.entry(cid.clone()).or_insert_with(|| {
                                let l = next;
                                next += 1;
                                l
                            })
                        } else {
                            -1
                        }
                    })
                    .collect()
            };

            let (prec, recall, f1, k, noise) = eval_pairwise(&valid_true_labels, &pred);
            let label = if (t - 0.77).abs() < 0.001 {
                "OLD(0.77)"
            } else if (t - 0.85).abs() < 0.001 {
                "NEW(0.85)"
            } else {
                "OPTIMAL"
            };
            eprintln!(
                "  Pipeline t={:.2} [{}]: K={} Noise={} P={:.4} R={:.4} F1={:.4}",
                t, label, k, noise, prec, recall, f1
            );
        }

        assert!(best_f1 > 0.0, "Should find at least some clustering structure");
    }
}

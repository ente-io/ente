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
    use crate::ml::pet::cluster::{ClusterConfig, PetClusterInput, run_pet_clustering};
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

        let (shape, output) =
            onnx::run_f32(session, input, [n as i64, 3, 224, 224]).expect("ONNX inference failed");

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

        let prec = if tp + fp > 0 {
            tp as f64 / (tp + fp) as f64
        } else {
            0.0
        };
        let recall = if tp + fn_ > 0 {
            tp as f64 / (tp + fn_) as f64
        } else {
            0.0
        };
        let f1 = if prec + recall > 0.0 {
            2.0 * prec * recall / (prec + recall)
        } else {
            0.0
        };
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
            eprintln!(
                "\n  [SKIP] No model at {} or {}",
                DOG_FACE_MODEL, CAT_FACE_MODEL
            );
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
        eprintln!(
            "  Preprocessed {}/{} images",
            preprocessed.len(),
            entries.len()
        );

        // 5. Run embedding model
        eprintln!("  Running embedding model...");
        let policy = ExecutionProviderPolicy {
            prefer_coreml: false,
            prefer_nnapi: false,
            prefer_xnnpack: false,
            allow_cpu_fallback: true,
        };
        let session = onnx::build_session(model_path, &policy).expect("Failed to load ONNX model");

        let embeddings = embed_batch(&session, &preprocessed);
        let emb_dim = embeddings.first().map(|e| e.len()).unwrap_or(0);
        eprintln!(
            "  Got {} embeddings of dimension {}",
            embeddings.len(),
            emb_dim
        );

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
                intra[0],
                imean,
                ip95,
                intra.last().unwrap(),
                intra.len()
            );
            eprintln!(
                "    Inter-cluster: min={:.4} p5={:.4} mean={:.4} max={:.4} (n={})",
                inter[0],
                ep5,
                emean,
                inter.last().unwrap(),
                inter.len()
            );
            eprintln!(
                "    Ideal threshold range: ({:.4}, {:.4})",
                intra.last().unwrap(),
                inter[0]
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
                let mark = if valid_entries[i].group == majority {
                    "OK"
                } else {
                    "XX"
                };
                eprintln!(
                    "    [{}] {:<28} group='{}'",
                    mark, valid_entries[i].filename, valid_entries[i].group
                );
            }
        }

        // 9. Also test production threshold
        let prod_pred = agglomerative_precomputed(&dist, n, 0.85);
        let (p_prec, p_recall, p_f1, p_k, p_noise) = eval_pairwise(&valid_true_labels, &prod_pred);
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

        assert!(
            best_f1 > 0.0,
            "Should find at least some clustering structure"
        );
    }

    // ══════════════════════════════════════════════════════════════════════
    // Full pipeline test: detect → align → embed on the same crops.
    // This tests whether adding the alignment step fixes embedding quality.
    // ══════════════════════════════════════════════════════════════════════

    const PET_FACE_DETECT_MODEL: &str =
        concat!(env!("HOME"), "/Downloads/models/yolov5s_pet_face_fp16.onnx");

    #[test]
    fn realimages_full_pipeline() {
        let entries = match load_test_images() {
            Some(e) => e,
            None => {
                eprintln!("\n  [SKIP] No images at {}", TEST_MIX_DIR);
                return;
            }
        };

        for required in [PET_FACE_DETECT_MODEL, CAT_FACE_MODEL] {
            if !Path::new(required).exists() {
                eprintln!("\n  [SKIP] Missing model: {}", required);
                return;
            }
        }

        let policy = ExecutionProviderPolicy {
            prefer_coreml: false,
            prefer_nnapi: false,
            prefer_xnnpack: false,
            allow_cpu_fallback: true,
        };

        eprintln!("\n{}", "=".repeat(95));
        eprintln!("  FULL PIPELINE TEST: detect -> align -> embed");
        eprintln!("  Images: {} from {}", entries.len(), TEST_MIX_DIR);
        eprintln!("{}", "=".repeat(95));

        // Build ground truth
        let mut groups: HashMap<String, Vec<usize>> = HashMap::new();
        for (i, entry) in entries.iter().enumerate() {
            groups.entry(entry.group.clone()).or_default().push(i);
        }
        let mut group_names: Vec<String> = groups.keys().cloned().collect();
        group_names.sort();
        let group_to_label: HashMap<String, i32> = group_names
            .iter()
            .enumerate()
            .map(|(i, g)| (g.clone(), i as i32))
            .collect();

        eprintln!(
            "\n  Ground truth: {} groups, {} images",
            group_names.len(),
            entries.len()
        );

        // Load images as DecodedImage (raw RGB bytes)
        let mut decoded_images: Vec<Option<crate::ml::types::DecodedImage>> = Vec::new();
        for entry in &entries {
            let img = image::open(&entry.path).ok().map(|i| i.to_rgb8());
            match img {
                Some(rgb) => {
                    let (w, h) = rgb.dimensions();
                    decoded_images.push(Some(crate::ml::types::DecodedImage {
                        dimensions: crate::ml::types::Dimensions {
                            width: w,
                            height: h,
                        },
                        rgb: rgb.into_raw(),
                    }));
                }
                None => decoded_images.push(None),
            }
        }

        // ── Step 1: Run face detection on each crop ──
        eprintln!("  Running face detection...");
        let detect_session = onnx::build_session(PET_FACE_DETECT_MODEL, &policy)
            .expect("Failed to load detection model");

        let mut detections_per_image: Vec<Vec<crate::ml::types::PetFaceDetection>> = Vec::new();
        for decoded in &decoded_images {
            match decoded {
                Some(dec) => {
                    // Run detection - we need to call the function directly
                    let dets = crate::ml::pet::detect::run_pet_face_detection_with_session(
                        &detect_session,
                        dec,
                    );
                    detections_per_image.push(dets.unwrap_or_default());
                }
                None => detections_per_image.push(Vec::new()),
            }
        }

        let total_dets: usize = detections_per_image.iter().map(|d| d.len()).sum();
        eprintln!(
            "  Detected {} faces across {} images",
            total_dets,
            entries.len()
        );

        // ── Step 2: Align detected faces ──
        eprintln!("  Running alignment...");
        let mut aligned_inputs: Vec<Vec<f32>> = Vec::new();
        let mut aligned_labels: Vec<i32> = Vec::new();
        let mut aligned_names: Vec<String> = Vec::new();

        for (i, dets) in detections_per_image.iter().enumerate() {
            let decoded = match &decoded_images[i] {
                Some(d) => d,
                None => continue,
            };

            if dets.is_empty() {
                continue;
            }

            let (aligned, _face_results) =
                crate::ml::pet::align::run_pet_face_alignment(i as i64, decoded, dets)
                    .unwrap_or_default();

            // Take the first (highest-score) aligned face per image
            if let Some(tensor) = aligned.into_iter().next() {
                aligned_inputs.push(tensor);
                aligned_labels.push(*group_to_label.get(&entries[i].group).unwrap_or(&-1));
                aligned_names.push(entries[i].filename.clone());
            }
        }

        eprintln!("  Aligned {} faces", aligned_inputs.len());

        if aligned_inputs.len() < 2 {
            eprintln!("  Not enough aligned faces to cluster");
            return;
        }

        // ── Step 3: Embed using the ACTUAL pipeline function ──
        eprintln!("  Running embedding via run_pet_face_embedding_with_sessions...");
        let dog_embed_session =
            onnx::build_session(DOG_FACE_MODEL, &policy).expect("Failed to load dog embed model");
        let cat_embed_session =
            onnx::build_session(CAT_FACE_MODEL, &policy).expect("Failed to load cat embed model");

        // Reconstruct face_results from the alignment step so we can call the real embed fn
        let mut all_face_results: Vec<crate::ml::types::PetFaceResult> = Vec::new();
        let mut all_aligned: Vec<Vec<f32>> = Vec::new();
        let mut result_labels: Vec<i32> = Vec::new();
        let mut result_names: Vec<String> = Vec::new();

        for (i, dets) in detections_per_image.iter().enumerate() {
            let decoded = match &decoded_images[i] {
                Some(d) => d,
                None => continue,
            };
            if dets.is_empty() {
                continue;
            }
            let (aligned, face_results) =
                match crate::ml::pet::align::run_pet_face_alignment(i as i64, decoded, dets) {
                    Ok(r) => r,
                    Err(_) => continue,
                };
            for (j, tensor) in aligned.into_iter().enumerate() {
                if j < face_results.len() {
                    all_aligned.push(tensor);
                    all_face_results.push(face_results[j].clone());
                    result_labels.push(*group_to_label.get(&entries[i].group).unwrap_or(&-1));
                    result_names.push(entries[i].filename.clone());
                }
            }
        }

        crate::ml::pet::embed::run_pet_face_embedding_with_sessions(
            &all_aligned,
            &mut all_face_results,
            &dog_embed_session,
            &cat_embed_session,
        )
        .expect("Embedding failed");

        let aligned_embeddings: Vec<Vec<f32>> = all_face_results
            .iter()
            .map(|r| r.face_embedding.clone())
            .collect();
        let aligned_labels = result_labels;
        let aligned_names = result_names;

        eprintln!(
            "  Got {} embeddings of dim {}",
            aligned_embeddings.len(),
            aligned_embeddings.first().map(|e| e.len()).unwrap_or(0)
        );

        // Show species detected
        for (i, r) in all_face_results.iter().enumerate() {
            let sp = if r.species == 0 { "dog" } else { "cat" };
            eprintln!(
                "    {} -> species={} score={:.3}",
                aligned_names[i], sp, r.detection.score
            );
        }

        // ── Step 4: Also embed UN-ALIGNED (raw) for comparison ──
        eprintln!("  Running embedding (raw/un-aligned) for comparison...");
        let raw_preprocessed: Vec<Vec<f32>> = (0..entries.len())
            .filter_map(|i| preprocess_image(&entries[i].path))
            .collect();
        let raw_labels: Vec<i32> = (0..entries.len())
            .filter(|i| preprocess_image(&entries[*i].path).is_some())
            .map(|i| *group_to_label.get(&entries[i].group).unwrap_or(&-1))
            .collect();
        let raw_embeddings = embed_batch(&cat_embed_session, &raw_preprocessed);

        // ── Step 5: Compare distance distributions ──
        fn compute_distance_stats(embeddings: &[Vec<f32>], labels: &[i32]) -> (f32, f32, f32, f32) {
            let n = embeddings.len();
            let mut intra = Vec::new();
            let mut inter = Vec::new();
            for i in 0..n {
                for j in (i + 1)..n {
                    let d = 1.0 - dot(&embeddings[i], &embeddings[j]);
                    if labels[i] == labels[j] {
                        intra.push(d);
                    } else {
                        inter.push(d);
                    }
                }
            }
            let intra_mean = if intra.is_empty() {
                0.0
            } else {
                intra.iter().sum::<f32>() / intra.len() as f32
            };
            let inter_mean = if inter.is_empty() {
                0.0
            } else {
                inter.iter().sum::<f32>() / inter.len() as f32
            };
            let separation = inter_mean - intra_mean;
            let ratio = if inter_mean > 0.0 {
                intra_mean / inter_mean
            } else {
                1.0
            };
            (intra_mean, inter_mean, separation, ratio)
        }

        let (raw_intra, raw_inter, raw_sep, raw_ratio) =
            compute_distance_stats(&raw_embeddings, &raw_labels);
        let (aligned_intra, aligned_inter, aligned_sep, aligned_ratio) =
            compute_distance_stats(&aligned_embeddings, &aligned_labels);

        eprintln!("\n  === ALIGNMENT IMPACT ON EMBEDDING QUALITY ===");
        eprintln!(
            "  {:>15} | {:>10} | {:>10} | {:>10} | {:>10}",
            "", "Intra(mean)", "Inter(mean)", "Separation", "Ratio"
        );
        eprintln!("  {}", "-".repeat(65));
        eprintln!(
            "  {:>15} | {:>10.4} | {:>10.4} | {:>10.4} | {:>10.4}",
            "Raw (no align)", raw_intra, raw_inter, raw_sep, raw_ratio
        );
        eprintln!(
            "  {:>15} | {:>10.4} | {:>10.4} | {:>10.4} | {:>10.4}",
            "With alignment", aligned_intra, aligned_inter, aligned_sep, aligned_ratio
        );
        eprintln!();
        eprintln!(
            "  Separation improvement: {:.4} -> {:.4}",
            raw_sep, aligned_sep
        );
        eprintln!("  (Positive = inter > intra = good. Larger = better separation.)");

        // ── Step 6: Cluster both and compare F1 ──
        let n_aligned = aligned_embeddings.len();
        let n_raw = raw_embeddings.len();

        let aligned_dist = {
            let mut d = vec![0.0f32; n_aligned * n_aligned];
            for i in 0..n_aligned {
                for j in (i + 1)..n_aligned {
                    let v =
                        (1.0 - dot(&aligned_embeddings[i], &aligned_embeddings[j])).clamp(0.0, 2.0);
                    d[i * n_aligned + j] = v;
                    d[j * n_aligned + i] = v;
                }
            }
            d
        };

        let raw_dist = {
            let mut d = vec![0.0f32; n_raw * n_raw];
            for i in 0..n_raw {
                for j in (i + 1)..n_raw {
                    let v = (1.0 - dot(&raw_embeddings[i], &raw_embeddings[j])).clamp(0.0, 2.0);
                    d[i * n_raw + j] = v;
                    d[j * n_raw + i] = v;
                }
            }
            d
        };

        eprintln!("  === CLUSTERING COMPARISON (threshold sweep) ===");
        eprintln!(
            "  {:>6} | {:>12} | {:>12}",
            "Thresh", "Raw F1", "Aligned F1"
        );
        eprintln!("  {}", "-".repeat(38));

        let mut best_raw_f1 = 0.0f64;
        let mut best_aligned_f1 = 0.0f64;
        let mut best_raw_t = 0.0f32;
        let mut best_aligned_t = 0.0f32;

        for t_int in (50..=100).step_by(5) {
            let t = t_int as f32 * 0.01;
            let raw_pred = agglomerative_precomputed(&raw_dist, n_raw, t);
            let aligned_pred = agglomerative_precomputed(&aligned_dist, n_aligned, t);

            let (_, _, raw_f1, _, _) = eval_pairwise(&raw_labels, &raw_pred);
            let (_, _, aligned_f1, _, _) = eval_pairwise(&aligned_labels, &aligned_pred);

            if raw_f1 > best_raw_f1 {
                best_raw_f1 = raw_f1;
                best_raw_t = t;
            }
            if aligned_f1 > best_aligned_f1 {
                best_aligned_f1 = aligned_f1;
                best_aligned_t = t;
            }

            eprintln!("  {:>6.2} | {:>12.4} | {:>12.4}", t, raw_f1, aligned_f1);
        }

        eprintln!(
            "\n  Best RAW:     t={:.2} F1={:.4}",
            best_raw_t, best_raw_f1
        );
        eprintln!(
            "  Best ALIGNED: t={:.2} F1={:.4}",
            best_aligned_t, best_aligned_f1
        );
        eprintln!(
            "  Improvement:  {:.1}x",
            if best_raw_f1 > 0.0 {
                best_aligned_f1 / best_raw_f1
            } else {
                0.0
            }
        );
    }

    // ══════════════════════════════════════════════════════════════════════
    // Run full pipeline on REAL FULL PHOTOS (not pre-cropped).
    // detect -> align -> embed -> cluster, with no ground truth.
    // ══════════════════════════════════════════════════════════════════════

    const FULL_PHOTOS_DIR: &str = concat!(env!("HOME"), "/Downloads/new_data/converted");

    #[test]
    fn realimages_full_photos_pipeline() {
        let dir = Path::new(FULL_PHOTOS_DIR);
        if !dir.exists() {
            eprintln!("\n  [SKIP] No photos at {}", FULL_PHOTOS_DIR);
            return;
        }

        for required in [PET_FACE_DETECT_MODEL, CAT_FACE_MODEL, DOG_FACE_MODEL] {
            if !Path::new(required).exists() {
                eprintln!("\n  [SKIP] Missing model: {}", required);
                return;
            }
        }

        let policy = ExecutionProviderPolicy {
            prefer_coreml: false,
            prefer_nnapi: false,
            prefer_xnnpack: false,
            allow_cpu_fallback: true,
        };

        // Load images
        let mut photo_paths: Vec<String> = Vec::new();
        for entry in std::fs::read_dir(dir).unwrap() {
            let entry = entry.unwrap();
            let name = entry.file_name().to_string_lossy().to_string();
            let lower = name.to_lowercase();
            if lower.ends_with(".jpg") || lower.ends_with(".jpeg") || lower.ends_with(".png") {
                photo_paths.push(entry.path().to_string_lossy().to_string());
            }
        }
        photo_paths.sort();

        eprintln!("\n{}", "=".repeat(95));
        eprintln!("  FULL PHOTO PIPELINE: detect -> align -> embed -> cluster");
        eprintln!("  Photos: {} from {}", photo_paths.len(), FULL_PHOTOS_DIR);
        eprintln!("{}", "=".repeat(95));

        // Load sessions
        let detect_session =
            onnx::build_session(PET_FACE_DETECT_MODEL, &policy).expect("detect model");
        let dog_embed_session =
            onnx::build_session(DOG_FACE_MODEL, &policy).expect("dog embed model");
        let cat_embed_session =
            onnx::build_session(CAT_FACE_MODEL, &policy).expect("cat embed model");

        // Process each photo through full pipeline
        let mut all_face_results: Vec<crate::ml::types::PetFaceResult> = Vec::new();
        let mut all_aligned: Vec<Vec<f32>> = Vec::new();
        let mut face_source_photo: Vec<String> = Vec::new();

        eprintln!("\n  Processing photos...");
        for (idx, path) in photo_paths.iter().enumerate() {
            let filename = Path::new(path)
                .file_name()
                .unwrap()
                .to_string_lossy()
                .to_string();

            let img = match image::open(path) {
                Ok(i) => i.to_rgb8(),
                Err(e) => {
                    eprintln!(
                        "    [{}/{}] {} FAILED: {}",
                        idx + 1,
                        photo_paths.len(),
                        filename,
                        e
                    );
                    continue;
                }
            };

            let (w, h) = img.dimensions();
            let decoded = crate::ml::types::DecodedImage {
                dimensions: crate::ml::types::Dimensions {
                    width: w,
                    height: h,
                },
                rgb: img.into_raw(),
            };

            // Step 1: Detect
            let detections = crate::ml::pet::detect::run_pet_face_detection_with_session(
                &detect_session,
                &decoded,
            )
            .unwrap_or_default();

            if detections.is_empty() {
                eprintln!(
                    "    [{}/{}] {} ({}x{}) -> no faces",
                    idx + 1,
                    photo_paths.len(),
                    filename,
                    w,
                    h
                );
                continue;
            }

            // Step 2: Align
            let (aligned, face_results) = match crate::ml::pet::align::run_pet_face_alignment(
                idx as i64,
                &decoded,
                &detections,
            ) {
                Ok(r) => r,
                Err(e) => {
                    eprintln!(
                        "    [{}/{}] {} -> align failed: {:?}",
                        idx + 1,
                        photo_paths.len(),
                        filename,
                        e
                    );
                    continue;
                }
            };

            let n_faces = face_results.len();
            for (j, (tensor, result)) in aligned
                .into_iter()
                .zip(face_results.into_iter())
                .enumerate()
            {
                let sp = if result.detection.class_id == 0 {
                    "dog"
                } else {
                    "cat"
                };
                if j == 0 {
                    eprintln!(
                        "    [{}/{}] {} ({}x{}) -> {} face(s), first: {} score={:.3}",
                        idx + 1,
                        photo_paths.len(),
                        filename,
                        w,
                        h,
                        n_faces,
                        sp,
                        result.detection.score
                    );
                }
                all_aligned.push(tensor);
                all_face_results.push(result);
                face_source_photo.push(filename.clone());
            }
        }

        eprintln!(
            "\n  Total: {} faces from {} photos",
            all_face_results.len(),
            photo_paths.len()
        );

        if all_face_results.len() < 2 {
            eprintln!("  Not enough faces to cluster");
            return;
        }

        // Step 3: Embed using actual pipeline function
        eprintln!("  Running embedding...");
        crate::ml::pet::embed::run_pet_face_embedding_with_sessions(
            &all_aligned,
            &mut all_face_results,
            &dog_embed_session,
            &cat_embed_session,
        )
        .expect("Embedding failed");

        let embeddings: Vec<Vec<f32>> = all_face_results
            .iter()
            .map(|r| r.face_embedding.clone())
            .collect();

        let dim = embeddings[0].len();
        eprintln!("  Embeddings: {} x {}-d", embeddings.len(), dim);

        // Step 4: Pairwise distance analysis
        let n = embeddings.len();
        let mut all_dists: Vec<(usize, usize, f32)> = Vec::new();
        for i in 0..n {
            for j in (i + 1)..n {
                let d = 1.0 - dot(&embeddings[i], &embeddings[j]);
                all_dists.push((i, j, d));
            }
        }
        all_dists.sort_by(|a, b| a.2.partial_cmp(&b.2).unwrap());

        eprintln!("\n  === PAIRWISE DISTANCE DISTRIBUTION ===");
        eprintln!("  Total pairs: {}", all_dists.len());
        let mean_d: f32 = all_dists.iter().map(|d| d.2).sum::<f32>() / all_dists.len() as f32;
        let min_d = all_dists.first().map(|d| d.2).unwrap_or(0.0);
        let max_d = all_dists.last().map(|d| d.2).unwrap_or(0.0);
        let p10 = all_dists[(all_dists.len() as f32 * 0.10) as usize].2;
        let p50 = all_dists[(all_dists.len() as f32 * 0.50) as usize].2;
        let p90 = all_dists[(all_dists.len() as f32 * 0.90) as usize].2;
        eprintln!(
            "  min={:.4} p10={:.4} median={:.4} mean={:.4} p90={:.4} max={:.4}",
            min_d, p10, p50, mean_d, p90, max_d
        );

        // Show closest 20 pairs
        eprintln!("\n  === 20 CLOSEST PAIRS (most similar) ===");
        for &(i, j, d) in all_dists.iter().take(20) {
            let sp_i = if all_face_results[i].species == 0 {
                "dog"
            } else {
                "cat"
            };
            let sp_j = if all_face_results[j].species == 0 {
                "dog"
            } else {
                "cat"
            };
            eprintln!(
                "    dist={:.4}  {} ({}) <-> {} ({})",
                d, face_source_photo[i], sp_i, face_source_photo[j], sp_j
            );
        }

        // Show most distant 10 pairs
        eprintln!("\n  === 10 MOST DISTANT PAIRS ===");
        for &(i, j, d) in all_dists.iter().rev().take(10) {
            let sp_i = if all_face_results[i].species == 0 {
                "dog"
            } else {
                "cat"
            };
            let sp_j = if all_face_results[j].species == 0 {
                "dog"
            } else {
                "cat"
            };
            eprintln!(
                "    dist={:.4}  {} ({}) <-> {} ({})",
                d, face_source_photo[i], sp_i, face_source_photo[j], sp_j
            );
        }

        // Step 5: Cluster with production config
        eprintln!("\n  === CLUSTERING (production t=0.85) ===");
        let inputs: Vec<crate::ml::pet::cluster::PetClusterInput> = embeddings
            .iter()
            .enumerate()
            .map(|(i, emb)| crate::ml::pet::cluster::PetClusterInput {
                pet_face_id: format!("{}_{}", face_source_photo[i], i),
                face_embedding: emb.clone(),
                body_embedding: vec![],
                species: all_face_results[i].species,
                file_id: i as i64,
            })
            .collect();

        // Step 5: Threshold sweep
        eprintln!("\n  === THRESHOLD SWEEP (BIRCH) ===");
        eprintln!(
            "  {:>6} | {:>4} | {:>6} | {:>8} | cluster sizes",
            "Thresh", "K", "Noise", "Largest"
        );
        eprintln!("  {}", "-".repeat(65));

        for t_int in (30..=100).step_by(5) {
            let t = t_int as f32 * 0.01;
            let mut config = ClusterConfig::for_species(crate::ml::pet::cluster::Species::from_u8(
                all_face_results[0].species,
            ));
            config.agglomerative_threshold = t;
            let result = run_pet_clustering(&inputs, &config);

            let mut cluster_sizes: Vec<usize> = {
                let mut m: HashMap<String, usize> = HashMap::new();
                for inp in &inputs {
                    if let Some(cid) = result.face_to_cluster.get(&inp.pet_face_id) {
                        *m.entry(cid.clone()).or_default() += 1;
                    }
                }
                m.values().copied().collect()
            };
            cluster_sizes.sort_by(|a, b| b.cmp(a));
            let largest = cluster_sizes.first().copied().unwrap_or(0);
            let sizes_str: String = cluster_sizes
                .iter()
                .map(|s| s.to_string())
                .collect::<Vec<_>>()
                .join(",");

            eprintln!(
                "  {:>6.2} | {:>4} | {:>6} | {:>8} | [{}]",
                t,
                cluster_sizes.len(),
                result.n_unclustered,
                largest,
                sizes_str
            );
        }

        // Show detailed clusters at production threshold
        let prod_t = 0.77;
        eprintln!("\n  === CLUSTERS AT t={} (production) ===", prod_t);
        let mut config = ClusterConfig::for_species(crate::ml::pet::cluster::Species::from_u8(
            all_face_results[0].species,
        ));
        config.agglomerative_threshold = prod_t as f32;
        let result = run_pet_clustering(&inputs, &config);

        let mut cluster_members: HashMap<String, Vec<usize>> = HashMap::new();
        for (i, inp) in inputs.iter().enumerate() {
            if let Some(cid) = result.face_to_cluster.get(&inp.pet_face_id) {
                cluster_members.entry(cid.clone()).or_default().push(i);
            }
        }
        let mut sorted_clusters: Vec<(String, Vec<usize>)> = cluster_members.into_iter().collect();
        sorted_clusters.sort_by(|a, b| b.1.len().cmp(&a.1.len()));

        eprintln!(
            "  {} clusters, {} unclustered\n",
            sorted_clusters.len(),
            result.n_unclustered
        );

        for (cid, members) in &sorted_clusters {
            eprintln!(
                "  Cluster {} (size={})",
                &cid[..std::cmp::min(30, cid.len())],
                members.len()
            );
            for &i in members {
                let sp = if all_face_results[i].species == 0 {
                    "dog"
                } else {
                    "cat"
                };
                eprintln!(
                    "    {} ({}, score={:.3})",
                    face_source_photo[i], sp, all_face_results[i].detection.score
                );
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    // Compare ALL 4 embedding models on the same crops to find which
    // model (if any) can distinguish these pets.
    // ══════════════════════════════════════════════════════════════════════

    const DOG_BODY_MODEL: &str =
        concat!(env!("HOME"), "/Downloads/models/dog_body_embedding192.onnx");
    const CAT_BODY_MODEL: &str =
        concat!(env!("HOME"), "/Downloads/models/cat_body_embedding192.onnx");

    #[test]
    fn realimages_all_models_comparison() {
        let entries = match load_test_images() {
            Some(e) => e,
            None => {
                eprintln!("\n  [SKIP] No images at {}", TEST_MIX_DIR);
                return;
            }
        };

        let models: Vec<(&str, &str)> = vec![
            ("Cat face 128-d", CAT_FACE_MODEL),
            ("Dog face 128-d", DOG_FACE_MODEL),
            ("Cat body 192-d", CAT_BODY_MODEL),
            ("Dog body 192-d", DOG_BODY_MODEL),
        ];

        let policy = ExecutionProviderPolicy {
            prefer_coreml: false,
            prefer_nnapi: false,
            prefer_xnnpack: false,
            allow_cpu_fallback: true,
        };

        eprintln!("\n{}", "=".repeat(95));
        eprintln!("  ALL MODELS COMPARISON: which embedding model separates these pets?");
        eprintln!("  Images: {} from {}", entries.len(), TEST_MIX_DIR);
        eprintln!("{}", "=".repeat(95));

        // Build ground truth
        let mut groups: HashMap<String, Vec<usize>> = HashMap::new();
        for (i, entry) in entries.iter().enumerate() {
            groups.entry(entry.group.clone()).or_default().push(i);
        }
        let mut group_names: Vec<String> = groups.keys().cloned().collect();
        group_names.sort();
        let group_to_label: HashMap<String, i32> = group_names
            .iter()
            .enumerate()
            .map(|(i, g)| (g.clone(), i as i32))
            .collect();
        let true_labels: Vec<i32> = entries
            .iter()
            .map(|e| *group_to_label.get(&e.group).unwrap_or(&-1))
            .collect();

        eprintln!(
            "\n  Groups: {:?}",
            group_names
                .iter()
                .map(|g| format!("{}: {}", g, groups[g].len()))
                .collect::<Vec<_>>()
        );

        // Preprocess all images
        let preprocessed: Vec<Option<Vec<f32>>> =
            entries.iter().map(|e| preprocess_image(&e.path)).collect();

        let valid: Vec<usize> = (0..entries.len())
            .filter(|i| preprocessed[*i].is_some())
            .collect();
        let valid_labels: Vec<i32> = valid.iter().map(|&i| true_labels[i]).collect();
        let valid_tensors: Vec<&Vec<f32>> = valid
            .iter()
            .map(|&i| preprocessed[i].as_ref().unwrap())
            .collect();

        eprintln!("  Valid images: {}/{}\n", valid.len(), entries.len());

        // Test each model
        eprintln!(
            "  {:>20} | {:>5} | {:>10} | {:>10} | {:>10} | {:>8} | {:>8}",
            "Model", "Dim", "Intra", "Inter", "Separation", "Best F1", "Best t"
        );
        eprintln!("  {}", "-".repeat(85));

        for (name, path) in &models {
            if !Path::new(path).exists() {
                eprintln!("  {:>20} | SKIPPED (model not found)", name);
                continue;
            }

            let session = match onnx::build_session(path, &policy) {
                Ok(s) => s,
                Err(e) => {
                    eprintln!("  {:>20} | FAILED: {:?}", name, e);
                    continue;
                }
            };

            // Run embedding - body models expect same 224x224 CHW input
            let input_tensors: Vec<Vec<f32>> = valid_tensors.iter().map(|t| (*t).clone()).collect();
            let embeddings = embed_batch(&session, &input_tensors);

            if embeddings.is_empty() {
                eprintln!("  {:>20} | No embeddings produced", name);
                continue;
            }

            let dim = embeddings[0].len();

            // Distance stats
            let n = embeddings.len();
            let mut intra = Vec::new();
            let mut inter = Vec::new();
            for i in 0..n {
                for j in (i + 1)..n {
                    let d = 1.0 - dot(&embeddings[i], &embeddings[j]);
                    if valid_labels[i] == valid_labels[j] {
                        intra.push(d);
                    } else {
                        inter.push(d);
                    }
                }
            }

            let intra_mean = if intra.is_empty() {
                0.0
            } else {
                intra.iter().sum::<f32>() / intra.len() as f32
            };
            let inter_mean = if inter.is_empty() {
                0.0
            } else {
                inter.iter().sum::<f32>() / inter.len() as f32
            };
            let separation = inter_mean - intra_mean;

            // Best F1 via threshold sweep
            let dist_matrix = {
                let mut d = vec![0.0f32; n * n];
                for i in 0..n {
                    for j in (i + 1)..n {
                        let v = (1.0 - dot(&embeddings[i], &embeddings[j])).clamp(0.0, 2.0);
                        d[i * n + j] = v;
                        d[j * n + i] = v;
                    }
                }
                d
            };

            let mut best_f1 = 0.0f64;
            let mut best_t = 0.0f32;
            for t_int in 10..=120 {
                let t = t_int as f32 * 0.01;
                let pred = agglomerative_precomputed(&dist_matrix, n, t);
                let (_, _, f1, _, _) = eval_pairwise(&valid_labels, &pred);
                if f1 > best_f1 {
                    best_f1 = f1;
                    best_t = t;
                }
            }

            eprintln!(
                "  {:>20} | {:>5} | {:>10.4} | {:>10.4} | {:>10.4} | {:>8.4} | {:>8.2}",
                name, dim, intra_mean, inter_mean, separation, best_f1, best_t
            );
        }

        // Also show per-group pairwise distances for the best model
        eprintln!("\n  === PER-PAIR GROUP DISTANCES (cat face model) ===");
        let cat_session = onnx::build_session(CAT_FACE_MODEL, &policy).unwrap();
        let cat_embs = embed_batch(
            &cat_session,
            &valid_tensors
                .iter()
                .map(|t| (*t).clone())
                .collect::<Vec<_>>(),
        );

        eprintln!("  {:>6} |", "");
        for g1 in &group_names {
            eprint!(" {:>6}", g1);
        }
        eprintln!();
        eprintln!("  {}", "-".repeat(8 + group_names.len() * 7));

        for g1 in &group_names {
            eprint!("  {:>6} |", g1);
            for g2 in &group_names {
                let mut dists = Vec::new();
                for &i in &valid {
                    for &j in &valid {
                        if i >= j {
                            continue;
                        }
                        if entries[i].group == *g1 && entries[j].group == *g2 {
                            let vi = valid.iter().position(|&v| v == i).unwrap();
                            let vj = valid.iter().position(|&v| v == j).unwrap();
                            dists.push(1.0 - dot(&cat_embs[vi], &cat_embs[vj]));
                        }
                    }
                }
                if dists.is_empty() {
                    eprint!("    -  ");
                } else {
                    let mean: f32 = dists.iter().sum::<f32>() / dists.len() as f32;
                    eprint!(" {:>6.3}", mean);
                }
            }
            eprintln!();
        }
        eprintln!("  (diagonal = intra-group, off-diagonal = inter-group)");
    }

    // ══════════════════════════════════════════════════════════════════════
    // Test whether BGR vs RGB channel order explains the bad embeddings.
    // OpenCV loads as BGR; the `image` crate loads as RGB.
    // If the BYOL model was trained with cv2 (BGR), we need to swap channels.
    // ══════════════════════════════════════════════════════════════════════

    /// Preprocess with BGR channel order (swap R and B).
    fn preprocess_image_bgr(path: &str) -> Option<Vec<f32>> {
        let img = image::open(path).ok()?.to_rgb8();
        let (w, h) = img.dimensions();
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
                // BGR order: channel 0 = B, channel 1 = G, channel 2 = R
                output[dst] = (pixels[src + 2] as f32 / 255.0 - MEAN[0]) / STD[0]; // B
                output[pixel_count + dst] = (pixels[src + 1] as f32 / 255.0 - MEAN[1]) / STD[1]; // G
                output[2 * pixel_count + dst] = (pixels[src] as f32 / 255.0 - MEAN[2]) / STD[2]; // R
            }
        }

        Some(output)
    }

    #[test]
    fn realimages_rgb_vs_bgr() {
        let entries = match load_test_images() {
            Some(e) => e,
            None => {
                eprintln!("\n  [SKIP] No images at {}", TEST_MIX_DIR);
                return;
            }
        };

        let policy = ExecutionProviderPolicy {
            prefer_coreml: false,
            prefer_nnapi: false,
            prefer_xnnpack: false,
            allow_cpu_fallback: true,
        };

        if !Path::new(CAT_FACE_MODEL).exists() {
            eprintln!("\n  [SKIP] No model at {}", CAT_FACE_MODEL);
            return;
        }

        eprintln!("\n{}", "=".repeat(95));
        eprintln!("  RGB vs BGR CHANNEL ORDER TEST");
        eprintln!("{}", "=".repeat(95));

        // Build ground truth
        let mut group_names: Vec<String> = {
            let mut g: HashMap<String, ()> = HashMap::new();
            for e in &entries {
                g.insert(e.group.clone(), ());
            }
            g.keys().cloned().collect()
        };
        group_names.sort();
        let group_to_label: HashMap<String, i32> = group_names
            .iter()
            .enumerate()
            .map(|(i, g)| (g.clone(), i as i32))
            .collect();
        let true_labels: Vec<i32> = entries
            .iter()
            .map(|e| *group_to_label.get(&e.group).unwrap_or(&-1))
            .collect();

        // Preprocess both ways
        let rgb_tensors: Vec<Vec<f32>> = entries
            .iter()
            .filter_map(|e| preprocess_image(&e.path))
            .collect();
        let bgr_tensors: Vec<Vec<f32>> = entries
            .iter()
            .filter_map(|e| preprocess_image_bgr(&e.path))
            .collect();

        let session = onnx::build_session(CAT_FACE_MODEL, &policy).unwrap();

        let rgb_embs = embed_batch(&session, &rgb_tensors);
        let bgr_embs = embed_batch(&session, &bgr_tensors);

        // Compare distance distributions
        fn stats(embs: &[Vec<f32>], labels: &[i32]) -> (f32, f32, f32) {
            let n = embs.len();
            let mut intra = Vec::new();
            let mut inter = Vec::new();
            for i in 0..n {
                for j in (i + 1)..n {
                    let d = 1.0 - dot(&embs[i], &embs[j]);
                    if labels[i] == labels[j] {
                        intra.push(d);
                    } else {
                        inter.push(d);
                    }
                }
            }
            let intra_m = intra.iter().sum::<f32>() / intra.len().max(1) as f32;
            let inter_m = inter.iter().sum::<f32>() / inter.len().max(1) as f32;
            (intra_m, inter_m, inter_m - intra_m)
        }

        fn best_f1(embs: &[Vec<f32>], labels: &[i32]) -> (f64, f32) {
            let n = embs.len();
            let dist = {
                let mut d = vec![0.0f32; n * n];
                for i in 0..n {
                    for j in (i + 1)..n {
                        let v = (1.0 - dot(&embs[i], &embs[j])).clamp(0.0, 2.0);
                        d[i * n + j] = v;
                        d[j * n + i] = v;
                    }
                }
                d
            };
            let mut bf = 0.0f64;
            let mut bt = 0.0f32;
            for t_int in 10..=120 {
                let t = t_int as f32 * 0.01;
                let pred = agglomerative_precomputed(&dist, n, t);
                let (_, _, f1, _, _) = eval_pairwise(labels, &pred);
                if f1 > bf {
                    bf = f1;
                    bt = t;
                }
            }
            (bf, bt)
        }

        let (rgb_intra, rgb_inter, rgb_sep) = stats(&rgb_embs, &true_labels);
        let (bgr_intra, bgr_inter, bgr_sep) = stats(&bgr_embs, &true_labels);
        let (rgb_f1, rgb_t) = best_f1(&rgb_embs, &true_labels);
        let (bgr_f1, bgr_t) = best_f1(&bgr_embs, &true_labels);

        eprintln!(
            "\n  {:>10} | {:>10} | {:>10} | {:>10} | {:>8} | {:>6}",
            "Order", "Intra", "Inter", "Separation", "Best F1", "Best t"
        );
        eprintln!("  {}", "-".repeat(65));
        eprintln!(
            "  {:>10} | {:>10.4} | {:>10.4} | {:>10.4} | {:>8.4} | {:>6.2}",
            "RGB", rgb_intra, rgb_inter, rgb_sep, rgb_f1, rgb_t
        );
        eprintln!(
            "  {:>10} | {:>10.4} | {:>10.4} | {:>10.4} | {:>8.4} | {:>6.2}",
            "BGR", bgr_intra, bgr_inter, bgr_sep, bgr_f1, bgr_t
        );

        let winner = if bgr_sep > rgb_sep { "BGR" } else { "RGB" };
        eprintln!(
            "\n  Winner: {} (separation {:.4} vs {:.4})",
            winner,
            bgr_sep.max(rgb_sep),
            bgr_sep.min(rgb_sep),
        );

        if bgr_f1 > rgb_f1 * 1.1 {
            eprintln!("  ** BGR significantly better! The model likely expects BGR input. **");
            eprintln!("  ** Check if the Rust pipeline should swap R<->B channels. **");
        } else if rgb_f1 > bgr_f1 * 1.1 {
            eprintln!("  RGB is better. Current pipeline channel order is correct.");
        } else {
            eprintln!("  No significant difference. Channel order is not the issue.");
        }
    }
}

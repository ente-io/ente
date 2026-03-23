//! Real-data clustering evaluation.
//!
//! Loads pet face/body embeddings exported from the app via
//! `PetClusteringService.dumpEmbeddingsJson()` and runs clustering at
//! multiple thresholds to find the optimal one for your actual embeddings.
//!
//! Usage:
//!   1. On device, call `dumpEmbeddingsJson(outputPath: "/path/to/pet_embeddings.json")`
//!   2. Copy the JSON file to `rust/test_fixtures/pet_embeddings.json`
//!   3. Run: `cargo test cluster_realdata -- --nocapture`

#[cfg(test)]
mod tests {
    use crate::ml::cluster::dot;
    use crate::ml::pet::cluster::{ClusterConfig, PetClusterInput, Species, run_pet_clustering};
    use std::collections::HashMap;
    use std::fs;
    use std::path::Path;

    const FIXTURE_PATH: &str = "test_fixtures/pet_embeddings.json";

    /// Parsed embedding data from the JSON export.
    struct RealDataset {
        species: u8,
        species_name: String,
        inputs: Vec<PetClusterInput>,
        /// Existing cluster assignments from the app (petFaceId -> clusterId).
        existing_clusters: HashMap<String, String>,
    }

    fn load_fixture() -> Option<Vec<RealDataset>> {
        let path = Path::new(FIXTURE_PATH);
        if !path.exists() {
            return None;
        }
        let content = fs::read_to_string(path).ok()?;

        // Minimal JSON parsing without serde — parse the array of species groups.
        // The format is: [{ "species": 0, "inputs": [...], "clusters": {...} }, ...]
        //
        // Since we don't have serde, use a simple state-machine parser for the
        // specific JSON structure we expect. However, for robustness let's just
        // look for the key patterns and extract numbers/arrays.
        //
        // Actually, let's use a very simple approach: split on known delimiters.
        // This is test code, not production.
        parse_json_datasets(&content)
    }

    fn parse_json_datasets(json: &str) -> Option<Vec<RealDataset>> {
        // Very simple JSON parser for our specific format.
        // Uses character-by-character parsing to handle nested structures.
        let chars: Vec<char> = json.chars().collect();
        let len = chars.len();
        let mut pos = 0;

        // Skip whitespace
        fn skip_ws(chars: &[char], pos: &mut usize) {
            while *pos < chars.len() && chars[*pos].is_whitespace() {
                *pos += 1;
            }
        }

        // Parse a JSON number (integer or float)
        fn parse_number(chars: &[char], pos: &mut usize) -> f64 {
            let start = *pos;
            if *pos < chars.len() && chars[*pos] == '-' {
                *pos += 1;
            }
            while *pos < chars.len() && (chars[*pos].is_ascii_digit() || chars[*pos] == '.') {
                *pos += 1;
            }
            // Handle scientific notation
            if *pos < chars.len() && (chars[*pos] == 'e' || chars[*pos] == 'E') {
                *pos += 1;
                if *pos < chars.len() && (chars[*pos] == '+' || chars[*pos] == '-') {
                    *pos += 1;
                }
                while *pos < chars.len() && chars[*pos].is_ascii_digit() {
                    *pos += 1;
                }
            }
            let s: String = chars[start..*pos].iter().collect();
            s.parse().unwrap_or(0.0)
        }

        // Parse a JSON string (assumes we're at the opening quote)
        fn parse_string(chars: &[char], pos: &mut usize) -> String {
            assert_eq!(chars[*pos], '"');
            *pos += 1;
            let mut s = String::new();
            while *pos < chars.len() && chars[*pos] != '"' {
                if chars[*pos] == '\\' {
                    *pos += 1;
                    if *pos < chars.len() {
                        s.push(chars[*pos]);
                    }
                } else {
                    s.push(chars[*pos]);
                }
                *pos += 1;
            }
            if *pos < chars.len() {
                *pos += 1; // skip closing quote
            }
            s
        }

        // Parse an array of f64
        fn parse_f64_array(chars: &[char], pos: &mut usize) -> Vec<f64> {
            let mut result = Vec::new();
            skip_ws(chars, pos);
            if *pos >= chars.len() || chars[*pos] != '[' {
                return result;
            }
            *pos += 1;
            loop {
                skip_ws(chars, pos);
                if *pos >= chars.len() || chars[*pos] == ']' {
                    *pos += 1;
                    break;
                }
                let val = parse_number(chars, pos);
                result.push(val);
                skip_ws(chars, pos);
                if *pos < chars.len() && chars[*pos] == ',' {
                    *pos += 1;
                }
            }
            result
        }

        // Skip a JSON value (for keys we don't care about)
        fn skip_value(chars: &[char], pos: &mut usize) {
            skip_ws(chars, pos);
            if *pos >= chars.len() {
                return;
            }
            match chars[*pos] {
                '"' => {
                    parse_string(chars, pos);
                }
                '[' => {
                    *pos += 1;
                    let mut depth = 1;
                    while *pos < chars.len() && depth > 0 {
                        if chars[*pos] == '[' {
                            depth += 1;
                        }
                        if chars[*pos] == ']' {
                            depth -= 1;
                        }
                        *pos += 1;
                    }
                }
                '{' => {
                    *pos += 1;
                    let mut depth = 1;
                    while *pos < chars.len() && depth > 0 {
                        if chars[*pos] == '{' {
                            depth += 1;
                        }
                        if chars[*pos] == '}' {
                            depth -= 1;
                        }
                        *pos += 1;
                    }
                }
                _ => {
                    // number, bool, null
                    while *pos < chars.len()
                        && chars[*pos] != ','
                        && chars[*pos] != '}'
                        && chars[*pos] != ']'
                    {
                        *pos += 1;
                    }
                }
            }
        }

        let mut datasets = Vec::new();

        // Expect top-level array
        skip_ws(&chars, &mut pos);
        if pos >= len || chars[pos] != '[' {
            return None;
        }
        pos += 1;

        // Parse each species group object
        loop {
            skip_ws(&chars, &mut pos);
            if pos >= len || chars[pos] == ']' {
                break;
            }
            if chars[pos] != '{' {
                pos += 1;
                continue;
            }
            pos += 1;

            let mut species: u8 = 0;
            let mut species_name = String::new();
            let mut inputs: Vec<PetClusterInput> = Vec::new();
            let mut clusters: HashMap<String, String> = HashMap::new();

            // Parse object keys
            loop {
                skip_ws(&chars, &mut pos);
                if pos >= len || chars[pos] == '}' {
                    pos += 1;
                    break;
                }
                if chars[pos] == ',' {
                    pos += 1;
                    continue;
                }
                if chars[pos] != '"' {
                    pos += 1;
                    continue;
                }

                let key = parse_string(&chars, &mut pos);
                skip_ws(&chars, &mut pos);
                if pos < len && chars[pos] == ':' {
                    pos += 1;
                }
                skip_ws(&chars, &mut pos);

                match key.as_str() {
                    "species" => {
                        species = parse_number(&chars, &mut pos) as u8;
                    }
                    "speciesName" => {
                        species_name = parse_string(&chars, &mut pos);
                    }
                    "count" => {
                        parse_number(&chars, &mut pos);
                    }
                    "inputs" => {
                        // Parse array of input objects
                        if pos < len && chars[pos] == '[' {
                            pos += 1;
                            loop {
                                skip_ws(&chars, &mut pos);
                                if pos >= len || chars[pos] == ']' {
                                    pos += 1;
                                    break;
                                }
                                if chars[pos] == ',' {
                                    pos += 1;
                                    continue;
                                }
                                if chars[pos] != '{' {
                                    pos += 1;
                                    continue;
                                }
                                pos += 1;

                                let mut pet_face_id = String::new();
                                let mut face_emb: Vec<f64> = Vec::new();
                                let mut body_emb: Vec<f64> = Vec::new();
                                let mut file_id: i64 = 0;

                                loop {
                                    skip_ws(&chars, &mut pos);
                                    if pos >= len || chars[pos] == '}' {
                                        pos += 1;
                                        break;
                                    }
                                    if chars[pos] == ',' {
                                        pos += 1;
                                        continue;
                                    }
                                    if chars[pos] != '"' {
                                        pos += 1;
                                        continue;
                                    }
                                    let ikey = parse_string(&chars, &mut pos);
                                    skip_ws(&chars, &mut pos);
                                    if pos < len && chars[pos] == ':' {
                                        pos += 1;
                                    }
                                    skip_ws(&chars, &mut pos);

                                    match ikey.as_str() {
                                        "petFaceId" => {
                                            pet_face_id = parse_string(&chars, &mut pos);
                                        }
                                        "faceEmbedding" => {
                                            face_emb = parse_f64_array(&chars, &mut pos);
                                        }
                                        "bodyEmbedding" => {
                                            body_emb = parse_f64_array(&chars, &mut pos);
                                        }
                                        "fileId" => {
                                            file_id = parse_number(&chars, &mut pos) as i64;
                                        }
                                        _ => {
                                            skip_value(&chars, &mut pos);
                                        }
                                    }
                                }

                                inputs.push(PetClusterInput {
                                    pet_face_id,
                                    face_embedding: face_emb.iter().map(|&v| v as f32).collect(),
                                    body_embedding: body_emb.iter().map(|&v| v as f32).collect(),
                                    species,
                                    file_id,
                                });
                            }
                        }
                    }
                    "clusters" => {
                        // Parse object { petFaceId: clusterId, ... }
                        if pos < len && chars[pos] == '{' {
                            pos += 1;
                            loop {
                                skip_ws(&chars, &mut pos);
                                if pos >= len || chars[pos] == '}' {
                                    pos += 1;
                                    break;
                                }
                                if chars[pos] == ',' {
                                    pos += 1;
                                    continue;
                                }
                                if chars[pos] != '"' {
                                    pos += 1;
                                    continue;
                                }
                                let face_id = parse_string(&chars, &mut pos);
                                skip_ws(&chars, &mut pos);
                                if pos < len && chars[pos] == ':' {
                                    pos += 1;
                                }
                                skip_ws(&chars, &mut pos);
                                let cluster_id = parse_string(&chars, &mut pos);
                                clusters.insert(face_id, cluster_id);
                            }
                        }
                    }
                    _ => {
                        skip_value(&chars, &mut pos);
                    }
                }
            }

            if !inputs.is_empty() {
                datasets.push(RealDataset {
                    species,
                    species_name,
                    inputs,
                    existing_clusters: clusters,
                });
            }

            skip_ws(&chars, &mut pos);
            if pos < len && chars[pos] == ',' {
                pos += 1;
            }
        }

        Some(datasets)
    }

    // ── Metrics (same as cluster_eval) ────────────────────────────────────

    /// Convert existing cluster assignments to numeric ground-truth labels.
    fn cluster_ids_to_labels(
        inputs: &[PetClusterInput],
        clusters: &HashMap<String, String>,
    ) -> Vec<i32> {
        let mut id_map: HashMap<String, i32> = HashMap::new();
        let mut next = 0i32;

        inputs
            .iter()
            .map(|inp| {
                if let Some(cid) = clusters.get(&inp.pet_face_id) {
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
    }

    fn pred_labels_from_result(
        inputs: &[PetClusterInput],
        result: &crate::ml::pet::cluster::PetClusterResult,
    ) -> Vec<i32> {
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
    }

    fn eval_pairwise(true_labels: &[i32], pred_labels: &[i32]) -> (f64, f64, f64) {
        let n = true_labels.len();
        let valid: Vec<usize> = (0..n)
            .filter(|&i| pred_labels[i] >= 0 && true_labels[i] >= 0)
            .collect();
        let nv = valid.len();
        if nv < 2 {
            return (0.0, 0.0, 0.0);
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
                    (false, false) => {}
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
        (precision, recall, f1)
    }

    // ── Tests ─────────────────────────────────────────────────────────────

    #[test]
    fn realdata_threshold_sweep() {
        let datasets = match load_fixture() {
            Some(d) if !d.is_empty() => d,
            _ => {
                eprintln!("\n  [SKIP] No fixture at {}", FIXTURE_PATH);
                eprintln!("  To generate it:");
                eprintln!(
                    "    1. In the app, call PetClusteringService.instance.dumpEmbeddingsJson(...)"
                );
                eprintln!("    2. Copy the JSON file to rust/{}", FIXTURE_PATH);
                eprintln!("    3. Re-run this test\n");
                return;
            }
        };

        for ds in &datasets {
            let true_labels = cluster_ids_to_labels(&ds.inputs, &ds.existing_clusters);
            let n_true_clusters = {
                let mut s = std::collections::HashSet::new();
                for &l in &true_labels {
                    if l >= 0 {
                        s.insert(l);
                    }
                }
                s.len()
            };

            eprintln!("\n{}", "=".repeat(95));
            eprintln!(
                "  REAL DATA: {} (species={}, {} inputs, {} existing clusters)",
                ds.species_name,
                ds.species,
                ds.inputs.len(),
                n_true_clusters
            );
            eprintln!("{}", "=".repeat(95));

            // Distance stats
            let face_embs: Vec<Vec<f32>> = ds
                .inputs
                .iter()
                .filter(|i| !i.face_embedding.is_empty())
                .map(|i| i.face_embedding.clone())
                .collect();

            if face_embs.len() >= 2 {
                let mut intra = Vec::new();
                let mut inter = Vec::new();
                for i in 0..face_embs.len() {
                    for j in (i + 1)..face_embs.len() {
                        let idx_i = ds
                            .inputs
                            .iter()
                            .position(|inp| inp.face_embedding == face_embs[i])
                            .unwrap();
                        let idx_j = ds
                            .inputs
                            .iter()
                            .position(|inp| inp.face_embedding == face_embs[j])
                            .unwrap();
                        let d = 1.0 - dot(&face_embs[i], &face_embs[j]);
                        if true_labels[idx_i] >= 0
                            && true_labels[idx_j] >= 0
                            && true_labels[idx_i] == true_labels[idx_j]
                        {
                            intra.push(d);
                        } else if true_labels[idx_i] >= 0 && true_labels[idx_j] >= 0 {
                            inter.push(d);
                        }
                    }
                }
                intra.sort_by(|a, b| a.partial_cmp(b).unwrap());
                inter.sort_by(|a, b| a.partial_cmp(b).unwrap());

                if !intra.is_empty() && !inter.is_empty() {
                    let imean: f32 = intra.iter().sum::<f32>() / intra.len() as f32;
                    let emean: f32 = inter.iter().sum::<f32>() / inter.len() as f32;
                    eprintln!(
                        "  Intra-cluster dist: min={:.4} mean={:.4} max={:.4} (n={})",
                        intra[0],
                        imean,
                        intra.last().unwrap(),
                        intra.len()
                    );
                    eprintln!(
                        "  Inter-cluster dist: min={:.4} mean={:.4} max={:.4} (n={})",
                        inter[0],
                        emean,
                        inter.last().unwrap(),
                        inter.len()
                    );
                    eprintln!(
                        "  Ideal threshold: ({:.4}, {:.4})",
                        intra.last().unwrap(),
                        inter[0]
                    );
                }
            }

            // Threshold sweep using the full pipeline
            eprintln!(
                "\n  {:<12} | {:>4} | {:>5} | {:>7} | {:>7} | {:>7} | {:>13}",
                "Threshold", "K", "Noise", "Prec", "Recall", "F1", "vs existing"
            );
            eprintln!("  {}", "-".repeat(75));

            let thresholds: Vec<f32> = (30..=110).map(|i| i as f32 * 0.01).collect();

            let mut best_f1 = -1.0f64;
            let mut best_t = 0.0f32;

            for &t in &thresholds {
                let mut config = ClusterConfig::for_species(Species::from_u8(ds.species));
                config.agglomerative_threshold = t;
                let result = run_pet_clustering(&ds.inputs, &config);
                let pred = pred_labels_from_result(&ds.inputs, &result);

                let (prec, recall, f1) = eval_pairwise(&true_labels, &pred);
                let n_clusters = result.cluster_counts.len();
                let n_noise = result.n_unclustered;

                // Compare with existing: how many assignments match?
                let n_match = ds
                    .inputs
                    .iter()
                    .filter(|inp| {
                        let existing = ds.existing_clusters.get(&inp.pet_face_id);
                        let new = result.face_to_cluster.get(&inp.pet_face_id);
                        existing.is_some() && existing == new
                    })
                    .count();
                let match_pct = if !ds.existing_clusters.is_empty() {
                    n_match as f64 / ds.existing_clusters.len() as f64 * 100.0
                } else {
                    0.0
                };

                let mark = if f1 > best_f1 { "  <- BEST" } else { "" };
                if f1 > best_f1 {
                    best_f1 = f1;
                    best_t = t;
                }

                eprintln!(
                    "  {:<12.2} | {:>4} | {:>5} | {:>7.4} | {:>7.4} | {:>7.4} | {:>5.1}% match{}",
                    t, n_clusters, n_noise, prec, recall, f1, match_pct, mark
                );
            }

            eprintln!("\n  Best threshold: {:.2} (F1={:.4})", best_t, best_f1);
            eprintln!("  Production threshold: 0.85 (updated from 0.77)");

            // Run at production threshold and inspect
            let mut config = ClusterConfig::for_species(Species::from_u8(ds.species));
            config.agglomerative_threshold = 0.85;
            let result = run_pet_clustering(&ds.inputs, &config);

            eprintln!("\n  --- Production (t=0.85) cluster sizes ---");
            let mut sizes: Vec<(&String, &usize)> = result.cluster_counts.iter().collect();
            sizes.sort_by(|a, b| b.1.cmp(a.1));
            for (cid, count) in &sizes {
                eprintln!(
                    "    {} : {} members",
                    &cid[..std::cmp::min(20, cid.len())],
                    count
                );
            }
        }
    }

    #[test]
    fn realdata_per_cluster_inspection() {
        let datasets = match load_fixture() {
            Some(d) if !d.is_empty() => d,
            _ => {
                eprintln!("\n  [SKIP] No fixture at {}", FIXTURE_PATH);
                return;
            }
        };

        for ds in &datasets {
            eprintln!("\n{}", "=".repeat(95));
            eprintln!(
                "  CLUSTER INSPECTION: {} ({} inputs)",
                ds.species_name,
                ds.inputs.len()
            );
            eprintln!("{}", "=".repeat(95));

            // Run at new threshold
            let mut config = ClusterConfig::for_species(Species::from_u8(ds.species));
            config.agglomerative_threshold = 0.85;
            let result = run_pet_clustering(&ds.inputs, &config);

            // Group by predicted cluster
            let mut cluster_members: HashMap<String, Vec<usize>> = HashMap::new();
            for (i, inp) in ds.inputs.iter().enumerate() {
                if let Some(cid) = result.face_to_cluster.get(&inp.pet_face_id) {
                    cluster_members.entry(cid.clone()).or_default().push(i);
                }
            }

            let mut sorted_clusters: Vec<(String, Vec<usize>)> =
                cluster_members.into_iter().collect();
            sorted_clusters.sort_by(|a, b| b.1.len().cmp(&a.1.len()));

            for (cid, members) in &sorted_clusters {
                // Check if all members had the same existing cluster
                let existing_ids: Vec<Option<&String>> = members
                    .iter()
                    .map(|&i| ds.existing_clusters.get(&ds.inputs[i].pet_face_id))
                    .collect();

                let all_same = existing_ids.windows(2).all(|w| w[0] == w[1]);
                let status = if all_same { "CONSISTENT" } else { "MIXED" };

                eprintln!(
                    "\n  Cluster {} (size={}) [{}]",
                    &cid[..std::cmp::min(24, cid.len())],
                    members.len(),
                    status
                );

                for &i in members {
                    let inp = &ds.inputs[i];
                    let existing = ds
                        .existing_clusters
                        .get(&inp.pet_face_id)
                        .map(|s| &s[..std::cmp::min(12, s.len())])
                        .unwrap_or("none");
                    eprintln!(
                        "    file={:<8} face={:<20} was={}",
                        inp.file_id,
                        &inp.pet_face_id[..std::cmp::min(20, inp.pet_face_id.len())],
                        existing
                    );
                }
            }

            let unclustered: Vec<usize> = (0..ds.inputs.len())
                .filter(|i| {
                    !result
                        .face_to_cluster
                        .contains_key(&ds.inputs[*i].pet_face_id)
                })
                .collect();
            if !unclustered.is_empty() {
                eprintln!("\n  UNCLUSTERED ({}):", unclustered.len());
                for &i in &unclustered {
                    eprintln!(
                        "    file={} face={}",
                        ds.inputs[i].file_id, ds.inputs[i].pet_face_id
                    );
                }
            }
        }
    }
}

//! Standalone test binary for pet ML pipeline.
//!
//! Runs the *real* compiled Rust preprocessing, detection, alignment, and embedding
//! code on test images, then clusters them and dumps results to JSON so Python can compare.
//!
//! Usage:
//!   cargo run --bin pet_test -- \
//!     --images-dir ~/test_pets_mixed \
//!     --models-dir ~/pet_pipeline/pet_models \
//!     --output /tmp/rust_pet_cluster_output.json

use std::path::{Path, PathBuf};

use ente_photos_rust::ml::{
    error::MlResult,
    pet::{
        align, detect, embed,
        cluster::{run_pet_clustering, PetClusterInput, ClusterConfig},
    },
    runtime::{ExecutionProviderPolicy, MlRuntime, MlRuntimeConfig, ModelPaths, with_runtime},
    types::{DecodedImage, Dimensions},
};
use image::GenericImageView;

fn main() {
    let args: Vec<String> = std::env::args().collect();

    let images_dir = get_arg(&args, "--images-dir")
        .unwrap_or_else(|| "/Users/akente/test_pets_mixed".to_string());
    let models_dir = get_arg(&args, "--models-dir")
        .unwrap_or_else(|| "/Users/akente/pet_pipeline/pet_models".to_string());
    let output_path = get_arg(&args, "--output")
        .unwrap_or_else(|| "/tmp/rust_pet_cluster_output.json".to_string());

    eprintln!("=== Rust Pet Pipeline Test (All Images + Clustering) ===");
    eprintln!("Images: {images_dir}");
    eprintln!("Models: {models_dir}");
    eprintln!("Output: {output_path}");

    let config = MlRuntimeConfig {
        model_paths: ModelPaths {
            face_detection: String::new(),
            face_embedding: String::new(),
            clip_image: String::new(),
            clip_text: String::new(),
            pet_face_detection: format!("{models_dir}/yolov5s_face_fp16.onnx"),
            pet_face_embedding_dog: format!("{models_dir}/dog_byol_128.onnx"),
            pet_face_embedding_cat: format!("{models_dir}/cat_byol_128.onnx"),
            pet_body_detection: format!("{models_dir}/yolov5n.onnx"),
            pet_body_embedding_dog: format!("{models_dir}/dog_body_192.onnx"),
            pet_body_embedding_cat: format!("{models_dir}/cat_body_192.onnx"),
        },
        provider_policy: ExecutionProviderPolicy {
            prefer_coreml: false,
            prefer_nnapi: false,
            prefer_xnnpack: false,
            allow_cpu_fallback: true,
        },
    };

    let results = with_runtime(&config, |runtime| {
        process_all_images(runtime, &images_dir)
    });

    match results {
        Ok(image_results) => {
            // Run clustering
            let clustering = run_clustering(&image_results);
            let json = format_full_json(&image_results, &clustering);
            std::fs::write(&output_path, &json).expect("failed to write output JSON");
            eprintln!("\nWrote {} image results to {output_path}", image_results.len());
            eprintln!(
                "Clustering: dog={} clusters ({} unclustered), cat={} clusters ({} unclustered)",
                clustering.dog.cluster_counts.len(),
                clustering.dog.n_unclustered,
                clustering.cat.cluster_counts.len(),
                clustering.cat.n_unclustered,
            );
        }
        Err(e) => {
            eprintln!("ERROR: {e}");
            std::process::exit(1);
        }
    }
}

#[derive(Debug)]
struct ImageResult {
    folder: String,
    image_path: String,
    expected_species: String,
    pet_face_id: String,
    faces: Vec<FaceEmbeddingResult>,
    bodies: Vec<BodyEmbeddingResult>,
}

#[derive(Debug)]
struct FaceEmbeddingResult {
    score: f32,
    class_id: u8,
    species_label: String,
    box_xyxy: [f32; 4],
    embedding: Vec<f32>,
    embedding_dim: usize,
}

#[derive(Debug)]
struct BodyEmbeddingResult {
    score: f32,
    coco_class: u8,
    species_label: String,
    box_xyxy: [f32; 4],
    embedding: Vec<f32>,
    embedding_dim: usize,
}

struct ClusteringOutput {
    dog: SpeciesClusterOutput,
    cat: SpeciesClusterOutput,
}

struct SpeciesClusterOutput {
    /// pet_face_id -> cluster label string
    assignments: Vec<(String, String)>,
    n_unclustered: usize,
    cluster_counts: Vec<(String, usize)>,
}

fn process_all_images(runtime: &MlRuntime, images_dir: &str) -> MlResult<Vec<ImageResult>> {
    let mut results = Vec::new();
    let mut folders: Vec<_> = std::fs::read_dir(images_dir)
        .expect("cannot read images directory")
        .filter_map(|e| e.ok())
        .filter(|e| e.file_type().map(|t| t.is_dir()).unwrap_or(false))
        .collect();
    folders.sort_by_key(|e| e.file_name());

    for folder_entry in &folders {
        let folder_name = folder_entry.file_name().to_string_lossy().to_string();
        let expected = if folder_name.starts_with("dog") { "dog" } else { "cat" };
        let folder_path = folder_entry.path();

        let image_paths = find_all_images(&folder_path);
        if image_paths.is_empty() {
            eprintln!("  {folder_name}: no images found, skipping");
            continue;
        }

        eprintln!("\n--- {folder_name} ({expected}) — {} images ---", image_paths.len());

        for image_path in &image_paths {
            let file_stem = image_path
                .file_stem()
                .map(|s| s.to_string_lossy().to_string())
                .unwrap_or_default();
            let pet_face_id = format!("{}_{}", folder_name, file_stem);

            eprintln!("  Image: {} [id={}]", image_path.display(), pet_face_id);

            match process_single_image(runtime, image_path, &folder_name, expected, &pet_face_id) {
                Ok(result) => {
                    eprintln!("    Faces: {}, Bodies: {}", result.faces.len(), result.bodies.len());
                    for (i, f) in result.faces.iter().enumerate() {
                        eprintln!(
                            "      Face {i}: score={:.4}, class={} ({}), embed_dim={}",
                            f.score, f.class_id, f.species_label, f.embedding_dim
                        );
                    }
                    for (i, b) in result.bodies.iter().enumerate() {
                        eprintln!(
                            "      Body {i}: score={:.4}, coco_class={} ({}), embed_dim={}",
                            b.score, b.coco_class, b.species_label, b.embedding_dim
                        );
                    }
                    results.push(result);
                }
                Err(e) => {
                    eprintln!("    ERROR: {e}");
                }
            }
        }
    }

    Ok(results)
}

fn process_single_image(
    runtime: &MlRuntime,
    image_path: &Path,
    folder_name: &str,
    expected_species: &str,
    pet_face_id: &str,
) -> MlResult<ImageResult> {
    // Load and decode image to RGB
    let img = image::open(image_path)
        .map_err(|e| ente_photos_rust::ml::error::MlError::Decode(format!("{e}")))?;
    let (w, h) = img.dimensions();
    let rgb_image = img.to_rgb8();
    let rgb_bytes = rgb_image.into_raw();

    let decoded = DecodedImage {
        dimensions: Dimensions { width: w, height: h },
        rgb: rgb_bytes,
    };

    // --- Face pipeline ---
    let face_detections = detect::run_pet_face_detection(runtime, &decoded)?;

    let (aligned_inputs, mut face_results) =
        align::run_pet_face_alignment(1, &decoded, &face_detections)?;

    if !face_results.is_empty() {
        embed::run_pet_face_embedding(runtime, &aligned_inputs, &mut face_results)?;
    }

    let faces: Vec<FaceEmbeddingResult> = face_results
        .iter()
        .map(|fr| {
            let dim = fr.face_embedding.len();
            FaceEmbeddingResult {
                score: fr.detection.score,
                class_id: fr.detection.class_id,
                species_label: if fr.species == 0 { "dog".to_string() } else { "cat".to_string() },
                box_xyxy: fr.detection.box_xyxy,
                embedding: fr.face_embedding.clone(),
                embedding_dim: dim,
            }
        })
        .collect();

    // --- Body pipeline ---
    let body_detections = detect::run_pet_body_detection(runtime, &decoded)?;

    let mut body_results: Vec<_> = body_detections
        .iter()
        .map(|bd| ente_photos_rust::ml::types::PetBodyResult {
            detection: bd.clone(),
            pet_body_id: String::new(),
            body_embedding: Vec::new(),
        })
        .collect();

    if !body_results.is_empty() {
        embed::run_pet_body_embedding(runtime, &decoded, &mut body_results)?;
    }

    let bodies: Vec<BodyEmbeddingResult> = body_results
        .iter()
        .map(|br| {
            let dim = br.body_embedding.len();
            BodyEmbeddingResult {
                score: br.detection.score,
                coco_class: br.detection.coco_class,
                species_label: if br.detection.coco_class == 16 {
                    "dog".to_string()
                } else {
                    "cat".to_string()
                },
                box_xyxy: br.detection.box_xyxy,
                embedding: br.body_embedding.clone(),
                embedding_dim: dim,
            }
        })
        .collect();

    Ok(ImageResult {
        folder: folder_name.to_string(),
        image_path: image_path.to_string_lossy().to_string(),
        expected_species: expected_species.to_string(),
        pet_face_id: pet_face_id.to_string(),
        faces,
        bodies,
    })
}

fn run_clustering(results: &[ImageResult]) -> ClusteringOutput {
    // Build PetClusterInputs, split by species
    let mut dog_inputs = Vec::new();
    let mut cat_inputs = Vec::new();

    for r in results {
        // Pick highest-score face embedding (if any)
        let best_face = r.faces.iter().max_by(|a, b| {
            a.score.partial_cmp(&b.score).unwrap_or(std::cmp::Ordering::Equal)
        });
        let face_embedding = best_face
            .map(|f| f.embedding.clone())
            .unwrap_or_default();

        // Pick highest-score body embedding (if any)
        let best_body = r.bodies.iter().max_by(|a, b| {
            a.score.partial_cmp(&b.score).unwrap_or(std::cmp::Ordering::Equal)
        });
        let body_embedding = best_body
            .map(|b| b.embedding.clone())
            .unwrap_or_default();

        // Use folder-based species (matches Python pipeline's species split)
        let species_u8: u8 = if r.expected_species == "dog" { 0 } else { 1 };

        let input = PetClusterInput {
            pet_face_id: r.pet_face_id.clone(),
            face_embedding,
            body_embedding,
            species: species_u8,
            file_id: 0,
        };

        if species_u8 == 0 {
            dog_inputs.push(input);
        } else {
            cat_inputs.push(input);
        }
    }

    eprintln!("\n=== Clustering ===");
    eprintln!("Dogs: {} inputs", dog_inputs.len());
    eprintln!("Cats: {} inputs", cat_inputs.len());

    let dog_result = run_pet_clustering(&dog_inputs, &ClusterConfig::dog());
    let cat_result = run_pet_clustering(&cat_inputs, &ClusterConfig::cat());

    eprintln!(
        "Dog clustering: {} clusters, {} unclustered",
        dog_result.cluster_counts.len(),
        dog_result.n_unclustered
    );
    eprintln!(
        "Cat clustering: {} clusters, {} unclustered",
        cat_result.cluster_counts.len(),
        cat_result.n_unclustered
    );

    let dog_assignments: Vec<(String, String)> = dog_inputs
        .iter()
        .filter_map(|inp| {
            dog_result
                .face_to_cluster
                .get(&inp.pet_face_id)
                .map(|c| (inp.pet_face_id.clone(), c.clone()))
        })
        .collect();

    let mut dog_counts: Vec<(String, usize)> = dog_result.cluster_counts.into_iter().collect();
    dog_counts.sort_by(|a, b| a.0.cmp(&b.0));

    let cat_assignments: Vec<(String, String)> = cat_inputs
        .iter()
        .filter_map(|inp| {
            cat_result
                .face_to_cluster
                .get(&inp.pet_face_id)
                .map(|c| (inp.pet_face_id.clone(), c.clone()))
        })
        .collect();

    let mut cat_counts: Vec<(String, usize)> = cat_result.cluster_counts.into_iter().collect();
    cat_counts.sort_by(|a, b| a.0.cmp(&b.0));

    ClusteringOutput {
        dog: SpeciesClusterOutput {
            assignments: dog_assignments,
            n_unclustered: dog_result.n_unclustered,
            cluster_counts: dog_counts,
        },
        cat: SpeciesClusterOutput {
            assignments: cat_assignments,
            n_unclustered: cat_result.n_unclustered,
            cluster_counts: cat_counts,
        },
    }
}

fn find_all_images(dir: &Path) -> Vec<PathBuf> {
    let mut entries: Vec<_> = std::fs::read_dir(dir)
        .into_iter()
        .flatten()
        .filter_map(|e| e.ok())
        .filter(|e| {
            let name = e.file_name().to_string_lossy().to_lowercase();
            name.ends_with(".jpg") || name.ends_with(".jpeg") || name.ends_with(".png")
        })
        .collect();
    entries.sort_by_key(|e| e.file_name());
    entries.into_iter().map(|e| e.path()).collect()
}

fn get_arg(args: &[String], flag: &str) -> Option<String> {
    args.iter()
        .position(|a| a == flag)
        .and_then(|i| args.get(i + 1))
        .cloned()
}

fn format_full_json(results: &[ImageResult], clustering: &ClusteringOutput) -> String {
    let mut json = String::from("{\n");

    // Images array
    json.push_str("  \"images\": [\n");
    for (ri, r) in results.iter().enumerate() {
        json.push_str("    {\n");
        json.push_str(&format!("      \"folder\": {:?},\n", r.folder));
        json.push_str(&format!("      \"image_path\": {:?},\n", r.image_path));
        json.push_str(&format!("      \"expected_species\": {:?},\n", r.expected_species));
        json.push_str(&format!("      \"pet_face_id\": {:?},\n", r.pet_face_id));

        // Faces
        json.push_str("      \"faces\": [\n");
        for (fi, f) in r.faces.iter().enumerate() {
            json.push_str("        {\n");
            json.push_str(&format!("          \"score\": {},\n", f.score));
            json.push_str(&format!("          \"class_id\": {},\n", f.class_id));
            json.push_str(&format!("          \"species_label\": {:?},\n", f.species_label));
            json.push_str(&format!(
                "          \"box_xyxy\": [{}, {}, {}, {}],\n",
                f.box_xyxy[0], f.box_xyxy[1], f.box_xyxy[2], f.box_xyxy[3]
            ));
            json.push_str(&format!("          \"embedding_dim\": {},\n", f.embedding_dim));
            json.push_str("          \"embedding\": [");
            for (ei, v) in f.embedding.iter().enumerate() {
                if ei > 0 {
                    json.push_str(", ");
                }
                json.push_str(&format!("{v}"));
            }
            json.push_str("]\n");
            json.push_str("        }");
            if fi + 1 < r.faces.len() {
                json.push(',');
            }
            json.push('\n');
        }
        json.push_str("      ],\n");

        // Bodies
        json.push_str("      \"bodies\": [\n");
        for (bi, b) in r.bodies.iter().enumerate() {
            json.push_str("        {\n");
            json.push_str(&format!("          \"score\": {},\n", b.score));
            json.push_str(&format!("          \"coco_class\": {},\n", b.coco_class));
            json.push_str(&format!("          \"species_label\": {:?},\n", b.species_label));
            json.push_str(&format!(
                "          \"box_xyxy\": [{}, {}, {}, {}],\n",
                b.box_xyxy[0], b.box_xyxy[1], b.box_xyxy[2], b.box_xyxy[3]
            ));
            json.push_str(&format!("          \"embedding_dim\": {},\n", b.embedding_dim));
            json.push_str("          \"embedding\": [");
            for (ei, v) in b.embedding.iter().enumerate() {
                if ei > 0 {
                    json.push_str(", ");
                }
                json.push_str(&format!("{v}"));
            }
            json.push_str("]\n");
            json.push_str("        }");
            if bi + 1 < r.bodies.len() {
                json.push(',');
            }
            json.push('\n');
        }
        json.push_str("      ]\n");

        json.push_str("    }");
        if ri + 1 < results.len() {
            json.push(',');
        }
        json.push('\n');
    }
    json.push_str("  ],\n");

    // Clustering section
    json.push_str("  \"clustering\": {\n");

    // Dog
    json.push_str("    \"dog\": ");
    json.push_str(&format_species_cluster_json(&clustering.dog));
    json.push_str(",\n");

    // Cat
    json.push_str("    \"cat\": ");
    json.push_str(&format_species_cluster_json(&clustering.cat));
    json.push('\n');

    json.push_str("  }\n");
    json.push('}');
    json
}

fn format_species_cluster_json(output: &SpeciesClusterOutput) -> String {
    let mut json = String::from("{\n");

    // Assignments
    json.push_str("      \"assignments\": {");
    for (i, (face_id, cluster_id)) in output.assignments.iter().enumerate() {
        if i > 0 {
            json.push_str(", ");
        }
        json.push_str(&format!("{:?}: {:?}", face_id, cluster_id));
    }
    json.push_str("},\n");

    // n_unclustered
    json.push_str(&format!("      \"n_unclustered\": {},\n", output.n_unclustered));

    // cluster_counts
    json.push_str("      \"cluster_counts\": {");
    for (i, (cluster_id, count)) in output.cluster_counts.iter().enumerate() {
        if i > 0 {
            json.push_str(", ");
        }
        json.push_str(&format!("{:?}: {}", cluster_id, count));
    }
    json.push_str("}\n");

    json.push_str("    }");
    json
}

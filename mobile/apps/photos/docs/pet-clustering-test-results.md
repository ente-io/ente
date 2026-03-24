# Pet Clustering Test Results

Date: 2026-03-24

## Test Setup

- **Test images**: 38 pre-cropped 224x224 cat face crops in `~/Downloads/test_mix/`
- **Ground truth**: 6 groups (00-05) with 3-10 images each
- **Models tested**: All 4 pet embedding models
- **Note**: These crops are already aligned (224x224 is the alignment output size), so the "raw" path is the correct pipeline

## Ground Truth Groups

| Group | Images |
|-------|--------|
| 00    | 10     |
| 01    | 10     |
| 02    | 7      |
| 03    | 5      |
| 04    | 3      |
| 05    | 3      |

---

## All Models Comparison

Every model was tested on the same 38 images. Separation = inter - intra (positive = good).

| Model | Dim | Intra (same pet) | Inter (diff pet) | Separation | Best F1 | Best t |
|-------|-----|-----------------|-----------------|------------|---------|--------|
| Cat face BYOL | 128 | 0.9059 | 0.8933 | **-0.0126** | 0.3060 | 0.97 |
| Dog face BYOL | 128 | 0.6494 | 0.6294 | **-0.0200** | 0.3153 | 0.81 |
| Cat body      | 192 | 0.9385 | 0.8983 | **-0.0402** | 0.3060 | 0.97 |
| Dog body      | 192 | 0.6163 | 0.5956 | **-0.0206** | 0.3060 | 0.80 |

**ALL four models have negative separation** -- same-pet pairs are MORE distant than different-pet pairs. None can distinguish these cats. Best F1 across all models is ~0.31, which is achieved by putting everything in 1 cluster (trivial recall=1.0).

## Per-Group Distance Matrix (Cat Face Model)

Cosine distances between groups (diagonal = intra-group):

|    | 00    | 01    | 02    | 03    | 04    | 05    |
|----|-------|-------|-------|-------|-------|-------|
| 00 | 0.909 | 0.888 | 0.922 | 0.902 | 0.915 | 0.967 |
| 01 |       | 0.909 | 0.898 | 0.857 | 0.904 | 0.919 |
| 02 |       |       | 0.930 | 0.867 | 0.881 | 0.897 |
| 03 |       |       |       | 0.837 | 0.802 | 0.804 |
| 04 |       |       |       |       | 0.877 | 0.825 |
| 05 |       |       |       |       |       | 0.913 |

Key observations:
- Diagonal (same pet): 0.837 - 0.930
- Off-diagonal (different pet): 0.802 - 0.967
- The ranges completely overlap -- no threshold can separate them
- Groups 03-04 inter-distance (0.802) is LOWER than group 00 intra-distance (0.909)
- This means cat 03 looks MORE similar to cat 04 than cat 00 looks to itself across photos

## Alignment Impact Test

Running face detection + alignment on the already-aligned crops (double-processing):

| Method | Intra | Inter | Separation |
|--------|-------|-------|------------|
| Raw (correct) | 0.9059 | 0.8933 | -0.0126 |
| Double-aligned | 0.9122 | 0.8707 | -0.0415 |

Double-alignment makes things worse (expected -- it distorts already-normalized faces). Only 27/38 faces were re-detected by YOLOv5 in the crops.

## Threshold Sweep (Cat Face Model, Production Pipeline)

| Threshold | K | Precision | Recall | F1 |
|-----------|---|-----------|--------|------|
| 0.77 (old) | 12 | 0.0857 | 0.0472 | 0.0609 |
| **0.85 (current)** | **8** | **0.1233** | **0.1417** | **0.1319** |
| 0.90 | 6 | 0.1244 | 0.2047 | 0.1548 |
| 0.97 (best) | 1 | 0.1807 | 1.0000 | 0.3060 |

Best F1 = 0.31 at t=0.97, but that's 1 cluster containing all 38 images (trivial).

---

## Analysis

### Why the clustering fails on this dataset

The embedding models produce **indistinguishable** distance distributions for same-pet and different-pet pairs. This is NOT a clustering algorithm problem -- it's an embedding quality problem for this specific test set.

Evidence:
- All 4 models (face and body, cat and dog) show negative separation
- The per-group distance matrix shows complete overlap between intra and inter distances
- No threshold at any value produces F1 > 0.31

### Possible explanations

1. **Similar-looking cats**: If the 6 cats are the same breed/color, face embeddings genuinely can't distinguish them (even humans struggle with same-breed cats)

2. **Small crop size**: 224x224 face crops may not contain enough discriminative detail for cats. Cat faces have fewer distinctive landmarks than dog faces or human faces

3. **Model capacity**: The BYOL 128-d model may be undertrained for fine-grained cat re-identification. The training set may not have had enough same-cat pairs across varied conditions

4. **Missing context**: The body embedding (designed for coat pattern/body shape) was tested on face crops, not full body shots. On actual body crops, the 192-d body model might perform much better

### Clustering algorithm: verified correct

Synthetic tests (13/13 pass) confirm the algorithm works perfectly when embeddings are discriminative:

```
WITHOUT bodies: TP=16, FP=0, unclustered=5
WITH    bodies: TP=43, FP=0, unclustered=0
DELTA: TP+27, FP+0, unclustered-5
```

### What would improve real-world clustering

| Change | Layer | Impact |
|--------|-------|--------|
| Better BYOL model (larger, more training data) | Model | High -- directly improves separation |
| Test with actual body crops (not face crops) | Test | Medium -- body models designed for full body |
| Combine face + body scores in a learned way | Algorithm | Medium -- currently fixed weights |
| Export real embeddings from app | Test | High -- validates full pipeline end-to-end |
| Negative constraint: faces in same photo must be different | Algorithm | Low -- edge case |

### Next step

Export real aligned embeddings from the app via the "Dump pet embeddings JSON" debug button to validate the full pipeline on real user data. The test images here may not be representative of typical usage.

## How to run these tests

```bash
cd ~/ente/rust/photos

# All models comparison
ORT_DYLIB_PATH=/opt/homebrew/Cellar/onnxruntime/1.24.2/lib/libonnxruntime.dylib \
  cargo test realimages_all_models -- --nocapture

# Full pipeline with alignment
ORT_DYLIB_PATH=/opt/homebrew/Cellar/onnxruntime/1.24.2/lib/libonnxruntime.dylib \
  cargo test realimages_with_alignment -- --nocapture

# Original threshold sweep
ORT_DYLIB_PATH=/opt/homebrew/Cellar/onnxruntime/1.24.2/lib/libonnxruntime.dylib \
  cargo test realimages_embed_and_cluster -- --nocapture

# Real data from app (needs fixture file)
ORT_DYLIB_PATH=/opt/homebrew/Cellar/onnxruntime/1.24.2/lib/libonnxruntime.dylib \
  cargo test cluster_realdata -- --nocapture
```

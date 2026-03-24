# Pet Clustering Architecture

The pet clustering system has **4 layers**: ML models (detection + embedding), data storage (SQLite + vector DB), clustering engine (Rust), and user feedback (Dart).

---

## 1. ML Indexing Pipeline (Detection + Embedding)

When a photo is indexed, **6 ONNX models** run on-device (`lib/services/machine_learning/pet_ml/pet_model_services.dart`):

| Model | Purpose | Output |
|---|---|---|
| `yolov5s_pet_face_fp16.onnx` | Detect pet faces (with eye + nose landmarks) | Bounding boxes + keypoints |
| `dog_face_embedding128.onnx` | Dog face embedding (BYOL) | 128-d vector |
| `cat_face_embedding128.onnx` | Cat face embedding (BYOL) | 128-d vector |
| `yolov5s_object_fp16.onnx` | Detect pet bodies (COCO class 15=cat, 16=dog) | Bounding boxes |
| `dog_body_embedding192.onnx` | Dog body embedding | 192-d vector |
| `cat_body_embedding192.onnx` | Cat body embedding | 192-d vector |

```
                            +------------------+
                            |     Photo        |
                            +--------+---------+
                                     |
                     +---------------+---------------+
                     |                               |
              +------v-------+               +-------v------+
              | YOLOv5-face  |               | YOLOv5s COCO |
              | (pet faces)  |               | (pet bodies) |
              +------+-------+               +-------+------+
                     |                               |
              species classification          class filter
              (class_id: 0=dog, 1=cat)        (COCO 15=cat, 16=dog)
                     |                               |
          +----------+----------+          +---------+---------+
          |                     |          |                   |
   +------v------+       +-----v------+   +------v-----+ +----v-------+
   | Dog Face    |       | Cat Face   |   | Dog Body   | | Cat Body   |
   | BYOL 128-d  |       | BYOL 128-d |   | Embed 192-d| | Embed 192-d|
   +------+------+       +-----+------+   +------+-----+ +-----+------+
          |                     |                 |              |
          +----------+----------+                 +------+-------+
                     |                                   |
                     v                                   v
              face embedding                      body embedding
               (128-d vec)                         (192-d vec)
                     |                                   |
          +----------+----------+              +---------+---------+
          |                     |              |                   |
   +------v-------+     +------v-------+ +----v--------+ +-------v-------+
   | SQLite       |     | usearch VDB  | | SQLite      | | usearch VDB   |
   | petFacesTable|     | dogFace 128-d| | petBodies   | | dogBody 192-d |
   |              |     | catFace 128-d| | Table       | | catBody 192-d |
   +--------------+     +--------------+ +-------------+ +---------------+
```

Each detection produces a `PetFaceResult` or `PetBodyResult` (`lib/services/machine_learning/ml_result.dart:201-272`), which gets persisted as `DBPetFace`/`DBPetBody` rows in SQLite, and their embeddings go into separate **usearch vector databases** (one per species x modality = 4 online + 4 offline).

---

## 2. Data Storage Layer

```
+------------------------------- SQLite DB --------------------------------+
|                                                                          |
|  petFacesTable          petBodiesTable         petFaceClustersTable       |
|  +----------------+     +----------------+     +---------------------+   |
|  | fileId         |     | fileId         |     | petFaceId           |   |
|  | petFaceId      |     | petBodyId      |     | clusterId           |   |
|  | faceVectorId --+--+  | bodyVectorId --+--+  +---------------------+   |
|  | species        |  |  | species        |  |                            |
|  | score          |  |  | score          |  |  petClusterSummaryTable    |
|  | detection JSON |  |  | detection JSON |  |  +---------------------+   |
|  +----------------+  |  +----------------+  |  | clusterId           |   |
|                      |                      |  | count               |   |
|  petClusterPetTable  |                      |  | species             |   |
|  +----------------+  |                      |  +---------------------+   |
|  | clusterId      |  |                      |                            |
|  | petId ---------+--+--> PetEntity (E2EE)  |  notPetFeedbackTable      |
|  +----------------+  |                      |  +---------------------+   |
|                      |                      |  | clusterId           |   |
|  ID Mapping Tables   |                      |  | petFaceId           |   |
|  +----------------+  |                      |  +---------------------+   |
|  | petFaceId    --+--+                      |                            |
|  | vectorId (int) |                         |                            |
|  +----------------+                         |                            |
|  | petBodyId    --+--------------------------                            |
|  | vectorId (int) |                                                      |
|  +----------------+                                                      |
+--------------------------------------------------------------------------+

+------------------------ usearch Vector DBs --------------------------+
|                                                                       |
|  dogFace (128-d)    catFace (128-d)                                   |
|  +---------------+  +---------------+                                 |
|  | vectorId: emb |  | vectorId: emb |   <-- face embeddings          |
|  +---------------+  +---------------+                                 |
|                                                                       |
|  dogBody (192-d)    catBody (192-d)                                   |
|  +---------------+  +---------------+                                 |
|  | vectorId: emb |  | vectorId: emb |   <-- body embeddings          |
|  +---------------+  +---------------+                                 |
|                                                                       |
|  dogCentroid (128-d)  catCentroid (128-d)                             |
|  +------------------+ +------------------+                            |
|  | vectorId: emb    | | vectorId: emb    |  <-- cluster centroids     |
|  +------------------+ +------------------+                            |
+-----------------------------------------------------------------------+
```

### SQLite tables (via `lib/db/ml/schema.dart`):
- `petFacesTable` -- one row per detected pet face (fileId, petFaceId, species, faceVectorId, score, detection JSON)
- `petBodiesTable` -- one row per detected pet body
- `petFaceClustersTable` -- maps petFaceId -> clusterId
- `petClusterSummaryTable` -- cluster metadata (count, species)
- `petClusterPetTable` -- maps clusterId -> petId (the named PetEntity)
- `notPetFeedbackTable` -- "not this pet" feedback from user
- `petFaceVectorIdMappingTable` / `petBodyVectorIdMappingTable` -- string ID -> integer key mapping for usearch
- `petClusterCentroidVectorIdMappingTable` -- cluster ID -> centroid vector key

### Vector databases (`PetVectorDB` at `lib/db/ml/pet_vector_db.dart`):
- 4 online instances: `dogFace` (128-d), `catFace` (128-d), `dogBody` (192-d), `catBody` (192-d)
- 4 offline mirrors
- Built on **usearch** via Rust FFI for approximate nearest-neighbor search

### Centroid vector DB (`PetClusterCentroidVectorDB` at `lib/db/ml/pet_cluster_centroid_vector_db.dart`):
- Stores the L2-normalized mean centroid of each cluster's face embeddings (128-d)
- Used in incremental clustering to match new faces against existing clusters

---

## 3. Clustering Engine (Rust) -- 3-Phase Pipeline

Triggered from `MLService._clusterPets()` -> `PetClusteringService.clusterPets()` -> Rust FFI.

### Dart Orchestrator Flow

```
MLService._clusterPets()
         |
         v
PetClusteringService.clusterPets()
         |
         v
+-- unclustered count == 0? --YES--> return (nothing to do)
|        NO
|        v
+-- for each species (dog=0, cat=1):
         |
         v
    _clusterSpecies()
         |
    +----v--------------------------------------------+
    | 1. Load faces from SQLite (getPetFacesForClustering)
    | 2. Load bodies from SQLite (getPetBodiesForClustering)
    | 3. Pair bodies to faces by fileId (highest score wins)
    | 4. Fetch face embeddings from PetVectorDB
    | 5. Fetch body embeddings from PetVectorDB
    | 6. Build RustPetClusterInput list
    +----+--------------------------------------------+
         |
         v
    existing cluster summaries?
         |
    +----+----+
    |         |
   NO        YES
    |         |
    v         v
  BATCH    INCREMENTAL
  MODE     MODE
    |         |
    v         v
  runPet    runPetClusteringIncrementalRust()
  Clustering  (new faces + existing centroids)
  Rust()      |
    |         |
    +----+----+
         |
         v
    +----v--------------------------------------------+
    | 7. Apply user feedback (notPetFeedbackTable)    |
    |    - rejected faces -> assign to new UUID cluster|
    | 8. Save assignments (petFaceClustersTable)       |
    | 9. Recompute centroids from DB membership        |
    | 10. Update cluster summaries                     |
    | 11. Write centroids to PetClusterCentroidVectorDB|
    | 12. Clean up stale (empty) cluster summaries     |
    +--------------------------------------------------+
```

### The Rust 3-Phase Algorithm

```
                    All pet face/body inputs for one species
                                    |
                                    v
+======================================================================+
|                     PHASE 1: Face Clustering                         |
|                                                                      |
|   Inputs with face embeddings (128-d)                                |
|                                                                      |
|   1. Compute pairwise cosine distance matrix                         |
|      dist[i][j] = 1 - dot(face_i, face_j)                           |
|                                                                      |
|   2. Agglomerative clustering (average linkage)                      |
|      threshold = 0.85                                                |
|      max 5000 faces (memory guard: n^2 * 4 bytes)                    |
|                                                                      |
|   Result:                                                            |
|     +----------+  +----------+  +----------+     +-----------+       |
|     |Cluster A |  |Cluster B |  |Cluster C | ... |Unclustered|       |
|     |face,face |  |face,face |  |face      |     |face, face |       |
|     |face      |  |          |  |face,face |     |face       |       |
|     +----------+  +----------+  +----------+     +-----------+       |
+========================================|=============================+
                                         |
                                         v
+======================================================================+
|                     PHASE 2: Body Rescue                             |
|                                                                      |
|   For each UNCLUSTERED image that has a body embedding:              |
|                                                                      |
|   +------------------+     +------------------+                      |
|   | Unclustered img  |     | Existing Cluster |                      |
|   | body_emb (192-d) |---->| body members     |                      |
|   +------------------+     +------------------+                      |
|                                    |                                 |
|   Compare body vs each cluster member:                               |
|     sim = dot(candidate_body, member_body)                           |
|                                                                      |
|   Accept if:                                                         |
|     n_above_threshold >= min_body_agreements (dog:3, cat:2)          |
|     threshold = body_rescue_threshold (dog:0.25, cat:0.20)           |
|     avg_sim is best among all clusters                               |
|                                                                      |
|   Face veto check:                                                   |
|     If image also has a face:                                        |
|       face_sim = dot(face_emb, cluster_face_centroid)                |
|       If face_sim < 0.05 --> VETO (body matches but face doesn't)   |
|                                                                      |
|   Result: some unclustered images rescued into existing clusters     |
|                                                                      |
|     +----------+  +----------+  +----------+     +-----------+       |
|     |Cluster A |  |Cluster B |  |Cluster C | ... |Still      |       |
|     |face,face |  |face,face |  |face      |     |Unclustered|       |
|     |face      |  |+rescued  |  |face,face |     |img, img   |       |
|     |+rescued  |  |          |  |+rescued  |     |           |       |
|     +----------+  +----------+  +----------+     +-----------+       |
+========================================|=============================+
                                         |
                                         v
+======================================================================+
|                   PHASE 2b: Body-Only Clustering                     |
|                                                                      |
|   Still-unclustered images WITH body embeddings                      |
|                                                                      |
|   1. Compute pairwise cosine distance (body embeddings)              |
|      dist[i][j] = 1 - dot(body_i, body_j)                           |
|                                                                      |
|   2. Agglomerative clustering (same algorithm as Phase 1)            |
|      threshold = 0.85                                                |
|                                                                      |
|   Result: new body-only clusters formed                              |
|                                                                      |
|     +----------+  +----------+  +----------+  +--------+ +------+   |
|     |Cluster A |  |Cluster B |  |Cluster C |  |Clust D | |Clst E|   |
|     |(face)    |  |(face)    |  |(face)    |  |(body   | |(body |   |
|     |          |  |          |  |          |  | only)  | |only) |   |
|     +----------+  +----------+  +----------+  +--------+ +------+   |
+========================================|=============================+
                                         |
                                         v
+======================================================================+
|                   PHASE 3: Cross-Cluster Merge                       |
|                                                                      |
|   Goal: merge clusters that are separate in face space               |
|         but similar in body space (same pet, different angles)       |
|                                                                      |
|   Step 1: Compute body centroid per cluster                          |
|     centroid_X = median(all body embeddings in cluster X)            |
|                                                                      |
|   Step 2: Pre-screen pairs                                           |
|     +----------+      +----------+                                   |
|     |Cluster A |      |Cluster D |                                   |
|     |centroid  |----->|centroid   |                                   |
|     +----------+      +----------+                                   |
|     sim = dot(centroid_A, centroid_D)                                 |
|     Pass if sim > body_merge_threshold * 0.7                         |
|                                                                      |
|   Step 3: Full pairwise evaluation                                   |
|     For each candidate pair (A, D):                                  |
|       +----+    +----+                                               |
|       | a1 |--->| d1 |  sim = dot(body_a1, body_d1)                  |
|       | a2 |--->| d2 |  sim = dot(body_a1, body_d2)                  |
|       | a3 |    |    |  ... all pairs                                |
|       +----+    +----+                                               |
|                                                                      |
|     Accept if:                                                       |
|       avg_body_sim >= body_merge_threshold (dog:0.35, cat:0.30)      |
|       ratio_above >= min_body_overlap_ratio (0.50)                   |
|                                                                      |
|     Face contradiction check:                                        |
|       If both clusters have faces:                                   |
|         avg_face_sim < face_contradiction_threshold (0.10)           |
|         --> BLOCK (bodies similar but faces clearly different)        |
|                                                                      |
|   Step 4: Union-find merge (best similarity first)                   |
|                                                                      |
|   Before:  A  B  C  D  E                                            |
|   After:   [A+D]  B  [C+E]    (example merges)                      |
+======================================================================+
```

### Incremental Mode

```
+-------------------+        +------------------------+
| New unclustered   |        | Existing cluster       |
| faces/bodies      |        | centroids (from VDB)   |
+--------+----------+        +-----------+------------+
         |                                |
         v                                v
    +-------------------------------------------------+
    | For each new input:                             |
    |                                                 |
    |   score = face_weight * dot(face, centroid_face)|
    |         + body_weight * dot(body, centroid_body)|
    |                                                 |
    |   Dog: 0.5 * face + 0.5 * body                 |
    |   Cat: 0.3 * face + 0.7 * body                 |
    |                                                 |
    |   If only one modality: use raw similarity      |
    |   Assign to best cluster if score > threshold   |
    +---------+-------------------+-------------------+
              |                   |
         assigned            unassigned
              |                   |
              v                   v
    +------------------+   +---------------------+
    | Added to existing|   | Run full 3-phase    |
    | clusters         |   | pipeline on these   |
    +------------------+   | (batch mode)        |
                           +---------------------+
```

### Species-specific configs

| Parameter | Dog | Cat |
|---|---|---|
| face_weight | 0.5 | 0.3 |
| body_rescue_threshold | 0.25 | 0.20 |
| min_body_agreements | 3 | 2 |
| body_merge_threshold | 0.35 | 0.30 |
| agglomerative_threshold | 0.85 | 0.85 |

Cats use lower face weight because cat faces are less distinctive than dog faces, so body evidence is weighted more heavily.

---

## 4. PetEntity and User Feedback

```
+------------------------------------------------------------------+
|                        User Interaction                           |
|                                                                  |
|  "Name this pet"     "Not this pet"      "Merge these two"      |
|       |                    |                     |               |
|       v                    v                     v               |
|  SaveOrEditPet      Remove faces from      Merge clusters       |
|  (UI widget)        cluster                (map to same          |
|       |                    |                PetEntity)           |
|       v                    v                     |               |
+-------+--------------------+---------------------+--------------+
        |                    |                     |
        v                    v                     v
+------------------------------------------------------------------+
|                 PetClusterFeedbackService                        |
|                                                                  |
|  removePetFacesFromCluster:                                      |
|    1. Find petFaceIds for given fileIds in cluster               |
|    2. Record (clusterId, faceId) in notPetFeedbackTable          |
|    3. Move each face to new singleton cluster (UUID)             |
|    4. Recompute summaries + centroids for affected clusters      |
|                                                                  |
|  movePetFacesToCluster:                                          |
|    1. Find petFaceIds for given fileIds in source cluster        |
|    2. Record feedback in notPetFeedbackTable                     |
|    3. Reassign faces to target cluster                           |
|    4. Recompute summaries + centroids                            |
|                                                                  |
|  mergePetClusters:                                               |
|    1. Find or create PetEntity for target cluster                |
|    2. Map source cluster to same PetEntity (petClusterPetTable)  |
|    (Reversible -- clusters keep their own faces/summaries)       |
+-------------------------------+----------------------------------+
                                |
                                v
+------------------------------------------------------------------+
|                        PetService                                |
|                                                                  |
|  PetEntity (synced E2EE via EntityType.person):                  |
|  +------------------------------------------------------------+  |
|  | remoteID    | name     | species | assigned (ClusterInfo[]) |  |
|  | avatarFaceID| isHidden | isPinned| rejectedFaceIDs          |  |
|  | birthDate   | hideFromMemories   | manuallyAssigned         |  |
|  +------------------------------------------------------------+  |
|                                                                  |
|  Multiple clusters --> one PetEntity (via petClusterPetTable)    |
|                                                                  |
|  Cached in memory, invalidated on sync or mutation               |
|  Synced to server via entity sync service                        |
+------------------------------------------------------------------+
```

### Feedback Loop

```
                    +---> Clustering assigns faces to clusters
                    |            |
                    |            v
                    |     User sees clusters in UI
                    |            |
                    |     +------+------+------+
                    |     |             |      |
                    |   Correct     Wrong    Merge
                    |   (name it)  (remove) (combine)
                    |     |             |      |
                    |     v             v      v
                    |   PetEntity   notPet   petCluster
                    |   created    Feedback  PetTable
                    |     |        Table     updated
                    |     |             |      |
                    |     +------+------+------+
                    |            |
                    |            v
                    |     Next clustering run respects feedback:
                    |       - Rejected faces get new UUID cluster
                    |       - Centroids recomputed
                    |       - Summaries updated
                    |            |
                    +------------+
```

---

## End-to-End Flow

```
+--------+     +-------------+     +-----------+     +----------+     +------+
| Photo  |---->| Detection   |---->| Embedding |---->| Storage  |---->| Rust |
|        |     | YOLOv5 face |     | BYOL 128-d|     | SQLite + |     | 3-   |
|        |     | YOLOv5 body |     | Body 192-d|     | usearch  |     |phase |
+--------+     +-------------+     +-----------+     +----------+     +--+---+
                                                                         |
    +--------------------------------------------------------------------+
    |
    v
+--------+     +-----------+     +-----------+
| Store  |---->| UI shows  |---->| User      |
| assign |     | clusters  |     | feedback  |---+
| ments  |     | + pets    |     | (name,    |   |
+--------+     +-----------+     | remove,   |   |
                                 | merge)    |   |
                                 +-----------+   |
                                                 |
    +--------------------------------------------+
    |
    v
+------------------+
| Update feedback  |
| tables + re-     |
| compute centroids|
| for next run     |
+------------------+
```

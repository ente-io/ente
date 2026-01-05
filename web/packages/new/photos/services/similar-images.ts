import { newID } from "ente-base/id";
import type { EnteFile } from "ente-media/file";
import { FileType } from "ente-media/file-type";
import { savedCollectionFiles } from "./photos-fdb";
import {
    createCollectionNameByID,
    savedNormalCollections,
} from "./collection";
import { ensureLocalUser } from "ente-accounts/services/user";
import {
    clearCachedCLIPIndexes,
    getCLIPIndexes,
} from "./ml/clip";
import {
    clearSimilarImagesCache as clearSimilarImagesCacheInDB,
    loadSimilarImagesCache,
    saveSimilarImagesCache,
    loadHNSWIndexMetadata,
    saveHNSWIndexMetadata,
    clearHNSWIndexMetadata,
    generateFileIDHash,
} from "./ml/db";
import { dotProduct } from "./ml/math";
import { getCLIPHNSWIndex, clearCLIPHNSWIndex, type HNSWIndex } from "./ml/hnsw";
import type {
    CachedSimilarImages,
    SimilarImageGroup,
    SimilarImageItem,
    SimilarImagesOptions,
    SimilarImagesResult,
} from "./similar-images-types";

/**
 * Default distance threshold for considering images as similar.
 *
 * Based on CLIP embedding cosine distance:
 * - 0.04 is a good balance between finding true duplicates/similar shots
 *   and avoiding false positives.
 */
const DEFAULT_DISTANCE_THRESHOLD = 0.04;

/**
 * Cache version for similar images results.
 */
const CACHE_VERSION = 1;

/**
 * Find similar images in the user's library.
 *
 * This function analyzes the user's library using CLIP embeddings to find
 * visually similar images. The results are grouped by similarity.
 *
 * [Note: Similar Images Algorithm]
 *
 * 1. Fetch all CLIP embeddings from IndexedDB.
 * 2. Fetch all user files and their collection associations.
 * 3. Match files with their embeddings.
 * 4. Check cache for existing results.
 * 5. If cache miss, group files by similarity using O(n²) pairwise comparison.
 * 6. Cache the results for future use.
 * 7. Return groups with more than one file.
 *
 * @param options Configuration options for the search.
 * @returns Promise resolving to the analysis results.
 */
export const getSimilarImages = async (
    options: SimilarImagesOptions = {},
): Promise<SimilarImagesResult> => {
    const startTime = performance.now();

    const {
        distanceThreshold = DEFAULT_DISTANCE_THRESHOLD,
        fileIDs: specificFileIDs,
        forceRefresh = false,
        onProgress,
    } = options;

    // Step 1: Get all CLIP embeddings
    onProgress?.(10);
    const clipIndexes = await getCLIPIndexes();
    console.log(`[Similar Images] Loaded ${clipIndexes.length} CLIP embeddings`);
    const embeddingsByFileID = new Map<number, Float32Array>();
    for (const index of clipIndexes) {
        embeddingsByFileID.set(index.fileID, index.embedding);
    }

    // Step 2: Get all eligible files
    onProgress?.(30);
    const userID = ensureLocalUser().id;
    const normalCollections = await savedNormalCollections();
    const normalOwnedCollections = normalCollections.filter(
        ({ owner }) => owner.id == userID,
    );
    const allowedCollectionIDs = new Set(
        normalOwnedCollections.map(({ id }) => id),
    );
    const collectionNameByID = createCollectionNameByID(normalOwnedCollections);

    let collectionFiles = await savedCollectionFiles();
    collectionFiles = collectionFiles.filter(
        (f) =>
            allowedCollectionIDs.has(f.collectionID) &&
            f.ownerID == userID && // Only user's own files
            f.metadata.fileType !== FileType.video && // Exclude videos
            embeddingsByFileID.has(f.id), // Must have CLIP embedding
    );

    // If specific fileIDs are provided, filter to those
    if (specificFileIDs) {
        const specificFileSet = new Set(specificFileIDs);
        collectionFiles = collectionFiles.filter((f) =>
            specificFileSet.has(f.id),
        );
    }

    // Aggregate collection IDs per file ID (like dedup.ts does)
    // Each file can belong to multiple collections, but savedCollectionFiles()
    // returns one entry per (file, collection) pair. We need to aggregate all
    // collection IDs for each file to preserve all memberships during deletion.
    const collectionIDsByFileID = new Map<number, Set<number>>();
    const uniqueFiles = new Map<number, EnteFile>();
    for (const file of collectionFiles) {
        let collectionIDs = collectionIDsByFileID.get(file.id);
        if (!collectionIDs) {
            collectionIDsByFileID.set(file.id, (collectionIDs = new Set()));
            // First time seeing this file ID, store the file
            uniqueFiles.set(file.id, file);
        }
        collectionIDs.add(file.collectionID);
    }

    const files = Array.from(uniqueFiles.values());
    const fileIDs = Array.from(uniqueFiles.keys());
    console.log(`[Similar Images] Found ${files.length} eligible files with embeddings`);

    // Step 3: Check cache for existing results
    onProgress?.(40);
    if (!forceRefresh && fileIDs.length > 0) {
        console.log(`[Similar Images] Checking cache...`);
        const cached = await loadSimilarImagesCache(distanceThreshold, fileIDs);
        if (cached && cached.version === CACHE_VERSION) {
            console.log(`[Similar Images] Cache found, validating...`);
            // Cache hit - verify the cached groups are still valid
            // For large libraries, skip the expensive validation
            if (fileIDs.length > 10000) {
                console.log(`[Similar Images] Large library detected, trusting cache`);
                return {
                    groups: cached.groups,
                    totalFilesAnalyzed: fileIDs.length,
                    filesWithEmbeddings: embeddingsByFileID.size,
                    computationTimeMs: 0, // Cache hit, no computation needed
                };
            }
            const cachedFileIDs = new Set(cached.fileIDs);
            const stillValid = fileIDs.every((id) => cachedFileIDs.has(id));
            if (stillValid) {
                console.log(`[Similar Images] Cache is valid, using cached results`);
                return {
                    groups: cached.groups,
                    totalFilesAnalyzed: fileIDs.length,
                    filesWithEmbeddings: embeddingsByFileID.size,
                    computationTimeMs: 0, // Cache hit, no computation needed
                };
            }
        }
        console.log(`[Similar Images] Cache miss or invalid, computing...`);
    }

    // Step 4: Group files by similarity (cache miss)
    onProgress?.(50);
    console.log(`[Similar Images] Starting similarity computation for ${files.length} files...`);

    // Use HNSW-based grouping for better performance
    const groups = await groupSimilarImagesHNSW(
        files,
        collectionIDsByFileID,
        embeddingsByFileID,
        collectionNameByID,
        distanceThreshold,
        onProgress,
    );
    console.log(`[Similar Images] Found ${groups.length} similar image groups`);

    // Step 5: Save to cache
    if (fileIDs.length > 0 && !forceRefresh) {
        const cacheKey = `si_${distanceThreshold.toFixed(3)}_${hashFileIDs(
            fileIDs,
        )}`;
        const cacheEntry: CachedSimilarImages = {
            id: cacheKey,
            groups,
            distanceThreshold,
            fileIDs,
            createdAt: Date.now(),
            version: CACHE_VERSION,
        };
        await saveSimilarImagesCache(cacheEntry);
    }

    const endTime = performance.now();

    return {
        groups,
        totalFilesAnalyzed: collectionFiles.length,
        filesWithEmbeddings: embeddingsByFileID.size,
        computationTimeMs: Math.round(endTime - startTime),
    };
};

/**
 * Generate a hash of file IDs for cache key generation.
 */
const hashFileIDs = (fileIDs: number[]): string => {
    const sorted = [...fileIDs].sort((a, b) => a - b).join(",");
    let hash = 0;
    for (let i = 0; i < sorted.length; i++) {
        const char = sorted.charCodeAt(i);
        hash = (hash << 5) - hash + char;
        hash = hash & hash;
    }
    return Math.abs(hash).toString(36);
};

/**
 * Group files by visual similarity using HNSW index for efficient search.
 *
 * Uses HNSW (Hierarchical Navigable Small World) approximate nearest neighbor
 * algorithm. Much faster than O(n²) for large libraries:
 * - O(n²): ~6.4B comparisons for 80k images
 * - HNSW: ~1.3M comparisons for 80k images (~5000x faster)
 *
 * Implements index persistence for massive performance improvement:
 * - First load: ~7 minutes (build + save)
 * - Subsequent loads: ~2-5 seconds (load from IDBFS)
 */
const groupSimilarImagesHNSW = async (
    files: EnteFile[],
    collectionIDsByFileID: Map<number, Set<number>>,
    embeddingsByFileID: Map<number, Float32Array>,
    collectionNameByID: Map<number, string>,
    threshold: number,
    onProgress?: (progress: number) => void,
): Promise<SimilarImageGroup[]> => {
    if (files.length < 2) return [];

    onProgress?.(55);

    // Prepare vectors for indexing
    const fileIDs: number[] = [];
    const embeddings: Float32Array[] = [];
    for (const file of files) {
        const embedding = embeddingsByFileID.get(file.id);
        if (embedding) {
            fileIDs.push(file.id);
            embeddings.push(embedding);
        }
    }

    const currentFileIDHash = generateFileIDHash(fileIDs);
    const indexFilename = "clip_hnsw.bin";

    // Try to load cached index
    console.log(`[Similar Images] Checking for cached HNSW index...`);
    const cachedMetadata = await loadHNSWIndexMetadata("clip-hnsw-index");

    // Clear any existing index in memory
    clearCLIPHNSWIndex();

    let indexLoaded = false;
    let index: HNSWIndex;

    if (cachedMetadata) {
        // We have a cached index - try to load it
        console.log(`[Similar Images] Found cached index (${cachedMetadata.vectorCount} vectors)`);
        console.log(`[Similar Images] Cached metadata:`, {
            vectorCount: cachedMetadata.vectorCount,
            maxElements: cachedMetadata.maxElements,
            fileIDHash: cachedMetadata.fileIDHash?.substring(0, 16) + '...',
            mappingsCount: cachedMetadata.fileIDToLabel.length,
        });

        // Backward compatibility: If old cache doesn't have maxElements, estimate it
        if (!cachedMetadata.maxElements) {
            console.log(`[Similar Images] Old cache format detected (missing maxElements)`);
            // Estimate the original capacity (would have been rounded up to nearest 10k)
            const estimatedCapacity = Math.ceil(cachedMetadata.vectorCount / 10000) * 10000;
            console.log(`[Similar Images] Estimating original capacity: ${estimatedCapacity} (from ${cachedMetadata.vectorCount} vectors)`);

            // Try to load with estimated capacity
            cachedMetadata.maxElements = estimatedCapacity;
        }

        // Check if we need incremental updates
        const cachedFileIDs = new Set(
            cachedMetadata.fileIDToLabel.map(([fileID]) => fileID)
        );
        const currentFileIDs = new Set(fileIDs);
        const addedFileIDs = fileIDs.filter(id => !cachedFileIDs.has(id));
        const removedFileIDs = Array.from(cachedFileIDs).filter(id => !currentFileIDs.has(id));

        // Check if capacity is sufficient for incremental updates
        const netChange = addedFileIDs.length - removedFileIDs.length;
        const requiredSize = cachedMetadata.vectorCount + netChange;

        // Check if the cached index has enough capacity
        const cachedMaxElements = cachedMetadata.maxElements;

        // If adding more vectors than the cached index can hold, rebuild from scratch
        if (requiredSize > cachedMaxElements) {
                console.log(`[Similar Images] Capacity insufficient (need ${requiredSize}, cached max ${cachedMaxElements}), will rebuild`);
                console.log(`[Similar Images] Cache details: ${cachedMetadata.vectorCount} cached, +${addedFileIDs.length} added, -${removedFileIDs.length} removed = ${requiredSize} required`);

                // Create fresh index with correct capacity
                index = await getCLIPHNSWIndex(fileIDs.length);
                console.log(`[Similar Images] Created fresh index with capacity: ${index.getMaxElements()}`);

                indexLoaded = false;
            } else if (cachedMetadata.fileIDHash === currentFileIDHash) {
                // No changes, just load the cached index
                console.log(`[Similar Images] Loading index from IDBFS...`);
                // CRITICAL: Use the exact maxElements from when the index was saved
                // CRITICAL: Pass skipInit=true since we'll call loadIndex()
                index = await getCLIPHNSWIndex(cachedMetadata.maxElements, true);
                onProgress?.(56);

                try {
                    await index.loadIndex(indexFilename, {
                        fileIDToLabel: cachedMetadata.fileIDToLabel,
                        labelToFileID: cachedMetadata.labelToFileID,
                    });
                    console.log(`[Similar Images] Index is up-to-date, no changes needed`);
                    indexLoaded = true;
                    onProgress?.(65);
                } catch (error) {
                    console.error(`[Similar Images] Failed to load cached index, clearing corrupted cache and rebuilding:`, error);
                    // Clear the corrupted index and create a fresh one for rebuild
                    clearCLIPHNSWIndex();

                    // Delete corrupted metadata so we don't keep trying to load it
                    try {
                        await clearHNSWIndexMetadata();
                        console.log(`[Similar Images] Cleared corrupted cache metadata`);
                    } catch (deleteError) {
                        console.warn(`[Similar Images] Failed to clear cache metadata (non-fatal):`, deleteError);
                    }

                    index = await getCLIPHNSWIndex(fileIDs.length);
                    indexLoaded = false;
                }
            } else {
                // Changes detected, load and apply incremental updates
                console.log(`[Similar Images] Loading index from IDBFS for incremental update...`);
                console.log(`[Similar Images] Changes: +${addedFileIDs.length} files, -${removedFileIDs.length} files`);
                // CRITICAL: Use the exact maxElements from when the index was saved
                // CRITICAL: Pass skipInit=true since we'll call loadIndex()
                index = await getCLIPHNSWIndex(cachedMetadata.maxElements, true);
                onProgress?.(56);

                try {
                    await index.loadIndex(indexFilename, {
                        fileIDToLabel: cachedMetadata.fileIDToLabel,
                        labelToFileID: cachedMetadata.labelToFileID,
                    });
                    console.log(`[Similar Images] Successfully loaded cached index`);

                    // Apply incremental updates
                    if (removedFileIDs.length > 0 || addedFileIDs.length > 0) {
                        // Remove deleted files
                        for (const fileID of removedFileIDs) {
                            index.removeVector(fileID);
                        }

                        // Add new files
                        for (const fileID of addedFileIDs) {
                            const embedding = embeddingsByFileID.get(fileID);
                            if (embedding) {
                                index.addVector(fileID, embedding);
                            }
                        }

                        console.log(`[Similar Images] Incremental update completed`);

                        // Save updated index
                        console.log(`[Similar Images] Saving updated index...`);
                        const mappings = await index.saveIndex(indexFilename);

                        // Update metadata
                        await saveHNSWIndexMetadata({
                            id: "clip-hnsw-index",
                            fileIDHash: currentFileIDHash,
                            fileIDToLabel: mappings.fileIDToLabel,
                            labelToFileID: mappings.labelToFileID,
                            vectorCount: fileIDs.length,
                            maxElements: index.getMaxElements(),
                            createdAt: Date.now(),
                            filename: indexFilename,
                        });
                        console.log(`[Similar Images] Updated index saved`);
                    }

                    indexLoaded = true;
                    onProgress?.(65);
                } catch (error) {
                    console.error(`[Similar Images] Failed to load/update cached index, clearing corrupted cache and rebuilding:`, error);
                    // Clear the corrupted index and create a fresh one for rebuild
                    clearCLIPHNSWIndex();

                    // Delete corrupted metadata so we don't keep trying to load it
                    try {
                        await clearHNSWIndexMetadata();
                        console.log(`[Similar Images] Cleared corrupted cache metadata`);
                    } catch (deleteError) {
                        console.warn(`[Similar Images] Failed to clear cache metadata (non-fatal):`, deleteError);
                    }

                    index = await getCLIPHNSWIndex(fileIDs.length);
                    indexLoaded = false;
                }
            }
    } else {
        console.log(`[Similar Images] No cached index found, building from scratch...`);
        index = await getCLIPHNSWIndex(fileIDs.length);
    }

    if (!indexLoaded) {
        // Build index from scratch
        console.log(`[Similar Images] Building HNSW index for ${fileIDs.length} vectors...`);
        console.log(`[Similar Images] Index capacity: ${index.getMaxElements()}, current size: ${index.size()}`);
        onProgress?.(58);

        try {
            // Add all vectors at once with progress reporting
            await index.addVectors(fileIDs, embeddings, (addProgress) => {
                // Map internal progress (0-100) to overall progress (58-90)
                const overallProgress = 58 + (addProgress * 32) / 100;
                onProgress?.(Math.round(overallProgress));
            });
            console.log(`[Similar Images] Successfully added ${index.size()} vectors`);

            onProgress?.(90);

            // Save index to IDBFS for next time
            console.log(`[Similar Images] Saving index to IDBFS...`);
            const mappings = await index.saveIndex(indexFilename);

            // Save metadata to IndexedDB
            await saveHNSWIndexMetadata({
                id: "clip-hnsw-index",
                fileIDHash: currentFileIDHash,
                fileIDToLabel: mappings.fileIDToLabel,
                labelToFileID: mappings.labelToFileID,
                vectorCount: fileIDs.length,
                maxElements: index.getMaxElements(),
                createdAt: Date.now(),
                filename: indexFilename,
            });

            console.log(`[Similar Images] Index saved successfully`);
            onProgress?.(95);
        } catch (error) {
            console.error(`[Similar Images] Failed to add vectors to HNSW index:`, error);
            throw new Error(`Failed to build similarity index: ${error}`);
        }
    }

    onProgress?.(65);

    // Search for similar files using HNSW
    console.log(`[Similar Images] Searching for similar images...`);
    const searchResults = await index.searchBatch(
        fileIDs,
        embeddings,
        100, // k neighbors to search
        (searchProgress) => {
            // Map search progress (0-100) to overall progress (65-80)
            const overallProgress = 65 + (searchProgress * 15) / 100;
            onProgress?.(Math.round(overallProgress));
        },
    );

    onProgress?.(80);

    // Group similar files
    console.log(`[Similar Images] Grouping similar images...`);
    const usedFileIDs = new Set<number>();
    const groups: SimilarImageGroup[] = [];
    const fileByID = new Map(files.map((f) => [f.id, f]));

    for (const [fileID, neighbors] of searchResults) {
        if (usedFileIDs.has(fileID)) continue;

        const referenceFile = fileByID.get(fileID);
        if (!referenceFile) continue;

        const group: SimilarImageItem[] = [];
        let furthestDistance = 0;

        // Add reference file with all its collection memberships
        const referenceCollectionIDs = collectionIDsByFileID.get(fileID) || new Set([referenceFile.collectionID]);
        group.push({
            file: referenceFile,
            distance: 0,
            similarityScore: 100,
            collectionIDs: referenceCollectionIDs,
            collectionName:
                collectionNameByID.get(referenceFile.collectionID) || "Unknown",
        });

        // Add similar files within threshold
        for (const { fileID: neighborID, distance } of neighbors) {
            if (usedFileIDs.has(neighborID)) continue;
            if (distance > threshold) continue;

            const neighborFile = fileByID.get(neighborID);
            if (!neighborFile) continue;

            // Get all collection memberships for this file
            const neighborCollectionIDs = collectionIDsByFileID.get(neighborID) || new Set([neighborFile.collectionID]);
            const similarityScore = Math.round((1 - distance) * 100);
            group.push({
                file: neighborFile,
                distance,
                similarityScore,
                collectionIDs: neighborCollectionIDs,
                collectionName:
                    collectionNameByID.get(neighborFile.collectionID) ||
                    "Unknown",
            });

            if (distance > furthestDistance) {
                furthestDistance = distance;
            }

            usedFileIDs.add(neighborID);
        }

        // Only create group if we have more than one file
        if (group.length > 1) {
            // Sort by distance
            group.sort((a, b) => a.distance - b.distance);

            groups.push({
                id: newID("sig_"),
                items: group,
                furthestDistance,
                totalSize: group.reduce((sum, item) => {
                    const fileSize = item.file.info?.fileSize || 0;
                    return sum + fileSize;
                }, 0),
                isSelected: true,
            });

            usedFileIDs.add(fileID);
        }
    }

    onProgress?.(100);
    console.log(`[Similar Images] Created ${groups.length} groups using HNSW`);

    return groups;
};

/**
 * Calculate cosine distance between two normalized vectors.
 *
 * Cosine distance = 1 - cosine similarity
 * For normalized vectors: cosine similarity = dot product
 *
 * @param v1 First normalized vector
 * @param v2 Second normalized vector
 * @returns Distance in [0, 1], where 0 = identical, 1 = completely different
 */
export const cosineDistance = (
    v1: Float32Array | number[],
    v2: Float32Array | number[],
): number => {
    if (v1.length !== v2.length) {
        throw new Error(`Vector length mismatch: ${v1.length} vs ${v2.length}`);
    }

    // For normalized vectors, cosine similarity = dot product
    let dotProd: number;
    if (v1 instanceof Float32Array && v2 instanceof Float32Array) {
        dotProd = dotProduct(v1, v2);
    } else {
        const arr1 = v1 as number[];
        const arr2 = v2 as number[];
        dotProd = arr1.reduce((sum, val, i) => sum + val * (arr2[i] ?? 0), 0);
    }

    // Clamp to [-1, 1] to handle floating point errors
    const similarity = Math.max(-1, Math.min(1, dotProd));

    // Cosine distance = 1 - cosine similarity
    return 1 - similarity;
};

/**
 * Calculate cosine similarity between two vectors.
 *
 * @param v1 First vector
 * @param v2 Second vector
 * @returns Similarity in [-1, 1], where 1 = identical, 0 = orthogonal, -1 = opposite
 */
export const cosineSimilarity = (
    v1: Float32Array | number[],
    v2: Float32Array | number[],
): number => {
    return 1 - cosineDistance(v1, v2);
};

/**
 * Clear the cached similar images results, CLIP indexes, and HNSW index.
 *
 * Call this when files are added or removed to ensure fresh computation.
 */
export const clearSimilarImagesCache = async () => {
    clearCachedCLIPIndexes();
    clearCLIPHNSWIndex();
    await clearSimilarImagesCacheInDB();
};

/**
 * Filter groups by category based on their furthest distance.
 */
export const filterGroupsByCategory = (
    groups: SimilarImageGroup[],
    category: "close" | "similar" | "related",
): SimilarImageGroup[] => {
    const thresholds = {
        close: { min: 0, max: 0.02 },
        similar: { min: 0.02, max: 0.04 },
        related: { min: 0.04, max: 0.08 },
    };

    const { min, max } = thresholds[category];

    return groups.filter(
        (group) => group.furthestDistance >= min && group.furthestDistance < max,
    );
};

/**
 * Sort groups by various criteria.
 */
export const sortSimilarImageGroups = (
    groups: SimilarImageGroup[],
    sortBy: "size" | "count" | "distance",
    sortOrder: "asc" | "desc" = "desc",
): SimilarImageGroup[] => {
    const sorted = [...groups].sort((a, b) => {
        let comparison = 0;

        switch (sortBy) {
            case "size":
                comparison = a.totalSize - b.totalSize;
                break;
            case "count":
                comparison = a.items.length - b.items.length;
                break;
            case "distance":
                comparison = a.furthestDistance - b.furthestDistance;
                break;
        }

        return sortOrder === "desc" ? -comparison : comparison;
    });

    return sorted;
};

/**
 * Calculate the total size and count of files that would be deleted
 * if all selected groups are removed.
 */
export const calculateDeletionStats = (
    groups: SimilarImageGroup[],
): { totalSize: number; fileCount: number; groupCount: number } => {
    let totalSize = 0;
    let fileCount = 0;
    let groupCount = 0;

    for (const group of groups) {
        if (!group.isSelected) continue;

        groupCount++;
        // Count all files except the first (reference) in each group
        fileCount += group.items.length - 1;
        totalSize += group.totalSize - (group.items[0]?.file.info?.fileSize || 0);
    }

    return { totalSize, fileCount, groupCount };
};

/**
 * Format file size for display.
 */
export const formatFileSize = (bytes: number): string => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    if (bytes < 1024 * 1024 * 1024)
        return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`;
};

import type { EnteFile } from "ente-media/file";

/**
 * A group of similar images as shown in the UI.
 *
 * Similar to {@link DuplicateGroup} in dedup.ts, but for visually similar
 * images based on CLIP embedding similarity.
 */
export interface SimilarImageGroup {
    /**
     * A unique identifier for this group.
     *
     * This can be used as the key when rendering the group in a list.
     */
    id: string;
    /**
     * Files which our algorithm has determined to be visually similar.
     *
     * These are sorted by the distance from the reference (closest first).
     */
    items: SimilarImageItem[];
    /**
     * The maximum distance between any two images in this group.
     *
     * This indicates how "tight" the group is - lower values indicate
     * more visually similar images.
     */
    furthestDistance: number;
    /**
     * The total size (in bytes) of all files in this group.
     */
    totalSize: number;
    /**
     * `true` if the user has marked this group for removal.
     */
    isSelected: boolean;
}

/**
 * A single image item within a similar image group.
 */
export interface SimilarImageItem {
    /**
     * The underlying file.
     */
    file: EnteFile;
    /**
     * The distance from the group's reference image.
     *
     * Lower values indicate closer similarity.
     */
    distance: number;
    /**
     * The similarity score (1 - distance) as a percentage.
     */
    similarityScore: number;
    /**
     * IDs of the collections to which this file belongs.
     */
    collectionIDs: Set<number>;
    /**
     * The name of the collection to which this file belongs.
     */
    collectionName: string;
    /**
     * `true` if the user has marked this individual item for removal.
     * This allows fine-grained selection within a group.
     */
    isSelected?: boolean;
}

/**
 * Configuration options for finding similar images.
 */
export interface SimilarImagesOptions {
    /**
     * The distance threshold for considering images as similar.
     *
     * Distance is in [0, 1] where 0 = identical, 1 = completely different.
     * Default: 0.04 (4% difference threshold)
     *
     * - Close by: 0.00 - 0.02
     * - Similar: 0.02 - 0.04
     * - Related: 0.04 - 0.08
     */
    distanceThreshold?: number;
    /**
     * If true, force recomputation even if cached results exist.
     */
    forceRefresh?: boolean;
    /**
     * Optional file IDs to limit the search to.
     * If not provided, all indexed files will be considered.
     */
    fileIDs?: number[];
    /**
     * Callback for progress updates during computation.
     */
    onProgress?: (progress: number) => void;
}

/**
 * Category for filtering similar images groups.
 *
 * Based on distance thresholds:
 * - CLOSE: Very similar images (distance < 0.02)
 * - SIMILAR: Moderately similar images (0.02 <= distance < 0.04)
 * - RELATED: Loosely related images (0.04 <= distance < 0.08)
 */
export enum SimilarImageCategory {
    CLOSE = "close",
    SIMILAR = "similar",
    RELATED = "related",
}

/**
 * Result of the similar images analysis.
 */
export interface SimilarImagesResult {
    /**
     * Groups of similar images.
     */
    groups: SimilarImageGroup[];
    /**
     * Total number of files that were analyzed.
     */
    totalFilesAnalyzed: number;
    /**
     * Number of files that had CLIP embeddings.
     */
    filesWithEmbeddings: number;
    /**
     * Time taken to compute the results in milliseconds.
     */
    computationTimeMs: number;
}

/**
 * Cached similar images result stored in IndexedDB.
 */
export interface CachedSimilarImages {
    /**
     * A unique identifier for this cache entry.
     * Generated based on threshold and file IDs.
     */
    id: string;
    /**
     * The groups that were found.
     */
    groups: SimilarImageGroup[];
    /**
     * The distance threshold used for this analysis.
     */
    distanceThreshold: number;
    /**
     * The file IDs that were included in this analysis.
     */
    fileIDs: number[];
    /**
     * Timestamp when this cache entry was created.
     */
    createdAt: number;
    /**
     * Version of the caching format.
     */
    version: number;
}

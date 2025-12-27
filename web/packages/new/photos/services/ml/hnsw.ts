import { loadHnswlib } from "hnswlib-wasm";
import type { HierarchicalNSW } from "hnswlib-wasm";

/**
 * HNSW Index wrapper for efficient vector similarity search.
 *
 * This uses the hnswlib-wasm library to provide approximate nearest neighbor
 * search with HNSW (Hierarchical Navigable Small World) algorithm.
 *
 * Performance characteristics:
 * - Index build: O(n log n) where n is number of vectors
 * - Search: O(log n) per query
 * - Memory: ~8-10 bytes per element × M parameter
 *
 * Compared to naive O(n²) pairwise comparison, this is ~5000x faster
 * for large libraries (e.g., 80k images).
 */
export class HNSWIndex {
    private index: HierarchicalNSW | null = null;
    private lib: Awaited<ReturnType<typeof loadHnswlib>> | null = null;
    private readonly dimensions: number;
    private readonly maxElements: number;
    private readonly m: number;
    private readonly efConstruction: number;
    private efSearch: number;
    private fileIDToLabel = new Map<number, number>();
    private labelToFileID = new Map<number, number>();

    /**
     * Create a new HNSW index.
     *
     * @param dimensions - Vector dimension (512 for CLIP embeddings)
     * @param maxElements - Maximum number of vectors to store
     * @param m - Number of connections per layer (12-48 recommended)
     * @param efConstruction - Build quality (higher = better but slower)
     * @param efSearch - Search accuracy (higher = more accurate but slower)
     */
    constructor(
        dimensions: number = 512,
        maxElements: number = 100000,
        m: number = 16,
        efConstruction: number = 200,
        efSearch: number = 50,
    ) {
        this.dimensions = dimensions;
        this.maxElements = maxElements;
        this.m = m;
        this.efConstruction = efConstruction;
        this.efSearch = efSearch;
    }

    /**
     * Initialize the index. Must be called before use.
     */
    async init(): Promise<void> {
        if (this.index) return; // Already initialized

        this.lib = await loadHnswlib();
        this.index = new this.lib.HierarchicalNSW(
            "cosine",
            this.dimensions,
            "", // autoSaveFilename - empty string means no auto-save
        );
        this.index.initIndex(
            this.maxElements,
            this.m,
            this.efConstruction,
            Math.floor(Math.random() * 10000),
        );
        this.index.setEfSearch(this.efSearch);
    }

    /**
     * Add vectors to the index.
     *
     * @param fileIDs - Array of file IDs
     * @param embeddings - Array of embeddings (Float32Array[])
     * @param onProgress - Optional progress callback (0-100)
     */
    async addVectors(
        fileIDs: number[],
        embeddings: Float32Array[],
        onProgress?: (progress: number) => void,
    ): Promise<void> {
        if (!this.index) throw new Error("Index not initialized");
        if (fileIDs.length !== embeddings.length) {
            throw new Error("fileIDs and embeddings length mismatch");
        }

        // Convert to number[][] format expected by addItems
        // Report progress during conversion (0-50%)
        const items: number[][] = [];
        const conversionBatchSize = 10000;
        for (let i = 0; i < embeddings.length; i += conversionBatchSize) {
            const end = Math.min(i + conversionBatchSize, embeddings.length);
            for (let j = i; j < end; j++) {
                items.push(Array.from(embeddings[j]!));
            }
            onProgress?.(Math.round((end / embeddings.length) * 50));
            // Yield to browser to keep UI responsive
            await new Promise((resolve) => setTimeout(resolve, 0));
        }

        console.log(`[HNSW] Adding ${items.length} vectors to index...`);
        onProgress?.(50);

        // Add to index and get labels (this is the slow part)
        const labels = this.index.addItems(items, true);

        console.log(`[HNSW] Mapping ${labels.length} labels to file IDs...`);
        onProgress?.(90);

        // Map labels to fileIDs
        for (let i = 0; i < fileIDs.length; i++) {
            const fileID = fileIDs[i]!;
            const label = labels[i]!;
            this.fileIDToLabel.set(fileID, label);
            this.labelToFileID.set(label, fileID);
        }

        onProgress?.(100);
    }

    /**
     * Search for k nearest neighbors for each query vector.
     *
     * @param queryFileIDs - File IDs to search for
     * @param queryEmbeddings - Corresponding embeddings
     * @param k - Number of nearest neighbors to return
     * @param onProgress - Optional callback for progress (0-100)
     * @returns Map of fileID -> array of {fileID, distance} for nearest neighbors
     */
    async searchBatch(
        queryFileIDs: number[],
        queryEmbeddings: Float32Array[],
        k: number,
        onProgress?: (progress: number) => void,
    ): Promise<Map<number, Array<{ fileID: number; distance: number }>>> {
        if (!this.index) throw new Error("Index not initialized");

        const results = new Map<
            number,
            Array<{ fileID: number; distance: number }>
        >();

        const progressInterval = Math.floor(queryFileIDs.length / 100) || 1;
        const logInterval = Math.floor(queryFileIDs.length / 10) || 1;

        for (let i = 0; i < queryFileIDs.length; i++) {
            const queryFileID = queryFileIDs[i]!;
            const embedding = queryEmbeddings[i]!;

            // Search for k+1 neighbors (to exclude the query itself)
            const searchResult = this.index.searchKnn(
                Array.from(embedding),
                k + 1,
                undefined, // no label filter
            );

            const neighbors: Array<{ fileID: number; distance: number }> = [];

            // searchResult is { neighbors: number[], distances: number[] }
            const neighborLabels = searchResult.neighbors;
            const distances = searchResult.distances;

            for (let j = 0; j < neighborLabels.length; j++) {
                const label = neighborLabels[j]!;
                const distance = distances[j]!;
                const neighborFileID = this.labelToFileID.get(label);

                // Skip if it's the query itself
                if (neighborFileID === queryFileID) continue;

                if (neighborFileID !== undefined) {
                    neighbors.push({ fileID: neighborFileID, distance });
                }

                // Stop once we have k neighbors (excluding self)
                if (neighbors.length >= k) break;
            }

            results.set(queryFileID, neighbors);

            // Report progress periodically
            if (onProgress && i % progressInterval === 0) {
                const progress = Math.round((i / queryFileIDs.length) * 100);
                onProgress(progress);
            }

            // Log progress periodically
            if (i % logInterval === 0 && i > 0) {
                console.log(`[HNSW] Searched ${i}/${queryFileIDs.length} vectors (${Math.round((i / queryFileIDs.length) * 100)}%)`);
            }
        }

        // Ensure we report 100% at the end
        onProgress?.(100);

        return results;
    }

    /**
     * Get the number of elements in the index.
     */
    size(): number {
        return this.index?.getCurrentCount() ?? 0;
    }

    /**
     * Update search accuracy parameter.
     * Higher values = more accurate but slower.
     */
    setEfSearch(efSearch: number): void {
        this.efSearch = efSearch;
        this.index?.setEfSearch(efSearch);
    }

    /**
     * Get the maximum number of elements this index can hold.
     */
    getMaxElements(): number {
        return this.maxElements;
    }

    /**
     * Clean up resources.
     */
    destroy(): void {
        // Note: HierarchicalNSW doesn't have a delete() method in the type definitions
        // The index will be garbage collected when the reference is cleared
        this.index = null;
        this.lib = null;
        this.fileIDToLabel.clear();
        this.labelToFileID.clear();
    }
}

/**
 * Singleton HNSW index instance for CLIP embeddings.
 * Lazily initialized on first use.
 */
let _clipHNSWIndex: HNSWIndex | null = null;

/**
 * Get or create the global CLIP HNSW index.
 *
 * @param requiredCapacity - Minimum capacity needed (will round up to nearest 10k)
 */
export const getCLIPHNSWIndex = async (
    requiredCapacity?: number,
): Promise<HNSWIndex> => {
    const capacity = requiredCapacity
        ? Math.ceil(requiredCapacity / 10000) * 10000
        : 100000;

    // If we need more capacity than current index, recreate it
    if (_clipHNSWIndex && requiredCapacity && capacity > _clipHNSWIndex.getMaxElements()) {
        console.log(
            `[HNSW] Recreating index with larger capacity: ${capacity}`,
        );
        _clipHNSWIndex.destroy();
        _clipHNSWIndex = null;
    }

    if (!_clipHNSWIndex) {
        console.log(`[HNSW] Creating new index with capacity: ${capacity}`);
        _clipHNSWIndex = new HNSWIndex(
            512, // CLIP embedding dimension
            capacity,
            16, // M parameter - good balance
            200, // efConstruction - good quality
            50, // efSearch - good accuracy
        );
        await _clipHNSWIndex.init();
    }
    return _clipHNSWIndex;
};

/**
 * Clear the global CLIP HNSW index.
 * Call this when the index needs to be rebuilt (e.g., after major changes).
 */
export const clearCLIPHNSWIndex = (): void => {
    if (_clipHNSWIndex) {
        _clipHNSWIndex.destroy();
        _clipHNSWIndex = null;
    }
};

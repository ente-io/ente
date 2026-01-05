import { loadHnswlib, syncFileSystem } from "hnswlib-wasm";
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
     *
     * @param skipInit - If true, create the index object but don't call initIndex().
     *                   Use this when you plan to loadIndex() instead.
     */
    async init(skipInit: boolean = false): Promise<void> {
        if (this.index) return; // Already initialized

        this.lib = await loadHnswlib();

        // Enable debug logging to see what's happening with IDBFS
        this.lib.EmscriptenFileSystemManager.setDebugLogs(true);

        // CRITICAL: Only sync IDBFS if we're building a new index
        // If skipInit=true, we're going to call loadIndex() which will sync itself
        // Syncing twice causes race conditions and corruption
        if (!skipInit) {
            console.log(`[HNSW] Syncing IDBFS from IndexedDB on init...`);
            try {
                await syncFileSystem('read');
                console.log(`[HNSW] IDBFS synced successfully on init`);
            } catch (e) {
                console.log(`[HNSW] IDBFS sync failed on init (OK if first time):`, e);
            }
        } else {
            console.log(`[HNSW] Skipping IDBFS sync - will be done by loadIndex()`);
        }

        this.index = new this.lib.HierarchicalNSW(
            "cosine",
            this.dimensions,
            "", // autoSaveFilename - empty string means no auto-save
        );

        if (!skipInit) {
            console.log(`[HNSW] Initializing new empty index with maxElements=${this.maxElements}`);
            this.index.initIndex(
                this.maxElements,
                this.m,
                this.efConstruction,
                Math.floor(Math.random() * 10000),
            );
            this.index.setEfSearch(this.efSearch);
        } else {
            console.log(`[HNSW] Skipping initIndex() - will load from file instead`);
        }
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
     * Save index to Emscripten virtual filesystem (backed by IDBFS).
     *
     * @param filename - Name of file to save to in virtual FS
     * @returns Object containing file mappings for reconstruction
     */
    async saveIndex(filename: string = "clip_hnsw.bin"): Promise<{
        fileIDToLabel: [number, number][];
        labelToFileID: [number, number][];
    }> {
        if (!this.index) throw new Error("Index not initialized");
        if (!this.lib) throw new Error("Library not loaded");

        console.log(`[HNSW] Saving index to virtual filesystem: ${filename}`);

        // Write index to Emscripten virtual FS
        await this.index.writeIndex(filename);

        console.log(`[HNSW] writeIndex completed, verifying file was written...`);

        // Verify file was written to virtual FS
        const fileExistsBeforeSync = this.lib.EmscriptenFileSystemManager.checkFileExists(filename);
        console.log(`[HNSW] File exists in virtual FS before sync: ${fileExistsBeforeSync}`);

        if (!fileExistsBeforeSync) {
            throw new Error(`writeIndex failed - file '${filename}' not found in virtual FS`);
        }

        console.log(`[HNSW] Syncing virtual FS to IndexedDB...`);

        // Sync virtual FS to IndexedDB (IDBFS persistence)
        // Add a small delay to ensure write is complete before syncing
        await new Promise(resolve => setTimeout(resolve, 100));
        await syncFileSystem('write');

        console.log(`[HNSW] Sync completed, waiting for persistence...`);

        // Wait a bit more to ensure persistence is complete
        await new Promise(resolve => setTimeout(resolve, 100));

        // Verify file still exists after sync
        const fileExistsAfterSync = this.lib.EmscriptenFileSystemManager.checkFileExists(filename);
        console.log(`[HNSW] File exists in virtual FS after sync: ${fileExistsAfterSync}`);

        console.log(`[HNSW] Index saved to IDBFS successfully`);

        // Return mappings (needed for reconstruction)
        return {
            fileIDToLabel: Array.from(this.fileIDToLabel.entries()),
            labelToFileID: Array.from(this.labelToFileID.entries()),
        };
    }

    /**
     * Load index from Emscripten virtual filesystem (backed by IDBFS).
     *
     * @param filename - Name of file to load from virtual FS
     * @param mappings - File ID to label mappings
     */
    async loadIndex(
        filename: string = "clip_hnsw.bin",
        mappings: {
            fileIDToLabel: [number, number][];
            labelToFileID: [number, number][];
        }
    ): Promise<void> {
        if (!this.index) throw new Error("Index not initialized");
        if (!this.lib) throw new Error("Library not loaded");

        console.log(`[HNSW] Loading index from IDBFS: ${filename}`);
        console.log(`[HNSW] Index maxElements: ${this.maxElements}`);

        // Sync IndexedDB to virtual FS
        console.log(`[HNSW] Syncing IDBFS from IndexedDB before load...`);
        await syncFileSystem('read');
        console.log(`[HNSW] IDBFS sync completed`);

        // Add delay to ensure sync is complete
        await new Promise(resolve => setTimeout(resolve, 100));

        // Check if file exists in the virtual filesystem
        const fileExists = this.lib.EmscriptenFileSystemManager.checkFileExists(filename);
        console.log(`[HNSW] File exists check for '${filename}': ${fileExists}`);

        if (!fileExists) {
            throw new Error(`Index file '${filename}' does not exist in IDBFS - was never saved or was deleted`);
        }

        // CRITICAL DIAGNOSTIC: Check if we're trying to load into an already-initialized index
        // This is a diagnostic check - getCurrentCount() will throw if index is not initialized (which is what we want)
        console.log(`[HNSW] Checking index initialization state before readIndex...`);
        try {
            const currentSize = this.index.getCurrentCount();
            // If we get here, the index is already initialized - this is BAD
            console.error(`[HNSW] ERROR: Index already has ${currentSize} vectors before readIndex!`);
            console.error(`[HNSW] readIndex() requires an uninitialized index. This will fail.`);
            throw new Error(`Cannot load index: index already initialized with ${currentSize} vectors. readIndex() requires uninitialized index.`);
        } catch (e: unknown) {
            // Check if this is the expected "uninitialized" error or an actual problem
            const errorMessage = e instanceof Error ? e.message : String(e);
            if (errorMessage.includes('already initialized')) {
                // Our own error - re-throw it
                throw e;
            }
            // getCurrentCount() threw because index is uninitialized - that's exactly what we want!
            console.log(`[HNSW] Index is uninitialized (correct state for readIndex)`);
        }

        // Load index from virtual FS
        // NOTE: readIndex() does its own initialization - no need to call initIndex() first!
        console.log(`[HNSW] Calling readIndex with maxElements=${this.maxElements}`);
        try {
            const success = await this.index.readIndex(filename, this.maxElements);
            console.log(`[HNSW] readIndex returned: ${success} (type: ${typeof success})`);

            if (success !== true) {
                throw new Error(`readIndex returned ${success} (expected true) - possible capacity mismatch or index already initialized`);
            }
        } catch (error) {
            console.error(`[HNSW] readIndex threw error:`, error);
            throw new Error(`Failed to load HNSW index from ${filename}: ${error instanceof Error ? error.message : String(error)}`);
        }

        // Set search parameters after loading
        this.index.setEfSearch(this.efSearch);
        console.log(`[HNSW] Set efSearch to ${this.efSearch}`);

        // Restore mappings
        this.fileIDToLabel = new Map(mappings.fileIDToLabel);
        this.labelToFileID = new Map(mappings.labelToFileID);

        console.log(`[HNSW] Index loaded successfully (${this.size()} vectors)`);
    }

    /**
     * Check if a saved index exists in IDBFS.
     *
     * Note: This method syncs IDBFS but doesn't actually check for file existence.
     * Actual file existence is checked during loadIndex via try/catch.
     */
    async hasSavedIndex(): Promise<boolean> {
        try {
            await syncFileSystem('read');
            // Try to access the file (will throw if not found)
            // Note: We'd need access to FS API to check file existence
            // For now, we'll rely on try/catch in loadIndex
            return true;
        } catch {
            return false;
        }
    }

    /**
     * Add a single vector to the index (for incremental updates).
     *
     * @param fileID - File ID to add
     * @param embedding - Vector embedding
     * @returns The label assigned to this vector
     */
    addVector(fileID: number, embedding: Float32Array): number {
        if (!this.index) throw new Error("Index not initialized");

        // Use addItems with a single item to get the label
        // replaceDeleted=true will reuse labels from deleted items
        const labels = this.index.addItems([Array.from(embedding)], true);
        const label = labels[0]!;

        this.fileIDToLabel.set(fileID, label);
        this.labelToFileID.set(label, fileID);

        return label;
    }

    /**
     * Remove a vector from the index (for incremental updates).
     *
     * @param fileID - File ID to remove
     * @returns True if the vector was removed, false if not found
     */
    removeVector(fileID: number): boolean {
        if (!this.index) throw new Error("Index not initialized");

        const label = this.fileIDToLabel.get(fileID);
        if (label === undefined) return false;

        // Mark as deleted in the index
        this.index.markDelete(label);

        // Remove from mappings
        this.fileIDToLabel.delete(fileID);
        this.labelToFileID.delete(label);

        return true;
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
 * @param skipInit - If true, don't call initIndex(). Use when loading from file.
 */
export const getCLIPHNSWIndex = async (
    requiredCapacity?: number,
    skipInit: boolean = false,
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
        await _clipHNSWIndex.init(skipInit);
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

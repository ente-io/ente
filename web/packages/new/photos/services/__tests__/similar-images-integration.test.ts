import * as user from "ente-accounts/services/user";
import { FileType } from "ente-media/file-type";
import { beforeEach, describe, expect, it, vi } from "vitest";
import * as collection from "../collection";
import * as clip from "../ml/clip";
import * as db from "../ml/db";
import * as photosFdb from "../photos-fdb";
import { getSimilarImages } from "../similar-images";

// Mock dependencies
vi.mock("../ml/db");
vi.mock("../ml/clip");
vi.mock("../collection");
vi.mock("../photos-fdb");
vi.mock("ente-accounts/services/user");
vi.mock("../ml/hnsw", () => {
    return {
        getCLIPHNSWIndex: vi
            .fn()
            .mockResolvedValue({
                init: vi.fn(),
                addVectors: vi.fn(),
                searchBatch: vi.fn().mockResolvedValue(new Map()),
                size: vi.fn().mockReturnValue(0),
                getMaxElements: vi.fn().mockReturnValue(1000),
                saveIndex: vi
                    .fn()
                    .mockResolvedValue({
                        fileIDToLabel: [],
                        labelToFileID: [],
                    }),
                destroy: vi.fn(),
            }),
        clearCLIPHNSWIndex: vi.fn(),
    };
});

describe("getSimilarImages Integration", () => {
    beforeEach(() => {
        vi.resetAllMocks();

        // Setup default mocks
        vi.mocked(user.ensureLocalUser).mockReturnValue({ id: 1 } as any);
        vi.mocked(collection.savedNormalCollections).mockResolvedValue([
            { id: 101, owner: { id: 1 }, type: "normal" } as any,
        ]);
        vi.mocked(collection.createCollectionNameByID).mockReturnValue(
            new Map([[101, "Album"]]),
        );

        // Mock DB functions
        vi.mocked(db.loadSimilarImagesCache).mockResolvedValue(undefined);
        vi.mocked(db.loadHNSWIndexMetadata).mockResolvedValue(undefined);
    });

    it("should return empty result if no files found", async () => {
        vi.mocked(clip.getCLIPIndexes).mockResolvedValue([]);
        vi.mocked(photosFdb.savedCollectionFiles).mockResolvedValue([]);

        const result = await getSimilarImages();

        expect(result.groups).toHaveLength(0);
        expect(result.totalFilesAnalyzed).toBe(0);
    });

    it("should process files and return empty groups if no matches found", async () => {
        // Setup data
        const files = [
            {
                id: 1,
                collectionID: 101,
                ownerID: 1,
                metadata: { fileType: FileType.image },
            },
            {
                id: 2,
                collectionID: 101,
                ownerID: 1,
                metadata: { fileType: FileType.image },
            },
        ] as any[];

        const embeddings = [
            { fileID: 1, embedding: new Float32Array([1, 0]) },
            { fileID: 2, embedding: new Float32Array([0, 1]) }, // Orthogonal
        ] as any[];

        vi.mocked(clip.getCLIPIndexes).mockResolvedValue(embeddings);
        vi.mocked(photosFdb.savedCollectionFiles).mockResolvedValue(files);

        // HNSW mock will return empty search results by default (no neighbors)

        const result = await getSimilarImages();

        expect(result.groups).toHaveLength(0);
        expect(result.totalFilesAnalyzed).toBe(2);
        expect(result.filesWithEmbeddings).toBe(2);
    });

    it("should use cache if valid", async () => {
        const files = [
            {
                id: 1,
                collectionID: 101,
                ownerID: 1,
                metadata: { fileType: FileType.image },
            },
        ] as any[];
        const embeddings = [
            { fileID: 1, embedding: new Float32Array([1]) },
        ] as any[];

        vi.mocked(clip.getCLIPIndexes).mockResolvedValue(embeddings);
        vi.mocked(photosFdb.savedCollectionFiles).mockResolvedValue(files);

        // Mock cache hit
        const cachedGroups = [{ id: "g1", items: [] }] as any[];
        vi.mocked(db.loadSimilarImagesCache).mockResolvedValue({
            version: 1,
            fileIDs: [1],
            groups: cachedGroups,
        } as any);

        const result = await getSimilarImages();

        expect(result.groups).toBe(cachedGroups);
        expect(result.computationTimeMs).toBe(0);
        expect(db.saveSimilarImagesCache).not.toHaveBeenCalled();
    });

    it("should ignore cache if file count mismatch", async () => {
        const files = [
            {
                id: 1,
                collectionID: 101,
                ownerID: 1,
                metadata: { fileType: FileType.image },
            },
            {
                id: 2,
                collectionID: 101,
                ownerID: 1,
                metadata: { fileType: FileType.image },
            },
        ] as any[];
        const embeddings = [
            { fileID: 1, embedding: new Float32Array([1]) },
            { fileID: 2, embedding: new Float32Array([1]) },
        ] as any[];

        vi.mocked(clip.getCLIPIndexes).mockResolvedValue(embeddings);
        vi.mocked(photosFdb.savedCollectionFiles).mockResolvedValue(files);

        // Cache has only file 1
        vi.mocked(db.loadSimilarImagesCache).mockResolvedValue({
            version: 1,
            fileIDs: [1],
            groups: [],
        } as any);

        await getSimilarImages();

        // Should have proceeded to computation (and save)
        expect(db.saveSimilarImagesCache).toHaveBeenCalled();
    });
});

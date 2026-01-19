import type { EnteFile } from "ente-media/file";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { SimilarImageGroup } from "../similar-images-types";

// Mock external dependencies
vi.mock("../collection", () => ({
    savedNormalCollections: vi.fn(),
    addToCollection: vi.fn(),
    moveToTrash: vi.fn(),
}));

vi.mock("../pull", () => ({ pullFiles: vi.fn() }));

vi.mock("../similar-images", () => ({ clearSimilarImagesCache: vi.fn() }));

vi.mock("ente-accounts/services/user", () => ({
    ensureLocalUser: () => ({ id: 1 }),
}));

import * as collection from "../collection";
import * as pull from "../pull";
import * as similarImages from "../similar-images";
import { removeSelectedSimilarImageGroups } from "../similar-images-delete";

describe("similar-images-delete", () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    const createMockFile = (id: number, size = 1000): EnteFile =>
        ({
            id,
            info: { fileSize: size },
            metadata: {
                title: `file${id}.jpg`,
                creationTime: Date.now(),
                modificationTime: Date.now(),
            },
            key: "test-key",
            file: null as any,
            thumbnail: null as any,
            // Add other required EnteFile properties as needed
        }) as EnteFile;

    const createMockGroup = (
        id: string,
        fileIds: number[],
        isSelected = true,
    ): SimilarImageGroup => ({
        id,
        items: fileIds.map((fileId, index) => ({
            file: createMockFile(fileId),
            collectionIDs: new Set([1]), // Default collection
            collectionName: "Test Collection",
            distance: index * 0.01,
            similarityScore: 100 - index * 10,
            isSelected: index > 0, // First item (best photo) not selected by default
        })),
        furthestDistance: 0.01,
        totalSize: fileIds.length * 1000,
        isSelected,
    });

    describe("removeSelectedSimilarImageGroups", () => {
        it("should mark group as NOT fully removed when items remain", async () => {
            // Setup: Group with 5 items, but 2 are manually deselected
            const group = createMockGroup("group1", [1, 2, 3, 4, 5], true);
            group.items[2]!.isSelected = false; // Deselect item 3
            group.items[3]!.isSelected = false; // Deselect item 4

            // Mock collections (no favorites)
            vi.mocked(collection.savedNormalCollections).mockResolvedValue([
                { id: 1, type: "normal", owner: { id: 1 } } as any,
            ]);

            const result = await removeSelectedSimilarImageGroups(
                [group],
                vi.fn(),
            );

            // Should delete: items 2, 5 (items 1 is retained, 3,4 deselected)
            expect(result.deletedFileIDs).toEqual(new Set([2, 5]));

            // Group should NOT be fully removed (3 items remain: 1, 3, 4)
            expect(result.fullyRemovedGroupIDs.has("group1")).toBe(false);
        });

        it("should mark group as fully removed when <2 items remain", async () => {
            // Setup: Group with 2 items, both selected
            const group = createMockGroup("group1", [1, 2], true);

            vi.mocked(collection.savedNormalCollections).mockResolvedValue([
                { id: 1, type: "normal", owner: { id: 1 } } as any,
            ]);

            const result = await removeSelectedSimilarImageGroups(
                [group],
                vi.fn(),
            );

            // Should delete item 2 (item 1 is retained)
            expect(result.deletedFileIDs).toEqual(new Set([2]));

            // Group should be fully removed (only 1 item remains)
            expect(result.fullyRemovedGroupIDs.has("group1")).toBe(true);
        });

        it("should protect favorited files from deletion", async () => {
            // Setup: Group where item 3 is favorited
            const group = createMockGroup("group1", [1, 2, 3, 4], true);

            // Item 3 is also in favorites collection
            group.items[2]!.collectionIDs = new Set([1, 2]); // 1=normal, 2=favorites

            // Mock collections with favorites
            vi.mocked(collection.savedNormalCollections).mockResolvedValue([
                { id: 1, type: "normal", owner: { id: 1 } } as any,
                { id: 2, type: "favorites", owner: { id: 1 } } as any,
            ]);

            const result = await removeSelectedSimilarImageGroups(
                [group],
                vi.fn(),
            );

            // Should NOT delete item 3 (favorited)
            // Should delete items 2, 4 (item 1 is retained)
            expect(result.deletedFileIDs).toEqual(new Set([2, 4]));

            // Group should NOT be fully removed (2 items remain: 1, 3)
            expect(result.fullyRemovedGroupIDs.has("group1")).toBe(false);
        });

        it("should handle individual item selections in non-selected groups", async () => {
            // Setup: Group NOT fully selected, but individual items selected
            const group = createMockGroup("group1", [1, 2, 3, 4], false);
            group.items[1]!.isSelected = true; // Select item 2
            group.items[3]!.isSelected = true; // Select item 4

            vi.mocked(collection.savedNormalCollections).mockResolvedValue([
                { id: 1, type: "normal", owner: { id: 1 } } as any,
            ]);

            const result = await removeSelectedSimilarImageGroups(
                [group],
                vi.fn(),
            );

            // Should delete individually selected items: 2, 4
            expect(result.deletedFileIDs).toEqual(new Set([2, 4]));

            // Group should NOT be fully removed (2 items remain: 1, 3)
            expect(result.fullyRemovedGroupIDs.has("group1")).toBe(false);
        });

        it("should fully remove group after individual selections if <2 remain", async () => {
            // Setup: Group with 2 items, one individually selected
            const group = createMockGroup("group1", [1, 2], false);
            group.items[1]!.isSelected = true; // Select item 2

            vi.mocked(collection.savedNormalCollections).mockResolvedValue([
                { id: 1, type: "normal", owner: { id: 1 } } as any,
            ]);

            const result = await removeSelectedSimilarImageGroups(
                [group],
                vi.fn(),
            );

            // Should delete item 2
            expect(result.deletedFileIDs).toEqual(new Set([2]));

            // Group should be fully removed (only 1 item remains)
            expect(result.fullyRemovedGroupIDs.has("group1")).toBe(true);
        });

        it("should handle multiple groups correctly", async () => {
            // Group 1: Will be fully removed (2 items total)
            const group1 = createMockGroup("group1", [1, 2], true);

            // Group 2: Will NOT be fully removed (has deselected items)
            const group2 = createMockGroup("group2", [3, 4, 5, 6], true);
            group2.items[2]!.isSelected = false; // Deselect item 5

            vi.mocked(collection.savedNormalCollections).mockResolvedValue([
                { id: 1, type: "normal", owner: { id: 1 } } as any,
            ]);

            const result = await removeSelectedSimilarImageGroups(
                [group1, group2],
                vi.fn(),
            );

            // Should delete: 2 (from g1), 4, 6 (from g2, excluding 5)
            expect(result.deletedFileIDs).toEqual(new Set([2, 4, 6]));

            // Group1 should be fully removed, Group2 should not
            expect(result.fullyRemovedGroupIDs.has("group1")).toBe(true);
            expect(result.fullyRemovedGroupIDs.has("group2")).toBe(false);
        });

        it("should call external functions correctly", async () => {
            const group = createMockGroup("group1", [1, 2], true);

            vi.mocked(collection.savedNormalCollections).mockResolvedValue([
                { id: 1, type: "normal", owner: { id: 1 } } as any,
            ]);

            const progressFn = vi.fn();
            await removeSelectedSimilarImageGroups([group], progressFn);

            // Should call moveToTrash with deleted files
            expect(collection.moveToTrash).toHaveBeenCalledWith(
                expect.arrayContaining([expect.objectContaining({ id: 2 })]),
            );

            // Should sync local state
            expect(pull.pullFiles).toHaveBeenCalled();

            // Should clear cache
            expect(similarImages.clearSimilarImagesCache).toHaveBeenCalled();

            // Should report progress
            expect(progressFn).toHaveBeenCalled();
        });

        it("should protect favorites even in individual selections", async () => {
            // Setup: Non-selected group with individual selections
            const group = createMockGroup("group1", [1, 2, 3], false);
            group.items[1]!.isSelected = true; // Select item 2
            group.items[2]!.isSelected = true; // Select item 3
            group.items[2]!.collectionIDs = new Set([1, 2]); // Item 3 in favorites

            vi.mocked(collection.savedNormalCollections).mockResolvedValue([
                { id: 1, type: "normal", owner: { id: 1 } } as any,
                { id: 2, type: "favorites", owner: { id: 1 } } as any,
            ]);

            const result = await removeSelectedSimilarImageGroups(
                [group],
                vi.fn(),
            );

            // Should only delete item 2 (item 3 is favorited)
            expect(result.deletedFileIDs).toEqual(new Set([2]));

            // Group should NOT be fully removed (2 items remain: 1, 3)
            expect(result.fullyRemovedGroupIDs.has("group1")).toBe(false);
        });

        it("should handle empty groups array", async () => {
            vi.mocked(collection.savedNormalCollections).mockResolvedValue([]);

            const result = await removeSelectedSimilarImageGroups([], vi.fn());

            expect(result.deletedFileIDs.size).toBe(0);
            expect(result.fullyRemovedGroupIDs.size).toBe(0);
        });

        it("should handle all items deselected in a selected group", async () => {
            // Setup: Group is selected, but ALL deletable items are deselected
            const group = createMockGroup("group1", [1, 2, 3, 4], true);
            group.items[1]!.isSelected = false;
            group.items[2]!.isSelected = false;
            group.items[3]!.isSelected = false;

            vi.mocked(collection.savedNormalCollections).mockResolvedValue([
                { id: 1, type: "normal", owner: { id: 1 } } as any,
            ]);

            const result = await removeSelectedSimilarImageGroups(
                [group],
                vi.fn(),
            );

            // Should delete nothing
            expect(result.deletedFileIDs.size).toBe(0);

            // Group should NOT be fully removed (all 4 items remain)
            expect(result.fullyRemovedGroupIDs.has("group1")).toBe(false);
        });

        it("should swap retained item if best photo is explicitly selected", async () => {
            // Setup: Group with 2 items. Item 1 is "best" (index 0).
            // Initially: Item 1 retained, Item 2 selected.
            const group = createMockGroup("group1", [1, 2], true);

            // User explicitly selects Item 1 (override retention)
            group.items[0]!.isSelected = true;

            // User explicity deselects Item 2 (to keep it instead)
            group.items[1]!.isSelected = false;

            vi.mocked(collection.savedNormalCollections).mockResolvedValue([
                { id: 1, type: "normal", owner: { id: 1 } } as any,
            ]);

            const result = await removeSelectedSimilarImageGroups(
                [group],
                vi.fn(),
            );

            // Item 1 (id=1) should be deleted because it was strictly selected
            // Item 2 (id=2) should be retained because it was deselected
            expect(result.deletedFileIDs).toEqual(new Set([1]));

            // Group should be fully removed (only 1 item remains)
            expect(result.fullyRemovedGroupIDs.has("group1")).toBe(true);
        });
    });
});

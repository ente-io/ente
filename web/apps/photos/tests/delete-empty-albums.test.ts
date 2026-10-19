import type { CollectionSummary } from "ente-new/photos/services/collection-summary";
import { beforeEach, describe, expect, test, vi } from "vitest";
import { useDeleteEmptyAlbums } from "../src/components/Collections/useDeleteEmptyAlbums";

const mocks = vi.hoisted(() => ({
    candidateIDs: undefined as number[] | undefined,
    notify: vi.fn<
        (notification: { title: { key: string; opts?: unknown } }) => void
    >(),
    pull: vi.fn(),
    collections: vi.fn(),
    files: vi.fn(),
    remove: vi.fn(),
}));
vi.mock("react", () => ({
    useState: () => [
        mocks.candidateIDs,
        (ids: number[] | undefined) => {
            mocks.candidateIDs = ids;
        },
    ],
}));
vi.mock("ente-new/photos/types/context", () => ({
    usePhotosAppContext: () => ({ showNotification: mocks.notify }),
}));
vi.mock("ente-accounts/services/user", () => ({
    ensureLocalUser: () => ({ id: 1 }),
}));
vi.mock("ente-new/photos/services/collection", () => ({
    deleteCollection: mocks.remove,
    isArchivedCollection: (c: { archived?: boolean }) => !!c.archived,
    isDefaultHiddenCollection: (c: { hidden?: boolean }) => !!c.hidden,
}));
vi.mock("ente-new/photos/services/photos-fdb", () => ({
    savedCollections: mocks.collections,
    savedCollectionFiles: mocks.files,
}));
vi.mock("i18next", () => ({
    t: (key: string, opts?: unknown) => ({ key, opts }),
}));

const summary = (id: number): CollectionSummary => ({
    id,
    name: `${id}`,
    type: "album",
    fileCount: 0,
    attributes: new Set(),
    latestFile: undefined,
    coverFile: undefined,
    updationTime: undefined,
    sortPriority: 0,
});
const collection = (id: number) => ({
    id,
    type: "album",
    owner: { id: 1 },
    sharees: [],
    publicURLs: [],
});
const start = (ids = [1, 2, 3]) => {
    const result = useDeleteEmptyAlbums(ids.map(summary), mocks.pull);
    result.handleDeleteEmptyAlbums();
    return useDeleteEmptyAlbums(ids.map(summary), mocks.pull)
        .deleteEmptyAlbumsDialogProps;
};
beforeEach(() => {
    vi.resetAllMocks();
    mocks.candidateIDs = undefined;
    mocks.pull.mockResolvedValue(undefined);
    mocks.collections.mockResolvedValue([1, 2, 3].map(collection));
    mocks.files.mockResolvedValue([]);
    mocks.remove.mockResolvedValue(undefined);
});
describe("shared empty album deletion", () => {
    test("confirms the candidate count and does nothing until confirmed", () => {
        const dialog = start();
        expect(dialog.open).toBe(true);
        expect(dialog.count).toBe(3);
        expect(dialog.message).toEqual({
            key: "delete_empty_albums_message",
            opts: { count: 3 },
        });
        expect(mocks.pull).not.toHaveBeenCalled();
        expect(mocks.remove).not.toHaveBeenCalled();
        dialog.onClose();
        expect(
            useDeleteEmptyAlbums([summary(1)], mocks.pull)
                .deleteEmptyAlbumsDialogProps.open,
        ).toBe(false);
        expect(
            useDeleteEmptyAlbums([summary(1), summary(2)], mocks.pull)
                .hasEnoughEmptyAlbums,
        ).toBe(false);
    });
    test("revalidates candidates and does not include new albums", async () => {
        mocks.collections.mockResolvedValue([
            collection(1),
            collection(2),
            { ...collection(3), publicURLs: [{}] },
            { ...collection(4), owner: { id: 2 } },
            { ...collection(5), archived: true },
            { ...collection(6), hidden: true },
            { ...collection(7), type: "favorites" },
            { ...collection(8), sharees: [{}] },
            collection(9),
        ]);
        mocks.files.mockResolvedValue([{ collectionID: 2 }]);
        await start([1, 2, 3, 4, 5, 6, 7, 8]).onConfirm();
        expect(mocks.remove.mock.calls).toEqual([[1, { keepFiles: true }]]);
        expect(mocks.pull.mock.calls).toEqual([
            [{ strict: true }],
            [{ strict: true }],
        ]);
    });
    test("aborts on initial sync failure", async () => {
        mocks.pull.mockRejectedValueOnce(new Error("sync"));
        await start().onConfirm();
        expect(mocks.remove).not.toHaveBeenCalled();
        expect(mocks.notify.mock.calls[0]![0].title).toEqual({
            key: "delete_empty_albums_failed",
            opts: { count: 3 },
        });
    });
    test("continues after a deletion failure and reports the failed count", async () => {
        mocks.remove.mockRejectedValueOnce(new Error("delete"));
        await start().onConfirm();
        expect(mocks.remove).toHaveBeenCalledTimes(3);
        expect(mocks.pull).toHaveBeenCalledTimes(2);
        expect(mocks.notify.mock.calls[0]![0].title).toEqual({
            key: "delete_empty_albums_failed",
            opts: { count: 1 },
        });
    });
    test("reports refresh failure after successful deletion", async () => {
        mocks.pull
            .mockResolvedValueOnce(undefined)
            .mockRejectedValueOnce(new Error("refresh"));
        await start().onConfirm();
        expect(mocks.notify.mock.calls[0]![0].title.key).toBe(
            "delete_empty_albums_refresh_failed",
        );
    });
});

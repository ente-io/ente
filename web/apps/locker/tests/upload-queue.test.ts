import { createElement } from "react";
import { renderToString } from "react-dom/server";
import { expect, test, vi } from "vitest";
import {
    uploadQueueItemKey,
    type UploadCollectionSelection,
} from "../src/components/create-item/file-upload-helpers";
import { useUploadQueue } from "../src/components/create-item/use-upload-queue";

vi.mock("@/services/locker-limits", () => ({
    exceedsPaidLockerHardLimit: () => false,
    validateLockerUploadBatch: () => undefined,
}));
vi.mock("@/services/locker-errors", () => ({
    formatLockerMutationError: () => Promise.resolve("Upload failed"),
    lockerUpgradeCTAType: () => Promise.resolve(null),
}));
vi.mock("ente-base/log", () => ({ default: { error: vi.fn() } }));

test("a newly created collection keeps its ID after failure and can be cleared before retry", async () => {
    const item = {
        file: new File(["test"], "retry.txt"),
        suggestedCollectionNames: [],
    };
    const key = uploadQueueItemKey(item);
    let selections: Record<string, UploadCollectionSelection[]> = {
        [key]: ["New collection"],
    };
    const onEnsureCollections = vi.fn(() =>
        Promise.resolve(new Map([["New collection", 3]])),
    );
    const onUploadProgress = vi
        .fn()
        .mockRejectedValueOnce(new Error("Network failure"))
        .mockResolvedValue(undefined);
    let upload!: ReturnType<typeof useUploadQueue>["upload"];
    function Harness() {
        upload = useUploadQueue({
            selectedUploadItems: [item],
            selectedCollectionsByFileKey: selections,
            setSelectedCollectionsByFileKey: (update) => {
                selections =
                    typeof update === "function" ? update(selections) : update;
            },
            setError: vi.fn(),
            setUpgradeCTAType: vi.fn(),
            userDetails: {
                usage: 0,
                storageLimit: 100000,
                fileCount: 0,
                lockerFileLimit: 100,
                isPartOfFamily: false,
            },
            onEnsureCollections,
            onUploadProgress,
        }).upload;
        return null;
    }
    renderToString(createElement(Harness));
    await upload(vi.fn());
    expect(onUploadProgress.mock.calls[0]![1]).toEqual([3]);
    expect(selections[key]).toEqual([3]);
    selections = { [key]: [] };
    renderToString(createElement(Harness));
    await upload(vi.fn());
    expect(onUploadProgress.mock.calls[1]![1]).toEqual([]);
    expect(onEnsureCollections).toHaveBeenCalledTimes(1);
});

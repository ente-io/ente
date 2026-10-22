import { expect, test } from "vitest";
import {
    collectionsByUploadItem,
    dedupeCollectionNames,
    resolveUploadCollectionIDs,
    toggleCollectionName,
    uploadCollectionSelection,
    uploadQueueItemKey,
} from "../src/components/create-item/file-upload-helpers";

const collections = [
    { id: 1, name: "QA TEST A" },
    { id: 2, name: "QA TEST a" },
];

test("uploads retain the open collection ID despite case-colliding names", () => {
    const item = {
        file: new File(["test"], "test.txt"),
        suggestedCollectionNames: [],
    };
    const selections = collectionsByUploadItem([item], 2, collections)[
        uploadQueueItemKey(item)
    ]!;
    expect(selections).toEqual([2]);
    expect(
        resolveUploadCollectionIDs(selections, new Map([["QA TEST a", 1]])),
    ).toEqual([2]);
    expect(toggleCollectionName([1, 2], 1)).toEqual([2]);
    expect(toggleCollectionName([2], 1)).toEqual([2, 1]);
});

test("folder suggestions resolve exact case and preserve new collection names", () => {
    const item = {
        file: new File(["test"], "test.txt"),
        suggestedCollectionNames: ["QA TEST a", "New"],
    };
    const selections = collectionsByUploadItem([item], 1, collections)[
        uploadQueueItemKey(item)
    ]!;
    expect(selections).toEqual([2, "New"]);
    expect(
        resolveUploadCollectionIDs(selections, new Map([["New", 3]])),
    ).toEqual([2, 3]);
    expect(dedupeCollectionNames(["A", "a", "A"])).toEqual(["A", "a"]);
});

test("existing selections remain distinct even with identical names", () => {
    expect(resolveUploadCollectionIDs([1, 2], new Map())).toEqual([1, 2]);
    expect(uploadCollectionSelection("QA TEST a", collections)).toBe(2);
});

test("unresolved drafts fail instead of silently uploading to Uncategorized", () => {
    expect(() => resolveUploadCollectionIDs(["Missing"], new Map())).toThrow();
    expect(resolveUploadCollectionIDs([], new Map())).toEqual([]);
});

import type {
    CollectionSummary,
    CollectionSummaryAttribute,
} from "ente-new/photos/services/collection-summary";
import { describe, expect, test } from "vitest";
import {
    matchesAlbumFilter,
    visibleAlbumFilters,
    type AlbumFilter,
} from "../src/utils/album-filters";

const album = (
    id: number,
    attributes: CollectionSummaryAttribute[] = [],
    fileCount = 1,
): CollectionSummary => ({
    id,
    type: "album",
    attributes: new Set(attributes),
    name: `Album ${id}`,
    fileCount,
    latestFile: undefined,
    coverFile: undefined,
    updationTime: undefined,
    sortPriority: 0,
});

describe("album filters shared by the dialog and sidebar", () => {
    test("Ente contains non-empty local albums outside the other categories", () => {
        const albums = [
            album(1),
            { ...album(2, ["userFavorites"]), type: "userFavorites" as const },
            album(3, ["sharedOutgoing", "shared"]),
            album(4, ["sharedIncoming"]),
            album(5, ["sharedViaLink"]),
            album(6, ["quickLink"]),
            album(7, [], 0),
            album(8, ["archived"], 0),
            album(9, ["system"]),
            album(10, ["shared"]),
        ];
        expect(
            albums
                .filter((cs) => matchesAlbumFilter(cs, "ente"))
                .map(({ id }) => id),
        ).toEqual([1, 2]);
        expect(
            albums.filter((cs) => matchesAlbumFilter(cs, "all")),
        ).toHaveLength(10);
    });

    test("separates outgoing sharing, incoming sharing, and quick links", () => {
        const albums = [
            album(1),
            album(2, ["sharedOutgoing", "shared"]),
            album(3, ["sharedIncoming", "sharedViaLink", "shared"]),
            album(4, ["sharedViaLink", "shared"]),
            album(5, ["quickLink", "sharedViaLink", "shared"]),
        ];
        const ids = (filter: AlbumFilter) =>
            albums
                .filter((cs) => matchesAlbumFilter(cs, filter))
                .map(({ id }) => id);
        expect(ids("all")).toEqual([1, 2, 3, 4, 5]);
        expect(ids("shared")).toEqual([2, 4]);
        expect(ids("received")).toEqual([3]);
        expect(ids("links")).toEqual([5]);
        expect(albums.map(({ id }) => id)).toEqual([1, 2, 3, 4, 5]);
    });

    test("empty albums exclude shared, archived, system, and favorites collections", () => {
        expect(matchesAlbumFilter(album(1, [], 0), "empty-albums")).toBe(true);
        expect(
            matchesAlbumFilter(
                { ...album(2, [], 0), type: "folder" },
                "empty-albums",
            ),
        ).toBe(true);
        for (const attribute of ["shared", "archived", "system"] as const) {
            expect(
                matchesAlbumFilter(album(3, [attribute], 0), "empty-albums"),
            ).toBe(false);
        }
        expect(
            matchesAlbumFilter(
                { ...album(4, [], 0), type: "userFavorites" },
                "empty-albums",
            ),
        ).toBe(false);
        expect(matchesAlbumFilter(album(5), "empty-albums")).toBe(false);
    });

    test("shows available categories in pill order and requires three eligible empty albums", () => {
        const albums = [
            album(1, [], 0),
            album(2, [], 0),
            album(3, ["shared"], 0),
        ];
        expect(visibleAlbumFilters(albums).map(({ value }) => value)).toEqual([
            "all",
        ]);
        albums.push(
            album(4, [], 0),
            album(5, ["sharedOutgoing"]),
            album(6, ["sharedIncoming"]),
            album(7, ["quickLink"]),
        );
        expect(visibleAlbumFilters(albums).map(({ value }) => value)).toEqual([
            "all",
            "shared",
            "received",
            "links",
            "empty-albums",
        ]);
        expect(visibleAlbumFilters([]).map(({ value }) => value)).toEqual([
            "all",
        ]);
    });
});

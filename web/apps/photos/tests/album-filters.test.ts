import type {
    CollectionSummary,
    CollectionSummaryAttribute,
} from "ente-new/photos/services/collection-summary";
import { describe, expect, test } from "vitest";
import {
    matchesAlbumFilter,
    searchAlbumRows,
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
    test("sidebar search trims its query and matches album names rather than group labels", () => {
        const albums = [
            { ...album(1), name: "Wedding favourites" },
            { ...album(2), name: "Music" },
        ];
        expect(searchAlbumRows(albums, "  WEDDING  ")).toEqual([
            { type: "group", filter: "ente" },
            {
                type: "collection",
                filter: "ente",
                collectionSummary: albums[0],
            },
        ]);
        expect(searchAlbumRows(albums, "Shared")).toEqual([]);
        expect(searchAlbumRows(albums, "missing")).toEqual([]);
        expect(searchAlbumRows(albums, "   ")).toEqual(
            searchAlbumRows(albums, ""),
        );
    });

    test("sidebar search preserves group order, album order, and overlapping memberships", () => {
        const albums = [
            album(4, ["quickLink"]),
            album(3, ["sharedIncoming"]),
            album(2, ["sharedOutgoing"]),
            album(1),
        ];
        const rows = searchAlbumRows(albums, "Album");
        expect(
            rows.map((row) =>
                row.type == "group"
                    ? row.filter
                    : `${row.filter}:${row.collectionSummary.id}`,
            ),
        ).toEqual([
            "ente",
            "ente:3",
            "ente:2",
            "ente:1",
            "shared",
            "shared:2",
            "received",
            "received:3",
            "links",
            "links:4",
        ]);
        expect(albums.map(({ id }) => id)).toEqual([4, 3, 2, 1]);
        expect(searchAlbumRows(albums, "4")).toEqual([
            { type: "group", filter: "links" },
            {
                type: "collection",
                filter: "links",
                collectionSummary: albums[0],
            },
        ]);
    });

    test("sidebar search keeps full-list empty-album thresholds and collection eligibility", () => {
        const albums = [album(1, [], 0), album(2, [], 0)];
        expect(
            searchAlbumRows(albums, "1").filter((row) => row.type == "group"),
        ).toEqual([{ type: "group", filter: "ente" }]);
        albums.push(
            album(3, [], 0),
            album(4, ["archived"]),
            album(5, ["system"]),
        );
        expect(
            searchAlbumRows(albums, "1").filter((row) => row.type == "group"),
        ).toEqual([
            { type: "group", filter: "ente" },
            { type: "group", filter: "empty-albums" },
        ]);
        expect(searchAlbumRows(albums, "4")).toEqual([]);
        expect(searchAlbumRows(albums, "5")).toEqual([]);
    });

    test("sidebar search reflects updated summaries and upstream sorting", () => {
        const albums = [album(1), album(2)];
        const ids = (summaries: CollectionSummary[]) =>
            searchAlbumRows(summaries, "Album").flatMap((row) =>
                row.type == "collection" ? [row.collectionSummary.id] : [],
            );
        expect(ids(albums)).toEqual([1, 2]);
        expect(ids([...albums].reverse())).toEqual([2, 1]);
        expect(ids([{ ...albums[0]!, name: "Renamed" }, albums[1]!])).toEqual([
            2,
        ]);
    });

    test("Ente matches mobile membership, including shared, received, and empty albums", () => {
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
            {
                ...album(11, ["userFavorites"], 0),
                type: "userFavorites" as const,
            },
            {
                ...album(12, ["sharedIncoming", "favorites"], 0),
                type: "sharedIncoming" as const,
            },
            album(13, ["sharedIncoming", "uncategorized"]),
            {
                ...album(
                    14,
                    ["system", "uncategorized", "sharedOutgoing", "shared"],
                    0,
                ),
                type: "uncategorized" as const,
            },
            album(15, ["sharedOutgoing", "shared", "archived"]),
            album(16, ["sharedIncoming", "shared", "archived"]),
        ];
        expect(
            albums
                .filter((cs) => matchesAlbumFilter(cs, "ente"))
                .map(({ id }) => id),
        ).toEqual([1, 2, 3, 4, 5, 7, 10, 12]);
        expect(matchesAlbumFilter(albums[13]!, "shared")).toBe(true);
        expect(matchesAlbumFilter(albums[12]!, "received")).toBe(true);
        expect(matchesAlbumFilter(albums[14]!, "shared")).toBe(false);
        expect(matchesAlbumFilter(albums[15]!, "received")).toBe(false);
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
        expect(ids("ente")).toEqual([1, 2, 3, 4]);
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
            "ente",
        ]);
        albums.push(
            album(4, [], 0),
            album(5, ["sharedOutgoing"]),
            album(6, ["sharedIncoming"]),
            album(7, ["quickLink"]),
        );
        expect(visibleAlbumFilters(albums).map(({ value }) => value)).toEqual([
            "ente",
            "shared",
            "received",
            "links",
            "empty-albums",
        ]);
        expect(visibleAlbumFilters([]).map(({ value }) => value)).toEqual([
            "ente",
        ]);
    });
});

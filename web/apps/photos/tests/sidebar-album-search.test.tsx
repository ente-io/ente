import { ThemeProvider } from "@mui/material";
import { photosTheme } from "ente-base/components/utils/theme";
import type { CollectionSummary } from "ente-new/photos/services/collection-summary";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, test, vi } from "vitest";
import {
    GalleryBarImpl,
    type GalleryBarImplProps,
} from "../src/components/gallery/BarImpl";
import { visibleAlbumFilters } from "../src/utils/album-filters";

vi.mock("@/components/CollectionsSortOptions", () => ({
    CollectionsSortOptions: () => null,
}));
vi.mock("@/components/PeopleSortOptions", () => ({
    PeopleSortOptions: () => null,
}));
vi.mock("@/utils/album-filters", () => import("../src/utils/album-filters"));
vi.mock("i18next", () => ({ t: (key: string) => key }));
vi.mock("ente-new/photos/components/Tiles", () => ({ ItemCard: () => null }));
vi.mock("react-virtualized-auto-sizer", () => ({
    default: ({
        children,
    }: {
        children: (size: { width: number; height: number }) => React.ReactNode;
    }) => children({ width: 300, height: 400 }),
}));

const owned: CollectionSummary = {
    id: 1,
    name: "Family",
    type: "album",
    attributes: new Set(),
    fileCount: 1,
    latestFile: undefined,
    coverFile: undefined,
    updationTime: undefined,
    sortPriority: 0,
};
const link: CollectionSummary = {
    ...owned,
    id: 2,
    name: "Holiday link",
    attributes: new Set(["quickLink"]),
};
const albums = [owned, link];

const renderSearch = (query: string, albumFilter = "ente") => {
    const normalizedQuery = query.trim().toLowerCase();
    const props: GalleryBarImplProps = {
        mode: "albums",
        albumFilter: albumFilter as GalleryBarImplProps["albumFilter"],
        albumSearchQuery: query,
        collectionSummaries: albums.filter((album) =>
            album.name.toLowerCase().includes(normalizedQuery),
        ),
        visibleAlbumFilters: visibleAlbumFilters(albums, query),
        normalCollectionSummaries: new Map(),
        uncategorizedCollectionSummaryID: 99,
        activeCollectionID: undefined,
        collectionsSortBy: "updation-time-desc",
        peopleSortBy: "name-asc",
        people: [],
        activePerson: undefined,
        collapsed: false,
        mobileDrawerProps: { open: false, onClose: vi.fn() },
        onAlbumSearchQueryChange: vi.fn(),
        onShowAlbumOverview: vi.fn(),
        onShowCollectionSummary: vi.fn(),
        onSelectCollectionID: vi.fn(),
        onShowAllAlbums: vi.fn(),
        onCreateAlbum: vi.fn(),
        onShowAllPeople: vi.fn(),
        onChangeCollectionsSortBy: vi.fn(),
        onChangePeopleSortBy: vi.fn(),
        onSelectPerson: vi.fn(),
    };
    return renderToStaticMarkup(
        <ThemeProvider theme={photosTheme}>
            <GalleryBarImpl {...props} />
        </ThemeProvider>,
    );
};

describe("sidebar album search across groups", () => {
    test("reveals matching Links albums while Ente is selected", () => {
        const html = renderSearch("holiday");
        expect(html).toContain('aria-label="links_albums_title"');
        expect(html).toContain('aria-expanded="true"');
        expect(html).toContain("Holiday link");
        expect(html).not.toContain('aria-label="Ente"');
        expect(html).not.toContain("no-matches.svg");
    });

    test("reveals matching Ente albums while Links is selected", () => {
        const html = renderSearch("family", "links");
        expect(html).toContain('aria-label="Ente"');
        expect(html).toContain("Family");
        expect(html).not.toContain('aria-label="links_albums_title"');
        expect(html).not.toContain("no-matches.svg");
    });

    test("shows the empty state only when no groups match", () => {
        const html = renderSearch("missing");
        expect(html).toContain("no-matches.svg");
        expect(html).not.toContain('aria-label="filter_albums"');
    });

    test.each(["", "   "])(
        "restores all group headings for query %j",
        (query) => {
            const html = renderSearch(query);
            expect(html).toContain('aria-label="Ente"');
            expect(html).toContain('aria-label="links_albums_title"');
            expect(html).toContain("Family");
            expect(html).not.toContain("Holiday link");
            expect(html).not.toContain("no-matches.svg");
        },
    );
});

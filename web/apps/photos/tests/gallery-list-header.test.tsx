import type { FileListHeaderOrFooter } from "@/components/FileList";
import type { Collection } from "ente-media/collection";
import {
    PseudoCollectionID,
    type CollectionSummary,
} from "ente-new/photos/services/collection-summary";
import type { Person } from "ente-new/photos/services/ml/people";
import type { ComponentProps } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, test, vi } from "vitest";
import { GalleryListHeader } from "../src/components/collections/GalleryListHeader";

vi.mock("@/components/collections/CollectionShare", () => ({
    CollectionShare: () => <div>Share dialog</div>,
}));
vi.mock("../src/components/collections/AlbumCastDialog", () => ({
    AlbumCastDialog: () => <div>Cast dialog</div>,
}));
vi.mock("../src/components/collections/CollectionHeader", () => ({
    CollectionHeader: ({
        collectionSummary,
    }: {
        collectionSummary: CollectionSummary;
    }) => <div>{collectionSummary.name}</div>,
}));
vi.mock("@/components/gallery/PeopleHeader", () => ({
    PeopleHeader: ({
        person,
        people,
    }: {
        person: Person;
        people: Person[];
    }) => (
        <div>
            {person.name}: {people.length}
        </div>
    ),
}));

const summary: CollectionSummary = {
    id: PseudoCollectionID.all,
    type: "all",
    attributes: new Set(),
    name: "All photos",
    fileCount: 12,
    latestFile: undefined,
    coverFile: undefined,
    updationTime: undefined,
    sortPriority: 9,
};

type Props = Omit<ComponentProps<typeof GalleryListHeader>, "children">;
const render = (overrides: Partial<Props> = {}, showFileList = true) => {
    let header: FileListHeaderOrFooter | undefined;
    const markup = renderToStaticMarkup(
        <GalleryListHeader
            mode="albums"
            shouldHide={false}
            collectionSummary={summary}
            activeCollection={undefined}
            activePerson={undefined}
            people={[]}
            setActiveCollectionID={vi.fn()}
            onSelectPerson={vi.fn()}
            hasActiveFileSelection={false}
            isActiveCollectionDownloadInProgress={() => false}
            onRemotePull={vi.fn()}
            onAddSaveGroup={vi.fn()}
            onEditAlbumDetails={vi.fn()}
            onShowMap={vi.fn()}
            onCollectionSlideshow={vi.fn()}
            user={{ id: 1, email: "test@example.org", token: "test-token" }}
            emailByUserID={new Map()}
            shareSuggestionEmails={[]}
            setBlockingLoad={vi.fn()}
            {...overrides}
        >
            {(value) => {
                header = value;
                return showFileList ? value?.component : <div>Overview</div>;
            }}
        </GalleryListHeader>,
    );
    return { markup, header };
};

describe("gallery list header", () => {
    test("provides a pseudo-collection header on the first render without effects", () => {
        const { markup, header } = render();
        expect(markup).toContain("All photos");
        expect(header?.height).toBe(72);
    });

    test("uses the current person and people data directly", () => {
        const person = { id: "person", name: "Alice" } as Person;
        expect(
            render({ mode: "people", activePerson: person, people: [person] })
                .markup,
        ).toContain("Alice: 1");
        expect(
            render({
                mode: "people",
                activePerson: person,
                people: [person, person],
            }).markup,
        ).toContain("Alice: 2");
    });

    test("does not supply a collection header for search or links", () => {
        expect(render({ shouldHide: true }).header).toBeUndefined();
        expect(render({ mode: "links" }).header).toBeUndefined();
    });

    test("keeps collection dialogs outside the file list when an overview is shown", () => {
        const { markup } = render(
            { activeCollection: { id: 1 } as Collection },
            false,
        );
        expect(markup).toContain("Overview");
        expect(markup).toContain("Share dialog");
        expect(markup).toContain("Cast dialog");
        expect(markup).not.toContain("All photos");
    });

    test("hides collection dialogs during search", () => {
        const { markup } = render({
            activeCollection: { id: 1 } as Collection,
            shouldHide: true,
        });
        expect(markup).not.toContain("Share dialog");
        expect(markup).not.toContain("Cast dialog");
    });
});

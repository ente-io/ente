// TODO: Audit this file
import { AllAlbums } from "components/Collections/AllAlbums";
import {
    CollectionShare,
    type CollectionShareProps,
} from "components/Collections/CollectionShare";
import type { FileListHeaderOrFooter } from "components/FileList";
import { useModalVisibility } from "ente-base/components/utils/modal";
import {
    isSaveCancelled,
    isSaveComplete,
    type SaveGroup,
} from "ente-gallery/components/utils/save-groups";
import { sortFiles } from "ente-gallery/utils/file";
import type { Collection } from "ente-media/collection";
import type { EnteFile } from "ente-media/file";
import {
    GalleryBarImpl,
    type GalleryBarImplProps,
} from "ente-new/photos/components/gallery/BarImpl";
import { PeopleHeader } from "ente-new/photos/components/gallery/PeopleHeader";
import type { CollectionSummary } from "ente-new/photos/services/collection-summary";
import {
    collectionsSortBy,
    haveOnlySystemCollections,
    PseudoCollectionID,
    type CollectionsSortBy,
    type CollectionSummaries,
} from "ente-new/photos/services/collection-summary";
import { includes } from "ente-utils/type-guards";
import React, { useCallback, useEffect, useMemo, useState } from "react";
import { AlbumCastDialog } from "./AlbumCastDialog";
import {
    CollectionHeader,
    type CollectionHeaderProps,
} from "./CollectionHeader";

type GalleryBarAndListHeaderProps = Omit<
    GalleryBarImplProps,
    | "collectionSummaries"
    | "onSelectCollectionID"
    | "collectionsSortBy"
    | "onChangeCollectionsSortBy"
    | "onShowAllAlbums"
> & {
    /**
     * When `true`, the bar is be hidden altogether.
     */
    shouldHide: boolean;
    barCollectionSummaries: CollectionSummaries;
    activeCollection: Collection;
    setActiveCollectionID: (collectionID: number) => void;
    setFileListHeader: (header: FileListHeaderOrFooter) => void;
    saveGroups: SaveGroup[];
} & Pick<CollectionHeaderProps, "onRemotePull" | "onAddSaveGroup"> &
    Pick<
        CollectionShareProps,
        "user" | "emailByUserID" | "shareSuggestionEmails" | "setBlockingLoad"
    >;

/**
 * The gallery bar, the header for the list items, and state for any associated
 * dialogs that might be triggered by actions on either the bar or the header..
 *
 * This component manages the sticky horizontally scrollable bar shown at the
 * top of the gallery, AND the (non-sticky) header shown below the bar, at the
 * top of the actual list of items.
 *
 * These are disparate views - indeed, the list header is not even a child of
 * this component but is instead proxied via {@link setFileListHeader}. Still,
 * having this intermediate wrapper component allows us to move some of the
 * common concerns shared by both the gallery bar and list header (e.g. some
 * dialogs that can be invoked from both places) into this file instead of
 * cluttering the already big gallery component.
 *
 * TODO: Once the gallery code is better responsibilitied out, consider moving
 * this code back inline into the gallery.
 */
export const GalleryBarAndListHeader: React.FC<
    GalleryBarAndListHeaderProps
> = ({
    shouldHide,
    mode,
    onChangeMode,
    user,
    barCollectionSummaries: toShowCollectionSummaries,
    activeCollection,
    activeCollectionID,
    setActiveCollectionID,
    setBlockingLoad,
    people,
    saveGroups,
    activePerson,
    emailByUserID,
    shareSuggestionEmails,
    onRemotePull,
    onAddSaveGroup,
    onSelectPerson,
    setFileListHeader,
}) => {
    const { show: showAllAlbums, props: allAlbumsVisibilityProps } =
        useModalVisibility();
    const { show: showCollectionShare, props: collectionShareVisibilityProps } =
        useModalVisibility();
    const { show: showCollectionCast, props: collectionCastVisibilityProps } =
        useModalVisibility();

    const [collectionsSortBy, setCollectionsSortBy] =
        useCollectionsSortByLocalState("updation-time-desc");

    const shouldBeHidden = useMemo(
        () =>
            shouldHide ||
            (haveOnlySystemCollections(toShowCollectionSummaries) &&
                activeCollectionID === PseudoCollectionID.all),
        [shouldHide, toShowCollectionSummaries, activeCollectionID],
    );

    const sortedCollectionSummaries = useMemo(
        () =>
            sortCollectionSummaries(
                [...toShowCollectionSummaries.values()],
                collectionsSortBy,
            ),
        [collectionsSortBy, toShowCollectionSummaries],
    );

    const isActiveCollectionDownloadInProgress = useCallback(() => {
        const group = saveGroups.find(
            (g) => g.collectionSummaryID === activeCollectionID,
        );
        return !!group && !isSaveComplete(group) && !isSaveCancelled(group);
    }, [saveGroups, activeCollectionID]);

    useEffect(() => {
        if (shouldHide) return;

        setFileListHeader({
            component:
                mode != "people" ? (
                    <CollectionHeader
                        {...{
                            activeCollection,
                            setActiveCollectionID,
                            isActiveCollectionDownloadInProgress,
                            onRemotePull,
                            onAddSaveGroup,
                        }}
                        collectionSummary={
                            toShowCollectionSummaries.get(activeCollectionID!)!
                        }
                        onCollectionShare={showCollectionShare}
                        onCollectionCast={showCollectionCast}
                    />
                ) : activePerson ? (
                    <PeopleHeader
                        person={activePerson}
                        {...{ onSelectPerson, people }}
                    />
                ) : (
                    <></>
                ),
            height: 68,
        });
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [
        shouldHide,
        mode,
        toShowCollectionSummaries,
        activeCollectionID,
        isActiveCollectionDownloadInProgress,
        activePerson,
        showCollectionShare,
        showCollectionCast,
        // TODO: Cluster
        // This causes a loop since it is an array dep
        // people,
    ]);

    if (shouldBeHidden) {
        return <></>;
    }

    return (
        <>
            <GalleryBarImpl
                {...{
                    mode,
                    onChangeMode,
                    activeCollectionID,
                    people,
                    activePerson,
                    onSelectPerson,
                    collectionsSortBy,
                }}
                onSelectCollectionID={setActiveCollectionID}
                onChangeCollectionsSortBy={setCollectionsSortBy}
                onShowAllAlbums={showAllAlbums}
                collectionSummaries={sortedCollectionSummaries.filter(
                    (cs) => !cs.attributes.has("hideFromCollectionBar"),
                )}
            />

            <AllAlbums
                {...allAlbumsVisibilityProps}
                collectionSummaries={sortedCollectionSummaries.filter(
                    (cs) => !cs.attributes.has("system"),
                )}
                onSelectCollectionID={setActiveCollectionID}
                onChangeCollectionsSortBy={setCollectionsSortBy}
                collectionsSortBy={collectionsSortBy}
                isInHiddenSection={mode == "hidden-albums"}
            />
            <CollectionShare
                {...collectionShareVisibilityProps}
                collectionSummary={
                    toShowCollectionSummaries.get(activeCollectionID!)!
                }
                collection={activeCollection}
                {...{
                    user,
                    emailByUserID,
                    shareSuggestionEmails,
                    setBlockingLoad,
                    onRemotePull,
                }}
            />
            <AlbumCastDialog
                {...collectionCastVisibilityProps}
                collection={activeCollection}
            />
        </>
    );
};

/**
 * A hook that maintains the collections sort order both as in-memory and local
 * storage state.
 */
const useCollectionsSortByLocalState = (initialValue: CollectionsSortBy) => {
    const key = "collectionsSortBy";

    const [value, setValue] = useState(initialValue);

    useEffect(() => {
        const value = localStorage.getItem(key);
        if (value && includes(collectionsSortBy, value)) setValue(value);
    }, []);

    const setter = (value: CollectionsSortBy) => {
        localStorage.setItem(key, value);
        setValue(value);
    };

    return [value, setter] as const;
};

const sortCollectionSummaries = (
    collectionSummaries: CollectionSummary[],
    by: CollectionsSortBy,
) =>
    collectionSummaries
        .sort((a, b) => {
            switch (by) {
                case "name":
                    return a.name.localeCompare(b.name);
                case "creation-time-asc":
                    return (
                        -1 *
                        compareCollectionsLatestFile(b.latestFile, a.latestFile)
                    );
                case "updation-time-desc":
                    return (b.updationTime ?? 0) - (a.updationTime ?? 0);
            }
        })
        .sort((a, b) => b.sortPriority - a.sortPriority);

const compareCollectionsLatestFile = (
    first: EnteFile | undefined,
    second: EnteFile | undefined,
) => {
    if (!first) {
        return 1;
    } else if (!second) {
        return -1;
    } else {
        const sortedFiles = sortFiles([first, second]);
        if (sortedFiles[0]?.id !== first.id) {
            return 1;
        } else {
            return -1;
        }
    }
};

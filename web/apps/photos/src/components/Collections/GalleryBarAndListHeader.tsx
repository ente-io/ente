import { useModalVisibility } from "@/base/components/utils/modal";
import type { Collection } from "@/media/collection";
import {
    GalleryBarImpl,
    type GalleryBarImplProps,
} from "@/new/photos/components/gallery/BarImpl";
import { PeopleHeader } from "@/new/photos/components/gallery/PeopleHeader";
import { ALL_SECTION } from "@/new/photos/services/collection";
import {
    areOnlySystemCollections,
    collectionsSortBy,
    isSystemCollection,
    shouldShowOnCollectionBar,
    type CollectionsSortBy,
    type CollectionSummaries,
} from "@/new/photos/services/collection/ui";
import { includes } from "@/utils/type-guards";
import {
    getData,
    LS_KEYS,
    removeData,
} from "@ente/shared/storage/localStorage";
import { AllAlbums } from "components/Collections/AllAlbums";
import { SetCollectionNamerAttributes } from "components/Collections/CollectionNamer";
import { CollectionShare } from "components/Collections/CollectionShare";
import { ITEM_TYPE, TimeStampListItem } from "components/FileList";
import React, { useCallback, useEffect, useMemo, useState } from "react";
import { sortCollectionSummaries } from "services/collectionService";
import { SetFilesDownloadProgressAttributesCreator } from "types/gallery";
import {
    FilesDownloadProgressAttributes,
    isFilesDownloadCancelled,
    isFilesDownloadCompleted,
} from "../FilesDownloadProgress";
import { AlbumCastDialog } from "./AlbumCastDialog";
import { CollectionHeader } from "./CollectionHeader";

type CollectionsProps = Omit<
    GalleryBarImplProps,
    | "collectionSummaries"
    | "hiddenCollectionSummaries"
    | "onSelectCollectionID"
    | "collectionsSortBy"
    | "onChangeCollectionsSortBy"
    | "onShowAllAlbums"
> & {
    /**
     * When `true`, the bar is be hidden altogether.
     */
    shouldHide: boolean;
    collectionSummaries: CollectionSummaries;
    activeCollection: Collection;
    setActiveCollectionID: (collectionID: number) => void;
    hiddenCollectionSummaries: CollectionSummaries;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    setPhotoListHeader: (value: TimeStampListItem) => void;
    filesDownloadProgressAttributesList: FilesDownloadProgressAttributes[];
    setFilesDownloadProgressAttributesCreator: SetFilesDownloadProgressAttributesCreator;
};

/**
 * The gallery bar, the header for the list items, and state for any associated
 * dialogs that might be triggered by actions on either the bar or the header..
 *
 * This component manages the sticky horizontally scrollable bar shown at the
 * top of the gallery, AND the non-sticky header shown below the bar, at the top
 * of the actual list of items.
 *
 * These are disparate views - indeed, the list header is not even a child of
 * this component but is instead proxied via {@link setPhotoListHeader}. Still,
 * having this intermediate wrapper component allows us to move some of the
 * common concerns shared by both the gallery bar and list header (e.g. some
 * dialogs that can be invoked from both places) into this file instead of
 * cluttering the already big gallery component.
 *
 * TODO: Once the gallery code is better responsibilitied out, consider moving
 * this code back inline into the gallery.
 */
export const GalleryBarAndListHeader: React.FC<CollectionsProps> = ({
    shouldHide,
    mode,
    onChangeMode,
    collectionSummaries,
    activeCollection,
    activeCollectionID,
    setActiveCollectionID,
    hiddenCollectionSummaries,
    people,
    activePerson,
    onSelectPerson,
    setCollectionNamerAttributes,
    setPhotoListHeader,
    filesDownloadProgressAttributesList,
    setFilesDownloadProgressAttributesCreator,
}) => {
    const { show: showAllAlbums, props: allAlbumsVisibilityProps } =
        useModalVisibility();
    const { show: showCollectionShare, props: collectionShareVisibilityProps } =
        useModalVisibility();
    const { show: showCollectionCast, props: collectionCastVisibilityProps } =
        useModalVisibility();

    const [collectionsSortBy, setCollectionsSortBy] =
        useCollectionsSortByLocalState("updation-time-desc");

    const toShowCollectionSummaries = useMemo(
        () =>
            mode == "hidden-albums"
                ? hiddenCollectionSummaries
                : collectionSummaries,
        [mode, hiddenCollectionSummaries, collectionSummaries],
    );

    const shouldBeHidden = useMemo(
        () =>
            shouldHide ||
            (areOnlySystemCollections(toShowCollectionSummaries) &&
                activeCollectionID === ALL_SECTION),
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
        const attributes = filesDownloadProgressAttributesList.find(
            (attr) => attr.collectionID === activeCollectionID,
        );
        return (
            attributes &&
            !isFilesDownloadCancelled(attributes) &&
            !isFilesDownloadCompleted(attributes)
        );
    }, [activeCollectionID, filesDownloadProgressAttributesList]);

    useEffect(() => {
        if (shouldHide) return;

        setPhotoListHeader({
            item:
                mode != "people" ? (
                    <CollectionHeader
                        {...{
                            activeCollection,
                            setActiveCollectionID,
                            setCollectionNamerAttributes,
                            setFilesDownloadProgressAttributesCreator,
                            isActiveCollectionDownloadInProgress,
                        }}
                        collectionSummary={toShowCollectionSummaries.get(
                            activeCollectionID,
                        )}
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
            itemType: ITEM_TYPE.HEADER,
            height: 68,
        });
    }, [
        shouldHide,
        mode,
        toShowCollectionSummaries,
        activeCollectionID,
        isActiveCollectionDownloadInProgress,
        activePerson,
        showCollectionShare,
        showCollectionCast,
        // TODO-Cluster
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
                collectionSummaries={sortedCollectionSummaries.filter((x) =>
                    shouldShowOnCollectionBar(x.type),
                )}
            />

            <AllAlbums
                {...allAlbumsVisibilityProps}
                collectionSummaries={sortedCollectionSummaries.filter(
                    (x) => !isSystemCollection(x.type),
                )}
                onSelectCollectionID={setActiveCollectionID}
                onChangeCollectionsSortBy={setCollectionsSortBy}
                collectionsSortBy={collectionsSortBy}
                isInHiddenSection={mode == "hidden-albums"}
            />
            <CollectionShare
                {...collectionShareVisibilityProps}
                collectionSummary={toShowCollectionSummaries.get(
                    activeCollectionID,
                )}
                collection={activeCollection}
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
        if (value) {
            if (includes(collectionsSortBy, value)) setValue(value);
        } else {
            // Older versions of this code used to store the value in a
            // different place and format. Migrate if needed.
            //
            // This migration added Sep 2024, can be removed after a bit (esp
            // since it effectively runs on each app start). (tag: Migration).
            const oldData = getData(LS_KEYS.COLLECTION_SORT_BY);
            if (oldData) {
                let newValue: CollectionsSortBy | undefined;
                switch (oldData.value) {
                    case 0:
                        newValue = "name";
                        break;
                    case 1:
                        newValue = "creation-time-asc";
                        break;
                    case 2:
                        newValue = "updation-time-desc";
                        break;
                }
                if (newValue) {
                    localStorage.setItem(key, newValue);
                    setValue(newValue);
                }
                removeData(LS_KEYS.COLLECTION_SORT_BY);
            }
        }
    }, []);

    const setter = (value: CollectionsSortBy) => {
        localStorage.setItem(key, value);
        setValue(value);
    };

    return [value, setter] as const;
};

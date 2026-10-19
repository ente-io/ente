// TODO: Audit this file
import { collectionDialogBodyMutedSx as bodyMutedSx } from "@/components/CollectionDialog/styles";
import { AllAlbums } from "@/components/Collections/AllAlbums";
import { AllPeople } from "@/components/Collections/AllPeople";
import {
    CollectionShare,
    type CollectionShareIntent,
    type CollectionShareProps,
} from "@/components/Collections/CollectionShare";
import type { FileListHeaderOrFooter } from "@/components/FileList";
import {
    GalleryBarImpl,
    type GalleryBarImplProps,
} from "@/components/gallery/BarImpl";
import { PeopleHeader } from "@/components/gallery/PeopleHeader";
import {
    filterAlbumSummaries,
    visibleAlbumFilters as getVisibleAlbumFilters,
} from "@/utils/album-filters";
import { sortPeople } from "@/utils/people-sort";
import ArrowForwardIcon from "@mui/icons-material/ArrowForward";
import CloseIcon from "@mui/icons-material/Close";
import {
    Box,
    DialogTitle,
    Paper,
    Snackbar,
    Stack,
    Typography,
} from "@mui/material";
import { FilledIconButton } from "ente-base/components/mui";
import { SingleInputDialog } from "ente-base/components/SingleInputDialog";
import { useModalVisibility } from "ente-base/components/utils/modal";
import {
    isSaveCancelled,
    isSaveComplete,
    type SaveGroup,
} from "ente-gallery/components/utils/save-groups";
import type { Collection } from "ente-media/collection";
import {
    GalleryItemsHeaderAdapter,
    GalleryItemsSummary,
} from "ente-new/photos/components/gallery/ListHeader";
import {
    createAlbum,
    createHiddenAlbum,
} from "ente-new/photos/services/collection";
import {
    collectionsSortBy,
    PseudoCollectionID,
    sortCollectionSummaries,
    type CollectionsSortBy,
    type CollectionSummaries,
    type CollectionSummary,
} from "ente-new/photos/services/collection-summary";
import type { Person } from "ente-new/photos/services/ml/people";
import { usePhotosAppContext } from "ente-new/photos/types/context";
import { includes } from "ente-utils/type-guards";
import { t } from "i18next";
import React, {
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import { AlbumCastDialog } from "./AlbumCastDialog";
import {
    CollectionHeader,
    type CollectionHeaderProps,
} from "./CollectionHeader";

export type GalleryBarAndListHeaderProps = Omit<
    GalleryBarImplProps,
    | "collectionSummaries"
    | "visibleAlbumFilters"
    | "onSelectCollectionID"
    | "collectionsSortBy"
    | "onChangeCollectionsSortBy"
    | "onCreateAlbum"
    | "onShowAllAlbums"
    | "onShowAllPeople"
> & {
    onAlbumSummariesChange: (
        albums: CollectionSummary[],
        sortBy: CollectionsSortBy,
    ) => void;
    shouldHide: boolean;
    barCollectionSummaries: CollectionSummaries;
    allPeople: Person[];
    activeCollection: Collection | undefined;
    setActiveCollectionID: (collectionID: number) => void;
    setFileListHeader: (header: FileListHeaderOrFooter) => void;
    hasActiveFileSelection: boolean;
    saveGroups: SaveGroup[];
    canCreateAlbum: boolean;
} & Pick<
        CollectionHeaderProps,
        | "onRemotePull"
        | "onAddSaveGroup"
        | "onEditAlbumDetails"
        | "onShowMap"
        | "onCollectionSlideshow"
    > &
    Pick<
        CollectionShareProps,
        "user" | "emailByUserID" | "shareSuggestionEmails" | "setBlockingLoad"
    >;

// TODO: Move this back into the gallery once its responsibilities are split.
export const GalleryBarAndListHeader: React.FC<
    GalleryBarAndListHeaderProps
> = ({
    shouldHide,
    mode,
    user,
    barCollectionSummaries: toShowCollectionSummaries,
    normalCollectionSummaries,
    uncategorizedCollectionSummaryID,
    onShowCollectionSummary,
    activeCollection,
    activeCollectionID,
    setActiveCollectionID,
    setBlockingLoad,
    people,
    peopleSortBy,
    onChangePeopleSortBy,
    onAlbumSummariesChange,
    albumFilter,
    albumSearchQuery,
    onAlbumSearchQueryChange,
    onShowAlbumOverview,
    onSelectPerson,
    allPeople,
    saveGroups,
    canCreateAlbum,
    hasActiveFileSelection,
    activePerson,
    emailByUserID,
    shareSuggestionEmails,
    onRemotePull,
    onEditAlbumDetails,
    onAddSaveGroup,
    onShowMap,
    onCollectionSlideshow,
    setFileListHeader,
    collapsed,
    mobileDrawerProps,
}) => {
    const { show: showAllAlbums, props: allAlbumsVisibilityProps } =
        useModalVisibility();
    const { show: showAlbumNameInput, props: albumNameInputVisibilityProps } =
        useModalVisibility();
    const [albumCreatedToast, setAlbumCreatedToast] = useState<{
        open: boolean;
        albumId?: number;
        albumName?: string;
    }>({ open: false });

    const { showNotification } = usePhotosAppContext();
    const createInHiddenSection = useRef(false);
    const openAlbumCreation = () => {
        createInHiddenSection.current = mode == "hidden-albums";
        showAlbumNameInput();
    };

    const handleCreateAlbum = (albumName: string) => {
        allAlbumsVisibilityProps.onClose();

        void (async () => {
            try {
                const newAlbum = createInHiddenSection.current
                    ? await createHiddenAlbum(albumName)
                    : await createAlbum(albumName);
                await onRemotePull();

                setAlbumCreatedToast({
                    open: true,
                    albumId: newAlbum.id,
                    albumName: albumName,
                });
            } catch {
                showNotification({
                    color: "critical",
                    title: t("generic_error_retry"),
                });
            }
        })();
    };

    const { show: showAllPeople, props: allPeopleVisibilityProps } =
        useModalVisibility();
    const { show: showCollectionShare, props: collectionShareVisibilityProps } =
        useModalVisibility();
    const { show: showCollectionCast, props: collectionCastVisibilityProps } =
        useModalVisibility();
    const [collectionShareIntent, setCollectionShareIntent] =
        useState<CollectionShareIntent>();

    const openCollectionShare = useCallback(() => {
        setCollectionShareIntent(undefined);
        showCollectionShare();
    }, [showCollectionShare]);

    const openCollectionManageLink = useCallback(() => {
        setCollectionShareIntent("manage-link");
        showCollectionShare();
    }, [showCollectionShare]);

    const closeCollectionShare = useCallback(() => {
        setCollectionShareIntent(undefined);
        collectionShareVisibilityProps.onClose();
    }, [collectionShareVisibilityProps]);

    const [collectionsSortBy, setCollectionsSortBy] =
        useCollectionsSortByLocalState("updation-time-desc");

    const sortedCollectionSummaries = useMemo(
        () =>
            sortCollectionSummaries(
                [...toShowCollectionSummaries.values()],
                collectionsSortBy,
            ).sort((a, b) => b.sortPriority - a.sortPriority),
        [collectionsSortBy, toShowCollectionSummaries],
    );
    const eligibleCollectionSummaries = useMemo(
        () =>
            sortedCollectionSummaries.filter(
                (cs) =>
                    cs.id !== uncategorizedCollectionSummaryID &&
                    cs.id !== PseudoCollectionID.hiddenItems &&
                    cs.id !== PseudoCollectionID.archiveItems &&
                    cs.id !== PseudoCollectionID.trash &&
                    (mode == "albums"
                        ? !cs.attributes.has("system") ||
                          (cs.id > 0 && cs.type == "uncategorized")
                        : !cs.attributes.has("hideFromCollectionBar") &&
                          !cs.attributes.has("quickLink")),
            ),
        [sortedCollectionSummaries, uncategorizedCollectionSummaryID, mode],
    );
    const visibleAlbumFilters = useMemo(
        () => getVisibleAlbumFilters(eligibleCollectionSummaries),
        [eligibleCollectionSummaries],
    );
    const visibleCollectionSummaries = useMemo(
        () =>
            mode == "albums"
                ? filterAlbumSummaries(
                      eligibleCollectionSummaries,
                      albumFilter,
                      albumSearchQuery,
                  )
                : eligibleCollectionSummaries,
        [eligibleCollectionSummaries, mode, albumFilter, albumSearchQuery],
    );

    useEffect(() => {
        if (mode == "albums")
            onAlbumSummariesChange(
                visibleCollectionSummaries,
                collectionsSortBy,
            );
    }, [
        mode,
        visibleCollectionSummaries,
        collectionsSortBy,
        onAlbumSummariesChange,
    ]);

    const sortedPeople = useMemo(
        () => sortPeople(people, peopleSortBy),
        [people, peopleSortBy],
    );

    const isActiveCollectionDownloadInProgress = useCallback(() => {
        const group = saveGroups.find(
            (g) => g.collectionSummaryID === activeCollectionID,
        );
        return !!group && !isSaveComplete(group) && !isSaveCancelled(group);
    }, [saveGroups, activeCollectionID]);

    const albumDescription =
        activeCollection?.pubMagicMetadata?.data.caption?.trim();
    const [descriptionHeight, setDescriptionHeight] = useState(0);

    const { onClose: closeMobileDrawer } = mobileDrawerProps;
    const selectCollection = useCallback(
        (id: number) => {
            setActiveCollectionID(id);
            closeMobileDrawer();
        },
        [setActiveCollectionID, closeMobileDrawer],
    );
    const selectPerson = useCallback(
        (id: string) => {
            onSelectPerson(id);
            closeMobileDrawer();
        },
        [onSelectPerson, closeMobileDrawer],
    );

    useEffect(() => {
        if (shouldHide) return;

        const collectionSummary = toShowCollectionSummaries.get(
            activeCollectionID!,
        );
        // Pseudo-collections need header actions despite having no Collection.
        const shouldRenderCollectionHeader =
            mode != "people" &&
            collectionSummary &&
            (activeCollection ||
                collectionSummary.id <= PseudoCollectionID.all);

        setFileListHeader({
            component: shouldRenderCollectionHeader ? (
                <CollectionHeader
                    {...{
                        activeCollection,
                        setActiveCollectionID,
                        isActiveCollectionDownloadInProgress,
                        onRemotePull,
                        onAddSaveGroup,
                        onShowMap,
                        onCollectionSlideshow,
                    }}
                    collectionSummary={collectionSummary}
                    onCollectionShare={openCollectionShare}
                    onCollectionManageLink={openCollectionManageLink}
                    onCollectionCast={showCollectionCast}
                    onEditAlbumDetails={onEditAlbumDetails}
                    hasActiveFileSelection={hasActiveFileSelection}
                    onDescriptionHeightChange={setDescriptionHeight}
                />
            ) : mode != "people" && collectionSummary ? (
                <GalleryItemsHeaderAdapter>
                    <GalleryItemsSummary
                        name={collectionSummary.name}
                        fileCount={collectionSummary.fileCount}
                    />
                </GalleryItemsHeaderAdapter>
            ) : activePerson ? (
                <PeopleHeader
                    person={activePerson}
                    {...{ onSelectPerson, people }}
                />
            ) : (
                <></>
            ),
            height: 72 + (albumDescription ? descriptionHeight : 0),
        });
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [
        shouldHide,
        mode,
        toShowCollectionSummaries,
        activeCollection,
        activeCollectionID,
        isActiveCollectionDownloadInProgress,
        activePerson,
        showCollectionShare,
        openCollectionShare,
        openCollectionManageLink,
        showCollectionCast,
        hasActiveFileSelection,
        onRemotePull,
        onAddSaveGroup,
        onShowMap,
        onCollectionSlideshow,
        onEditAlbumDetails,
        albumDescription,
        descriptionHeight,
        // TODO: Cluster
        // This causes a loop since it is an array dep
        // people,
    ]);

    if (shouldHide) {
        return <></>;
    }

    return (
        <>
            <GalleryBarImpl
                {...{
                    mode,
                    albumFilter,
                    albumSearchQuery,
                    onAlbumSearchQueryChange,
                    onShowAlbumOverview,
                    activeCollectionID,
                    people: sortedPeople,
                    activePerson,
                    collectionsSortBy,
                    peopleSortBy,
                    collapsed,
                    mobileDrawerProps,
                    normalCollectionSummaries,
                    uncategorizedCollectionSummaryID,
                    onShowCollectionSummary,
                }}
                onSelectCollectionID={selectCollection}
                onSelectPerson={selectPerson}
                onChangeCollectionsSortBy={setCollectionsSortBy}
                onChangePeopleSortBy={onChangePeopleSortBy}
                onCreateAlbum={openAlbumCreation}
                onShowAllAlbums={showAllAlbums}
                onShowAllPeople={showAllPeople}
                collectionSummaries={visibleCollectionSummaries}
                visibleAlbumFilters={visibleAlbumFilters}
            />

            <AllAlbums
                {...allAlbumsVisibilityProps}
                collectionSummaries={sortedCollectionSummaries.filter(
                    (cs) => !cs.attributes.has("system"),
                )}
                onSelectCollectionID={selectCollection}
                onChangeCollectionsSortBy={setCollectionsSortBy}
                collectionsSortBy={collectionsSortBy}
                isInHiddenSection={mode == "hidden-albums"}
                isInArchiveSection={mode == "archive-albums"}
                canCreateAlbum={canCreateAlbum}
                onCreateAlbum={openAlbumCreation}
                onRemotePull={onRemotePull}
            />
            <SingleInputDialog
                {...albumNameInputVisibilityProps}
                variant="v2"
                title={t("new_album")}
                label={t("album_name")}
                submitButtonTitle={t("create")}
                onSubmit={handleCreateAlbum}
            />
            <Snackbar
                open={albumCreatedToast.open}
                anchorOrigin={{ horizontal: "right", vertical: "bottom" }}
            >
                <Paper sx={{ width: "min(360px, 100svw)" }}>
                    <DialogTitle>
                        <Stack
                            direction="row"
                            sx={{
                                justifyContent: "space-between",
                                alignItems: "center",
                            }}
                        >
                            <Box>
                                <Typography variant="h3">
                                    {t("album_created")}
                                </Typography>
                                <Typography
                                    sx={[bodyMutedSx, { marginTop: "4px" }]}
                                >
                                    {albumCreatedToast.albumName &&
                                    albumCreatedToast.albumName.length > 16
                                        ? albumCreatedToast.albumName.substring(
                                              0,
                                              16,
                                          ) + "..."
                                        : albumCreatedToast.albumName}
                                </Typography>
                            </Box>
                            <Stack direction="row" sx={{ gap: 1 }}>
                                <FilledIconButton
                                    onClick={() => {
                                        if (albumCreatedToast.albumId) {
                                            selectCollection(
                                                albumCreatedToast.albumId,
                                            );
                                        }
                                        setAlbumCreatedToast((prev) => ({
                                            ...prev,
                                            open: false,
                                        }));
                                    }}
                                >
                                    <ArrowForwardIcon />
                                </FilledIconButton>
                                <FilledIconButton
                                    onClick={() =>
                                        setAlbumCreatedToast((prev) => ({
                                            ...prev,
                                            open: false,
                                        }))
                                    }
                                >
                                    <CloseIcon />
                                </FilledIconButton>
                            </Stack>
                        </Stack>
                    </DialogTitle>
                </Paper>
            </Snackbar>
            <AllPeople
                {...allPeopleVisibilityProps}
                people={sortedPeople}
                allPeople={allPeople}
                onSelectPerson={selectPerson}
                peopleSortBy={peopleSortBy}
                onChangePeopleSortBy={onChangePeopleSortBy}
            />
            {activeCollection && (
                <>
                    <CollectionShare
                        {...collectionShareVisibilityProps}
                        onClose={closeCollectionShare}
                        collectionSummary={toShowCollectionSummaries.get(
                            activeCollectionID!,
                        )!}
                        collection={activeCollection}
                        intent={collectionShareIntent}
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
            )}
        </>
    );
};

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

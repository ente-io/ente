// TODO: Audit this file (too many null assertions + other issues)
/* eslint-disable @typescript-eslint/no-floating-promises */
import {
    Download01Icon,
    ImageAdd02Icon,
    Share08Icon,
} from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import CheckIcon from "@mui/icons-material/Check";
import CloseIcon from "@mui/icons-material/Close";
import {
    Box,
    Button,
    IconButton,
    Stack,
    styled,
    Tooltip,
    useMediaQuery,
} from "@mui/material";
import Typography from "@mui/material/Typography";
import { FeedIcon } from "components/Collections/CollectionHeader";
import { DownloadStatusNotifications } from "components/DownloadStatusNotifications";
import { type FileListHeaderOrFooter } from "components/FileList";
import { FileListWithViewer } from "components/FileListWithViewer";
import { TripLayout } from "components/TripLayout";
import { Upload } from "components/Upload";
import {
    AccountsPageContents,
    AccountsPageTitle,
} from "ente-accounts/components/layouts/centered-paper";
import { SpacedRow, Stack100vhCenter } from "ente-base/components/containers";
import { EnteLogo } from "ente-base/components/EnteLogo";
import {
    LoadingIndicator,
    TranslucentLoadingOverlay,
} from "ente-base/components/loaders";
import type { ButtonishProps } from "ente-base/components/mui";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { NavbarBase } from "ente-base/components/Navbar";
import {
    SingleInputForm,
    type SingleInputFormProps,
} from "ente-base/components/SingleInputForm";
import { useIsSmallWidth } from "ente-base/components/utils/hooks";
import { useModalVisibility } from "ente-base/components/utils/modal";
import { useBaseContext } from "ente-base/context";
import {
    isHTTP401Error,
    isHTTPErrorWithStatus,
    type PublicAlbumsCredentials,
} from "ente-base/http";
import log from "ente-base/log";
import {
    albumsAppOrigin,
    isCustomAlbumsAppOrigin,
    shouldOnlyServeAlbumsApp,
} from "ente-base/origins";
import { FullScreenDropZone } from "ente-gallery/components/FullScreenDropZone";
import {
    useSaveGroups,
    type AddSaveGroup,
} from "ente-gallery/components/utils/save-groups";
import { type FileViewerInitialSidebar } from "ente-gallery/components/viewer/FileViewer";
import {
    PublicFeedSidebar,
    type PublicFeedItemClickInfo,
} from "ente-gallery/components/viewer/PublicFeedSidebar";
import { downloadManager } from "ente-gallery/services/download";
import {
    downloadAndSaveCollectionFiles,
    downloadAndSaveFiles,
} from "ente-gallery/services/save";
import { extractCollectionKeyFromShareURL } from "ente-gallery/services/share";
import { updateShouldDisableCFUploadProxy } from "ente-gallery/services/upload";
import { sortFiles } from "ente-gallery/utils/file";
import type { Collection } from "ente-media/collection";
import { type EnteFile } from "ente-media/file";
import { fileCreationTime, fileFileName } from "ente-media/file-metadata";
import { FileType } from "ente-media/file-type";
import {
    removePublicCollectionAccessTokenJWT,
    removePublicCollectionByKey,
    savedPublicCollectionAccessTokenJWT,
    savedPublicCollectionByKey,
    savedPublicCollectionFiles,
    savePublicCollectionAccessTokenJWT,
} from "ente-new/albums/services/public-albums-fdb";
import {
    pullCollection,
    pullPublicCollectionFiles,
    removePublicCollectionFileData,
    verifyPublicAlbumPassword,
} from "ente-new/albums/services/public-collection";
import {
    GalleryItemsHeaderAdapter,
    GalleryItemsSummary,
} from "ente-new/photos/components/gallery/ListHeader";
import { Notification } from "ente-new/photos/components/Notification";
import { PseudoCollectionID } from "ente-new/photos/services/collection-summary";
import { usePhotosAppContext } from "ente-new/photos/types/context";
import { useJoinAlbum } from "hooks/useJoinAlbum";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { type FileWithPath } from "react-dropzone";
import { uploadManager } from "services/upload-manager";
import { getSelectedFiles, type SelectedState } from "utils/file";
import { getEnteURL } from "utils/public-album";
import { quickLinkDateRangeForCreationTimes } from "utils/quick-link";

export default function PublicCollectionGallery() {
    const { showMiniDialog, onGenericError } = useBaseContext();
    const { showLoadingBar, hideLoadingBar } = usePhotosAppContext();

    const [publicCollection, setPublicCollection] = useState<
        Collection | undefined
    >(undefined);
    const [publicFiles, setPublicFiles] = useState<EnteFile[] | undefined>(
        undefined,
    );
    const [errorMessage, setErrorMessage] = useState<string>("");
    const [loading, setLoading] = useState(true);
    const [isPasswordProtected, setIsPasswordProtected] = useState(false);
    const [uploadTypeSelectorView, setUploadTypeSelectorView] = useState(false);
    const [blockingLoad, setBlockingLoad] = useState(false);
    const [shouldDisableDropzone, setShouldDisableDropzone] = useState(false);
    const [dragAndDropFiles, setDragAndDropFiles] = useState<FileWithPath[]>(
        [],
    );
    const [selected, setSelected] = useState<SelectedState>({
        ownCount: 0,
        count: 0,
        collectionID: 0,
        context: undefined,
    });

    // TODO: Can we convert these to state
    const credentials = useRef<PublicAlbumsCredentials | undefined>(undefined);
    const collectionKey = useRef<string | undefined>(undefined);

    const isRedirectingToAlbumsAppRef = useRef<boolean>(false);

    const { saveGroups, onAddSaveGroup, onRemoveSaveGroup } = useSaveGroups();
    const { show: showPublicFeed, props: publicFeedVisibilityProps } =
        useModalVisibility();

    // Pending navigation from feed item click
    const [pendingFileNavigation, setPendingFileNavigation] = useState<{
        fileIndex: number;
        sidebar?: FileViewerInitialSidebar;
        commentID?: string;
    }>();

    /**
     * Handle clicks on feed items to navigate to the file and open sidebar.
     */
    const handleFeedItemClick = (info: PublicFeedItemClickInfo) => {
        if (!publicFiles) return;

        // Find the file index in publicFiles
        const fileIndex = publicFiles.findIndex((f) => f.id === info.fileID);
        if (fileIndex === -1) return;

        // Close the feed sidebar
        publicFeedVisibilityProps.onClose();

        // Determine which sidebar to open
        const sidebar: FileViewerInitialSidebar =
            info.type === "liked_photo" || info.type === "liked_video"
                ? "likes"
                : "comments";

        // Set navigation state
        setPendingFileNavigation({
            fileIndex,
            sidebar,
            commentID: info.commentID,
        });
    };

    const router = useRouter();

    const showPublicLinkExpiredMessage = () =>
        showMiniDialog({
            title: t("link_expired"),
            message: t("link_expired_message"),
            nonClosable: true,
            continue: {
                text: t("login"),
                action: async () => {
                    await router.push("/");
                },
            },
            cancel: false,
        });

    /**
     * Check if we need to redirect Trip albums from custom domains to albums.ente.io
     * Returns true if a redirect was initiated, false otherwise.
     * Reason: custom domains do not support the Trip layout fully
     */
    const checkAndRedirectForTripAlbum = (collection: Collection): boolean => {
        if (
            collection.pubMagicMetadata?.data.layout === "trip" &&
            shouldOnlyServeAlbumsApp
        ) {
            const currentURL = new URL(window.location.href);
            const albumsURL = new URL(albumsAppOrigin());

            if (currentURL.host !== albumsURL.host) {
                isRedirectingToAlbumsAppRef.current = true;

                albumsURL.search = currentURL.search;
                albumsURL.hash = currentURL.hash;

                window.location.href = albumsURL.href;
                return true;
            }
        }
        return false;
    };

    useEffect(() => {
        const currentURL = new URL(window.location.href);
        if (currentURL.pathname != "/") {
            router.replace(
                {
                    pathname: "/shared-albums",
                    search: currentURL.search,
                    hash: currentURL.hash,
                },
                {
                    pathname: "/",
                    search: currentURL.search,
                    hash: currentURL.hash,
                },
                { shallow: true },
            );
        }
        /**
         * Determine credentials, read the locally cached state, then start
         * pulling the latest from remote.
         */
        const main = async () => {
            let redirectingToWebsite = false;
            try {
                const currentURL = new URL(window.location.href);
                const t = currentURL.searchParams.get("t");
                const ck = await extractCollectionKeyFromShareURL(currentURL);
                if (!t && !ck) {
                    // Only redirect to ente.io if this is NOT a custom/self-hosted instance
                    if (!isCustomAlbumsAppOrigin) {
                        window.location.href = "https://ente.io";
                        redirectingToWebsite = true;
                    }
                }
                if (!t || !ck) {
                    return;
                }
                collectionKey.current = ck;
                const collection = await savedPublicCollectionByKey(ck);
                const accessToken = t;
                let accessTokenJWT: string | undefined;
                if (collection) {
                    setPublicCollection(collection);
                    setIsPasswordProtected(
                        !!collection.publicURLs[0]?.passwordEnabled,
                    );
                    setPublicFiles(
                        sortFilesForCollection(
                            await savedPublicCollectionFiles(accessToken),
                            collection,
                        ),
                    );
                    accessTokenJWT =
                        await savedPublicCollectionAccessTokenJWT(accessToken);
                }
                credentials.current = { accessToken, accessTokenJWT };
                downloadManager.setPublicAlbumsCredentials(credentials.current);
                // Update the CF proxy flag, but we don't need to block on it.
                void updateShouldDisableCFUploadProxy();
                await publicAlbumsRemotePull();
            } finally {
                if (
                    !redirectingToWebsite &&
                    !isRedirectingToAlbumsAppRef.current
                ) {
                    setLoading(false);
                }
            }
        };
        main();
        // TODO:
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    const downloadEnabled =
        publicCollection?.publicURLs[0]?.enableDownload ?? true;

    /**
     * Pull the latest data related to the public album from remote, updating
     * both our local database and component state.
     */
    const publicAlbumsRemotePull = useCallback(async () => {
        const accessToken = credentials.current!.accessToken;
        showLoadingBar();
        setLoading(true);
        try {
            const { collection } = await pullCollection(
                accessToken,
                collectionKey.current!,
            );

            if (checkAndRedirectForTripAlbum(collection)) {
                return;
            }

            setPublicCollection(collection);
            const isPasswordProtected =
                !!collection.publicURLs[0]?.passwordEnabled;
            setIsPasswordProtected(isPasswordProtected);
            setErrorMessage("");

            // Remove the locally cached accessTokenJWT if the sharer has
            // disabled password protection on the link.
            if (!isPasswordProtected && credentials.current?.accessTokenJWT) {
                credentials.current.accessTokenJWT = undefined;
                downloadManager.setPublicAlbumsCredentials(credentials.current);
                removePublicCollectionAccessTokenJWT(accessToken);
            }

            if (isPasswordProtected && !credentials.current?.accessTokenJWT) {
                await removePublicCollectionFileData(accessToken);
            } else {
                try {
                    await pullPublicCollectionFiles(
                        credentials.current!,
                        collection,
                        (files) =>
                            setPublicFiles(
                                sortFilesForCollection(files, collection),
                            ),
                    );
                } catch (e) {
                    // If we reached the try block and attempted to pull files,
                    // it means the accessToken itself is very likely valid
                    // (since the `pullCollection` succeeded just a moment ago).
                    //
                    // So a 401 Unauthorized now indicates that the
                    // accessTokenJWT is no longer valid since the sharer has
                    // changed the password.
                    //
                    // Clear the locally cached accessTokenJWT and ask the user
                    // to reenter the password.
                    if (isHTTP401Error(e)) {
                        credentials.current!.accessTokenJWT = undefined;
                        downloadManager.setPublicAlbumsCredentials(
                            credentials.current,
                        );
                    } else {
                        throw e;
                    }
                }
            }
        } catch (e) {
            // The 410 Gone or 429 Rate limited can arise from either the
            // collection pull or the files pull since they're part of the
            // remote's access token check sequence.
            //
            // In practice, it almost always will be a consequence of the
            // collection pull since it happens first.
            //
            // The 401 Unauthorized can only arise from the collection pull
            // since we already handle that separately for the files pull.
            if (
                isHTTPErrorWithStatus(e, 401) ||
                isHTTPErrorWithStatus(e, 410) ||
                isHTTPErrorWithStatus(e, 429)
            ) {
                setErrorMessage(
                    isHTTPErrorWithStatus(e, 429)
                        ? t("link_request_limit_exceeded")
                        : t("link_expired_message"),
                );
                // Sharing has been disabled. Clear out local cache.
                await removePublicCollectionFileData(accessToken);
                await removePublicCollectionByKey(collectionKey.current!);
                setPublicCollection(undefined);
                setPublicFiles(undefined);
            } else {
                log.error("Public album remote pull failed", e);
                // Don't use the `setErrorMessage`, show a dialog instead,
                // because this might be a transient network error.
                onGenericError(e);
            }
        } finally {
            hideLoadingBar();
            if (!isRedirectingToAlbumsAppRef.current) {
                setLoading(false);
            }
        }
    }, [showLoadingBar, hideLoadingBar, onGenericError]);

    // See: [Note: Visual feedback to acknowledge user actions]
    const handleVisualFeedback = useCallback(() => {
        showLoadingBar();
        setTimeout(hideLoadingBar, 0);
    }, [showLoadingBar, hideLoadingBar]);

    // Join album handler for use in file viewer's public like modal
    const { handleJoinAlbum } = useJoinAlbum({
        publicCollection,
        accessToken: credentials.current?.accessToken,
        collectionKey: collectionKey.current,
        credentials,
    });

    const handleSubmitPassword: SingleInputFormProps["onSubmit"] = async (
        password,
        setFieldError,
    ) => {
        try {
            const accessToken = credentials.current!.accessToken;
            const accessTokenJWT = await verifyPublicAlbumPassword(
                publicCollection!.publicURLs[0]!,
                password,
                accessToken,
            );
            credentials.current!.accessTokenJWT = accessTokenJWT;
            downloadManager.setPublicAlbumsCredentials(credentials.current);
            await savePublicCollectionAccessTokenJWT(
                accessToken,
                accessTokenJWT,
            );
        } catch (e) {
            log.error("Failed to verifyLinkPassword", e);
            if (isHTTP401Error(e)) {
                setFieldError(t("incorrect_password"));
                return;
            }
            throw e;
        }

        await publicAlbumsRemotePull();
    };

    const clearSelection = () => {
        if (!selected.count) {
            return;
        }
        setSelected({
            ownCount: 0,
            count: 0,
            collectionID: 0,
            context: undefined,
        });
    };

    const handleUploadFile = (file: EnteFile) =>
        setPublicFiles(
            sortFilesForCollection([...publicFiles!, file], publicCollection),
        );

    const downloadFilesHelper = async () => {
        try {
            const selectedFiles = getSelectedFiles(selected, publicFiles!);
            const singleFile =
                selectedFiles.length === 1 ? selectedFiles[0] : undefined;
            const title =
                singleFile?.metadata.fileType === FileType.livePhoto
                    ? fileFileName(singleFile)
                    : t("files_count", { count: selectedFiles.length });
            await downloadAndSaveFiles(selectedFiles, title, onAddSaveGroup);
            clearSelection();
        } catch (e) {
            log.error("failed to download selected files", e);
        }
    };

    const onAddPhotos = useMemo(() => {
        return publicCollection?.publicURLs[0]?.enableCollect
            ? () => setUploadTypeSelectorView(true)
            : undefined;
    }, [publicCollection]);

    const closeUploadTypeSelectorView = () => {
        setUploadTypeSelectorView(false);
    };

    const commentsEnabled =
        publicCollection?.publicURLs[0]?.enableComment ?? false;
    const joinEnabled = publicCollection?.publicURLs[0]?.enableJoin ?? false;
    const addPhotosEnabled = !!onAddPhotos;

    const hasSelection = selected.count > 0;
    const isMobileHeaderLayout = useMediaQuery("(width < 720px)");
    const fileListHeaderHeightForViewport = isMobileHeaderLayout
        ? fileListHeaderHeightMobile
        : fileListHeaderHeight;

    const fileListHeader = useMemo<FileListHeaderOrFooter | undefined>(
        () =>
            publicCollection && publicFiles
                ? {
                      component: (
                          <FileListHeader
                              {...{
                                  publicCollection,
                                  publicFiles,
                                  downloadEnabled,
                                  onAddSaveGroup,
                                  onAddPhotos,
                                  onShowFeed: commentsEnabled
                                      ? showPublicFeed
                                      : undefined,
                                  hasSelection,
                              }}
                          />
                      ),
                      height: fileListHeaderHeightForViewport,
                  }
                : undefined,
        [
            onAddSaveGroup,
            publicCollection,
            publicFiles,
            downloadEnabled,
            showPublicFeed,
            commentsEnabled,
            onAddPhotos,
            hasSelection,
            fileListHeaderHeightForViewport,
        ],
    );

    const fileListFooter = useMemo<FileListHeaderOrFooter>(
        () => ({
            component: <FileListFooter />,
            height: fileListFooterHeight,
            extendToInlineEdges: true,
        }),
        [],
    );

    if (loading && (!publicFiles || !credentials.current)) {
        return <LoadingIndicator />;
    } else if (errorMessage) {
        return (
            <Stack100vhCenter>
                <Typography sx={{ color: "critical.main" }}>
                    {errorMessage}
                </Typography>
            </Stack100vhCenter>
        );
    } else if (isPasswordProtected && !credentials.current?.accessTokenJWT) {
        return (
            <AccountsPageContents>
                <AccountsPageTitle>{t("password")}</AccountsPageTitle>
                <Stack>
                    <Typography
                        variant="small"
                        sx={{ color: "text.muted", mb: 2 }}
                    >
                        {t("link_password_description")}
                    </Typography>
                    <SingleInputForm
                        inputType="password"
                        label={t("password")}
                        submitButtonColor="primary"
                        submitButtonTitle={t("unlock")}
                        onSubmit={handleSubmitPassword}
                    />
                </Stack>
            </AccountsPageContents>
        );
    } else if (!publicFiles || !credentials.current) {
        return (
            <Stack100vhCenter>
                <Typography>{t("not_found")}</Typography>
            </Stack100vhCenter>
        );
    }

    const layout = publicCollection?.pubMagicMetadata?.data.layout || "grouped";

    return (
        <FullScreenDropZone
            disabled={shouldDisableDropzone}
            onDrop={setDragAndDropFiles}
            message={t("upload_dropzone_hint_public_album")}
        >
            {layout === "trip" ? (
                <TripLayout
                    files={publicFiles}
                    collection={publicCollection}
                    onAddPhotos={onAddPhotos}
                    enableDownload={downloadEnabled}
                    accessToken={credentials.current.accessToken}
                    collectionKey={collectionKey.current}
                    credentials={credentials}
                    enableComment={commentsEnabled}
                    enableJoin={publicCollection?.publicURLs[0]?.enableJoin}
                />
            ) : (
                <>
                    <NavbarBase
                        sx={[
                            {
                                flex: "0 0 60px",
                                px: "24px",
                                "@media (width < 720px)": { px: "4px" },
                            },
                            selected.count > 0 && {
                                borderColor: "accent.main",
                                overflowX: "hidden",
                            },
                        ]}
                    >
                        {selected.count > 0 ? (
                            <SelectedFileOptions
                                count={selected.count}
                                clearSelection={clearSelection}
                                downloadFilesHelper={downloadFilesHelper}
                            />
                        ) : (
                            <SpacedRow sx={{ flex: 1 }}>
                                <EnteLogoLink href="https://ente.io">
                                    <EnteLogo height={15} />
                                </EnteLogoLink>
                                <Stack direction="row" spacing={2}>
                                    <SecondaryActionButton
                                        onAddPhotos={onAddPhotos}
                                        enableJoin={joinEnabled}
                                        publicCollection={publicCollection}
                                        accessToken={
                                            credentials.current.accessToken
                                        }
                                        collectionKey={collectionKey.current}
                                        credentials={credentials}
                                    />
                                    <PrimaryActionButton
                                        showJoinAsPrimary={
                                            addPhotosEnabled && joinEnabled
                                        }
                                        publicCollection={publicCollection}
                                        accessToken={
                                            credentials.current.accessToken
                                        }
                                        collectionKey={collectionKey.current}
                                        credentials={credentials}
                                    />
                                </Stack>
                            </SpacedRow>
                        )}
                    </NavbarBase>
                    <FileListWithViewer
                        files={publicFiles}
                        header={fileListHeader}
                        footer={fileListFooter}
                        enableDownload={downloadEnabled}
                        enableSelect={downloadEnabled}
                        selected={selected}
                        setSelected={setSelected}
                        activeCollectionID={PseudoCollectionID.all}
                        disableGrouping={layout === "continuous"}
                        onRemotePull={publicAlbumsRemotePull}
                        onVisualFeedback={handleVisualFeedback}
                        onAddSaveGroup={onAddSaveGroup}
                        publicAlbumsCredentials={credentials.current}
                        collectionKey={collectionKey.current}
                        onJoinAlbum={handleJoinAlbum}
                        enableComment={commentsEnabled}
                        enableJoin={publicCollection?.publicURLs[0]?.enableJoin}
                        pendingFileIndex={pendingFileNavigation?.fileIndex}
                        pendingFileSidebar={pendingFileNavigation?.sidebar}
                        pendingHighlightCommentID={
                            pendingFileNavigation?.commentID
                        }
                        onPendingNavigationConsumed={() =>
                            setPendingFileNavigation(undefined)
                        }
                    />
                </>
            )}
            {blockingLoad && <TranslucentLoadingOverlay />}
            <Upload
                publicAlbumsCredentials={credentials.current}
                uploadCollection={publicCollection}
                setLoading={setBlockingLoad}
                setShouldDisableDropzone={setShouldDisableDropzone}
                uploadTypeSelectorIntent="collect"
                uploadTypeSelectorView={uploadTypeSelectorView}
                onRemotePull={publicAlbumsRemotePull}
                onUploadFile={handleUploadFile}
                closeUploadTypeSelector={closeUploadTypeSelectorView}
                onShowSessionExpiredDialog={showPublicLinkExpiredMessage}
                {...{ dragAndDropFiles }}
            />
            <DownloadStatusNotifications
                {...{ saveGroups, onRemoveSaveGroup }}
                fullWidthOnMobile
            />
            {publicCollection && collectionKey.current && (
                <PublicFeedSidebar
                    {...publicFeedVisibilityProps}
                    files={publicFiles}
                    credentials={credentials.current}
                    collectionKey={collectionKey.current}
                    onItemClick={handleFeedItemClick}
                />
            )}
        </FullScreenDropZone>
    );
}

/**
 * Sort the given {@link files} using {@link sortFiles}, using the ascending
 * ordering preference if specified in the given {@link collection}'s metadata.
 */
const sortFilesForCollection = (files: EnteFile[], collection?: Collection) =>
    sortFiles(files, collection?.pubMagicMetadata?.data.asc ?? false);

const EnteLogoLink = styled("a")(({ theme }) => ({
    // Remove the excess space at the top.
    svg: { verticalAlign: "middle" },
    color: theme.vars.palette.text.base,
    ":hover": { color: theme.vars.palette.accent.main },
}));

const GreenButton = styled(Button)(() => ({
    backgroundColor: "#08C225",
    borderRadius: "16px",
    paddingBlock: "11px",
    paddingInline: "20px",
    "&:hover": { backgroundColor: "#07A820" },
}));

const navbarActionButtonSx = { borderRadius: "16px", paddingBlock: "11px" };

const AddPhotosButton: React.FC<ButtonishProps> = ({ onClick }) => {
    const disabled = uploadManager.isUploadInProgress();
    const isSmallWidth = useIsSmallWidth();

    return (
        <FocusVisibleButton
            color="secondary"
            startIcon={
                isSmallWidth ? undefined : (
                    <HugeiconsIcon
                        icon={ImageAdd02Icon}
                        size={20}
                        strokeWidth={1.8}
                    />
                )
            }
            sx={navbarActionButtonSx}
            {...{ onClick, disabled }}
        >
            {t("add_photos")}
        </FocusVisibleButton>
    );
};

interface PrimaryActionButtonProps {
    /** If true, shows "Join Album" as the primary action */
    showJoinAsPrimary?: boolean;
    /** Collection to join (required if showJoinAsPrimary is true) */
    publicCollection?: Collection;
    /** Access token for the public link */
    accessToken?: string;
    /** Collection key from URL (base64 encoded) */
    collectionKey?: string;
    /** Credentials ref for JWT token access */
    credentials?: React.RefObject<PublicAlbumsCredentials | undefined>;
}

const PrimaryActionButton: React.FC<PrimaryActionButtonProps> = ({
    showJoinAsPrimary,
    publicCollection,
    accessToken,
    collectionKey,
    credentials,
}) => {
    const { handleJoinAlbum } = useJoinAlbum({
        publicCollection,
        accessToken,
        collectionKey,
        credentials,
    });

    if (showJoinAsPrimary) {
        return (
            <GreenButton color="accent" onClick={handleJoinAlbum}>
                {t("join_album")}
            </GreenButton>
        );
    }

    const handleGetEnte = () => {
        window.location.href = getEnteURL();
    };

    return (
        <GreenButton color="accent" onClick={handleGetEnte}>
            {t("try_ente")}
        </GreenButton>
    );
};

interface SecondaryActionButtonProps {
    onAddPhotos?: () => void;
    enableJoin?: boolean;
    publicCollection?: Collection;
    accessToken?: string;
    collectionKey?: string;
    credentials?: React.RefObject<PublicAlbumsCredentials | undefined>;
}

const SecondaryActionButton: React.FC<SecondaryActionButtonProps> = ({
    onAddPhotos,
    enableJoin,
    publicCollection,
    accessToken,
    collectionKey,
    credentials,
}) => {
    const { handleJoinAlbum } = useJoinAlbum({
        publicCollection,
        accessToken,
        collectionKey,
        credentials,
    });

    if (onAddPhotos) {
        return <AddPhotosButton onClick={onAddPhotos} />;
    }

    if (enableJoin) {
        return (
            <FocusVisibleButton
                color="secondary"
                sx={navbarActionButtonSx}
                onClick={handleJoinAlbum}
            >
                {t("join_album")}
            </FocusVisibleButton>
        );
    }

    return null;
};

interface SelectedFileOptionsProps {
    count: number;
    clearSelection: () => void;
    downloadFilesHelper: () => void;
}

const SelectedFileOptions: React.FC<SelectedFileOptionsProps> = ({
    count,
    clearSelection,
    downloadFilesHelper,
}) => (
    <Stack
        direction="row"
        sx={{
            flex: 1,
            minWidth: 0,
            gap: 1,
            alignItems: "center",
            width: "100%",
        }}
    >
        <IconButton
            onClick={clearSelection}
            sx={{ flexShrink: 0, ml: "-15px" }}
        >
            <CloseIcon />
        </IconButton>
        <Typography
            sx={{
                mr: "auto",
                minWidth: 0,
                overflow: "hidden",
                textOverflow: "ellipsis",
                whiteSpace: "nowrap",
            }}
        >
            {t("selected_count", { selected: count })}
        </Typography>
        <Tooltip title={t("download")}>
            <IconButton
                onClick={downloadFilesHelper}
                sx={{ flexShrink: 0, mr: "-15px" }}
            >
                <HugeiconsIcon icon={Download01Icon} strokeWidth={1.6} />
            </IconButton>
        </Tooltip>
    </Stack>
);

interface FileListHeaderProps {
    publicCollection: Collection;
    publicFiles: EnteFile[];
    downloadEnabled: boolean;
    onAddSaveGroup: AddSaveGroup;
    onAddPhotos?: () => void;
    onShowFeed?: () => void;
    hasSelection: boolean;
}

/**
 * The fixed height (in px) of {@link FileListHeader}.
 */
const fileListHeaderHeight = 84;

/**
 * The height (in px) of {@link FileListHeader} on mobile.
 *
 * Keep this fixed so the virtualized list has a stable header row height.
 */
const fileListHeaderHeightMobile = 132;

/**
 * A header shown before the listing of files.
 *
 * It scrolls along with the content. It has a fixed height,
 * {@link fileListHeaderHeight}.
 */
const FileListHeader: React.FC<FileListHeaderProps> = ({
    publicCollection,
    publicFiles,
    downloadEnabled,
    onAddSaveGroup,
    onAddPhotos,
    onShowFeed,
    hasSelection,
}) => {
    const [showCopiedMessage, setShowCopiedMessage] = useState(false);
    const addPhotosDisabled = uploadManager.isUploadInProgress();

    const memoriesDateRange = useMemo(() => {
        if (!publicFiles.length) return undefined;

        // publicFiles is already creation-time sorted, so the ends hold min/max.
        const firstCreationTime = fileCreationTime(publicFiles[0]!);
        const lastCreationTime = fileCreationTime(
            publicFiles[publicFiles.length - 1]!,
        );

        return quickLinkDateRangeForCreationTimes(
            Math.min(firstCreationTime, lastCreationTime),
            Math.max(firstCreationTime, lastCreationTime),
        );
    }, [publicFiles]);

    const downloadAllFiles = () =>
        downloadAndSaveCollectionFiles(
            publicCollection.name,
            publicCollection.id,
            publicFiles,
            undefined,
            onAddSaveGroup,
        );

    const handleShare = async () => {
        if (typeof window === "undefined") return;

        const shareUrl = window.location.href;
        const shareText = `${publicCollection.name}\n${shareUrl}`;
        const isMobile = window.matchMedia("(width < 720px)").matches;

        if (isMobile && typeof navigator.share === "function") {
            try {
                await navigator.share({ text: shareText });
                return;
            } catch (error) {
                if (error instanceof Error && error.name === "AbortError") {
                    return;
                }
            }
        }

        void navigator.clipboard.writeText(isMobile ? shareText : shareUrl);
        setShowCopiedMessage(true);
        setTimeout(() => setShowCopiedMessage(false), 2000);
    };

    return (
        <>
            <GalleryItemsHeaderAdapter sx={{ pt: "16px" }}>
                <SpacedRow
                    sx={{
                        width: "100%",
                        "@media (width < 720px)": {
                            flexDirection: "column",
                            alignItems: "flex-start",
                            gap: 1,
                        },
                    }}
                >
                    <Box
                        sx={{
                            minWidth: 0,
                            flex: 1,
                            "@media (width < 720px)": { width: "100%" },
                        }}
                    >
                        <GalleryItemsSummary
                            name={publicCollection.name}
                            fileCount={publicFiles.length}
                            endIcon={
                                memoriesDateRange ? (
                                    <Typography
                                        variant="small"
                                        sx={{ color: "text.muted", ml: "-6px" }}
                                    >
                                        <Box
                                            component="span"
                                            sx={{ mr: "6px" }}
                                        >
                                            {"\u00b7"}
                                        </Box>
                                        {memoriesDateRange}
                                    </Typography>
                                ) : undefined
                            }
                            nameProps={{
                                noWrap: true,
                                sx: { width: "100%", maxWidth: "100%" },
                            }}
                        />
                    </Box>
                    <Stack
                        direction="row"
                        spacing={0}
                        sx={{
                            alignItems: "center",
                            "@media (width > 720px)": { mr: -1.5 },
                            "@media (width < 720px)": { ml: -1.5 },
                        }}
                    >
                        {onShowFeed && (
                            <IconButton
                                onClick={onShowFeed}
                                disabled={hasSelection}
                            >
                                <Box
                                    sx={{
                                        width: 24,
                                        height: 24,
                                        display: "flex",
                                        alignItems: "center",
                                        justifyContent: "center",
                                    }}
                                >
                                    <FeedIcon />
                                </Box>
                            </IconButton>
                        )}
                        {downloadEnabled && (
                            <IconButton
                                onClick={downloadAllFiles}
                                disabled={hasSelection}
                            >
                                <HugeiconsIcon
                                    icon={Download01Icon}
                                    strokeWidth={1.6}
                                />
                            </IconButton>
                        )}
                        {onAddPhotos && (
                            <IconButton
                                onClick={onAddPhotos}
                                disabled={addPhotosDisabled || hasSelection}
                            >
                                <HugeiconsIcon
                                    icon={ImageAdd02Icon}
                                    strokeWidth={1.8}
                                />
                            </IconButton>
                        )}
                        <IconButton
                            onClick={handleShare}
                            disabled={hasSelection}
                        >
                            <HugeiconsIcon
                                icon={Share08Icon}
                                strokeWidth={1.6}
                            />
                        </IconButton>
                    </Stack>
                </SpacedRow>
            </GalleryItemsHeaderAdapter>
            <Notification
                open={showCopiedMessage}
                onClose={() => setShowCopiedMessage(false)}
                horizontal="left"
                attributes={{
                    color: "secondary",
                    startIcon: <CheckIcon />,
                    title: "Copied!",
                }}
            />
        </>
    );
};

/**
 * The fixed height (in px) of {@link FileListFooter}.
 */
const fileListFooterHeight = 24;

/**
 * A footer shown after the listing of files.
 *
 * It scrolls along with the content. It has a fixed height,
 * {@link fileListFooterHeight}.
 */
const FileListFooter: React.FC = () => (
    <Box sx={{ height: fileListFooterHeight }} />
);

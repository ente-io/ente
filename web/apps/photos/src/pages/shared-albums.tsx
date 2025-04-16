import AddPhotoAlternateOutlinedIcon from "@mui/icons-material/AddPhotoAlternateOutlined";
import CloseIcon from "@mui/icons-material/Close";
import DownloadIcon from "@mui/icons-material/Download";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import { Box, Button, IconButton, Stack, styled, Tooltip } from "@mui/material";
import Typography from "@mui/material/Typography";
import { TimeStampListItem } from "components/FileList";
import { FileListWithViewer } from "components/FileListWithViewer";
import {
    FilesDownloadProgress,
    FilesDownloadProgressAttributes,
} from "components/FilesDownloadProgress";
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
    OverflowMenu,
    OverflowMenuOption,
} from "ente-base/components/OverflowMenu";
import {
    useIsSmallWidth,
    useIsTouchscreen,
} from "ente-base/components/utils/hooks";
import { useBaseContext } from "ente-base/context";
import { isHTTP401Error, PublicAlbumsCredentials } from "ente-base/http";
import log from "ente-base/log";
import { FullScreenDropZone } from "ente-gallery/components/FullScreenDropZone";
import { downloadManager } from "ente-gallery/services/download";
import { extractCollectionKeyFromShareURL } from "ente-gallery/services/share";
import { updateShouldDisableCFUploadProxy } from "ente-gallery/services/upload";
import type { Collection } from "ente-media/collection";
import { mergeMetadata, type EnteFile } from "ente-media/file";
import { verifyPublicAlbumPassword } from "ente-new/albums/services/publicCollection";
import {
    GalleryItemsHeaderAdapter,
    GalleryItemsSummary,
} from "ente-new/photos/components/gallery/ListHeader";
import {
    ALL_SECTION,
    isHiddenCollection,
} from "ente-new/photos/services/collection";
import { sortFiles } from "ente-new/photos/services/files";
import { usePhotosAppContext } from "ente-new/photos/types/context";
import { CenteredFlex } from "ente-shared/components/Container";
import SingleInputForm, {
    type SingleInputFormProps,
} from "ente-shared/components/SingleInputForm";
import { CustomError, parseSharingErrorCodes } from "ente-shared/error";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { type FileWithPath } from "react-dropzone";
import {
    getLocalPublicCollection,
    getLocalPublicCollectionPassword,
    getLocalPublicFiles,
    getPublicCollection,
    getPublicCollectionUID,
    getReferralCode,
    removePublicCollectionWithFiles,
    removePublicFiles,
    savePublicCollectionPassword,
    syncPublicFiles,
} from "services/publicCollectionService";
import uploadManager from "services/upload/uploadManager";
import {
    SelectedState,
    SetFilesDownloadProgressAttributes,
    SetFilesDownloadProgressAttributesCreator,
} from "types/gallery";
import { downloadCollectionFiles } from "utils/collection";
import { downloadSelectedFiles, getSelectedFiles } from "utils/file";
import { PublicCollectionGalleryContext } from "utils/publicCollectionGallery";

export default function PublicCollectionGallery() {
    const credentials = useRef<PublicAlbumsCredentials | undefined>(undefined);
    const collectionKey = useRef<string>(null);
    const url = useRef<string>(null);
    const referralCode = useRef<string>("");
    const [publicFiles, setPublicFiles] = useState<EnteFile[]>(null);
    const [publicCollection, setPublicCollection] = useState<Collection>(null);
    const [errorMessage, setErrorMessage] = useState<string>(null);
    const { showMiniDialog } = useBaseContext();
    const { showLoadingBar, hideLoadingBar } = usePhotosAppContext();
    const [loading, setLoading] = useState(true);
    const router = useRouter();
    const [isPasswordProtected, setIsPasswordProtected] =
        useState<boolean>(false);

    const [photoListHeader, setPhotoListHeader] =
        useState<TimeStampListItem>(null);

    const [photoListFooter, setPhotoListFooter] =
        useState<TimeStampListItem>(null);

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

    const [
        filesDownloadProgressAttributesList,
        setFilesDownloadProgressAttributesList,
    ] = useState<FilesDownloadProgressAttributes[]>([]);

    const setFilesDownloadProgressAttributesCreator: SetFilesDownloadProgressAttributesCreator =
        useCallback((folderName, collectionID, isHidden) => {
            const id = Math.random();
            const updater: SetFilesDownloadProgressAttributes = (value) => {
                setFilesDownloadProgressAttributesList((prev) => {
                    const attributes = prev?.find((attr) => attr.id === id);
                    const updatedAttributes =
                        typeof value == "function"
                            ? value(attributes)
                            : { ...attributes, ...value };
                    const updatedAttributesList = attributes
                        ? prev.map((attr) =>
                              attr.id === id ? updatedAttributes : attr,
                          )
                        : [...prev, updatedAttributes];

                    return updatedAttributesList;
                });
            };
            updater({
                id,
                folderName,
                collectionID,
                isHidden,
                canceller: null,
                total: 0,
                success: 0,
                failed: 0,
                downloadDirPath: null,
            });
            return updater;
        }, []);

    const onAddPhotos = useMemo(() => {
        return publicCollection?.publicURLs?.[0]?.enableCollect
            ? () => setUploadTypeSelectorView(true)
            : undefined;
    }, [publicCollection]);

    const closeUploadTypeSelectorView = () => {
        setUploadTypeSelectorView(false);
    };

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
        const main = async () => {
            let redirectingToWebsite = false;
            try {
                url.current = window.location.href;
                const currentURL = new URL(url.current);
                const t = currentURL.searchParams.get("t");
                const ck = await extractCollectionKeyFromShareURL(currentURL);
                if (!t && !ck) {
                    window.location.href = "https://ente.io";
                    redirectingToWebsite = true;
                }
                if (!t || !ck) {
                    return;
                }
                collectionKey.current = ck;
                url.current = window.location.href;
                const localCollection = await getLocalPublicCollection(
                    collectionKey.current,
                );
                const accessToken = t;
                let accessTokenJWT: string | undefined;
                if (localCollection) {
                    referralCode.current = await getReferralCode();
                    const sortAsc: boolean =
                        localCollection?.pubMagicMetadata?.data.asc ?? false;
                    setPublicCollection(localCollection);
                    const isPasswordProtected =
                        localCollection?.publicURLs?.[0]?.passwordEnabled;
                    setIsPasswordProtected(isPasswordProtected);
                    const collectionUID = getPublicCollectionUID(accessToken);
                    const localFiles = await getLocalPublicFiles(collectionUID);
                    const localPublicFiles = sortFiles(
                        mergeMetadata(localFiles),
                        sortAsc,
                    );
                    setPublicFiles(localPublicFiles);
                    accessTokenJWT =
                        await getLocalPublicCollectionPassword(collectionUID);
                }
                credentials.current = { accessToken, accessTokenJWT };
                downloadManager.setPublicAlbumsCredentials(credentials.current);
                // Update the CF proxy flag, but we don't need to block on it.
                void updateShouldDisableCFUploadProxy();
                await syncWithRemote();
            } finally {
                if (!redirectingToWebsite) {
                    setLoading(false);
                }
            }
        };
        main();
    }, []);

    const downloadEnabled =
        publicCollection?.publicURLs?.[0]?.enableDownload ?? true;

    useEffect(() => {
        publicCollection &&
            publicFiles &&
            setPhotoListHeader({
                item: (
                    <ListHeader
                        {...{
                            publicCollection,
                            publicFiles,
                            setFilesDownloadProgressAttributesCreator,
                        }}
                    />
                ),
                tag: "header",
                height: 68,
            });
    }, [publicCollection, publicFiles]);

    useEffect(() => {
        setPhotoListFooter(
            onAddPhotos
                ? {
                      item: (
                          <CenteredFlex sx={{ marginTop: "56px" }}>
                              <AddMorePhotosButton onClick={onAddPhotos} />
                          </CenteredFlex>
                      ),
                      height: 104,
                  }
                : null,
        );
    }, [onAddPhotos]);

    const handleSyncWithRemote = useCallback(async () => {
        const collectionUID = getPublicCollectionUID(
            credentials.current.accessToken,
        );
        try {
            showLoadingBar();
            setLoading(true);
            const [collection, userReferralCode] = await getPublicCollection(
                credentials.current.accessToken,
                collectionKey.current,
            );
            referralCode.current = userReferralCode;

            setPublicCollection(collection);
            const isPasswordProtected =
                collection?.publicURLs?.[0]?.passwordEnabled;
            setIsPasswordProtected(isPasswordProtected);
            setErrorMessage(null);

            // Remove the locally saved outdated password token if the sharer
            // has disabled password protection on the link.
            if (!isPasswordProtected && credentials.current.accessTokenJWT) {
                credentials.current.accessTokenJWT = undefined;
                downloadManager.setPublicAlbumsCredentials(credentials.current);
                savePublicCollectionPassword(collectionUID, null);
            }

            if (
                !isPasswordProtected ||
                (isPasswordProtected && credentials.current.accessTokenJWT)
            ) {
                try {
                    await syncPublicFiles(
                        credentials.current.accessToken,
                        credentials.current.accessTokenJWT,
                        collection,
                        setPublicFiles,
                    );
                } catch (e) {
                    const parsedError = parseSharingErrorCodes(e);
                    if (parsedError.message === CustomError.TOKEN_EXPIRED) {
                        // passwordToken has expired, sharer has changed the password,
                        // so,clearing local cache token value to prompt user to re-enter password
                        credentials.current.accessTokenJWT = undefined;
                        downloadManager.setPublicAlbumsCredentials(
                            credentials.current,
                        );
                    }
                }
            }

            if (isPasswordProtected && !credentials.current.accessTokenJWT) {
                await removePublicFiles(collectionUID);
            }
        } catch (e) {
            const parsedError = parseSharingErrorCodes(e);
            if (
                parsedError.message === CustomError.TOKEN_EXPIRED ||
                parsedError.message === CustomError.TOO_MANY_REQUESTS
            ) {
                setErrorMessage(
                    parsedError.message === CustomError.TOO_MANY_REQUESTS
                        ? t("link_request_limit_exceeded")
                        : t("link_expired_message"),
                );
                // share has been disabled
                // local cache should be cleared
                removePublicCollectionWithFiles(
                    collectionUID,
                    collectionKey.current,
                );
                setPublicCollection(null);
                setPublicFiles(null);
            } else {
                log.error("failed to sync public album with remote", e);
            }
        } finally {
            hideLoadingBar();
            setLoading(false);
        }
    }, [showLoadingBar, hideLoadingBar]);

    // TODO: See gallery
    const syncWithRemote = handleSyncWithRemote;

    // See: [Note: Visual feedback to acknowledge user actions]
    const handleVisualFeedback = useCallback(() => {
        showLoadingBar();
        setTimeout(hideLoadingBar, 0);
    }, [showLoadingBar, hideLoadingBar]);

    const verifyLinkPassword: SingleInputFormProps["callback"] = async (
        password,
        setFieldError,
    ) => {
        try {
            const accessTokenJWT = await verifyPublicAlbumPassword(
                publicCollection.publicURLs[0]!,
                password,
                credentials.current.accessToken,
            );
            credentials.current.accessTokenJWT = accessTokenJWT;
            downloadManager.setPublicAlbumsCredentials(credentials.current);
            const collectionUID = getPublicCollectionUID(
                credentials.current.accessToken,
            );
            await savePublicCollectionPassword(collectionUID, accessTokenJWT);
        } catch (e) {
            log.error("Failed to verifyLinkPassword", e);
            if (isHTTP401Error(e)) {
                setFieldError(t("incorrect_password"));
            } else {
                setFieldError(t("generic_error_retry"));
            }
            return;
        }

        await syncWithRemote();
    };

    const clearSelection = () => {
        if (!selected?.count) {
            return;
        }
        setSelected({
            ownCount: 0,
            count: 0,
            collectionID: 0,
            context: undefined,
        });
    };

    const downloadFilesHelper = async () => {
        try {
            const selectedFiles = getSelectedFiles(selected, publicFiles);
            const setFilesDownloadProgressAttributes =
                setFilesDownloadProgressAttributesCreator(
                    t("files_count", { count: selectedFiles.length }),
                );
            await downloadSelectedFiles(
                selectedFiles,
                setFilesDownloadProgressAttributes,
            );
            clearSelection();
        } catch (e) {
            log.error("failed to download selected files", e);
        }
    };

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
    } else if (isPasswordProtected && !credentials.current.accessTokenJWT) {
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
                        callback={verifyLinkPassword}
                        placeholder={t("password")}
                        buttonText={t("unlock")}
                        fieldType="password"
                    />
                </Stack>
            </AccountsPageContents>
        );
    } else if (!publicFiles || !credentials.current) {
        return (
            <Stack100vhCenter>
                <Typography>{t("NOT_FOUND")}</Typography>
            </Stack100vhCenter>
        );
    }

    // TODO: memo this (after the dependencies are traceable).
    const context = {
        credentials: credentials.current,
        referralCode: referralCode.current,
        photoListHeader,
        photoListFooter,
    };

    return (
        <PublicCollectionGalleryContext.Provider value={context}>
            <FullScreenDropZone
                disabled={shouldDisableDropzone}
                onDrop={setDragAndDropFiles}
            >
                <NavbarBase
                    sx={{
                        mb: "16px",
                        px: "24px",
                        "@media (width < 720px)": { px: "4px" },
                    }}
                >
                    {selected.count > 0 ? (
                        <SelectedFileOptions
                            downloadFilesHelper={downloadFilesHelper}
                            clearSelection={clearSelection}
                            count={selected.count}
                        />
                    ) : (
                        <SpacedRow sx={{ flex: 1 }}>
                            <EnteLogoLink href="https://ente.io">
                                <EnteLogo height={15} />
                            </EnteLogoLink>
                            {onAddPhotos ? (
                                <AddPhotosButton onClick={onAddPhotos} />
                            ) : (
                                <GoToEnte />
                            )}
                        </SpacedRow>
                    )}
                </NavbarBase>

                <FileListWithViewer
                    files={publicFiles}
                    enableDownload={downloadEnabled}
                    selectable={downloadEnabled}
                    selected={selected}
                    setSelected={setSelected}
                    activeCollectionID={ALL_SECTION}
                    setFilesDownloadProgressAttributesCreator={
                        setFilesDownloadProgressAttributesCreator
                    }
                    onSyncWithRemote={handleSyncWithRemote}
                    onVisualFeedback={handleVisualFeedback}
                />
                {blockingLoad && <TranslucentLoadingOverlay />}
                <Upload
                    syncWithRemote={syncWithRemote}
                    uploadCollection={publicCollection}
                    setLoading={setBlockingLoad}
                    setShouldDisableDropzone={setShouldDisableDropzone}
                    onUploadFile={(file) =>
                        setPublicFiles(sortFiles([...publicFiles, file]))
                    }
                    uploadTypeSelectorView={uploadTypeSelectorView}
                    closeUploadTypeSelector={closeUploadTypeSelectorView}
                    showSessionExpiredMessage={showPublicLinkExpiredMessage}
                    uploadTypeSelectorIntent="collect"
                    {...{ dragAndDropFiles }}
                />
                <FilesDownloadProgress
                    attributesList={filesDownloadProgressAttributesList}
                    setAttributesList={setFilesDownloadProgressAttributesList}
                />
            </FullScreenDropZone>
        </PublicCollectionGalleryContext.Provider>
    );
}

const EnteLogoLink = styled("a")(({ theme }) => ({
    // Remove the excess space at the top.
    svg: { verticalAlign: "middle" },
    color: theme.vars.palette.text.base,
    ":hover": { color: theme.vars.palette.accent.main },
}));

const AddPhotosButton: React.FC<ButtonishProps> = ({ onClick }) => {
    const disabled = !uploadManager.shouldAllowNewUpload();
    const isSmallWidth = useIsSmallWidth();

    const icon = <AddPhotoAlternateOutlinedIcon />;

    return (
        <Box>
            {isSmallWidth ? (
                <IconButton {...{ onClick, disabled }}>{icon}</IconButton>
            ) : (
                <FocusVisibleButton
                    color="secondary"
                    startIcon={icon}
                    {...{ onClick, disabled }}
                >
                    {t("add_photos")}
                </FocusVisibleButton>
            )}
        </Box>
    );
};

/**
 * A visually different variation of {@link AddPhotosButton}. It also does not
 * shrink on mobile sized screens.
 */
const AddMorePhotosButton: React.FC<ButtonishProps> = ({ onClick }) => {
    const disabled = !uploadManager.shouldAllowNewUpload();

    return (
        <FocusVisibleButton
            color="accent"
            startIcon={<AddPhotoAlternateOutlinedIcon />}
            {...{ onClick, disabled }}
        >
            {t("add_more_photos")}
        </FocusVisibleButton>
    );
};

const GoToEnte: React.FC = () => {
    // Touchscreen devices are overwhemingly likely to be Android or iOS.
    const isTouchscreen = useIsTouchscreen();

    return (
        <Button color="accent" href="https://ente.io">
            {isTouchscreen ? t("install") : t("sign_up")}
        </Button>
    );
};

interface SelectedFileOptionsProps {
    count: number;
    clearSelection: () => void;
    downloadFilesHelper: () => void;
}

const SelectedFileOptions: React.FC<SelectedFileOptionsProps> = ({
    downloadFilesHelper,
    count,
    clearSelection,
}) => (
    <Stack
        direction="row"
        sx={{ flex: 1, gap: 2, alignItems: "center", mr: 1 }}
    >
        <IconButton onClick={clearSelection}>
            <CloseIcon />
        </IconButton>
        <Typography sx={{ mr: "auto" }}>
            {t("selected_count", { selected: count })}
        </Typography>
        <Tooltip title={t("download")}>
            <IconButton onClick={downloadFilesHelper}>
                <DownloadIcon />
            </IconButton>
        </Tooltip>
    </Stack>
);

interface ListHeaderProps {
    publicCollection: Collection;
    publicFiles: EnteFile[];
    setFilesDownloadProgressAttributesCreator: SetFilesDownloadProgressAttributesCreator;
}

const ListHeader: React.FC<ListHeaderProps> = ({
    publicCollection,
    publicFiles,
    setFilesDownloadProgressAttributesCreator,
}) => {
    const downloadEnabled =
        publicCollection.publicURLs?.[0]?.enableDownload ?? true;

    const downloadAllFiles = async () => {
        const setFilesDownloadProgressAttributes =
            setFilesDownloadProgressAttributesCreator(
                publicCollection.name,
                publicCollection.id,
                isHiddenCollection(publicCollection),
            );
        await downloadCollectionFiles(
            publicCollection.name,
            publicFiles,
            setFilesDownloadProgressAttributes,
        );
    };

    return (
        <GalleryItemsHeaderAdapter>
            <SpacedRow>
                <GalleryItemsSummary
                    name={publicCollection.name}
                    fileCount={publicFiles.length}
                />
                {downloadEnabled && (
                    <OverflowMenu ariaID="collection-options">
                        <OverflowMenuOption
                            startIcon={<FileDownloadOutlinedIcon />}
                            onClick={downloadAllFiles}
                        >
                            {t("download_album")}
                        </OverflowMenuOption>
                    </OverflowMenu>
                )}
            </SpacedRow>
        </GalleryItemsHeaderAdapter>
    );
};

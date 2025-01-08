import { EnteLogoSVG } from "@/base/components/EnteLogo";
import { FormPaper, FormPaperTitle } from "@/base/components/FormPaper";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { SpaceBetweenFlex } from "@/base/components/mui/Container";
import { NavbarBase, SelectionBar } from "@/base/components/Navbar";
import {
    OverflowMenu,
    OverflowMenuOption,
} from "@/base/components/OverflowMenu";
import {
    useIsSmallWidth,
    useIsTouchscreen,
} from "@/base/components/utils/hooks";
import { isHTTP401Error, PublicAlbumsCredentials } from "@/base/http";
import log from "@/base/log";
import { downloadManager } from "@/gallery/services/download";
import { extractCollectionKeyFromShareURL } from "@/gallery/services/share";
import { updateShouldDisableCFUploadProxy } from "@/gallery/services/upload";
import type { Collection } from "@/media/collection";
import { type EnteFile, mergeMetadata } from "@/media/file";
import { verifyPublicAlbumPassword } from "@/new/albums/services/publicCollection";
import {
    GalleryItemsHeaderAdapter,
    GalleryItemsSummary,
} from "@/new/photos/components/gallery/ListHeader";
import {
    ALL_SECTION,
    isHiddenCollection,
} from "@/new/photos/services/collection";
import { sortFiles } from "@/new/photos/services/files";
import { useAppContext } from "@/new/photos/types/context";
import {
    CenteredFlex,
    FluidContainer,
    VerticallyCentered,
} from "@ente/shared/components/Container";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import { CustomError, parseSharingErrorCodes } from "@ente/shared/error";
import { useFileInput } from "@ente/shared/hooks/useFileInput";
import AddPhotoAlternateOutlinedIcon from "@mui/icons-material/AddPhotoAlternateOutlined";
import CloseIcon from "@mui/icons-material/Close";
import DownloadIcon from "@mui/icons-material/Download";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import type { ButtonProps, IconButtonProps } from "@mui/material";
import { Box, Button, IconButton, Stack, styled, Tooltip } from "@mui/material";
import Typography from "@mui/material/Typography";
import {
    FilesDownloadProgress,
    FilesDownloadProgressAttributes,
} from "components/FilesDownloadProgress";
import FullScreenDropZone from "components/FullScreenDropZone";
import { LoadingOverlay } from "components/LoadingOverlay";
import PhotoFrame from "components/PhotoFrame";
import { ITEM_TYPE, TimeStampListItem } from "components/PhotoList";
import Uploader from "components/Upload/Uploader";
import { UploadSelectorInputs } from "components/UploadSelectorInputs";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useMemo, useRef, useState } from "react";
import { useDropzone } from "react-dropzone";
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
    const { showLoadingBar, hideLoadingBar, showMiniDialog } = useAppContext();
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
    const [selected, setSelected] = useState<SelectedState>({
        ownCount: 0,
        count: 0,
        collectionID: 0,
        context: undefined,
    });

    const {
        getRootProps: getDragAndDropRootProps,
        getInputProps: getDragAndDropInputProps,
        acceptedFiles: dragAndDropFilesReadOnly,
    } = useDropzone({
        noClick: true,
        noKeyboard: true,
        disabled: shouldDisableDropzone,
    });
    const {
        getInputProps: getFileSelectorInputProps,
        openSelector: openFileSelector,
        selectedFiles: fileSelectorFiles,
    } = useFileInput({
        directory: false,
    });
    const {
        getInputProps: getFolderSelectorInputProps,
        openSelector: openFolderSelector,
        selectedFiles: folderSelectorFiles,
    } = useFileInput({
        directory: true,
    });

    const [
        filesDownloadProgressAttributesList,
        setFilesDownloadProgressAttributesList,
    ] = useState<FilesDownloadProgressAttributes[]>([]);

    const setFilesDownloadProgressAttributesCreator: SetFilesDownloadProgressAttributesCreator =
        (folderName, collectionID, isHidden) => {
            const id = filesDownloadProgressAttributesList?.length ?? 0;
            const updater: SetFilesDownloadProgressAttributes = (value) => {
                setFilesDownloadProgressAttributesList((prev) => {
                    const attributes = prev?.find((attr) => attr.id === id);
                    const updatedAttributes =
                        typeof value === "function"
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
        };

    // Create a regular array from the readonly array returned by dropzone.
    const dragAndDropFiles = useMemo(
        () => [...dragAndDropFilesReadOnly],
        [dragAndDropFilesReadOnly],
    );

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
        if (currentURL.pathname !== "/") {
            router.replace(
                {
                    pathname: PAGES.SHARED_ALBUMS,
                    search: currentURL.search,
                    hash: currentURL.hash,
                },
                {
                    pathname: "/",
                    search: currentURL.search,
                    hash: currentURL.hash,
                },
                {
                    shallow: true,
                },
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
                itemType: ITEM_TYPE.HEADER,
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
                      itemType: ITEM_TYPE.FOOTER,
                      height: 104,
                  }
                : null,
        );
    }, [onAddPhotos]);

    const syncWithRemote = async () => {
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
                        ? t("LINK_TOO_MANY_REQUESTS")
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
    };

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
        return (
            <VerticallyCentered>
                <ActivityIndicator />
            </VerticallyCentered>
        );
    } else if (errorMessage) {
        return <VerticallyCentered>{errorMessage}</VerticallyCentered>;
    } else if (isPasswordProtected && !credentials.current.accessTokenJWT) {
        return (
            <VerticallyCentered>
                <FormPaper>
                    <FormPaperTitle>{t("password")}</FormPaperTitle>
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
                </FormPaper>
            </VerticallyCentered>
        );
    } else if (!publicFiles || !credentials.current) {
        return <VerticallyCentered>{t("NOT_FOUND")}</VerticallyCentered>;
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
            <FullScreenDropZone {...{ getDragAndDropRootProps }}>
                <UploadSelectorInputs
                    {...{
                        getDragAndDropInputProps,
                        getFileSelectorInputProps,
                        getFolderSelectorInputProps,
                    }}
                />
                <SharedAlbumNavbar onAddPhotos={onAddPhotos} />
                <PhotoFrame
                    files={publicFiles}
                    syncWithRemote={syncWithRemote}
                    setSelected={setSelected}
                    selected={selected}
                    activeCollectionID={ALL_SECTION}
                    enableDownload={downloadEnabled}
                    fileToCollectionsMap={null}
                    collectionNameMap={null}
                    setFilesDownloadProgressAttributesCreator={
                        setFilesDownloadProgressAttributesCreator
                    }
                    selectable={downloadEnabled}
                />
                {blockingLoad && (
                    <LoadingOverlay>
                        <ActivityIndicator />
                    </LoadingOverlay>
                )}
                <Uploader
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
                    {...{
                        dragAndDropFiles,
                        openFileSelector,
                        fileSelectorFiles,
                        openFolderSelector,
                        folderSelectorFiles,
                    }}
                />
                <FilesDownloadProgress
                    attributesList={filesDownloadProgressAttributesList}
                    setAttributesList={setFilesDownloadProgressAttributesList}
                />
                {selected.count > 0 && (
                    <SelectedFileOptions
                        downloadFilesHelper={downloadFilesHelper}
                        clearSelection={clearSelection}
                        count={selected.count}
                    />
                )}
            </FullScreenDropZone>
        </PublicCollectionGalleryContext.Provider>
    );
}

interface SharedAlbumNavbarProps {
    /**
     * If provided, then an "Add Photos" button will be shown in the navbar.
     */
    onAddPhotos: React.MouseEventHandler<HTMLButtonElement> | undefined;
}
const SharedAlbumNavbar: React.FC<SharedAlbumNavbarProps> = ({
    onAddPhotos,
}) => (
    <NavbarBase>
        <FluidContainer>
            <EnteLogoLink href="https://ente.io">
                <EnteLogoSVG height={15} />
            </EnteLogoLink>
        </FluidContainer>
        {onAddPhotos ? <AddPhotosButton onClick={onAddPhotos} /> : <GoToEnte />}
    </NavbarBase>
);

const EnteLogoLink = styled("a")(({ theme }) => ({
    // Remove the excess space at the top.
    svg: { verticalAlign: "middle" },
    color: theme.colors.text.base,
    ":hover": {
        color: theme.palette.accent.main,
    },
}));

const AddPhotosButton: React.FC<ButtonProps & IconButtonProps> = (props) => {
    const disabled = !uploadManager.shouldAllowNewUpload();
    const isSmallWidth = useIsSmallWidth();

    const icon = <AddPhotoAlternateOutlinedIcon />;

    return (
        <Box>
            {isSmallWidth ? (
                <IconButton {...props} disabled={disabled}>
                    {icon}
                </IconButton>
            ) : (
                <Button
                    {...props}
                    disabled={disabled}
                    color={"secondary"}
                    startIcon={icon}
                >
                    {t("add_photos")}
                </Button>
            )}
        </Box>
    );
};

/**
 * A visually different variation of {@link AddPhotosButton}. It also does not
 * shrink on mobile sized screens.
 */
const AddMorePhotosButton: React.FC<ButtonProps> = (props) => {
    const disabled = !uploadManager.shouldAllowNewUpload();
    return (
        <Box>
            <Button
                {...props}
                disabled={disabled}
                color={"accent"}
                startIcon={<AddPhotoAlternateOutlinedIcon />}
            >
                {t("add_more_photos")}
            </Button>
        </Box>
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
}) => {
    return (
        <SelectionBar>
            <FluidContainer>
                <IconButton onClick={clearSelection}>
                    <CloseIcon />
                </IconButton>
                <Box sx={{ ml: 1.5 }}>
                    {t("selected_count", { selected: count })}
                </Box>
            </FluidContainer>
            <Stack direction="row" sx={{ gap: 2, mr: 2 }}>
                <Tooltip title={t("download")}>
                    <IconButton onClick={downloadFilesHelper}>
                        <DownloadIcon />
                    </IconButton>
                </Tooltip>
            </Stack>
        </SelectionBar>
    );
};

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
            <SpaceBetweenFlex>
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
            </SpaceBetweenFlex>
        </GalleryItemsHeaderAdapter>
    );
};

import { EnteLogoSVG } from "@/base/components/EnteLogo";
import { FormPaper, FormPaperTitle } from "@/base/components/FormPaper";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { SpaceBetweenFlex } from "@/base/components/mui/Container";
import { NavbarBase, SelectionBar } from "@/base/components/Navbar";
import {
    useIsSmallWidth,
    useIsTouchscreen,
} from "@/base/components/utils/hooks";
import { sharedCryptoWorker } from "@/base/crypto";
import log from "@/base/log";
import { downloadManager } from "@/gallery/services/download";
import { updateShouldDisableCFUploadProxy } from "@/gallery/services/upload";
import type { Collection } from "@/media/collection";
import { type EnteFile, mergeMetadata } from "@/media/file";
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
import OverflowMenu from "@ente/shared/components/OverflowMenu/menu";
import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import { CustomError, parseSharingErrorCodes } from "@ente/shared/error";
import { useFileInput } from "@ente/shared/hooks/useFileInput";
import AddPhotoAlternateOutlined from "@mui/icons-material/AddPhotoAlternateOutlined";
import CloseIcon from "@mui/icons-material/Close";
import DownloadIcon from "@mui/icons-material/Download";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import MoreHoriz from "@mui/icons-material/MoreHoriz";
import type { ButtonProps, IconButtonProps } from "@mui/material";
import { Box, Button, IconButton, Stack, styled, Tooltip } from "@mui/material";
import Typography from "@mui/material/Typography";
import bs58 from "bs58";
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
    verifyPublicCollectionPassword,
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
    const token = useRef<string>(null);
    // passwordJWTToken refers to the jwt token which is used for album protected by password.
    const passwordJWTToken = useRef<string>(null);
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
        acceptedFiles: dragAndDropFiles,
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
                const cryptoWorker = await sharedCryptoWorker();

                url.current = window.location.href;
                const currentURL = new URL(url.current);
                const t = currentURL.searchParams.get("t");
                const ck = currentURL.hash.slice(1);
                if (!t && !ck) {
                    window.location.href = "https://ente.io";
                    redirectingToWebsite = true;
                }
                if (!t || !ck) {
                    return;
                }
                const dck =
                    ck.length < 50
                        ? await cryptoWorker.toB64(bs58.decode(ck))
                        : await cryptoWorker.fromHex(ck);
                token.current = t;
                downloadManager.setPublicAlbumsCredentials(
                    token.current,
                    undefined,
                );
                await updateShouldDisableCFUploadProxy();
                collectionKey.current = dck;
                url.current = window.location.href;
                const localCollection = await getLocalPublicCollection(
                    collectionKey.current,
                );
                if (localCollection) {
                    referralCode.current = await getReferralCode();
                    const sortAsc: boolean =
                        localCollection?.pubMagicMetadata?.data.asc ?? false;
                    setPublicCollection(localCollection);
                    const isPasswordProtected =
                        localCollection?.publicURLs?.[0]?.passwordEnabled;
                    setIsPasswordProtected(isPasswordProtected);
                    const collectionUID = getPublicCollectionUID(token.current);
                    const localFiles = await getLocalPublicFiles(collectionUID);
                    const localPublicFiles = sortFiles(
                        mergeMetadata(localFiles),
                        sortAsc,
                    );
                    setPublicFiles(localPublicFiles);
                    passwordJWTToken.current =
                        await getLocalPublicCollectionPassword(collectionUID);
                    downloadManager.setPublicAlbumsCredentials(
                        token.current,
                        passwordJWTToken.current,
                    );
                }
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
        const collectionUID = getPublicCollectionUID(token.current);
        try {
            showLoadingBar();
            setLoading(true);
            const [collection, userReferralCode] = await getPublicCollection(
                token.current,
                collectionKey.current,
            );
            referralCode.current = userReferralCode;

            setPublicCollection(collection);
            const isPasswordProtected =
                collection?.publicURLs?.[0]?.passwordEnabled;
            setIsPasswordProtected(isPasswordProtected);
            setErrorMessage(null);

            // remove outdated password, sharer has disabled the password
            if (!isPasswordProtected && passwordJWTToken.current) {
                passwordJWTToken.current = null;
                savePublicCollectionPassword(collectionUID, null);
            }
            if (
                !isPasswordProtected ||
                (isPasswordProtected && passwordJWTToken.current)
            ) {
                try {
                    await syncPublicFiles(
                        token.current,
                        passwordJWTToken.current,
                        collection,
                        setPublicFiles,
                    );
                } catch (e) {
                    const parsedError = parseSharingErrorCodes(e);
                    if (parsedError.message === CustomError.TOKEN_EXPIRED) {
                        // passwordToken has expired, sharer has changed the password,
                        // so,clearing local cache token value to prompt user to re-enter password
                        passwordJWTToken.current = null;
                    }
                }
            }
            if (isPasswordProtected && !passwordJWTToken.current) {
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
            const cryptoWorker = await sharedCryptoWorker();
            let hashedPassword: string = null;
            try {
                const publicUrl = publicCollection.publicURLs[0];
                hashedPassword = await cryptoWorker.deriveKey(
                    password,
                    publicUrl.nonce,
                    publicUrl.opsLimit,
                    publicUrl.memLimit,
                );
            } catch (e) {
                log.error("failed to derive key for verifyLinkPassword", e);
                setFieldError(`${t("generic_error_retry")} ${e.message}`);
                return;
            }
            const collectionUID = getPublicCollectionUID(token.current);
            try {
                const jwtToken = await verifyPublicCollectionPassword(
                    token.current,
                    hashedPassword,
                );
                passwordJWTToken.current = jwtToken;
                downloadManager.setPublicAlbumsCredentials(
                    token.current,
                    passwordJWTToken.current,
                );
                await savePublicCollectionPassword(collectionUID, jwtToken);
            } catch (e) {
                const parsedError = parseSharingErrorCodes(e);
                if (parsedError.message === CustomError.TOKEN_EXPIRED) {
                    setFieldError(t("INCORRECT_PASSPHRASE"));
                    return;
                }
                throw e;
            }
            await syncWithRemote();
            hideLoadingBar();
        } catch (e) {
            log.error("failed to verifyLinkPassword", e);
            setFieldError(`${t("generic_error_retry")} ${e.message}`);
        }
    };

    if (loading) {
        if (!publicFiles) {
            return (
                <VerticallyCentered>
                    <ActivityIndicator />
                </VerticallyCentered>
            );
        }
    } else {
        if (errorMessage) {
            return <VerticallyCentered>{errorMessage}</VerticallyCentered>;
        }
        if (isPasswordProtected && !passwordJWTToken.current) {
            return (
                <VerticallyCentered>
                    <FormPaper>
                        <FormPaperTitle>{t("password")}</FormPaperTitle>
                        <Typography color={"text.muted"} mb={2} variant="small">
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
        }
        if (!publicFiles) {
            return <VerticallyCentered>{t("NOT_FOUND")}</VerticallyCentered>;
        }
    }

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
                    `${selectedFiles.length} ${t("FILES")}`,
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

    return (
        <PublicCollectionGalleryContext.Provider
            value={{
                token: token.current,
                referralCode: referralCode.current,
                passwordToken: passwordJWTToken.current,
                accessedThroughSharedURL: true,
                photoListHeader,
                photoListFooter,
            }}
        >
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
                    page={PAGES.SHARED_ALBUMS}
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
                    onUploadFile={(file) => sortFiles([...publicFiles, file])}
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

    const icon = <AddPhotoAlternateOutlined />;

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
                startIcon={<AddPhotoAlternateOutlined />}
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
                <Box ml={1.5}>{t("selected_count", { selected: count })}</Box>
            </FluidContainer>
            <Stack spacing={2} direction="row" mr={2}>
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
                    <OverflowMenu
                        ariaControls={"collection-options"}
                        triggerButtonIcon={<MoreHoriz />}
                    >
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

import { EnteFile } from "@/new/photos/types/file";
import log from "@/next/log";
import {
    CenteredFlex,
    SpaceBetweenFlex,
    VerticallyCentered,
} from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import FormPaperTitle from "@ente/shared/components/Form/FormPaper/Title";
import OverflowMenu from "@ente/shared/components/OverflowMenu/menu";
import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import { ENTE_WEBSITE_LINK } from "@ente/shared/constants/urls";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { CustomError, parseSharingErrorCodes } from "@ente/shared/error";
import { useFileInput } from "@ente/shared/hooks/useFileInput";
import AddPhotoAlternateOutlined from "@mui/icons-material/AddPhotoAlternateOutlined";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import MoreHoriz from "@mui/icons-material/MoreHoriz";
import Typography from "@mui/material/Typography";
import bs58 from "bs58";
import { CollectionInfo } from "components/Collections/CollectionInfo";
import { CollectionInfoBarWrapper } from "components/Collections/styledComponents";
import {
    FilesDownloadProgress,
    FilesDownloadProgressAttributes,
} from "components/FilesDownloadProgress";
import FullScreenDropZone from "components/FullScreenDropZone";
import { LoadingOverlay } from "components/LoadingOverlay";
import PhotoFrame from "components/PhotoFrame";
import { ITEM_TYPE, TimeStampListItem } from "components/PhotoList";
import UploadButton from "components/Upload/UploadButton";
import Uploader from "components/Upload/Uploader";
import { UploadSelectorInputs } from "components/UploadSelectorInputs";
import SharedAlbumNavbar from "components/pages/sharedAlbum/Navbar";
import SelectedFileOptions from "components/pages/sharedAlbum/SelectedFileOptions";
import { ALL_SECTION } from "constants/collection";
import { t } from "i18next";
import { useRouter } from "next/router";
import { AppContext } from "pages/_app";
import { useContext, useEffect, useMemo, useRef, useState } from "react";
import { useDropzone } from "react-dropzone";
import downloadManager from "services/download";
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
import { Collection } from "types/collection";
import {
    SelectedState,
    SetFilesDownloadProgressAttributes,
    SetFilesDownloadProgressAttributesCreator,
} from "types/gallery";
import { downloadCollectionFiles, isHiddenCollection } from "utils/collection";
import {
    downloadSelectedFiles,
    getSelectedFiles,
    mergeMetadata,
    sortFiles,
} from "utils/file";
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
    const appContext = useContext(AppContext);
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

    const openUploader = () => {
        setUploadTypeSelectorView(true);
    };

    const closeUploadTypeSelectorView = () => {
        setUploadTypeSelectorView(false);
    };

    const showPublicLinkExpiredMessage = () =>
        appContext.setDialogMessage({
            title: t("LINK_EXPIRED"),
            content: t("LINK_EXPIRED_MESSAGE"),

            nonClosable: true,
            proceed: {
                text: t("LOGIN"),
                action: () => router.push(PAGES.ROOT),
                variant: "accent",
            },
        });

    useEffect(() => {
        const currentURL = new URL(window.location.href);
        if (currentURL.pathname !== PAGES.ROOT) {
            router.replace(
                {
                    pathname: PAGES.SHARED_ALBUMS,
                    search: currentURL.search,
                    hash: currentURL.hash,
                },
                {
                    pathname: PAGES.ROOT,
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
                const cryptoWorker = await ComlinkCryptoWorker.getInstance();
                await downloadManager.init();

                url.current = window.location.href;
                const currentURL = new URL(url.current);
                const t = currentURL.searchParams.get("t");
                const ck = currentURL.hash.slice(1);
                if (!t && !ck) {
                    window.location.href = ENTE_WEBSITE_LINK;
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
                downloadManager.updateToken(token.current);
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
                    downloadManager.updateToken(
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

    const downloadEnabled = useMemo(
        () => publicCollection?.publicURLs?.[0]?.enableDownload ?? true,
        [publicCollection],
    );

    const downloadAllFiles = async () => {
        try {
            if (!downloadEnabled) {
                return;
            }
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
        } catch (e) {
            log.error("failed to downloads shared album all files", e);
        }
    };

    useEffect(() => {
        publicCollection &&
            publicFiles &&
            setPhotoListHeader({
                item: (
                    <CollectionInfoBarWrapper>
                        <SpaceBetweenFlex>
                            <CollectionInfo
                                name={publicCollection.name}
                                fileCount={publicFiles.length}
                            />
                            {downloadEnabled ? (
                                <OverflowMenu
                                    ariaControls={"collection-options"}
                                    triggerButtonIcon={<MoreHoriz />}
                                >
                                    <OverflowMenuOption
                                        startIcon={<FileDownloadOutlinedIcon />}
                                        onClick={downloadAllFiles}
                                    >
                                        {t("DOWNLOAD_COLLECTION")}
                                    </OverflowMenuOption>
                                </OverflowMenu>
                            ) : (
                                <div />
                            )}
                        </SpaceBetweenFlex>
                    </CollectionInfoBarWrapper>
                ),
                itemType: ITEM_TYPE.HEADER,
                height: 68,
            });
    }, [publicCollection, publicFiles]);

    useEffect(() => {
        if (publicCollection?.publicURLs?.[0]?.enableCollect) {
            setPhotoListFooter({
                item: (
                    <CenteredFlex sx={{ marginTop: "56px" }}>
                        <UploadButton
                            disableShrink
                            openUploader={openUploader}
                            text={t("ADD_MORE_PHOTOS")}
                            color="accent"
                            icon={<AddPhotoAlternateOutlined />}
                        />
                    </CenteredFlex>
                ),
                itemType: ITEM_TYPE.FOOTER,
                height: 104,
            });
        } else {
            setPhotoListFooter(null);
        }
    }, [publicCollection]);

    const syncWithRemote = async () => {
        const collectionUID = getPublicCollectionUID(token.current);
        try {
            appContext.startLoading();
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
                        : t("LINK_EXPIRED_MESSAGE"),
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
            appContext.finishLoading();
            setLoading(false);
        }
    };

    const verifyLinkPassword: SingleInputFormProps["callback"] = async (
        password,
        setFieldError,
    ) => {
        try {
            const cryptoWorker = await ComlinkCryptoWorker.getInstance();
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
                setFieldError(`${t("UNKNOWN_ERROR")} ${e.message}`);
                return;
            }
            const collectionUID = getPublicCollectionUID(token.current);
            try {
                const jwtToken = await verifyPublicCollectionPassword(
                    token.current,
                    hashedPassword,
                );
                passwordJWTToken.current = jwtToken;
                downloadManager.updateToken(
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
            appContext.finishLoading();
        } catch (e) {
            log.error("failed to verifyLinkPassword", e);
            setFieldError(`${t("UNKNOWN_ERROR")} ${e.message}`);
        }
    };

    if (loading) {
        if (!publicFiles) {
            return (
                <VerticallyCentered>
                    <EnteSpinner />
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
        setSelected({ ownCount: 0, count: 0, collectionID: 0 });
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
                <SharedAlbumNavbar
                    showUploadButton={
                        publicCollection?.publicURLs?.[0]?.enableCollect
                    }
                    openUploader={openUploader}
                />
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
                />
                {blockingLoad && (
                    <LoadingOverlay>
                        <EnteSpinner />
                    </LoadingOverlay>
                )}
                <Uploader
                    syncWithRemote={syncWithRemote}
                    uploadCollection={publicCollection}
                    setLoading={setBlockingLoad}
                    setShouldDisableDropzone={setShouldDisableDropzone}
                    setFiles={setPublicFiles}
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

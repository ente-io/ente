// TODO: Audit this file (too many null assertions + other issues)
/* eslint-disable @typescript-eslint/no-floating-promises */
import AddPhotoAlternateOutlinedIcon from "@mui/icons-material/AddPhotoAlternateOutlined";
import CloseIcon from "@mui/icons-material/Close";
import DownloadIcon from "@mui/icons-material/Download";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import {
    Box,
    Button,
    IconButton,
    Link,
    Stack,
    styled,
    Tooltip,
} from "@mui/material";
import Typography from "@mui/material/Typography";
import { DownloadStatusNotifications } from "components/DownloadStatusNotifications";
import { type FileListHeaderOrFooter } from "components/FileList";
import { FileListWithViewer } from "components/FileListWithViewer";
import { Upload } from "components/Upload";
import {
    AccountsPageContents,
    AccountsPageTitle,
} from "ente-accounts/components/layouts/centered-paper";
import {
    CenteredFill,
    SpacedRow,
    Stack100vhCenter,
} from "ente-base/components/containers";
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
    SingleInputForm,
    type SingleInputFormProps,
} from "ente-base/components/SingleInputForm";
import {
    useIsSmallWidth,
    useIsTouchscreen,
} from "ente-base/components/utils/hooks";
import { useBaseContext } from "ente-base/context";
import {
    isHTTP401Error,
    isHTTPErrorWithStatus,
    type PublicAlbumsCredentials,
} from "ente-base/http";
import log from "ente-base/log";
import { FullScreenDropZone } from "ente-gallery/components/FullScreenDropZone";
import {
    useSaveGroups,
    type AddSaveGroup,
} from "ente-gallery/components/utils/save-groups";
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
import {
    removePublicCollectionAccessTokenJWT,
    removePublicCollectionByKey,
    savedLastPublicCollectionReferralCode,
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
import { PseudoCollectionID } from "ente-new/photos/services/collection-summary";
import { usePhotosAppContext } from "ente-new/photos/types/context";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { type FileWithPath } from "react-dropzone";
import { Trans } from "react-i18next";
import { uploadManager } from "services/upload-manager";
import { getSelectedFiles, type SelectedState } from "utils/file";

export default function PublicCollectionGallery() {
    const { showMiniDialog, onGenericError } = useBaseContext();
    const { showLoadingBar, hideLoadingBar } = usePhotosAppContext();

    const [publicCollection, setPublicCollection] = useState<
        Collection | undefined
    >(undefined);
    const [publicFiles, setPublicFiles] = useState<EnteFile[] | undefined>(
        undefined,
    );
    const [referralCode, setReferralCode] = useState<string>("");
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

    const { saveGroups, onAddSaveGroup, onRemoveSaveGroup } = useSaveGroups();

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
                    window.location.href = "https://ente.io";
                    redirectingToWebsite = true;
                }
                if (!t || !ck) {
                    return;
                }
                collectionKey.current = ck;
                const collection = await savedPublicCollectionByKey(ck);
                const accessToken = t;
                let accessTokenJWT: string | undefined;
                if (collection) {
                    setReferralCode(
                        (await savedLastPublicCollectionReferralCode()) ?? "",
                    );
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
                if (!redirectingToWebsite) {
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
            const { collection, referralCode: userReferralCode } =
                await pullCollection(accessToken, collectionKey.current!);
            setReferralCode(userReferralCode);

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
            setLoading(false);
        }
    }, [showLoadingBar, hideLoadingBar, onGenericError]);

    // See: [Note: Visual feedback to acknowledge user actions]
    const handleVisualFeedback = useCallback(() => {
        showLoadingBar();
        setTimeout(hideLoadingBar, 0);
    }, [showLoadingBar, hideLoadingBar]);

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
            await downloadAndSaveFiles(
                selectedFiles,
                t("files_count", { count: selectedFiles.length }),
                onAddSaveGroup,
            );
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
                              }}
                          />
                      ),
                      height: fileListHeaderHeight,
                  }
                : undefined,
        [onAddSaveGroup, publicCollection, publicFiles, downloadEnabled],
    );

    const fileListFooter = useMemo<FileListHeaderOrFooter>(() => {
        const props = { referralCode, onAddPhotos };
        return {
            component: <FileListFooter {...props} />,
            height: fileListFooterHeightForProps(props),
            extendToInlineEdges: true,
        };
    }, [referralCode, onAddPhotos]);

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

    return (
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
                        count={selected.count}
                        clearSelection={clearSelection}
                        downloadFilesHelper={downloadFilesHelper}
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
                header={fileListHeader}
                footer={fileListFooter}
                enableDownload={downloadEnabled}
                enableSelect={downloadEnabled}
                selected={selected}
                setSelected={setSelected}
                activeCollectionID={PseudoCollectionID.all}
                onRemotePull={publicAlbumsRemotePull}
                onVisualFeedback={handleVisualFeedback}
                onAddSaveGroup={onAddSaveGroup}
            />
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
            />
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

const AddPhotosButton: React.FC<ButtonishProps> = ({ onClick }) => {
    const disabled = uploadManager.isUploadInProgress();
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
    const disabled = uploadManager.isUploadInProgress();

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
    count,
    clearSelection,
    downloadFilesHelper,
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

interface FileListHeaderProps {
    publicCollection: Collection;
    publicFiles: EnteFile[];
    downloadEnabled: boolean;
    onAddSaveGroup: AddSaveGroup;
}

/**
 * The fixed height (in px) of {@link FileListHeader}.
 */
const fileListHeaderHeight = 68;

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
}) => {
    const downloadAllFiles = () =>
        downloadAndSaveCollectionFiles(
            publicCollection.name,
            publicCollection.id,
            publicFiles,
            undefined,
            onAddSaveGroup,
        );

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

interface FileListFooterProps {
    referralCode?: string;
    onAddPhotos?: () => void;
}

/**
 * The dynamic (prop-dependent) height of {@link FileListFooter}.
 */
const fileListFooterHeightForProps = ({
    referralCode,
    onAddPhotos,
}: FileListFooterProps) => (onAddPhotos ? 104 : 0) + (referralCode ? 113 : 75);

/**
 * A footer shown after the listing of files.
 *
 * It scrolls along with the content. It has a dynamic height, dependent on the
 * props, calculated using {@link fileListFooterHeightForProps}.
 */

const FileListFooter: React.FC<FileListFooterProps> = ({
    referralCode,
    onAddPhotos,
}) => (
    <Stack sx={{ flex: 1, alignSelf: "flex-end" }}>
        {onAddPhotos && (
            <CenteredFill>
                <AddMorePhotosButton onClick={onAddPhotos} />
            </CenteredFill>
        )}
        {/* Make the entire area tappable, otherwise it is hard to
            get at on mobile devices. */}
        <Link
            color="text.muted"
            sx={{
                mt: "48px",
                mb: "6px",
                textAlign: "center",
                "&:hover": { color: "inherit" },
            }}
            target="_blank"
            href="https://ente.io"
        >
            <Typography variant="small">
                <Trans
                    i18nKey="shared_using"
                    components={{
                        a: (
                            <Typography
                                variant="small"
                                component="span"
                                sx={{ color: "accent.main" }}
                            />
                        ),
                    }}
                    values={{ url: "ente.io" }}
                />
            </Typography>
        </Link>
        {referralCode && (
            <Typography
                sx={{
                    mt: "6px",
                    mb: 0,
                    padding: "8px",
                    bgcolor: "accent.main",
                    color: "accent.contrastText",
                    textAlign: "center",
                }}
            >
                <Trans
                    i18nKey={"sharing_referral_code"}
                    values={{ referralCode }}
                />
            </Typography>
        )}
    </Stack>
);

import CheckIcon from "@mui/icons-material/Check";
import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import DownloadOutlinedIcon from "@mui/icons-material/DownloadOutlined";
import FullscreenOutlinedIcon from "@mui/icons-material/FullscreenOutlined";
import InfoOutlinedIcon from "@mui/icons-material/InfoOutlined";
import MoreVertIcon from "@mui/icons-material/MoreVert";
import ShareOutlinedIcon from "@mui/icons-material/ShareOutlined";
import {
    Box,
    Button,
    CircularProgress,
    GlobalStyles,
    IconButton,
    Menu,
    MenuItem,
    Stack,
    styled,
    Typography,
} from "@mui/material";
import { EnteLogo } from "ente-base/components/EnteLogo";
import { ActivityIndicator } from "ente-base/components/mui/ActivityIndicator";
import { useBaseContext } from "ente-base/context";
import type { PublicAlbumsCredentials } from "ente-base/http";
import log from "ente-base/log";
import type { AddSaveGroup } from "ente-gallery/components/utils/save-groups";
import { FileViewer } from "ente-gallery/components/viewer/FileViewer";
import { downloadManager } from "ente-gallery/services/download";
import { downloadAndSaveFiles } from "ente-gallery/services/save";
import type { EnteFile } from "ente-media/file";
import { fileFileName } from "ente-media/file-metadata";
import { FileType } from "ente-media/file-type";
import { Notification } from "ente-new/photos/components/Notification";
import { t } from "i18next";
import { useCallback, useEffect, useMemo, useState } from "react";
import { getEnteURL } from "utils/public-album";

interface PublicAlbumSingleFileViewerProps {
    file: EnteFile;
    publicAlbumsCredentials: PublicAlbumsCredentials;
    collectionKey: string;
    enableDownload: boolean;
    enableComment: boolean;
    enableJoin?: boolean;
    onJoinAlbum?: () => void;
    onVisualFeedback: () => void;
    onAddSaveGroup: AddSaveGroup;
}

const bodyClassName = "ente-public-single-file-viewer";

/**
 * A dedicated public-album single-file viewer mode with a bespoke header/menu.
 *
 * This wraps the regular FileViewer but overlays its own controls.
 */
export const PublicAlbumSingleFileViewer: React.FC<
    PublicAlbumSingleFileViewerProps
> = ({
    file,
    publicAlbumsCredentials,
    collectionKey,
    enableDownload,
    enableComment,
    enableJoin,
    onJoinAlbum,
    onVisualFeedback,
    onAddSaveGroup,
}) => {
    const { onGenericError } = useBaseContext();
    const [menuAnchorEl, setMenuAnchorEl] = useState<HTMLElement | null>(null);
    const [showCopiedMessage, setShowCopiedMessage] = useState(false);
    const [isPhotoSwipeUIVisible, setIsPhotoSwipeUIVisible] = useState(true);
    const [isPhotoSwipeContentLoading, setIsPhotoSwipeContentLoading] =
        useState(false);
    const needsThumbnailPrime =
        file.metadata.fileType === FileType.image ||
        file.metadata.fileType === FileType.livePhoto;
    const needsOriginalPrime = needsThumbnailPrime;
    const [primedFileID, setPrimedFileID] = useState<number | undefined>(() =>
        needsThumbnailPrime ? undefined : file.id,
    );
    const isViewerPrimed = !needsThumbnailPrime || primedFileID === file.id;

    useEffect(() => {
        document.body.classList.add(bodyClassName);
        return () => document.body.classList.remove(bodyClassName);
    }, []);

    useEffect(() => {
        let classObserver: MutationObserver | undefined;
        let preloaderObserver: MutationObserver | undefined;
        let pswpElement: HTMLElement | null = null;
        let preloaderElement: HTMLElement | null = null;

        const updateVisibility = () => {
            setIsPhotoSwipeUIVisible(
                pswpElement?.classList.contains("pswp--ui-visible") ?? true,
            );
        };

        const updateLoading = () => {
            setIsPhotoSwipeContentLoading(
                preloaderElement?.classList.contains(
                    "pswp__preloader--active",
                ) ?? false,
            );
        };

        const bindToPreloaderElement = () => {
            const next =
                pswpElement?.querySelector<HTMLElement>(".pswp__preloader");
            if (next === preloaderElement) return;

            preloaderObserver?.disconnect();
            preloaderObserver = undefined;
            preloaderElement = next ?? null;

            if (!preloaderElement) {
                setIsPhotoSwipeContentLoading(false);
                return;
            }

            preloaderObserver = new MutationObserver(updateLoading);
            preloaderObserver.observe(preloaderElement, {
                attributes: true,
                attributeFilter: ["class"],
            });
            updateLoading();
        };

        const bindToPhotoSwipeElement = () => {
            const next = document.querySelector<HTMLElement>(".pswp");
            if (next !== pswpElement) {
                classObserver?.disconnect();
                classObserver = undefined;
                pswpElement = next;

                if (!pswpElement) {
                    preloaderObserver?.disconnect();
                    preloaderObserver = undefined;
                    preloaderElement = null;
                    setIsPhotoSwipeUIVisible(true);
                    setIsPhotoSwipeContentLoading(false);
                    return;
                }

                classObserver = new MutationObserver(updateVisibility);
                classObserver.observe(pswpElement, {
                    attributes: true,
                    attributeFilter: ["class"],
                });
                updateVisibility();
            }

            bindToPreloaderElement();
        };

        const treeObserver = new MutationObserver(bindToPhotoSwipeElement);
        treeObserver.observe(document.body, { childList: true, subtree: true });
        bindToPhotoSwipeElement();

        return () => {
            treeObserver.disconnect();
            classObserver?.disconnect();
            preloaderObserver?.disconnect();
        };
    }, []);

    useEffect(() => {
        if (!needsThumbnailPrime) {
            setPrimedFileID(file.id);
            return;
        }
        if (primedFileID === file.id) return;

        let isActive = true;
        void downloadManager
            .renderableThumbnailURL(file)
            .catch((error: unknown) =>
                log.warn(
                    "Failed to prime thumbnail for public single-file viewer",
                    error,
                ),
            )
            .finally(() => {
                if (isActive) setPrimedFileID(file.id);
            });

        return () => {
            isActive = false;
        };
    }, [file, file.id, needsThumbnailPrime, primedFileID]);

    useEffect(() => {
        if (!needsOriginalPrime) return;

        // Give thumbnail fetch a brief head-start, then warm the original.
        const prefetchTimer = window.setTimeout(() => {
            void downloadManager
                .renderableSourceURLs(file)
                .catch((error: unknown) =>
                    log.warn(
                        "Failed to prime original for public single-file viewer",
                        error,
                    ),
                );
        }, 120);

        return () => window.clearTimeout(prefetchTimer);
    }, [file, needsOriginalPrime]);

    const handleViewerClose = useCallback(() => {
        window.history.back();
    }, []);

    const handleMenuClose = useCallback(() => setMenuAnchorEl(null), []);

    const handleDownload = useCallback(
        (targetFile: EnteFile) =>
            downloadAndSaveFiles(
                [targetFile],
                fileFileName(targetFile),
                onAddSaveGroup,
            ),
        [onAddSaveGroup],
    );

    const handleShare = useCallback(async () => {
        handleMenuClose();
        const shareUrl = window.location.href;
        const isMobile = window.matchMedia("(width < 720px)").matches;

        if (isMobile && typeof navigator.share === "function") {
            try {
                await navigator.share({ text: shareUrl });
                return;
            } catch (error) {
                if (error instanceof Error && error.name === "AbortError") {
                    return;
                }
            }
        }

        try {
            await navigator.clipboard.writeText(shareUrl);
            setShowCopiedMessage(true);
            window.setTimeout(() => setShowCopiedMessage(false), 2000);
        } catch (error) {
            onGenericError(error);
        }
    }, [handleMenuClose, onGenericError]);

    const canCopyAsPNG = useMemo(
        () =>
            enableDownload &&
            (file.metadata.fileType === FileType.image ||
                file.metadata.fileType === FileType.livePhoto),
        [enableDownload, file.metadata.fileType],
    );

    const handleCopyAsPNG = useCallback(async () => {
        handleMenuClose();
        if (!canCopyAsPNG) return;

        try {
            const imageElement =
                document.querySelector<HTMLImageElement>(
                    ".pswp .pswp__item--active img.pswp__img",
                ) ??
                document.querySelector<HTMLImageElement>(".pswp img.pswp__img");

            const imageURL = imageElement?.currentSrc || imageElement?.src;
            if (!imageURL) return;

            await navigator.clipboard.write([
                new ClipboardItem({
                    "image/png": createImagePNGBlob(imageURL),
                }),
            ]);
            onVisualFeedback();
        } catch (error) {
            onGenericError(error);
        }
    }, [canCopyAsPNG, handleMenuClose, onGenericError, onVisualFeedback]);

    const handleOpenInfo = useCallback(() => {
        handleMenuClose();
        document
            .querySelector<HTMLButtonElement>(".pswp .pswp__button--info")
            ?.click();
    }, [handleMenuClose]);

    const handleToggleFullscreen = useCallback(() => {
        handleMenuClose();
        void (
            document.fullscreenElement
                ? document.exitFullscreen()
                : document.body.requestFullscreen()
        ).catch(onGenericError);
    }, [handleMenuClose, onGenericError]);

    const handleTryEnte = useCallback(() => {
        window.location.href = getEnteURL();
    }, []);

    const topControlsVisible = isViewerPrimed && isPhotoSwipeUIVisible;

    useEffect(() => {
        if (!topControlsVisible) {
            setMenuAnchorEl(null);
        }
    }, [topControlsVisible]);

    return (
        <>
            <GlobalStyles
                styles={{
                    [`body.${bodyClassName} .pswp-ente-public-album .pswp__counter`]:
                        { display: "none !important" },
                    [`body.${bodyClassName} .pswp-ente-public-album .pswp__button--zoom`]:
                        { display: "none !important" },
                    [`body.${bodyClassName} .pswp-ente-public-album .pswp__button--close`]:
                        { display: "none !important" },
                    [`body.${bodyClassName} .pswp-ente-public-album .pswp__button--more`]:
                        { display: "none !important" },
                    [`body.${bodyClassName} .pswp-ente-public-album .pswp__button--info`]:
                        { display: "none !important" },
                    [`body.${bodyClassName} .pswp-ente-public-album .pswp__button--ente-logo`]:
                        { display: "none !important" },
                    [`body.${bodyClassName} .pswp-ente-public-album .pswp__button--download`]:
                        { display: "none !important" },
                    [`body.${bodyClassName} .pswp-ente-public-album .pswp__preloader`]:
                        { display: "none !important" },
                }}
            />
            <FileViewer
                open
                onClose={handleViewerClose}
                files={[file]}
                initialIndex={0}
                disableEscapeClose
                disableDownload={!enableDownload}
                onDownload={enableDownload ? handleDownload : undefined}
                onVisualFeedback={onVisualFeedback}
                publicAlbumsCredentials={publicAlbumsCredentials}
                shouldCloseOnBrowserBack={false}
                collectionKey={collectionKey}
                onJoinAlbum={onJoinAlbum}
                enableComment={enableComment}
                enableJoin={enableJoin}
            />
            {isViewerPrimed && (
                <>
                    <Box
                        sx={{
                            position: "fixed",
                            top: {
                                xs: "calc(env(titlebar-area-height, 0px) * 0.4 + 12px)",
                                sm: "calc(env(titlebar-area-height, 0px) * 0.4 + 40px)",
                            },
                            left: 0,
                            right: 0,
                            pl: { xs: 1.5, sm: 5.5 },
                            pr: { xs: 0.5, sm: 4 },
                            zIndex: (theme) => theme.zIndex.drawer,
                            pointerEvents: "none",
                            opacity: topControlsVisible ? 1 : 0,
                            transform: topControlsVisible
                                ? "translateY(0)"
                                : "translateY(-8px)",
                            transition:
                                "opacity 220ms ease, transform 220ms ease",
                        }}
                    >
                        <Stack
                            direction="row"
                            justifyContent="space-between"
                            alignItems="center"
                            sx={{
                                pointerEvents: topControlsVisible
                                    ? "auto"
                                    : "none",
                            }}
                        >
                            <Stack
                                direction="row"
                                alignItems="center"
                                spacing={1.5}
                            >
                                <Box
                                    component="a"
                                    href="https://ente.io"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    sx={{
                                        color: "white",
                                        opacity: 0.85,
                                        lineHeight: 0,
                                        "& svg": {
                                            width: "auto",
                                            height: { xs: 15, sm: 19 },
                                        },
                                        "&:hover": { opacity: 1 },
                                    }}
                                >
                                    <EnteLogo height={15} />
                                </Box>
                                {isPhotoSwipeContentLoading && (
                                    <CircularProgress
                                        size={16}
                                        thickness={5}
                                        sx={{
                                            color: "rgb(255 255 255 / 0.85)",
                                        }}
                                    />
                                )}
                            </Stack>
                            <Stack
                                direction="row"
                                alignItems="center"
                                spacing={1}
                            >
                                <Button
                                    variant="contained"
                                    onClick={handleTryEnte}
                                    sx={{
                                        borderRadius: "16px",
                                        paddingBlock: "11px",
                                        paddingInline: "20px",
                                        minHeight: "unset",
                                        textTransform: "none",
                                        fontWeight: "medium",
                                        color: "#fff",
                                        backgroundColor: "#08C225",
                                        "&:hover": {
                                            color: "#fff",
                                            backgroundColor: "#07A820",
                                        },
                                    }}
                                >
                                    {t("try_ente")}
                                </Button>
                                <IconButton
                                    onClick={(event) =>
                                        setMenuAnchorEl(event.currentTarget)
                                    }
                                    aria-label={t("more")}
                                    sx={{
                                        color: "white",
                                        bgcolor: "rgba(0, 0, 0, 0.4)",
                                        "&:hover": {
                                            bgcolor: "rgba(0, 0, 0, 0.55)",
                                        },
                                    }}
                                >
                                    <MoreVertIcon />
                                </IconButton>
                            </Stack>
                        </Stack>
                    </Box>
                    <MoreMenu
                        open={!!menuAnchorEl}
                        anchorEl={menuAnchorEl}
                        onClose={handleMenuClose}
                        disableAutoFocusItem
                        slotProps={{ paper: { sx: { mt: "10px" } } }}
                    >
                        {enableDownload && (
                            <MoreMenuItem
                                onClick={() => {
                                    handleMenuClose();
                                    void handleDownload(file);
                                }}
                            >
                                <MoreMenuItemTitle>
                                    {t("download")}
                                </MoreMenuItemTitle>
                                <DownloadOutlinedIcon />
                            </MoreMenuItem>
                        )}
                        <MoreMenuItem onClick={handleOpenInfo}>
                            <MoreMenuItemTitle>{t("info")}</MoreMenuItemTitle>
                            <InfoOutlinedIcon />
                        </MoreMenuItem>
                        <MoreMenuItem onClick={() => void handleShare()}>
                            <MoreMenuItemTitle>
                                {t("share_action")}
                            </MoreMenuItemTitle>
                            <ShareOutlinedIcon />
                        </MoreMenuItem>
                        {canCopyAsPNG && (
                            <MoreMenuItem
                                onClick={() => void handleCopyAsPNG()}
                            >
                                <MoreMenuItemTitle>
                                    {t("copy_as_png")}
                                </MoreMenuItemTitle>
                                <ContentCopyIcon
                                    sx={{ "&&": { fontSize: "18px" } }}
                                />
                            </MoreMenuItem>
                        )}
                        <MoreMenuItem onClick={handleToggleFullscreen}>
                            <MoreMenuItemTitle>
                                {t("go_fullscreen")}
                            </MoreMenuItemTitle>
                            <FullscreenOutlinedIcon />
                        </MoreMenuItem>
                    </MoreMenu>
                </>
            )}
            {!isViewerPrimed && (
                <Box
                    sx={{
                        position: "fixed",
                        inset: 0,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        backgroundColor: "black",
                        zIndex: (theme) => theme.zIndex.modal + 2,
                    }}
                >
                    <ActivityIndicator />
                </Box>
            )}
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

const MoreMenu = styled(Menu)(
    ({ theme }) => `
    & .MuiPaper-root {
        background-color: ${theme.vars.palette.fixed.dark.background.paper};
    }
    & .MuiList-root {
        padding-block: 2px;
    }
`,
);

const MoreMenuItem = styled(MenuItem)(
    ({ theme }) => `
    min-width: 210px;
    padding-block: 12px;
    min-height: auto;
    gap: 1;
    justify-content: space-between;
    align-items: center;
    color: rgba(255 255 255 / 0.85);
    &:hover {
        color: rgba(255 255 255 / 1);
        background-color: ${theme.vars.palette.fixed.dark.background.paper2}
    }

    .MuiSvgIcon-root {
        font-size: 20px;
    }
`,
);

const MoreMenuItemTitle: React.FC<React.PropsWithChildren> = ({ children }) => (
    <Typography sx={{ fontWeight: "medium" }}>{children}</Typography>
);

/**
 * Return an "image/png" blob derived from the given source URL.
 */
const createImagePNGBlob = async (imageURL: string): Promise<Blob> =>
    new Promise((resolve, reject) => {
        const image = new Image();
        image.onload = () => {
            const canvas = document.createElement("canvas");
            canvas.width = image.width;
            canvas.height = image.height;
            canvas.getContext("2d")!.drawImage(image, 0, 0);
            canvas.toBlob(
                (blob) =>
                    blob ? resolve(blob) : reject(new Error("toBlob failed")),
                "image/png",
            );
        };
        image.onerror = reject;
        image.src = imageURL;
    });

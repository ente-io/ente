import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import FullscreenExitOutlinedIcon from "@mui/icons-material/FullscreenExitOutlined";
import FullscreenOutlinedIcon from "@mui/icons-material/FullscreenOutlined";
import InfoOutlinedIcon from "@mui/icons-material/InfoOutlined";
import {
    Box,
    CircularProgress,
    IconButton,
    styled,
    Typography,
} from "@mui/material";
import { EnteLogo } from "ente-base/components/EnteLogo";
import Head from "next/head";
import React, { useCallback, useState } from "react";
import { FileInfoPanel } from "./FileInfoPanel";
import { usePhotoShare } from "../hooks/usePhotoShare";

export const PhotoShareView: React.FC = () => {
    const [isFullscreen, setIsFullscreen] = useState(false);
    const [showFileInfo, setShowFileInfo] = useState(false);

    const {
        loading,
        downloading,
        error,
        fileInfo,
        thumbnailUrl,
        fileUrl,
        handleDownload,
        enableDownload,
    } = usePhotoShare();

    // Use full file URL if available, otherwise fall back to thumbnail
    const displayUrl = fileUrl || thumbnailUrl;
    const isVideo = fileInfo?.fileType === "video";
    const isImage = fileInfo?.fileType === "image";

    const handleToggleFullscreen = useCallback(() => {
        void (
            document.fullscreenElement
                ? document.exitFullscreen()
                : document.body.requestFullscreen()
        ).then(() => setIsFullscreen(!!document.fullscreenElement));
    }, []);

    const handleCopyAsPNG = useCallback(async () => {
        if (!displayUrl) return;
        try {
            const blob = await createImagePNGBlob(displayUrl);
            await navigator.clipboard.write([
                new ClipboardItem({ "image/png": blob }),
            ]);
        } catch (e) {
            console.error("Failed to copy image:", e);
        }
    }, [displayUrl]);

    const handleOpenFileInfo = useCallback(() => setShowFileInfo(true), []);
    const handleCloseFileInfo = useCallback(() => setShowFileInfo(false), []);

    return (
        <>
            <Head>
                <meta name="robots" content="noindex, nofollow" />
                <title>Ente Photos</title>
            </Head>
            <Box
                sx={{
                    minHeight: "100dvh",
                    bgcolor: "#000000",
                    display: "flex",
                    flexDirection: "column",
                }}
            >
                {/* Header - always visible */}
                <Box
                    sx={{
                        position: "fixed",
                        top: 0,
                        left: 0,
                        right: 0,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "space-between",
                        pl: 3,
                        pr: 1,
                        pt: 1,
                        height: 56,
                        zIndex: 10,
                        background:
                            "linear-gradient(180deg, rgba(0,0,0,0.5) 0%, rgba(0,0,0,0) 100%)",
                    }}
                >
                    <EnteLogoLink
                        href="https://ente.io"
                        target="_blank"
                        rel="noopener noreferrer"
                    >
                        <EnteLogo height={18} />
                    </EnteLogoLink>
                    {fileInfo && !loading && (
                        <Box sx={{ display: "flex", gap: 1 }}>
                            {/* Download button - only if enabled */}
                            {enableDownload && (
                                <BarIconButton
                                    title="Download"
                                    onClick={handleDownload}
                                    disabled={downloading}
                                >
                                    {downloading ? (
                                        <CircularProgress
                                            size={24}
                                            sx={{ color: "white" }}
                                        />
                                    ) : (
                                        <FileDownloadOutlinedIcon />
                                    )}
                                </BarIconButton>
                            )}
                            {/* Info button */}
                            <BarIconButton
                                title="Info"
                                onClick={handleOpenFileInfo}
                            >
                                <InfoOutlinedIcon sx={{ fontSize: 22 }} />
                            </BarIconButton>
                            {/* Copy as PNG button - only for images */}
                            {isImage && displayUrl && (
                                <BarIconButton
                                    title="Copy as PNG"
                                    onClick={handleCopyAsPNG}
                                >
                                    <ContentCopyIcon sx={{ fontSize: 18 }} />
                                </BarIconButton>
                            )}
                            {/* Fullscreen button */}
                            <BarIconButton
                                title={
                                    isFullscreen
                                        ? "Exit fullscreen"
                                        : "Fullscreen"
                                }
                                onClick={handleToggleFullscreen}
                            >
                                {isFullscreen ? (
                                    <FullscreenExitOutlinedIcon />
                                ) : (
                                    <FullscreenOutlinedIcon />
                                )}
                            </BarIconButton>
                        </Box>
                    )}
                </Box>

                {/* Main Content */}
                <Box
                    sx={{
                        flex: 1,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        position: "relative",
                    }}
                >
                    {/* Loading State */}
                    {loading && (
                        <CircularProgress
                            sx={{ color: "accent.main" }}
                            size={40}
                        />
                    )}

                    {/* Error State */}
                    {error && !loading && (
                        <Box
                            sx={{
                                textAlign: "center",
                                p: 3,
                            }}
                        >
                            <Typography variant="body" color="error">
                                {error}
                            </Typography>
                        </Box>
                    )}

                    {/* Image/Video Display */}
                    {fileInfo && !loading && !error && (
                        <>
                            {isVideo && displayUrl ? (
                                <Box
                                    component="video"
                                    src={displayUrl}
                                    controls
                                    autoPlay
                                    playsInline
                                    sx={{
                                        maxWidth: "100%",
                                        maxHeight: "100dvh",
                                        objectFit: "contain",
                                    }}
                                />
                            ) : displayUrl ? (
                                <Box
                                    component="img"
                                    src={displayUrl}
                                    alt={fileInfo.fileName}
                                    sx={{
                                        maxWidth: "100%",
                                        maxHeight: "100dvh",
                                        objectFit: "contain",
                                    }}
                                />
                            ) : (
                                // Fallback if no URL available yet
                                <Box
                                    sx={{
                                        display: "flex",
                                        flexDirection: "column",
                                        alignItems: "center",
                                        gap: 2,
                                    }}
                                >
                                    <CircularProgress
                                        sx={{ color: "accent.main" }}
                                        size={32}
                                    />
                                    <Typography
                                        variant="small"
                                        sx={{ color: "text.muted" }}
                                    >
                                        Loading file...
                                    </Typography>
                                </Box>
                            )}
                        </>
                    )}
                </Box>
            </Box>

            {/* File Info Panel */}
            {fileInfo && (
                <FileInfoPanel
                    open={showFileInfo}
                    onClose={handleCloseFileInfo}
                    fileInfo={fileInfo}
                />
            )}
        </>
    );
};

/**
 * Return a promise that resolves with a "image/png" blob derived from the given
 * {@link imageURL} that can be written to the navigator's clipboard.
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

const EnteLogoLink = styled("a")`
    line-height: 0;
    color: white;
    &:hover {
        color: white;
    }
`;

const BarIconButton = styled(IconButton)`
    color: rgba(255, 255, 255, 0.7);
    &:hover {
        color: white;
        background-color: transparent;
    }
`;


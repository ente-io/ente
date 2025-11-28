import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import {
    Box,
    CircularProgress,
    IconButton,
    Tooltip,
    Typography,
} from "@mui/material";
import Head from "next/head";
import React, { useState } from "react";
import { usePhotoShare } from "../hooks/usePhotoShare";

export const PhotoShareView: React.FC = () => {
    const [isHovering, setIsHovering] = useState(false);

    const {
        loading,
        downloading,
        error,
        fileInfo,
        thumbnailUrl,
        fileUrl,
        handleDownload,
    } = usePhotoShare();

    // Use full file URL if available, otherwise fall back to thumbnail
    const displayUrl = fileUrl || thumbnailUrl;
    const isVideo = fileInfo?.fileType === "video";

    return (
        <>
            <Head>
                <meta name="robots" content="noindex, nofollow" />
                {fileInfo?.fileName && <title>{fileInfo.fileName}</title>}
            </Head>
            <Box
                sx={{
                    minHeight: "100dvh",
                    bgcolor: "background.default",
                    display: "flex",
                    flexDirection: "column",
                }}
            >
                {/* Header */}
                <Box
                    sx={{
                        position: "fixed",
                        top: 0,
                        left: 0,
                        right: 0,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "space-between",
                        px: 2,
                        py: 1.5,
                        zIndex: 10,
                        background:
                            "linear-gradient(180deg, rgba(0,0,0,0.5) 0%, rgba(0,0,0,0) 100%)",
                        opacity: isHovering || loading ? 1 : 0,
                        transition: "opacity 0.3s ease",
                    }}
                >
                    <a
                        href="https://ente.io/photos"
                        target="_blank"
                        rel="noopener noreferrer"
                        style={{ display: "block", lineHeight: 0 }}
                    >
                        <Box
                            component="img"
                            src="/images/ente-photos-white.svg"
                            alt="Ente Photos"
                            sx={{ height: "32px", cursor: "pointer" }}
                        />
                    </a>
                    {fileInfo && !loading && (
                        <Tooltip title="Download">
                            <IconButton
                                onClick={handleDownload}
                                disabled={downloading}
                                sx={{
                                    color: "white",
                                    bgcolor: "rgba(255,255,255,0.1)",
                                    "&:hover": {
                                        bgcolor: "rgba(255,255,255,0.2)",
                                    },
                                }}
                            >
                                {downloading ? (
                                    <CircularProgress
                                        size={24}
                                        sx={{ color: "white" }}
                                    />
                                ) : (
                                    <FileDownloadOutlinedIcon />
                                )}
                            </IconButton>
                        </Tooltip>
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
                        cursor: isHovering ? "default" : "none",
                    }}
                    onMouseEnter={() => setIsHovering(true)}
                    onMouseLeave={() => setIsHovering(false)}
                    onTouchStart={() => setIsHovering(true)}
                >
                    {/* Loading State */}
                    {loading && (
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
                                size={40}
                            />
                            <Typography
                                variant="small"
                                sx={{ color: "text.muted" }}
                            >
                                Loading...
                            </Typography>
                        </Box>
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

                {/* Footer with file info */}
                {fileInfo && !loading && !error && (
                    <Box
                        sx={{
                            position: "fixed",
                            bottom: 0,
                            left: 0,
                            right: 0,
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            px: 2,
                            py: 2,
                            background:
                                "linear-gradient(0deg, rgba(0,0,0,0.5) 0%, rgba(0,0,0,0) 100%)",
                            opacity: isHovering ? 1 : 0,
                            transition: "opacity 0.3s ease",
                        }}
                    >
                        <Typography
                            variant="small"
                            sx={{
                                color: "white",
                                textAlign: "center",
                                textShadow: "0 1px 2px rgba(0,0,0,0.5)",
                            }}
                        >
                            {fileInfo.fileName}
                            {fileInfo.ownerName && (
                                <span style={{ opacity: 0.7 }}>
                                    {" "}
                                    &bull; Shared by {fileInfo.ownerName}
                                </span>
                            )}
                        </Typography>
                    </Box>
                )}
            </Box>
        </>
    );
};

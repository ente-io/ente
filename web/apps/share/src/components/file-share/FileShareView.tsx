import { Box, Button, CircularProgress, Typography } from "@mui/material";
import { Notification } from "ente-new/photos/components/Notification";
import Head from "next/head";
import React from "react";
import { useFileShare } from "../../hooks/useFileShare";
import { formatFileSize } from "../../services/file-share";
import { getLockerFileIcon } from "../../utils/file-type";
import { LockerTypeDisplay } from "./LockerTypeDisplay";

export const FileShareView: React.FC = () => {
    const {
        loading,
        downloading,
        error,
        fileInfo,
        notificationAttributes,
        handleDownload,
        handleCopyContent,
        setNotificationAttributes,
    } = useFileShare();

    return (
        <>
            <Head>
                <meta name="robots" content="noindex, nofollow" />
            </Head>
            <Box
                sx={{
                    minHeight: "100dvh",
                    bgcolor: "#1071FF",
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    padding: { xs: 1, md: 3 },
                    boxSizing: "border-box",
                }}
            >
                <Box
                    sx={{
                        minHeight: {
                            xs: "calc(100dvh - 16px)",
                            md: "calc(100dvh - 48px)",
                        },
                        width: "100%",
                        bgcolor: "#FAFAFA",
                        borderRadius: { xs: "20px", md: "40px" },
                        display: "flex",
                        flexDirection: "column",
                        alignItems: "center",
                        "& ::selection": {
                            backgroundColor: "#1071FF",
                            color: "#FFFFFF",
                        },
                        "& ::-moz-selection": {
                            backgroundColor: "#1071FF",
                            color: "#FFFFFF",
                        },
                    }}
                >
                    {/* Ente Locker Logo */}
                    <Box
                        sx={{
                            mt: { xs: 5, md: 6 },
                            mb: fileInfo?.lockerType ? { xs: 16, md: 0 } : 0,
                            alignSelf: { xs: "center", md: "flex-end" },
                            mr: { xs: 0, md: 6 },
                        }}
                    >
                        <a
                            href="https://ente.io/locker"
                            target="_blank"
                            rel="noopener noreferrer"
                            style={{ display: "block", lineHeight: 0 }}
                        >
                            <img
                                src="/images/ente-locker.svg"
                                alt="Ente Locker"
                                style={{ height: "56px", cursor: "pointer" }}
                            />
                        </a>
                    </Box>

                    {/* Main Container */}
                    <Box
                        sx={{
                            display: "flex",
                            flexDirection: "column",
                            alignItems: "center",
                            justifyContent: fileInfo?.lockerType
                                ? "flex-start"
                                : "center",
                            width: "100%",
                            maxWidth: 400,
                            flex: 1,
                            px: 3,
                            pb: 8,
                            mt: fileInfo?.lockerType
                                ? { xs: 0, md: "20dvh" }
                                : 0,
                        }}
                    >
                        {/* Loading State */}
                        {loading && (
                            <Box
                                sx={{
                                    flex: 1,
                                    display: "flex",
                                    alignItems: "center",
                                    justifyContent: "center",
                                }}
                            >
                                <CircularProgress
                                    sx={{ color: "#1071FF" }}
                                    size={32}
                                />
                            </Box>
                        )}

                        {/* Error State */}
                        {error && !loading && (
                            <Box
                                sx={{
                                    flex: 1,
                                    display: "flex",
                                    alignItems: "center",
                                    justifyContent: "center",
                                    textAlign: "center",
                                    p: 3,
                                }}
                            >
                                <Typography variant="body" color="error">
                                    {error}
                                </Typography>
                            </Box>
                        )}

                        {/* File Info Display */}
                        {fileInfo && !loading && (
                            <>
                                {/* File Info - Centered */}
                                <Box
                                    sx={{
                                        display: "flex",
                                        flexDirection: "column",
                                        alignItems: "center",
                                        justifyContent: "center",
                                        gap: 3,
                                        width: "100%",
                                        marginBottom: 4,
                                    }}
                                >
                                    {/* Large File Icon */}
                                    <Box
                                        sx={{
                                            backgroundColor: getLockerFileIcon(
                                                fileInfo.fileName,
                                                fileInfo.lockerType,
                                            ).backgroundColor,
                                            borderRadius: "20px",
                                            padding: 1.8,
                                            display: "flex",
                                            alignItems: "center",
                                            justifyContent: "center",
                                        }}
                                    >
                                        {
                                            getLockerFileIcon(
                                                fileInfo.fileName,
                                                fileInfo.lockerType,
                                            ).icon
                                        }
                                    </Box>

                                    {/* File Name */}
                                    <Typography
                                        variant="h5"
                                        sx={{
                                            fontWeight: 600,
                                            fontSize: fileInfo.lockerType
                                                ? "24px"
                                                : "22px",
                                            textAlign: "center",
                                            wordBreak: "break-word",
                                            color: "#000000",
                                        }}
                                    >
                                        {fileInfo.fileName}
                                    </Typography>

                                    {/* File Size - only show if no locker type */}
                                    {!fileInfo.lockerType && (
                                        <Typography
                                            variant="body"
                                            sx={{
                                                color: "#757575",
                                                mt: -2,
                                                fontSize: "1rem",
                                            }}
                                        >
                                            {fileInfo.fileSize > 0
                                                ? formatFileSize(
                                                      fileInfo.fileSize,
                                                  )
                                                : "Unknown size"}
                                        </Typography>
                                    )}

                                    {/* Locker Type Display */}
                                    {fileInfo.lockerType &&
                                        fileInfo.lockerInfoData && (
                                            <LockerTypeDisplay
                                                type={fileInfo.lockerType}
                                                data={fileInfo.lockerInfoData}
                                                onCopy={handleCopyContent}
                                            />
                                        )}
                                </Box>

                                {/* Download Button - Only show if not a LockerInfoType */}
                                {!fileInfo.lockerType && (
                                    <Box sx={{ width: "100%", mt: 4 }}>
                                        <Button
                                            variant="contained"
                                            size="large"
                                            fullWidth
                                            onClick={handleDownload}
                                            disabled={downloading}
                                            sx={{
                                                py: 2.5,
                                                fontSize: "1rem",
                                                fontWeight: 600,
                                                bgcolor: "#1071FF",
                                                color: "white",
                                                "&:hover": {
                                                    bgcolor: "#0056CC",
                                                },
                                                "&:disabled": {
                                                    bgcolor: "#1071FF",
                                                    color: "white",
                                                    opacity: 0.7,
                                                },
                                                borderRadius: "22px",
                                                textTransform: "none",
                                            }}
                                        >
                                            {downloading ? (
                                                <>
                                                    <CircularProgress
                                                        size={20}
                                                        sx={{
                                                            mr: 1,
                                                            color: "white",
                                                        }}
                                                    />
                                                    Downloading...
                                                </>
                                            ) : (
                                                "Download"
                                            )}
                                        </Button>
                                    </Box>
                                )}
                            </>
                        )}
                    </Box>

                    <Notification
                        open={!!notificationAttributes}
                        onClose={() => setNotificationAttributes(undefined)}
                        attributes={notificationAttributes}
                    />
                </Box>
            </Box>
        </>
    );
};

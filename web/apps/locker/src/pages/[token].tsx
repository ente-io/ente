import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import {
    Box,
    Button,
    CircularProgress,
    IconButton,
    Typography,
} from "@mui/material";
import bs58 from "bs58";
import { EnteLogo } from "ente-base/components/EnteLogo";
import {
    decryptBoxBytes,
    decryptMetadataJSON,
    decryptStreamBytes,
    fromHex,
    toB64,
} from "ente-base/crypto";
import { apiOrigin } from "ente-base/origins";
import type { NotificationAttributes } from "ente-new/photos/components/Notification";
import { Notification } from "ente-new/photos/components/Notification";
import { useRouter } from "next/router";
import React, { useEffect, useState } from "react";
import { getLockerFileIcon } from "../utils/file-type";

const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return "0 Bytes";

    const sizes = ["Bytes", "KB", "MB", "GB", "TB"];
    const k = 1024;
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    const size = bytes / Math.pow(k, i);

    return `${Math.round(size)} ${sizes[i]}`;
};

interface FileLinkInfo {
    file?: {
        id?: number;
        ownerID?: number;
        collectionID?: number;
        encryptedKey?: string;
        keyDecryptionNonce?: string;
        file?: { decryptionHeader?: string; size?: number };
        thumbnail?: { decryptionHeader?: string; size?: number };
        metadata?: {
            encryptedData?: string;
            decryptionHeader?: string;
            size?: number;
        };
        info?: { fileSize?: number; thumbSize?: number };
        isDeleted?: boolean;
        updationTime?: number;
        pubMagicMetadata?: {
            version?: number;
            count?: number;
            data?: string;
            header?: string;
        };
        // Legacy field names
        encryptedMetadata?: string;
        metadataDecryptionHeader?: string;
        fileSize?: number;
        uploadedTime?: number;
    };
    ownerName?: string;
}

interface DecryptedFileInfo {
    id: number;
    fileName: string;
    fileSize: number;
    uploadedTime: number;
    ownerName?: string;
    fileDecryptionHeader?: string;
    fileNonce?: string;
    fileKey?: string;
    lockerType?: string; // Locker file type from pubMagicMetadata.info
    lockerInfoData?: any; // Data from pubMagicMetadata.info.data
}

// Extract file key from URL hash (similar to extractCollectionKeyFromShareURL)
const extractFileKeyFromURL = async (url: URL): Promise<string | null> => {
    const hashValue = url.hash.slice(1); // Remove '#' prefix
    if (!hashValue) return null;

    try {
        let decodedKey: string;
        // Support both base58 and hex encoding
        if (hashValue.length < 50) {
            // Base58 encoded - convert to base64
            const decoded = bs58.decode(hashValue);
            decodedKey = await toB64(decoded);
        } else {
            // Hex encoded - convert to base64
            decodedKey = await fromHex(hashValue);
        }
        return decodedKey;
    } catch (error) {
        return null;
    }
};

// Fetch file info from the server
const fetchFileInfo = async (accessToken: string): Promise<FileLinkInfo> => {
    const url = `${await apiOrigin()}/file-link/info?accessToken=${accessToken}`;

    const response = await fetch(url, {
        headers: { "X-Auth-Access-Token": accessToken },
    });

    if (!response.ok) {
        throw new Error(`Failed to fetch file info: ${response.statusText}`);
    }

    const data = await response.json();
    return data;
};

// Decrypt file metadata using the file key
const decryptFileInfo = async (
    fileLinkInfo: FileLinkInfo,
    linkKey: string,
): Promise<DecryptedFileInfo> => {
    try {
        const file = fileLinkInfo.file;
        const ownerName = fileLinkInfo.ownerName;

        if (!file) {
            throw new Error("No file object in response");
        }

        // Try to decrypt the file key if it exists
        let fileKey = linkKey; // Default to link key

        if (file.encryptedKey && file.keyDecryptionNonce) {
            try {
                const decryptedKeyBytes = await decryptBoxBytes(
                    {
                        encryptedData: file.encryptedKey,
                        nonce: file.keyDecryptionNonce,
                    },
                    linkKey,
                );
                fileKey = await toB64(decryptedKeyBytes);
            } catch (error) {
                // If decryption fails, assume the link key IS the file key
                fileKey = linkKey;
            }
        }

        // Get file ID
        const fileId = file.id || 0;

        // Get upload/update time
        const uploadedTime = file.updationTime || 0;

        // Get file size from info field
        const fileSizeFromInfo = file.info?.fileSize || 0;
        console.log("file.info:", file.info);
        console.log("fileSizeFromInfo:", fileSizeFromInfo);

        // Extract nested encrypted metadata and decryption header
        const encryptedMetadata =
            file.metadata?.encryptedData || file.encryptedMetadata;
        const metadataDecryptionHeader =
            file.metadata?.decryptionHeader || file.metadataDecryptionHeader;

        // Extract file decryption header from nested structure
        const fileDecryptionHeader = file.file?.decryptionHeader;

        // Check if we have the necessary fields for decryption
        if (!encryptedMetadata || !metadataDecryptionHeader) {
            return {
                id: fileId,
                fileName: "Unknown file",
                fileSize:
                    fileSizeFromInfo || file.file?.size || file.fileSize || 0,
                uploadedTime: uploadedTime,
                ownerName: ownerName,
                fileDecryptionHeader: fileDecryptionHeader,
                fileNonce: undefined,
                fileKey: fileKey,
            };
        }

        // Try decryption with the extracted fields
        let metadata: any;

        try {
            // Use the decryption header format
            const decryptedMetadata = await decryptMetadataJSON(
                {
                    encryptedData: encryptedMetadata,
                    decryptionHeader: metadataDecryptionHeader,
                },
                fileKey,
            );
            metadata = decryptedMetadata as any;
            console.log("Decrypted metadata:", metadata);
        } catch (err) {
            metadata = {};
        }

        // Try to decrypt pubMagicMetadata if it exists
        let pubMagicMetadata: any = null;
        if (file.pubMagicMetadata?.data && file.pubMagicMetadata?.header) {
            try {
                const decryptedPubMagicMetadata = await decryptMetadataJSON(
                    {
                        encryptedData: file.pubMagicMetadata.data,
                        decryptionHeader: file.pubMagicMetadata.header,
                    },
                    fileKey,
                );
                pubMagicMetadata = decryptedPubMagicMetadata;
            } catch (err) {
                // Failed to decrypt pubMagicMetadata
            }
        }

        // Extract and parse info from pubMagicMetadata
        console.log("pubMagicMetadata:", pubMagicMetadata);
        console.log("pubMagicMetadata?.info:", pubMagicMetadata?.info);

        // Check if info is a JSON string that needs parsing
        let infoObject = pubMagicMetadata?.info;
        if (typeof infoObject === "string") {
            try {
                infoObject = JSON.parse(infoObject);
                console.log("Parsed info object:", infoObject);
            } catch (e) {
                console.log("Failed to parse info as JSON");
            }
        }

        const lockerType = infoObject?.type;
        console.log("Extracted lockerType:", lockerType);

        // Log full info for LockerInfoType cases
        if (lockerType) {
            console.log(
                "LockerInfoType detected - Full info object:",
                infoObject,
            );
        }

        // Extract file info from decrypted metadata
        const fileName =
            metadata.fileName ||
            metadata.title ||
            metadata.name ||
            "Unknown file";

        // Check if there's file size in pubMagicMetadata.info.data
        const pubMagicFileSize = infoObject?.data?.size;
        console.log("pubMagicFileSize:", pubMagicFileSize);

        // Use fileSize from info field first, then fall back to metadata or other sources
        const fileSize =
            pubMagicFileSize ||
            fileSizeFromInfo ||
            metadata.fileSize ||
            metadata.size ||
            file.file?.size ||
            0;
        const metadataUploadTime =
            metadata.uploadedTime ||
            metadata.createdAt ||
            metadata.modificationTime;

        const decryptedFileInfo = {
            id: fileId,
            fileName: fileName,
            fileSize: fileSize,
            uploadedTime: metadataUploadTime || uploadedTime,
            ownerName: ownerName,
            fileDecryptionHeader: fileDecryptionHeader,
            fileNonce: undefined,
            fileKey: fileKey,
            lockerType: lockerType,
            lockerInfoData: infoObject?.data,
        };

        console.log("Final decryptedFileInfo:", decryptedFileInfo);

        return decryptedFileInfo;
    } catch (error) {
        // Return partial info if decryption fails
        if (!fileLinkInfo.file) {
            return {
                id: 0,
                fileName: "Error: No file data",
                fileSize: 0,
                uploadedTime: 0,
                ownerName: fileLinkInfo.ownerName,
                fileDecryptionHeader: undefined,
                fileNonce: undefined,
                fileKey: linkKey,
            };
        }

        const file = fileLinkInfo.file;
        const fileId = file.id || 0;
        const uploadedTime = file.updationTime || 0;
        const fileDecryptionHeader = file.file?.decryptionHeader;
        const fileSizeFromInfo = file.info?.fileSize || 0;

        return {
            id: fileId,
            fileName: "Encrypted file",
            fileSize: fileSizeFromInfo || file.file?.size || 0,
            uploadedTime: uploadedTime,
            ownerName: fileLinkInfo.ownerName,
            fileDecryptionHeader: fileDecryptionHeader,
            fileNonce: undefined,
            fileKey: linkKey,
        };
    }
};

// Download and decrypt file
const downloadFile = async (
    accessToken: string,
    fileKey: string,
    fileName: string,
    fileDecryptionHeader?: string,
    fileNonce?: string,
) => {
    try {
        const url = `${await apiOrigin()}/file-link/file?accessToken=${accessToken}`;

        // Fetch the encrypted file from the server
        const response = await fetch(url, {
            headers: { "X-Auth-Access-Token": accessToken },
        });

        if (!response.ok) {
            throw new Error(`Failed to download file: ${response.statusText}`);
        }

        // Get the response stream
        const body = response.body;
        if (!body) {
            throw new Error("Response body is empty");
        }

        // For now, we'll do a simpler approach - download the entire file and decrypt it
        // In production, you'd want to stream the decryption for large files
        const encryptedData = new Uint8Array(await response.arrayBuffer());

        let decryptedData: Uint8Array;

        if (fileDecryptionHeader) {
            // Modern format: Decrypt the file using the decryption header
            decryptedData = await decryptStreamBytes(
                { encryptedData, decryptionHeader: fileDecryptionHeader },
                fileKey,
            );
        } else if (fileNonce) {
            // Legacy format: Use box decryption with nonce
            decryptedData = await decryptBoxBytes(
                { encryptedData: await toB64(encryptedData), nonce: fileNonce },
                fileKey,
            );
        } else {
            // No encryption information, return as is
            decryptedData = encryptedData;
        }

        // Create a blob from the decrypted data
        const blob = new Blob([new Uint8Array(decryptedData)]);

        // Create download link
        const blobUrl = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = blobUrl;
        a.download = fileName;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(blobUrl);
    } catch (error) {
        throw error;
    }
};

const FilePage: React.FC = () => {
    const router = useRouter();
    const [loading, setLoading] = useState(true);
    const [downloading, setDownloading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [fileInfo, setFileInfo] = useState<DecryptedFileInfo | null>(null);
    const [accessToken, setAccessToken] = useState<string | null>(null);
    const [notificationAttributes, setNotificationAttributes] =
        useState<NotificationAttributes>();

    useEffect(() => {
        const loadFileInfo = async () => {
            try {
                // Get the token from the URL path parameter
                const { token } = router.query;

                if (!token || typeof token !== "string") {
                    setError("Invalid file link. Missing access token.");
                    setLoading(false);
                    return;
                }

                const currentURL = new URL(window.location.href);
                const key = await extractFileKeyFromURL(currentURL);

                if (!key) {
                    setError("Invalid file link. Missing file key.");
                    setLoading(false);
                    return;
                }

                setAccessToken(token);

                // Fetch file info from server
                const encryptedInfo = await fetchFileInfo(token);

                // Decrypt file info
                const decryptedInfo = await decryptFileInfo(encryptedInfo, key);

                // Check if decryption failed (invalid key)
                if (
                    decryptedInfo.fileName === "Unknown file" ||
                    decryptedInfo.fileName === "Encrypted file" ||
                    decryptedInfo.fileName === "Error: No file data"
                ) {
                    setError("File not found");
                    setFileInfo(null);
                } else {
                    setFileInfo(decryptedInfo);
                }
            } catch (err) {
                setError(
                    err instanceof Error
                        ? err.message
                        : "Failed to load file information",
                );
            } finally {
                setLoading(false);
            }
        };

        // Only load when router is ready
        if (router.isReady) {
            void loadFileInfo();
        }
    }, [router.isReady, router.query]);

    const handleDownload = async () => {
        if (!accessToken || !fileInfo?.fileKey) return;

        setDownloading(true);
        try {
            await downloadFile(
                accessToken,
                fileInfo.fileKey,
                fileInfo.fileName,
                fileInfo.fileDecryptionHeader,
                fileInfo.fileNonce,
            );
        } catch (err) {
            setError(
                err instanceof Error ? err.message : "Failed to download file",
            );
        } finally {
            setDownloading(false);
        }
    };

    const handleCopyContent = async (content: string) => {
        try {
            await navigator.clipboard.writeText(content);
            setNotificationAttributes({
                color: "secondary",
                title: "Copied to clipboard",
            });
        } catch (err) {
            setNotificationAttributes({
                color: "critical",
                title: "Failed to copy",
            });
        }
    };

    return (
        <Box
            sx={{
                minHeight: "100vh",
                bgcolor: "#FAFAFA",
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                padding: { xs: 0, md: 3 },
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
            {/* Ente Logo - Always at the top */}
            <Box
                sx={{
                    mt: { xs: 3, md: 6 },
                    mb: fileInfo?.lockerType ? 20 : { xs: 20, md: 6 },
                    "& svg": { fill: "#000000" },
                }}
            >
                <EnteLogo />
            </Box>

            {/* Main Container - Centers the file content */}
            <Box
                sx={{
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    justifyContent: { xs: "flex-start", md: "center" },
                    width: "100%",
                    maxWidth: 400,
                    flex: 1,
                    px: 3,
                    pb: { xs: 3, md: 0 },
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
                        <CircularProgress sx={{ color: "#1071FF" }} size={32} />
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
                {fileInfo &&
                    !loading &&
                    (() => {
                        const iconInfo = getLockerFileIcon(
                            fileInfo.fileName,
                            fileInfo.lockerType,
                        );
                        return (
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
                                            backgroundColor:
                                                iconInfo.backgroundColor,
                                            borderRadius: "20px",
                                            padding: 1.8,
                                            display: "flex",
                                            alignItems: "center",
                                            justifyContent: "center",
                                        }}
                                    >
                                        {iconInfo.icon}
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

                                    {/* Note Content - show for note type */}
                                    {fileInfo.lockerType === "note" &&
                                        fileInfo.lockerInfoData?.content && (
                                            <Box sx={{ width: "100%", mt: 2 }}>
                                                <Typography
                                                    variant="h6"
                                                    sx={{
                                                        fontWeight: 500,
                                                        fontSize: "16px",
                                                        color: "#000000",
                                                        mb: 1,
                                                        mt: 3,
                                                    }}
                                                >
                                                    Content
                                                </Typography>
                                                <Box
                                                    sx={{
                                                        position: "relative",
                                                    }}
                                                >
                                                    <Box
                                                        sx={{
                                                            p: 4,
                                                            bgcolor: "#FFFFFF",
                                                            borderRadius:
                                                                "12px",
                                                        }}
                                                    >
                                                        <Typography
                                                            variant="body1"
                                                            sx={{
                                                                color: "#757575",
                                                                whiteSpace:
                                                                    "pre-wrap",
                                                                wordBreak:
                                                                    "break-word",
                                                            }}
                                                        >
                                                            {
                                                                fileInfo
                                                                    .lockerInfoData
                                                                    .content
                                                            }
                                                        </Typography>
                                                    </Box>
                                                    {/* Copy Button */}
                                                    <IconButton
                                                        onClick={() =>
                                                            handleCopyContent(
                                                                fileInfo
                                                                    .lockerInfoData
                                                                    .content,
                                                            )
                                                        }
                                                        sx={{
                                                            position:
                                                                "absolute",
                                                            top: 8,
                                                            right: 8,
                                                            color: "#757575",
                                                            "&:hover": {
                                                                bgcolor:
                                                                    "rgba(0, 0, 0, 0.04)",
                                                            },
                                                        }}
                                                    >
                                                        <ContentCopyIcon fontSize="small" />
                                                    </IconButton>
                                                </Box>
                                            </Box>
                                        )}

                                    {/* Physical Record - show for physicalRecord type */}
                                    {fileInfo.lockerType === "physicalRecord" &&
                                        fileInfo.lockerInfoData && (
                                            <Box
                                                sx={{
                                                    width: "100%",
                                                    mt: 2,
                                                    display: "flex",
                                                    flexDirection: "column",
                                                    gap: 2,
                                                }}
                                            >
                                                {/* Location */}
                                                {fileInfo.lockerInfoData
                                                    .location && (
                                                    <Box>
                                                        <Typography
                                                            variant="h6"
                                                            sx={{
                                                                fontWeight: 500,
                                                                fontSize:
                                                                    "16px",
                                                                color: "#000000",
                                                                mb: 1,
                                                                mt: 3,
                                                            }}
                                                        >
                                                            Location
                                                        </Typography>
                                                        <Box
                                                            sx={{
                                                                position:
                                                                    "relative",
                                                            }}
                                                        >
                                                            <Box
                                                                sx={{
                                                                    px: 4,
                                                                    py: 2,
                                                                    bgcolor:
                                                                        "#FFFFFF",
                                                                    borderRadius:
                                                                        "12px",
                                                                }}
                                                            >
                                                                <Typography
                                                                    variant="body1"
                                                                    sx={{
                                                                        color: "#757575",
                                                                        whiteSpace:
                                                                            "pre-wrap",
                                                                        wordBreak:
                                                                            "break-word",
                                                                    }}
                                                                >
                                                                    {
                                                                        fileInfo
                                                                            .lockerInfoData
                                                                            .location
                                                                    }
                                                                </Typography>
                                                            </Box>
                                                            <IconButton
                                                                onClick={() =>
                                                                    handleCopyContent(
                                                                        fileInfo
                                                                            .lockerInfoData
                                                                            .location,
                                                                    )
                                                                }
                                                                sx={{
                                                                    position:
                                                                        "absolute",
                                                                    top: 8,
                                                                    right: 8,
                                                                    color: "#757575",
                                                                    "&:hover": {
                                                                        bgcolor:
                                                                            "rgba(0, 0, 0, 0.04)",
                                                                    },
                                                                }}
                                                            >
                                                                <ContentCopyIcon fontSize="small" />
                                                            </IconButton>
                                                        </Box>
                                                    </Box>
                                                )}

                                                {/* Notes */}
                                                {fileInfo.lockerInfoData
                                                    .notes && (
                                                    <Box>
                                                        <Typography
                                                            variant="h6"
                                                            sx={{
                                                                fontWeight: 500,
                                                                fontSize:
                                                                    "16px",
                                                                color: "#000000",
                                                                mb: 1,
                                                                mt: 3,
                                                            }}
                                                        >
                                                            Notes
                                                        </Typography>
                                                        <Box
                                                            sx={{
                                                                position:
                                                                    "relative",
                                                            }}
                                                        >
                                                            <Box
                                                                sx={{
                                                                    p: 4,
                                                                    bgcolor:
                                                                        "#FFFFFF",
                                                                    borderRadius:
                                                                        "12px",
                                                                }}
                                                            >
                                                                <Typography
                                                                    variant="body1"
                                                                    sx={{
                                                                        color: "#757575",
                                                                        whiteSpace:
                                                                            "pre-wrap",
                                                                        wordBreak:
                                                                            "break-word",
                                                                    }}
                                                                >
                                                                    {
                                                                        fileInfo
                                                                            .lockerInfoData
                                                                            .notes
                                                                    }
                                                                </Typography>
                                                            </Box>
                                                            <IconButton
                                                                onClick={() =>
                                                                    handleCopyContent(
                                                                        fileInfo
                                                                            .lockerInfoData
                                                                            .notes,
                                                                    )
                                                                }
                                                                sx={{
                                                                    position:
                                                                        "absolute",
                                                                    top: 8,
                                                                    right: 8,
                                                                    color: "#757575",
                                                                    "&:hover": {
                                                                        bgcolor:
                                                                            "rgba(0, 0, 0, 0.04)",
                                                                    },
                                                                }}
                                                            >
                                                                <ContentCopyIcon fontSize="small" />
                                                            </IconButton>
                                                        </Box>
                                                    </Box>
                                                )}
                                            </Box>
                                        )}

                                    {/* Account Credential - show for accountCredential type */}
                                    {fileInfo.lockerType ===
                                        "accountCredential" &&
                                        fileInfo.lockerInfoData && (
                                            <Box
                                                sx={{
                                                    width: "100%",
                                                    mt: 2,
                                                    display: "flex",
                                                    flexDirection: "column",
                                                    gap: 2,
                                                }}
                                            >
                                                {/* Username */}
                                                {fileInfo.lockerInfoData
                                                    .username && (
                                                    <Box>
                                                        <Typography
                                                            variant="h6"
                                                            sx={{
                                                                fontWeight: 500,
                                                                fontSize:
                                                                    "16px",
                                                                color: "#000000",
                                                                mb: 1,
                                                                mt: 3,
                                                            }}
                                                        >
                                                            Username
                                                        </Typography>
                                                        <Box
                                                            sx={{
                                                                position:
                                                                    "relative",
                                                            }}
                                                        >
                                                            <Box
                                                                sx={{
                                                                    px: 4,
                                                                    py: 2,
                                                                    bgcolor:
                                                                        "#FFFFFF",
                                                                    borderRadius:
                                                                        "12px",
                                                                }}
                                                            >
                                                                <Typography
                                                                    variant="body1"
                                                                    sx={{
                                                                        color: "#757575",
                                                                        whiteSpace:
                                                                            "pre-wrap",
                                                                        wordBreak:
                                                                            "break-word",
                                                                    }}
                                                                >
                                                                    {
                                                                        fileInfo
                                                                            .lockerInfoData
                                                                            .username
                                                                    }
                                                                </Typography>
                                                            </Box>
                                                            <IconButton
                                                                onClick={() =>
                                                                    handleCopyContent(
                                                                        fileInfo
                                                                            .lockerInfoData
                                                                            .username,
                                                                    )
                                                                }
                                                                sx={{
                                                                    position:
                                                                        "absolute",
                                                                    top: 8,
                                                                    right: 8,
                                                                    color: "#757575",
                                                                    "&:hover": {
                                                                        bgcolor:
                                                                            "rgba(0, 0, 0, 0.04)",
                                                                    },
                                                                }}
                                                            >
                                                                <ContentCopyIcon fontSize="small" />
                                                            </IconButton>
                                                        </Box>
                                                    </Box>
                                                )}

                                                {/* Password */}
                                                {fileInfo.lockerInfoData
                                                    .password && (
                                                    <Box>
                                                        <Typography
                                                            variant="h6"
                                                            sx={{
                                                                fontWeight: 500,
                                                                fontSize:
                                                                    "16px",
                                                                color: "#000000",
                                                                mb: 1,
                                                                mt: 3,
                                                            }}
                                                        >
                                                            Password
                                                        </Typography>
                                                        <Box
                                                            sx={{
                                                                position:
                                                                    "relative",
                                                            }}
                                                        >
                                                            <Box
                                                                sx={{
                                                                    px: 4,
                                                                    py: 2,
                                                                    bgcolor:
                                                                        "#FFFFFF",
                                                                    borderRadius:
                                                                        "12px",
                                                                }}
                                                            >
                                                                <Typography
                                                                    variant="body1"
                                                                    sx={{
                                                                        color: "#757575",
                                                                        whiteSpace:
                                                                            "pre-wrap",
                                                                        wordBreak:
                                                                            "break-word",
                                                                    }}
                                                                >
                                                                    {
                                                                        fileInfo
                                                                            .lockerInfoData
                                                                            .password
                                                                    }
                                                                </Typography>
                                                            </Box>
                                                            <IconButton
                                                                onClick={() =>
                                                                    handleCopyContent(
                                                                        fileInfo
                                                                            .lockerInfoData
                                                                            .password,
                                                                    )
                                                                }
                                                                sx={{
                                                                    position:
                                                                        "absolute",
                                                                    top: 8,
                                                                    right: 8,
                                                                    color: "#757575",
                                                                    "&:hover": {
                                                                        bgcolor:
                                                                            "rgba(0, 0, 0, 0.04)",
                                                                    },
                                                                }}
                                                            >
                                                                <ContentCopyIcon fontSize="small" />
                                                            </IconButton>
                                                        </Box>
                                                    </Box>
                                                )}

                                                {/* Notes */}
                                                {fileInfo.lockerInfoData
                                                    .notes && (
                                                    <Box>
                                                        <Typography
                                                            variant="h6"
                                                            sx={{
                                                                fontWeight: 500,
                                                                fontSize:
                                                                    "16px",
                                                                color: "#000000",
                                                                mb: 1,
                                                                mt: 3,
                                                            }}
                                                        >
                                                            Notes
                                                        </Typography>
                                                        <Box
                                                            sx={{
                                                                position:
                                                                    "relative",
                                                            }}
                                                        >
                                                            <Box
                                                                sx={{
                                                                    p: 4,
                                                                    bgcolor:
                                                                        "#FFFFFF",
                                                                    borderRadius:
                                                                        "12px",
                                                                }}
                                                            >
                                                                <Typography
                                                                    variant="body1"
                                                                    sx={{
                                                                        color: "#757575",
                                                                        whiteSpace:
                                                                            "pre-wrap",
                                                                        wordBreak:
                                                                            "break-word",
                                                                    }}
                                                                >
                                                                    {
                                                                        fileInfo
                                                                            .lockerInfoData
                                                                            .notes
                                                                    }
                                                                </Typography>
                                                            </Box>
                                                            <IconButton
                                                                onClick={() =>
                                                                    handleCopyContent(
                                                                        fileInfo
                                                                            .lockerInfoData
                                                                            .notes,
                                                                    )
                                                                }
                                                                sx={{
                                                                    position:
                                                                        "absolute",
                                                                    top: 8,
                                                                    right: 8,
                                                                    color: "#757575",
                                                                    "&:hover": {
                                                                        bgcolor:
                                                                            "rgba(0, 0, 0, 0.04)",
                                                                    },
                                                                }}
                                                            >
                                                                <ContentCopyIcon fontSize="small" />
                                                            </IconButton>
                                                        </Box>
                                                    </Box>
                                                )}
                                            </Box>
                                        )}

                                    {/* Emergency Contact - show for emergencyContact type */}
                                    {fileInfo.lockerType ===
                                        "emergencyContact" &&
                                        fileInfo.lockerInfoData && (
                                            <Box
                                                sx={{
                                                    width: "100%",
                                                    mt: 2,
                                                    display: "flex",
                                                    flexDirection: "column",
                                                    gap: 2,
                                                }}
                                            >
                                                {/* Contact Details */}
                                                {fileInfo.lockerInfoData
                                                    .contactDetails && (
                                                    <Box>
                                                        <Typography
                                                            variant="h6"
                                                            sx={{
                                                                fontWeight: 500,
                                                                fontSize:
                                                                    "16px",
                                                                color: "#000000",
                                                                mb: 1,
                                                                mt: 3,
                                                            }}
                                                        >
                                                            Contact
                                                        </Typography>
                                                        <Box
                                                            sx={{
                                                                position:
                                                                    "relative",
                                                            }}
                                                        >
                                                            <Box
                                                                sx={{
                                                                    px: 4,
                                                                    py: 2,
                                                                    bgcolor:
                                                                        "#FFFFFF",
                                                                    borderRadius:
                                                                        "12px",
                                                                }}
                                                            >
                                                                <Typography
                                                                    variant="body1"
                                                                    sx={{
                                                                        color: "#757575",
                                                                        whiteSpace:
                                                                            "pre-wrap",
                                                                        wordBreak:
                                                                            "break-word",
                                                                    }}
                                                                >
                                                                    {
                                                                        fileInfo
                                                                            .lockerInfoData
                                                                            .contactDetails
                                                                    }
                                                                </Typography>
                                                            </Box>
                                                            <IconButton
                                                                onClick={() =>
                                                                    handleCopyContent(
                                                                        fileInfo
                                                                            .lockerInfoData
                                                                            .contactDetails,
                                                                    )
                                                                }
                                                                sx={{
                                                                    position:
                                                                        "absolute",
                                                                    top: 8,
                                                                    right: 8,
                                                                    color: "#757575",
                                                                    "&:hover": {
                                                                        bgcolor:
                                                                            "rgba(0, 0, 0, 0.04)",
                                                                    },
                                                                }}
                                                            >
                                                                <ContentCopyIcon fontSize="small" />
                                                            </IconButton>
                                                        </Box>
                                                    </Box>
                                                )}

                                                {/* Notes */}
                                                {fileInfo.lockerInfoData
                                                    .notes && (
                                                    <Box>
                                                        <Typography
                                                            variant="h6"
                                                            sx={{
                                                                fontWeight: 500,
                                                                fontSize:
                                                                    "16px",
                                                                color: "#000000",
                                                                mb: 1,
                                                                mt: 3,
                                                            }}
                                                        >
                                                            Notes
                                                        </Typography>
                                                        <Box
                                                            sx={{
                                                                position:
                                                                    "relative",
                                                            }}
                                                        >
                                                            <Box
                                                                sx={{
                                                                    p: 4,
                                                                    bgcolor:
                                                                        "#FFFFFF",
                                                                    borderRadius:
                                                                        "12px",
                                                                }}
                                                            >
                                                                <Typography
                                                                    variant="body1"
                                                                    sx={{
                                                                        color: "#757575",
                                                                        whiteSpace:
                                                                            "pre-wrap",
                                                                        wordBreak:
                                                                            "break-word",
                                                                    }}
                                                                >
                                                                    {
                                                                        fileInfo
                                                                            .lockerInfoData
                                                                            .notes
                                                                    }
                                                                </Typography>
                                                            </Box>
                                                            <IconButton
                                                                onClick={() =>
                                                                    handleCopyContent(
                                                                        fileInfo
                                                                            .lockerInfoData
                                                                            .notes,
                                                                    )
                                                                }
                                                                sx={{
                                                                    position:
                                                                        "absolute",
                                                                    top: 8,
                                                                    right: 8,
                                                                    color: "#757575",
                                                                    "&:hover": {
                                                                        bgcolor:
                                                                            "rgba(0, 0, 0, 0.04)",
                                                                    },
                                                                }}
                                                            >
                                                                <ContentCopyIcon fontSize="small" />
                                                            </IconButton>
                                                        </Box>
                                                    </Box>
                                                )}
                                            </Box>
                                        )}
                                </Box>

                                {/* Download Button */}
                                {/* Only show download button if not a LockerInfoType */}
                                {!fileInfo.lockerType && (
                                    <Box
                                        sx={{
                                            width: "100%",
                                            mt: 4,
                                        }}
                                    >
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
                        );
                    })()}
            </Box>

            <Notification
                open={!!notificationAttributes}
                onClose={() => setNotificationAttributes(undefined)}
                attributes={notificationAttributes}
            />
        </Box>
    );
};

export default FilePage;

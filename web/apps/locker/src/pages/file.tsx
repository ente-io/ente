import { Box, Button, CircularProgress, Typography } from "@mui/material";
// File type icons
import ArticleIcon from "@mui/icons-material/Article";
import AudioFileIcon from "@mui/icons-material/AudioFile";
import CodeIcon from "@mui/icons-material/Code";
import FolderZipIcon from "@mui/icons-material/FolderZip";
import ImageIcon from "@mui/icons-material/Image";
import InsertDriveFileIcon from "@mui/icons-material/InsertDriveFile";
import PictureAsPdfIcon from "@mui/icons-material/PictureAsPdf";
import VideoFileIcon from "@mui/icons-material/VideoFile";
import bs58 from "bs58";
import { EnteLogo } from "ente-base/components/EnteLogo";
import {
    decryptBoxBytes,
    decryptMetadataJSON,
    decryptStreamBytes,
    fromHex,
    toB64,
} from "ente-base/crypto";
import React, { useEffect, useState } from "react";

// Configure the server URL for file-link APIs
// TODO: Make this configurable via environment variables or settings
const FILE_LINK_SERVER = "https://f302453e6289.ngrok-free.app";

// Toggle to use mock data when server is down
// Set to false when server is back online
const USE_MOCK_DATA = true;

// Format file size in human-readable format
const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return "0 Bytes";

    const sizes = ["Bytes", "KB", "MB", "GB", "TB"];
    const k = 1024;
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    const size = bytes / Math.pow(k, i);

    // Round to nearest integer for all units
    return `${Math.round(size)} ${sizes[i]}`;
};

// Get file extension from filename
const getFileExtension = (fileName: string): string => {
    const lastDotIndex = fileName.lastIndexOf(".");
    if (lastDotIndex === -1 || lastDotIndex === fileName.length - 1) {
        return "";
    }
    return fileName.substring(lastDotIndex + 1).toLowerCase();
};

// Get appropriate icon component based on file extension
const getFileIcon = (fileName: string, size = 48) => {
    const extension = getFileExtension(fileName);

    // Image formats
    const imageExtensions = [
        "jpg",
        "jpeg",
        "png",
        "gif",
        "bmp",
        "svg",
        "webp",
        "ico",
        "heic",
        "heif",
        "raw",
        "tiff",
        "tif",
    ];
    // Video formats
    const videoExtensions = [
        "mp4",
        "avi",
        "mov",
        "wmv",
        "flv",
        "mkv",
        "webm",
        "m4v",
        "mpg",
        "mpeg",
        "3gp",
    ];
    // Audio formats
    const audioExtensions = [
        "mp3",
        "wav",
        "flac",
        "aac",
        "ogg",
        "wma",
        "m4a",
        "opus",
        "aiff",
    ];
    // Document formats
    const documentExtensions = ["doc", "docx", "odt", "rtf", "tex", "wpd"];
    // Code formats
    const codeExtensions = [
        "js",
        "jsx",
        "ts",
        "tsx",
        "html",
        "css",
        "scss",
        "json",
        "xml",
        "py",
        "java",
        "c",
        "cpp",
        "h",
        "cs",
        "php",
        "rb",
        "go",
        "rs",
        "kt",
        "swift",
        "sh",
        "yaml",
        "yml",
        "toml",
        "ini",
        "cfg",
        "conf",
    ];
    // Archive formats
    const archiveExtensions = [
        "zip",
        "rar",
        "7z",
        "tar",
        "gz",
        "bz2",
        "xz",
        "iso",
    ];

    // All icons are gray (#757575)
    const iconColor = "#757575";

    if (imageExtensions.includes(extension)) {
        return <ImageIcon sx={{ fontSize: size, color: iconColor }} />;
    } else if (videoExtensions.includes(extension)) {
        return <VideoFileIcon sx={{ fontSize: size, color: iconColor }} />;
    } else if (audioExtensions.includes(extension)) {
        return <AudioFileIcon sx={{ fontSize: size, color: iconColor }} />;
    } else if (extension === "pdf") {
        return <PictureAsPdfIcon sx={{ fontSize: size, color: iconColor }} />;
    } else if (documentExtensions.includes(extension) || extension === "txt") {
        return <ArticleIcon sx={{ fontSize: size, color: iconColor }} />;
    } else if (codeExtensions.includes(extension)) {
        return <CodeIcon sx={{ fontSize: size, color: iconColor }} />;
    } else if (archiveExtensions.includes(extension)) {
        return <FolderZipIcon sx={{ fontSize: size, color: iconColor }} />;
    } else {
        return (
            <InsertDriveFileIcon sx={{ fontSize: size, color: iconColor }} />
        );
    }
};

// Response from file-link/info API
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
    [key: string]: any; // Allow additional fields
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

// Mock response for when the server is down
const MOCK_FILE_INFO: FileLinkInfo = {
    file: {
        id: 10003111,
        ownerID: 1580559962386481,
        collectionID: 0,
        encryptedKey: "",
        keyDecryptionNonce: "",
        file: { decryptionHeader: "4p9rGKcAEjTHzO9nx4exD0ZgNoSUPuRn", size: 0 },
        thumbnail: {
            decryptionHeader: "50NerzzFpFlxPU0VpLCyR19nc62vA91J",
            size: 0,
        },
        metadata: {
            encryptedData:
                "4MgRhMb/L+yKqOloFnbNg///j+ekVIJRqp6hRJTDRf91FrNSykztXsh4wHBhZdQHYnNRjywg81Qitc/RwPkM9YlQ9xDsPP4uStDzwPyAhZ3O9mWBtvh2vM4bgWu2LA5bt8N+fKzdWD52K8WOpMD6JpSLnUbUjzFAI4C1XPkzr/IW3pQ+i6X3Qzz5POdncvMJC0sdhx7yEwXbvFnnAtaFuqUWYE3fOIL46iSzkQQL1zg+X79iCIOEOFv6Pe6iiIoX9eTBUxAhj5ZuteJCi2G119FoAR4wYpXBOA==",
            decryptionHeader: "/huO35Q51hB1GH6l1S7wpdAq/ktmfkLd",
            size: 0,
        },
        isDeleted: false,
        updationTime: 0,
        pubMagicMetadata: {
            version: 1,
            count: 1,
            data: "aQYjzEDhzI3BWUFUoaRiWLoxaTWdWq0nSlgXwjSyvqvR",
            header: "iJumCO2/t1NOZrHuvsXwGNN6+BcYyzND",
        },
        info: { fileSize: 184302, thumbSize: 1909 },
    },
};

// Fetch file info from the server
const fetchFileInfo = async (accessToken: string): Promise<FileLinkInfo> => {
    // Use mock data when server is down
    if (USE_MOCK_DATA) {
        // Simulate network delay (0.5 to 1.5 seconds)
        const delay = 800;
        await new Promise((resolve) => setTimeout(resolve, delay));
        return MOCK_FILE_INFO;
    }

    const url = `${FILE_LINK_SERVER}/file-link/info?accessToken=${accessToken}`;

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
        } catch (err) {
            metadata = {};
        }

        // Extract file info from decrypted metadata
        const fileName =
            metadata.fileName ||
            metadata.title ||
            metadata.name ||
            "Unknown file";
        // Use fileSize from info field first, then fall back to metadata or other sources
        const fileSize =
            fileSizeFromInfo ||
            metadata.fileSize ||
            metadata.size ||
            file.file?.size ||
            0;
        const metadataUploadTime =
            metadata.uploadedTime ||
            metadata.createdAt ||
            metadata.modificationTime;

        return {
            id: fileId,
            fileName: fileName,
            fileSize: fileSize,
            uploadedTime: metadataUploadTime || uploadedTime,
            ownerName: ownerName,
            fileDecryptionHeader: fileDecryptionHeader,
            fileNonce: undefined,
            fileKey: fileKey,
        };
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
        const url = `${FILE_LINK_SERVER}/file-link/file?accessToken=${accessToken}`;

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
    const [loading, setLoading] = useState(true);
    const [downloading, setDownloading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [fileInfo, setFileInfo] = useState<DecryptedFileInfo | null>(null);
    const [accessToken, setAccessToken] = useState<string | null>(null);

    useEffect(() => {
        const loadFileInfo = async () => {
            try {
                const currentURL = new URL(window.location.href);
                const token = currentURL.searchParams.get("t");
                const key = await extractFileKeyFromURL(currentURL);

                if (!token || !key) {
                    setError(
                        "Invalid file link. Missing access token or file key.",
                    );
                    setLoading(false);
                    return;
                }

                setAccessToken(token);

                // Fetch file info from server
                const encryptedInfo = await fetchFileInfo(token);

                // Decrypt file info
                const decryptedInfo = await decryptFileInfo(encryptedInfo, key);
                setFileInfo(decryptedInfo);
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

        void loadFileInfo();
    }, []);

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

    return (
        <Box
            sx={{
                minHeight: "100vh",
                bgcolor: "#F8F8F8",
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                padding: { xs: 0, md: 3 },
            }}
        >
            {/* Ente Logo - Always at the top */}
            <Box
                sx={{
                    mt: { xs: 3, md: 6 },
                    mb: 0,
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
                        <CircularProgress color="primary" size={48} />
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
                        {/* Spacer for mobile to push content down */}
                        <Box
                            sx={{
                                flex: { xs: 1, md: 0 },
                                minHeight: { xs: 40, md: 0 },
                            }}
                        />

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
                                    backgroundColor: "#F0F0F0",
                                    borderRadius: "24px",
                                    padding: 1.5,
                                    display: "flex",
                                    alignItems: "center",
                                    justifyContent: "center",
                                }}
                            >
                                {getFileIcon(fileInfo.fileName, 48)}
                            </Box>

                            {/* File Name */}
                            <Typography
                                variant="h5"
                                sx={{
                                    fontWeight: 500,
                                    textAlign: "center",
                                    wordBreak: "break-word",
                                    color: "#000000",
                                }}
                            >
                                {fileInfo.fileName}
                            </Typography>

                            {/* File Size */}
                            <Typography
                                variant="body"
                                sx={{
                                    color: "#757575",
                                    mt: -2,
                                    fontSize: "1rem",
                                }}
                            >
                                {fileInfo.fileSize > 0
                                    ? formatFileSize(fileInfo.fileSize)
                                    : "Unknown size"}
                            </Typography>
                        </Box>

                        {/* Another spacer to push button to bottom on mobile */}
                        <Box
                            sx={{
                                flex: { xs: 1, md: 0 },
                                minHeight: { xs: 40, md: 0 },
                            }}
                        />

                        {/* Download Button - Bottom on mobile, with file info on desktop */}
                        <Box sx={{ width: "100%", mt: { xs: 0, md: 4 } }}>
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
                                    "&:hover": { bgcolor: "#0056CC" },
                                    "&:disabled": {
                                        bgcolor: "#1071FF",
                                        color: "white",
                                        opacity: 0.7,
                                    },
                                    borderRadius: "20px",
                                    textTransform: "none",
                                }}
                            >
                                {downloading ? (
                                    <>
                                        <CircularProgress
                                            size={20}
                                            sx={{ mr: 1, color: "white" }}
                                        />
                                        Downloading...
                                    </>
                                ) : (
                                    "Download"
                                )}
                            </Button>
                        </Box>
                    </>
                )}
            </Box>
        </Box>
    );
};

export default FilePage;

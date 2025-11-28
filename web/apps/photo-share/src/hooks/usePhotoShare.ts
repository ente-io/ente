import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import {
    decryptFileInfo,
    downloadFile,
    downloadThumbnail,
    extractFileKeyFromURL,
    fetchFileInfo,
    getFileUrl,
} from "../services/photo-share";
import type { DecryptedFileInfo } from "../types/file-share";

interface UsePhotoShareResult {
    loading: boolean;
    downloading: boolean;
    error: string | null;
    fileInfo: DecryptedFileInfo | null;
    accessToken: string | null;
    thumbnailUrl: string | null;
    fileUrl: string | null;
    handleDownload: () => Promise<void>;
    enableDownload: boolean;
}

export const usePhotoShare = (): UsePhotoShareResult => {
    const router = useRouter();
    const [loading, setLoading] = useState(true);
    const [downloading, setDownloading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [fileInfo, setFileInfo] = useState<DecryptedFileInfo | null>(null);
    const [accessToken, setAccessToken] = useState<string | null>(null);
    const [thumbnailUrl, setThumbnailUrl] = useState<string | null>(null);
    const [fileUrl, setFileUrl] = useState<string | null>(null);

    useEffect(() => {
        const loadFileInfo = async () => {
            try {
                // Extract token from pathname (e.g., /4MzPEanZK8)
                const token = window.location.pathname.slice(1);

                if (!token) {
                    setError("Invalid file link. Missing access token.");
                    setLoading(false);
                    return;
                }

                const currentURL = new URL(window.location.href);
                const keyMaterial = await extractFileKeyFromURL(currentURL);

                if (!keyMaterial) {
                    setError("Invalid file link. Missing secret.");
                    setLoading(false);
                    return;
                }

                setAccessToken(token);

                const encryptedInfo = await fetchFileInfo(token);
                const decryptedInfo = await decryptFileInfo(
                    encryptedInfo,
                    keyMaterial,
                );

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

                    // Load thumbnail for preview first (quick)
                    if (decryptedInfo.fileKey) {
                        try {
                            const thumbnailBlob = await downloadThumbnail(
                                token,
                                decryptedInfo.fileKey,
                                decryptedInfo.thumbnailDecryptionHeader,
                            );
                            if (thumbnailBlob) {
                                const url = URL.createObjectURL(thumbnailBlob);
                                setThumbnailUrl(url);
                            }
                        } catch {
                            // Thumbnail loading failed, continue without it
                        }

                        // Load full file for viewing (images/videos)
                        if (
                            decryptedInfo.fileType === "image" ||
                            decryptedInfo.fileType === "video"
                        ) {
                            try {
                                const fullFileUrl = await getFileUrl(
                                    token,
                                    decryptedInfo.fileKey,
                                    decryptedInfo.fileName,
                                    decryptedInfo.fileType,
                                    decryptedInfo.fileDecryptionHeader,
                                    decryptedInfo.fileNonce,
                                );
                                if (fullFileUrl) {
                                    setFileUrl(fullFileUrl);
                                }
                            } catch {
                                // Full file loading failed, user can still download
                            }
                        }
                    }
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

        if (router.isReady) {
            void loadFileInfo();
        }
    }, [router.isReady]);

    // Cleanup URLs on unmount
    useEffect(() => {
        return () => {
            if (thumbnailUrl) {
                URL.revokeObjectURL(thumbnailUrl);
            }
            if (fileUrl) {
                URL.revokeObjectURL(fileUrl);
            }
        };
    }, [thumbnailUrl, fileUrl]);

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

    return {
        loading,
        downloading,
        error,
        fileInfo,
        accessToken,
        thumbnailUrl,
        fileUrl,
        handleDownload,
        enableDownload: fileInfo?.enableDownload ?? true,
    };
};

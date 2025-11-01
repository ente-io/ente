import type { NotificationAttributes } from "ente-new/photos/components/Notification";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import {
    decryptFileInfo,
    downloadFile,
    extractFileKeyFromURL,
    fetchFileInfo,
} from "../services/file-share";
import type { DecryptedFileInfo } from "../types/file-share";

interface UseFileShareResult {
    loading: boolean;
    downloading: boolean;
    error: string | null;
    fileInfo: DecryptedFileInfo | null;
    accessToken: string | null;
    notificationAttributes: NotificationAttributes | undefined;
    handleDownload: () => Promise<void>;
    handleCopyContent: (content: string) => Promise<void>;
    setNotificationAttributes: (
        attributes: NotificationAttributes | undefined,
    ) => void;
}

export const useFileShare = (): UseFileShareResult => {
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
                // Extract token from pathname (e.g., /4MzPEanZK8)
                const token = window.location.pathname.slice(1);

                if (!token) {
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

                const encryptedInfo = await fetchFileInfo(token);
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

        if (router.isReady) {
            void loadFileInfo();
        }
    }, [router.isReady]);

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
        } catch {
            setNotificationAttributes({
                color: "critical",
                title: "Failed to copy",
            });
        }
    };

    return {
        loading,
        downloading,
        error,
        fileInfo,
        accessToken,
        notificationAttributes,
        handleDownload,
        handleCopyContent,
        setNotificationAttributes,
    };
};

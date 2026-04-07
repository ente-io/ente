import type { SingleInputFormProps } from "ente-base/components/SingleInputForm";
import { HTTPError, isHTTP401Error, isHTTPErrorWithStatus } from "ente-base/http";
import { extractCollectionKeyFromShareURL } from "ente-gallery/services/share";
import type { PublicURL } from "ente-media/collection";
import type { NotificationAttributes } from "ente-new/photos/components/Notification";
import { useRouter } from "next/router";
import { useCallback, useEffect, useState } from "react";
import {
    downloadPublicCollectionFile,
    fetchPublicCollectionShare,
    fetchPublicCollectionShareMetadata,
    type PublicCollectionShareInfo,
    type SharedCollectionItemInfo,
    verifyPublicCollectionPassword,
} from "../services/collection-share";

const extractCollectionTokenFromPath = (pathname: string): string | null => {
    const match = /^\/c\/([^/]+)\/?$/.exec(pathname);
    return match?.[1] ?? null;
};

const extractCollectionTokenFromURL = (url: URL): string | null =>
    extractCollectionTokenFromPath(url.pathname);

interface UseCollectionShareResult {
    loading: boolean;
    requiresPassword: boolean;
    downloadingItemID: number | null;
    downloadProgress: number | null;
    errorTitle: string | null;
    error: string | null;
    errorIsExpired: boolean;
    collectionInfo: PublicCollectionShareInfo | null;
    selectedItem: SharedCollectionItemInfo | null;
    notificationAttributes: NotificationAttributes | undefined;
    handleItemClick: (item: SharedCollectionItemInfo) => void;
    handleCloseItem: () => void;
    handleDownload: () => Promise<void>;
    handleSubmitPassword: SingleInputFormProps["onSubmit"];
    handleCopyContent: (content: string) => Promise<void>;
    setNotificationAttributes: (
        attributes: NotificationAttributes | undefined,
    ) => void;
}

interface CollectionShareLoadError {
    title: string;
    message: string;
    isExpired: boolean;
}

const collectionShareLoadError = async (
    err: unknown,
): Promise<CollectionShareLoadError> => {
    if (err instanceof HTTPError && err.res.status === 410) {
        try {
            const payload = (await err.res.clone().json()) as {
                error?: string;
            };
            if (payload.error === "expired token") {
                return {
                    title: "Link expired",
                    message: "This link has either expired or has been disabled.",
                    isExpired: true,
                };
            }
        } catch {
            // Ignore payload parse failures and use the generic gone-state copy.
        }

        return {
            title: "Link expired",
            message: "This link has either expired or has been disabled.",
            isExpired: true,
        };
    }

    if (
        isHTTP401Error(err) ||
        isHTTPErrorWithStatus(err, 403) ||
        isHTTPErrorWithStatus(err, 404)
    ) {
        return {
            title: "Unable to open this collection",
            message:
                "This collection link is no longer available. It may have been removed or expired.",
            isExpired: false,
        };
    }

    return {
        title: "Unable to open this collection",
        message: "Unable to load this collection right now. Please try again later.",
        isExpired: false,
    };
};

export const useCollectionShare = (): UseCollectionShareResult => {
    const router = useRouter();
    const [loading, setLoading] = useState(true);
    const [downloadingItemID, setDownloadingItemID] = useState<number | null>(
        null,
    );
    const [downloadProgress, setDownloadProgress] = useState<number | null>(
        null,
    );
    const [errorTitle, setErrorTitle] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [errorIsExpired, setErrorIsExpired] = useState(false);
    const [collectionInfo, setCollectionInfo] =
        useState<PublicCollectionShareInfo | null>(null);
    const [selectedItem, setSelectedItem] =
        useState<SharedCollectionItemInfo | null>(null);
    const [accessToken, setAccessToken] = useState<string | null>(null);
    const [accessTokenJWT, setAccessTokenJWT] = useState<string | null>(null);
    const [collectionKey, setCollectionKey] = useState<string | null>(null);
    const [passwordProtectedPublicURL, setPasswordProtectedPublicURL] =
        useState<PublicURL | null>(null);
    const [notificationAttributes, setNotificationAttributes] =
        useState<NotificationAttributes>();
    const requiresPassword = !!passwordProtectedPublicURL && !accessTokenJWT;

    const loadCollection = useCallback(
        async (
            opts?: Partial<{
                accessToken: string;
                collectionKey: string;
                accessTokenJWT: string;
            }>,
        ) => {
            try {
                setLoading(true);
                setError(null);
                setErrorTitle(null);
                setErrorIsExpired(false);

                const url = new URL(window.location.href);
                const token =
                    opts?.accessToken ?? extractCollectionTokenFromURL(url);
                if (!token) {
                    setErrorTitle("Invalid collection link");
                    setError("This collection link is invalid.");
                    return;
                }

                const resolvedCollectionKey =
                    opts?.collectionKey ??
                    (await extractCollectionKeyFromShareURL(url));
                if (!resolvedCollectionKey) {
                    setErrorTitle("Invalid collection link");
                    setError("This collection link is invalid.");
                    return;
                }

                const resolvedAccessTokenJWT = opts?.accessTokenJWT;

                setAccessToken(token);
                setCollectionKey(resolvedCollectionKey);

                const metadata = await fetchPublicCollectionShareMetadata(
                    token,
                    resolvedCollectionKey,
                );
                if (metadata.passwordEnabled && !resolvedAccessTokenJWT) {
                    setPasswordProtectedPublicURL(metadata.publicURL ?? null);
                    setCollectionInfo(null);
                    return;
                }

                const info = await fetchPublicCollectionShare(
                    {
                        accessToken: token,
                        accessTokenJWT: resolvedAccessTokenJWT,
                    },
                    resolvedCollectionKey,
                );
                setPasswordProtectedPublicURL(null);
                setCollectionInfo(info);
            } catch (err) {
                const loadError = await collectionShareLoadError(err);
                setErrorTitle(loadError.title);
                setError(loadError.message);
                setErrorIsExpired(loadError.isExpired);
            } finally {
                setLoading(false);
            }
        },
        [],
    );

    useEffect(() => {
        if (router.isReady) {
            void loadCollection();
        }
    }, [router.isReady, loadCollection]);

    const handleCloseItem = () => {
        setSelectedItem(null);
    };

    const handleDownloadItem = async (item: SharedCollectionItemInfo) => {
        const { fileDecryptionHeader, fileKey } = item;

        if (
            downloadingItemID !== null ||
            !accessToken ||
            !fileKey ||
            !fileDecryptionHeader
        ) {
            return;
        }

        setDownloadingItemID(item.id);
        setDownloadProgress(null);
        try {
            await downloadPublicCollectionFile(
                accessToken,
                item.id,
                fileKey,
                item.fileName,
                fileDecryptionHeader,
                ({ loaded, total }) => {
                    if (total && total > 0) {
                        setDownloadProgress(
                            Math.min(100, Math.round((loaded / total) * 100)),
                        );
                    }
                },
            );
        } catch (err) {
            setNotificationAttributes({
                color: "critical",
                title:
                    err instanceof Error
                        ? err.message
                        : "Failed to download file",
            });
        } finally {
            setDownloadingItemID(null);
            setDownloadProgress(null);
        }
    };

    const handleItemClick = (item: SharedCollectionItemInfo) => {
        if (downloadingItemID !== null) {
            return;
        }

        setSelectedItem(item);
    };

    const handleDownload = async () => {
        if (!selectedItem) {
            return;
        }
        await handleDownloadItem(selectedItem);
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

    const handleSubmitPassword: SingleInputFormProps["onSubmit"] = async (
        password,
        setFieldError,
    ) => {
        if (!passwordProtectedPublicURL || !accessToken || !collectionKey) {
            return;
        }

        try {
            const jwtToken = await verifyPublicCollectionPassword(
                passwordProtectedPublicURL,
                password,
                accessToken,
            );
            setAccessTokenJWT(jwtToken);
            await loadCollection({
                accessToken,
                collectionKey,
                accessTokenJWT: jwtToken,
            });
        } catch (err) {
            if (isHTTP401Error(err)) {
                setFieldError("Incorrect password");
                return;
            }
            throw err;
        }
    };

    return {
        loading,
        requiresPassword,
        downloadingItemID,
        downloadProgress,
        errorTitle,
        error,
        errorIsExpired,
        collectionInfo,
        selectedItem,
        notificationAttributes,
        handleItemClick,
        handleCloseItem,
        handleDownload,
        handleSubmitPassword,
        handleCopyContent,
        setNotificationAttributes,
    };
};

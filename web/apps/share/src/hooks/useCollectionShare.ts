import type { SingleInputFormProps } from "ente-base/components/SingleInputForm";
import {
    HTTPError,
    isHTTP401Error,
    isHTTPErrorWithStatus,
} from "ente-base/http";
import { extractCollectionKeyFromShareURL } from "ente-gallery/services/share";
import type { PublicURL } from "ente-media/collection";
import type { NotificationAttributes } from "ente-new/photos/components/Notification";
import { useRouter } from "next/router";
import { useCallback, useEffect, useRef, useState } from "react";
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

const accessTokenJWTStorageKey = (accessToken: string) =>
    `share-collection-access-token-jwt:${accessToken}`;

const savedAccessTokenJWT = (accessToken: string): string | null => {
    try {
        return window.localStorage.getItem(
            accessTokenJWTStorageKey(accessToken),
        );
    } catch {
        return null;
    }
};

const saveAccessTokenJWT = (accessToken: string, accessTokenJWT: string) => {
    try {
        window.localStorage.setItem(
            accessTokenJWTStorageKey(accessToken),
            accessTokenJWT,
        );
    } catch {
        // Ignore storage failures and continue with in-memory state.
    }
};

const removeAccessTokenJWT = (accessToken: string) => {
    try {
        window.localStorage.removeItem(accessTokenJWTStorageKey(accessToken));
    } catch {
        // Ignore storage failures and continue with in-memory state.
    }
};

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
                    message:
                        "This link has either expired or has been disabled.",
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
        message:
            "Unable to load this collection right now. Please try again later.",
        isExpired: false,
    };
};

export const useCollectionShare = (): UseCollectionShareResult => {
    const router = useRouter();
    const isRevalidatingRef = useRef(false);
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
                setPasswordProtectedPublicURL(null);

                const url = new URL(window.location.href);
                const token =
                    opts?.accessToken ?? extractCollectionTokenFromURL(url);
                if (!token) {
                    setCollectionInfo(null);
                    setSelectedItem(null);
                    setErrorTitle("Invalid collection link");
                    setError("This collection link is invalid.");
                    return;
                }

                const resolvedCollectionKey =
                    opts?.collectionKey ??
                    (await extractCollectionKeyFromShareURL(url));
                if (!resolvedCollectionKey) {
                    setCollectionInfo(null);
                    setSelectedItem(null);
                    setErrorTitle("Invalid collection link");
                    setError("This collection link is invalid.");
                    return;
                }

                const storedAccessTokenJWT = savedAccessTokenJWT(token);
                const resolvedAccessTokenJWT =
                    opts?.accessTokenJWT ?? storedAccessTokenJWT ?? undefined;

                setAccessToken(token);
                setCollectionKey(resolvedCollectionKey);
                setAccessTokenJWT(resolvedAccessTokenJWT ?? null);

                const metadata = await fetchPublicCollectionShareMetadata(
                    token,
                    resolvedCollectionKey,
                );
                if (!metadata.passwordEnabled && resolvedAccessTokenJWT) {
                    removeAccessTokenJWT(token);
                    setAccessTokenJWT(null);
                }

                const activeAccessTokenJWT = metadata.passwordEnabled
                    ? resolvedAccessTokenJWT
                    : undefined;

                if (metadata.passwordEnabled && !activeAccessTokenJWT) {
                    setPasswordProtectedPublicURL(metadata.publicURL ?? null);
                    setCollectionInfo(null);
                    setSelectedItem(null);
                    return;
                }

                let info: PublicCollectionShareInfo;
                try {
                    info = await fetchPublicCollectionShare(
                        {
                            accessToken: token,
                            accessTokenJWT: activeAccessTokenJWT,
                        },
                        resolvedCollectionKey,
                    );
                } catch (err) {
                    if (activeAccessTokenJWT && isHTTP401Error(err)) {
                        removeAccessTokenJWT(token);
                        setAccessTokenJWT(null);
                        setPasswordProtectedPublicURL(
                            metadata.publicURL ?? null,
                        );
                        setCollectionInfo(null);
                        return;
                    }
                    throw err;
                }

                setPasswordProtectedPublicURL(null);
                setCollectionInfo(info);
            } catch (err) {
                setCollectionInfo(null);
                setSelectedItem(null);
                setPasswordProtectedPublicURL(null);
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

    useEffect(() => {
        if (!router.isReady) {
            return;
        }

        const revalidate = () => {
            if (document.visibilityState === "hidden" || isRevalidatingRef.current) {
                return;
            }

            isRevalidatingRef.current = true;
            void loadCollection().finally(() => {
                isRevalidatingRef.current = false;
            });
        };

        const onVisibilityChange = () => {
            if (document.visibilityState === "visible") {
                revalidate();
            }
        };

        window.addEventListener("focus", revalidate);
        window.addEventListener("pageshow", revalidate);
        document.addEventListener("visibilitychange", onVisibilityChange);

        return () => {
            window.removeEventListener("focus", revalidate);
            window.removeEventListener("pageshow", revalidate);
            document.removeEventListener("visibilitychange", onVisibilityChange);
        };
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
                { accessToken, accessTokenJWT: accessTokenJWT ?? undefined },
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
            if (accessTokenJWT && collectionKey && isHTTP401Error(err)) {
                removeAccessTokenJWT(accessToken);
                setAccessTokenJWT(null);
                setSelectedItem(null);
                await loadCollection({ accessToken, collectionKey });
                return;
            }
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
            saveAccessTokenJWT(accessToken, jwtToken);
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

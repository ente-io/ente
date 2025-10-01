import { styled } from "@mui/material";
import Typography from "@mui/material/Typography";
import {
    CenteredFill,
    Stack100vhCenter,
} from "ente-base/components/containers";
import { LoadingIndicator } from "ente-base/components/loaders";
import { useBaseContext } from "ente-base/context";
import {
    isHTTP401Error,
    isHTTPErrorWithStatus,
    type PublicAlbumsCredentials,
} from "ente-base/http";
import log from "ente-base/log";
import { downloadManager } from "ente-gallery/services/download";
import { extractCollectionKeyFromShareURL } from "ente-gallery/services/share";
import { sortFiles } from "ente-gallery/utils/file";
import type { Collection } from "ente-media/collection";
import { type EnteFile } from "ente-media/file";
import { usePhotosAppContext } from "ente-new/photos/types/context";
import { t } from "i18next";
import { useCallback, useEffect, useRef, useState } from "react";
import { EmbedFileListWithViewer } from "../components/EmbedFileListWithViewer";
import { EmbedPasswordForm } from "../components/EmbedPasswordForm";
import {
    removePublicCollectionByKey,
    savedPublicCollectionAccessTokenJWT,
    savedPublicCollectionByKey,
    savedPublicCollectionFiles,
    savePublicCollectionAccessTokenJWT,
} from "../services/public-albums-storage";
import {
    pullCollection,
    pullPublicCollectionFiles,
    removePublicCollectionFileData,
    verifyPublicAlbumPassword,
} from "../services/public-collection";

export default function EmbedGallery() {
    const { onGenericError } = useBaseContext();
    const { showLoadingBar, hideLoadingBar } = usePhotosAppContext();

    const [publicCollection, setPublicCollection] = useState<
        Collection | undefined
    >(undefined);
    const [publicFiles, setPublicFiles] = useState<EnteFile[] | undefined>(
        undefined,
    );
    const [errorMessage, setErrorMessage] = useState<string>("");
    const [loading, setLoading] = useState(true);
    const [isPasswordProtected, setIsPasswordProtected] = useState(false);

    const credentials = useRef<PublicAlbumsCredentials | undefined>(undefined);
    const collectionKey = useRef<string | undefined>(undefined);

    const publicAlbumsRemotePull = useCallback(async () => {
        const accessToken = credentials.current!.accessToken;
        showLoadingBar();
        setLoading(true);
        try {
            const { collection } = await pullCollection(
                accessToken,
                collectionKey.current!,
            );

            setPublicCollection(collection);
            const isPasswordProtected =
                !!collection.publicURLs[0]?.passwordEnabled;
            setIsPasswordProtected(isPasswordProtected);
            setErrorMessage("");

            if (!isPasswordProtected && credentials.current?.accessTokenJWT) {
                credentials.current.accessTokenJWT = undefined;
                downloadManager.setPublicAlbumsCredentials(credentials.current);
            }

            if (isPasswordProtected && !credentials.current?.accessTokenJWT) {
                removePublicCollectionFileData(accessToken);
            } else {
                try {
                    await pullPublicCollectionFiles(
                        credentials.current!,
                        collection,
                        (files) =>
                            setPublicFiles(
                                sortFilesForCollection(files, collection),
                            ),
                    );
                } catch (e) {
                    if (isHTTP401Error(e)) {
                        credentials.current!.accessTokenJWT = undefined;
                        downloadManager.setPublicAlbumsCredentials(
                            credentials.current,
                        );
                    } else {
                        throw e;
                    }
                }
            }
        } catch (e) {
            if (
                isHTTPErrorWithStatus(e, 401) ||
                isHTTPErrorWithStatus(e, 410) ||
                isHTTPErrorWithStatus(e, 429)
            ) {
                setErrorMessage(
                    isHTTPErrorWithStatus(e, 429)
                        ? t("link_request_limit_exceeded")
                        : t("link_expired_message"),
                );
                removePublicCollectionFileData(accessToken);
                removePublicCollectionByKey(collectionKey.current!);
                setPublicCollection(undefined);
                setPublicFiles(undefined);
            } else {
                log.error("Public album remote pull failed", e);
                onGenericError(e);
            }
        } finally {
            hideLoadingBar();
            setLoading(false);
        }
    }, [showLoadingBar, hideLoadingBar, onGenericError]);

    useEffect(() => {
        const main = async () => {
            let redirectingToWebsite = false;
            try {
                const currentURL = new URL(window.location.href);
                const t = currentURL.searchParams.get("t");
                const ck = await extractCollectionKeyFromShareURL(currentURL);
                if (!t && !ck) {
                    window.location.href = "https://ente.io";
                    redirectingToWebsite = true;
                }
                if (!t || !ck) {
                    return;
                }

                collectionKey.current = ck;
                const collection = savedPublicCollectionByKey(ck);
                const accessToken = t;
                let accessTokenJWT: string | undefined;

                if (collection) {
                    setPublicCollection(collection);
                    setIsPasswordProtected(
                        !!collection.publicURLs[0]?.passwordEnabled,
                    );
                    setPublicFiles(
                        sortFilesForCollection(
                            savedPublicCollectionFiles(accessToken),
                            collection,
                        ),
                    );
                    accessTokenJWT =
                        savedPublicCollectionAccessTokenJWT(accessToken);
                }

                credentials.current = { accessToken, accessTokenJWT };
                downloadManager.setPublicAlbumsCredentials(credentials.current);

                await publicAlbumsRemotePull();
            } finally {
                if (!redirectingToWebsite) {
                    setLoading(false);
                }
            }
        };

        void main();
    }, [publicAlbumsRemotePull]);

    const handleSubmitPassword = async (password: string) => {
        try {
            const accessToken = credentials.current!.accessToken;
            const accessTokenJWT = await verifyPublicAlbumPassword(
                publicCollection!.publicURLs[0]!,
                password,
                accessToken,
            );
            credentials.current!.accessTokenJWT = accessTokenJWT;
            downloadManager.setPublicAlbumsCredentials(credentials.current);
            savePublicCollectionAccessTokenJWT(accessToken, accessTokenJWT);
        } catch (e) {
            log.error("Failed to verify password", e);
            if (isHTTP401Error(e)) {
                throw new Error(t("incorrect_password"));
            }
            throw e;
        }

        await publicAlbumsRemotePull();
    };

    if (loading && (!publicFiles || !credentials.current)) {
        return (
            <EmbedContainer>
                <CenteredFill>
                    <LoadingIndicator />
                </CenteredFill>
            </EmbedContainer>
        );
    } else if (errorMessage) {
        return (
            <EmbedContainer>
                <Stack100vhCenter>
                    <Typography sx={{ color: "critical.main" }}>
                        {errorMessage}
                    </Typography>
                </Stack100vhCenter>
            </EmbedContainer>
        );
    } else if (isPasswordProtected && !credentials.current?.accessTokenJWT) {
        return (
            <EmbedContainer>
                <EmbedPasswordForm onSubmit={handleSubmitPassword} />
            </EmbedContainer>
        );
    } else if (!publicFiles || !credentials.current) {
        return (
            <EmbedContainer>
                <Stack100vhCenter>
                    <Typography>{t("not_found")}</Typography>
                </Stack100vhCenter>
            </EmbedContainer>
        );
    }

    return (
        <EmbedContainer>
            <EmbedFileListWithViewer
                files={publicFiles}
                publicCollection={publicCollection!}
                onRemotePull={publicAlbumsRemotePull}
            />
        </EmbedContainer>
    );
}

const sortFilesForCollection = (files: EnteFile[], collection?: Collection) =>
    sortFiles(files, collection?.pubMagicMetadata?.data.asc ?? false);

const EmbedContainer = styled("div")({
    width: "100%",
    height: "100vh",
    overflow: "hidden",
    display: "flex",
    flexDirection: "column",
});

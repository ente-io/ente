import { EnteFile } from "@/new/photos/types/file";
import { customAPIOrigin } from "@/next/origins";
import { CustomError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import { retryAsyncFunction } from "@ente/shared/utils";
import { DownloadClient } from "services/download";

export class PublicAlbumsDownloadClient implements DownloadClient {
    private token: string;
    private passwordToken: string;

    constructor(private timeout: number) {}

    updateTokens(token: string, passwordToken: string) {
        this.token = token;
        this.passwordToken = passwordToken;
    }

    downloadThumbnail = async (file: EnteFile) => {
        const accessToken = this.token;
        const accessTokenJWT = this.passwordToken;
        if (!accessToken) throw Error(CustomError.TOKEN_MISSING);
        const customOrigin = await customAPIOrigin();

        // See: [Note: Passing credentials for self-hosted file fetches]
        const getThumbnail = () => {
            const opts = {
                responseType: "arraybuffer",
            };

            if (customOrigin) {
                const params = new URLSearchParams({
                    accessToken,
                    ...(accessTokenJWT && { accessTokenJWT }),
                });
                return HTTPService.get(
                    `${customOrigin}/public-collection/files/preview/${file.id}?${params.toString()}`,
                    undefined,
                    undefined,
                    opts,
                );
            } else {
                return HTTPService.get(
                    `https://public-albums.ente.io/preview/?fileID=${file.id}`,
                    undefined,
                    {
                        "X-Auth-Access-Token": accessToken,
                        ...(accessTokenJWT && {
                            "X-Auth-Access-Token-JWT": accessTokenJWT,
                        }),
                    },
                    opts,
                );
            }
        };

        const resp = await getThumbnail();
        if (resp.data === undefined) throw Error(CustomError.REQUEST_FAILED);
        return new Uint8Array(resp.data);
    };

    downloadFile = async (
        file: EnteFile,
        onDownloadProgress: (event: { loaded: number; total: number }) => void,
    ) => {
        const accessToken = this.token;
        const accessTokenJWT = this.passwordToken;
        if (!accessToken) throw Error(CustomError.TOKEN_MISSING);

        const customOrigin = await customAPIOrigin();

        // See: [Note: Passing credentials for self-hosted file fetches]
        const getFile = () => {
            const opts = {
                responseType: "arraybuffer",
                timeout: this.timeout,
                onDownloadProgress,
            };

            if (customOrigin) {
                const params = new URLSearchParams({
                    accessToken,
                    ...(accessTokenJWT && { accessTokenJWT }),
                });
                return HTTPService.get(
                    `${customOrigin}/public-collection/files/download/${file.id}?${params.toString()}`,
                    undefined,
                    undefined,
                    opts,
                );
            } else {
                return HTTPService.get(
                    `https://public-albums.ente.io/download/?fileID=${file.id}`,
                    undefined,
                    {
                        "X-Auth-Access-Token": accessToken,
                        ...(accessTokenJWT && {
                            "X-Auth-Access-Token-JWT": accessTokenJWT,
                        }),
                    },
                    opts,
                );
            }
        };

        const resp = await retryAsyncFunction(getFile);
        if (resp.data === undefined) throw Error(CustomError.REQUEST_FAILED);
        return new Uint8Array(resp.data);
    };

    async downloadFileStream(file: EnteFile): Promise<Response> {
        const accessToken = this.token;
        const accessTokenJWT = this.passwordToken;
        if (!accessToken) throw Error(CustomError.TOKEN_MISSING);

        const customOrigin = await customAPIOrigin();

        // See: [Note: Passing credentials for self-hosted file fetches]
        const getFile = () => {
            if (customOrigin) {
                const params = new URLSearchParams({
                    accessToken,
                    ...(accessTokenJWT && { accessTokenJWT }),
                });
                return fetch(
                    `${customOrigin}/public-collection/files/download/${file.id}?${params.toString()}`,
                );
            } else {
                return fetch(
                    `https://public-albums.ente.io/download/?fileID=${file.id}`,
                    {
                        headers: {
                            "X-Auth-Access-Token": accessToken,
                            ...(accessTokenJWT && {
                                "X-Auth-Access-Token-JWT": accessTokenJWT,
                            }),
                        },
                    },
                );
            }
        };

        return retryAsyncFunction(getFile);
    }
}

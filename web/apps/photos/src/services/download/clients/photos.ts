import { EnteFile } from "@/new/photos/types/file";
import { customAPIOrigin } from "@/next/origins";
import { CustomError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import { retryAsyncFunction } from "@ente/shared/utils";
import { DownloadClient } from "services/download";

export class PhotosDownloadClient implements DownloadClient {
    constructor(
        private token: string,
        private timeout: number,
    ) {}

    updateTokens(token: string) {
        this.token = token;
    }

    async downloadThumbnail(file: EnteFile): Promise<Uint8Array> {
        const token = this.token;
        if (!token) throw Error(CustomError.TOKEN_MISSING);

        const customOrigin = await customAPIOrigin();

        // See: [Note: Passing credentials for self-hosted file fetches]
        const getThumbnail = () => {
            const opts = { responseType: "arraybuffer", timeout: this.timeout };
            if (customOrigin) {
                const params = new URLSearchParams({ token });
                return HTTPService.get(
                    `${customOrigin}/files/preview/${file.id}?${params.toString()}`,
                    undefined,
                    undefined,
                    opts,
                );
            } else {
                return HTTPService.get(
                    `https://thumbnails.ente.io/?fileID=${file.id}`,
                    undefined,
                    { "X-Auth-Token": token },
                    opts,
                );
            }
        };

        const resp = await retryAsyncFunction(getThumbnail);
        if (resp.data === undefined) throw Error(CustomError.REQUEST_FAILED);
        return new Uint8Array(resp.data);
    }

    async downloadFile(
        file: EnteFile,
        onDownloadProgress: (event: { loaded: number; total: number }) => void,
    ): Promise<Uint8Array> {
        const token = this.token;
        if (!token) throw Error(CustomError.TOKEN_MISSING);

        const customOrigin = await customAPIOrigin();

        // See: [Note: Passing credentials for self-hosted file fetches]
        const getFile = () => {
            const opts = {
                responseType: "arraybuffer",
                timeout: this.timeout,
                onDownloadProgress,
            };

            if (customOrigin) {
                const params = new URLSearchParams({ token });
                return HTTPService.get(
                    `${customOrigin}/files/download/${file.id}?${params.toString()}`,
                    undefined,
                    undefined,
                    opts,
                );
            } else {
                return HTTPService.get(
                    `https://files.ente.io/?fileID=${file.id}`,
                    undefined,
                    { "X-Auth-Token": token },
                    opts,
                );
            }
        };

        const resp = await retryAsyncFunction(getFile);
        if (resp.data === undefined) throw Error(CustomError.REQUEST_FAILED);
        return new Uint8Array(resp.data);
    }

    async downloadFileStream(file: EnteFile): Promise<Response> {
        const token = this.token;
        if (!token) throw Error(CustomError.TOKEN_MISSING);

        const customOrigin = await customAPIOrigin();

        // [Note: Passing credentials for self-hosted file fetches]
        //
        // Fetching files (or thumbnails) in the default self-hosted Ente
        // configuration involves a redirection:
        //
        // 1. The browser makes a HTTP GET to a museum with credentials. Museum
        //    inspects the credentials, in this case the auth token, and if
        //    they're valid, returns a HTTP 307 redirect to the pre-signed S3
        //    URL that to the file in the configured S3 bucket.
        //
        // 2. The browser follows the redirect to get the actual file. The URL
        //    is pre-signed, i.e. already has all credentials needed to prove to
        //    the S3 object storage that it should serve this response.
        //
        // For the first step normally we'd pass the auth the token via the
        // "X-Auth-Token" HTTP header. In this case though, that would be
        // problematic because the browser preserves the request headers when it
        // follows the HTTP 307 redirect, and the "X-Auth-Token" header also
        // gets sent to the redirected S3 request made in second step.
        //
        // To avoid this, we pass the token as a query parameter. Generally this
        // is not a good idea, but in this case (a) the URL is not a user
        // visible one and (b) even if it gets logged, it'll be in the
        // self-hosters own service.
        //
        // Note that Ente's own servers don't have these concerns because we use
        // a slightly different flow involving a proxy instead of directly
        // connecting to the S3 storage.
        //
        // 1. The web browser makes a HTTP GET request to a proxy passing it the
        //    credentials in the "X-Auth-Token".
        //
        // 2. The proxy then does both the original steps: (a). Use the
        //    credentials to get the pre signed URL, and (b) fetch that pre
        //    signed URL and stream back the response.

        const getFile = () => {
            if (customOrigin) {
                const params = new URLSearchParams({ token });
                return fetch(
                    `${customOrigin}/files/download/${file.id}?${params.toString()}`,
                );
            } else {
                return fetch(`https://files.ente.io/?fileID=${file.id}`, {
                    headers: {
                        "X-Auth-Token": token,
                    },
                });
            }
        };

        return retryAsyncFunction(getFile);
    }
}

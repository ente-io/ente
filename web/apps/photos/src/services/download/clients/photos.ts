import { CustomError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import { getFileURL, getThumbnailURL } from "@ente/shared/network/api";
import { DownloadClient } from "services/download";
import { EnteFile } from "types/file";
import { retryAsyncFunction } from "utils/network";

export class PhotosDownloadClient implements DownloadClient {
    constructor(
        private token: string,
        private timeout: number,
    ) {}
    updateTokens(token: string) {
        this.token = token;
    }

    updateTimeout(timeout: number) {
        this.timeout = timeout;
    }

    async downloadThumbnail(file: EnteFile): Promise<Uint8Array> {
        if (!this.token) {
            throw Error(CustomError.TOKEN_MISSING);
        }
        const resp = await retryAsyncFunction(() =>
            HTTPService.get(
                getThumbnailURL(file.id),
                null,
                { "X-Auth-Token": this.token },
                { responseType: "arraybuffer", timeout: this.timeout },
            ),
        );
        if (typeof resp.data === "undefined") {
            throw Error(CustomError.REQUEST_FAILED);
        }
        return new Uint8Array(resp.data);
    }

    async downloadFile(
        file: EnteFile,
        onDownloadProgress: (event: { loaded: number; total: number }) => void,
    ): Promise<Uint8Array> {
        if (!this.token) {
            throw Error(CustomError.TOKEN_MISSING);
        }
        const resp = await retryAsyncFunction(() =>
            HTTPService.get(
                getFileURL(file.id),
                null,
                { "X-Auth-Token": this.token },
                {
                    responseType: "arraybuffer",
                    timeout: this.timeout,
                    onDownloadProgress,
                },
            ),
        );
        if (typeof resp.data === "undefined") {
            throw Error(CustomError.REQUEST_FAILED);
        }
        return new Uint8Array(resp.data);
    }

    async downloadFileStream(file: EnteFile): Promise<Response> {
        if (!this.token) {
            throw Error(CustomError.TOKEN_MISSING);
        }
        return retryAsyncFunction(() =>
            fetch(getFileURL(file.id), {
                headers: {
                    "X-Auth-Token": this.token,
                },
            }),
        );
    }
}

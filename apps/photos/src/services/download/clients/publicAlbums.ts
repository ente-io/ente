import { CustomError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import {
    getPublicCollectionFileURL,
    getPublicCollectionThumbnailURL,
} from "@ente/shared/network/api";
import { DownloadClient } from "services/download";
import { EnteFile } from "types/file";
import { retryAsyncFunction } from "utils/network";

export class PublicAlbumsDownloadClient implements DownloadClient {
    constructor(
        private token: string,
        private passwordToken: string,
        private timeout: number,
    ) {}

    updateTokens(token: string, passwordToken: string) {
        this.token = token;
        this.passwordToken = passwordToken;
    }

    updateTimeout(timeout: number) {
        this.timeout = timeout;
    }

    downloadThumbnail = async (file: EnteFile) => {
        if (!this.token) {
            throw Error(CustomError.TOKEN_MISSING);
        }
        const resp = await HTTPService.get(
            getPublicCollectionThumbnailURL(file.id),
            null,
            {
                "X-Auth-Access-Token": this.token,
                ...(this.passwordToken && {
                    "X-Auth-Access-Token-JWT": this.passwordToken,
                }),
            },
            { responseType: "arraybuffer" },
        );

        if (typeof resp.data === "undefined") {
            throw Error(CustomError.REQUEST_FAILED);
        }
        return new Uint8Array(resp.data);
    };

    downloadFile = async (
        file: EnteFile,
        onDownloadProgress: (event: { loaded: number; total: number }) => void,
    ) => {
        if (!this.token) {
            throw Error(CustomError.TOKEN_MISSING);
        }
        const resp = await retryAsyncFunction(() =>
            HTTPService.get(
                getPublicCollectionFileURL(file.id),
                null,
                {
                    "X-Auth-Access-Token": this.token,
                    ...(this.passwordToken && {
                        "X-Auth-Access-Token-JWT": this.passwordToken,
                    }),
                },
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
    };

    async downloadFileStream(file: EnteFile): Promise<Response> {
        if (!this.token) {
            throw Error(CustomError.TOKEN_MISSING);
        }
        return retryAsyncFunction(() =>
            fetch(getPublicCollectionFileURL(file.id), {
                headers: {
                    "X-Auth-Access-Token": this.token,
                    ...(this.passwordToken && {
                        "X-Auth-Access-Token-JWT": this.passwordToken,
                    }),
                },
            }),
        );
    }
}

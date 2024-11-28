import { ensureOk } from "@/base/http";
import log from "@/base/log";
import { apiURL } from "@/base/origins";
import { EnteFile } from "@/media/file";
import { retryAsyncOperation } from "@/utils/promise";
import { CustomError, handleUploadError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import { z } from "zod";
import {
    MultipartUploadURLs,
    UploadFile,
    type UploadURL,
} from "./upload-service";

/**
 * Zod schema for {@link UploadURL}.
 *
 * TODO: Duplicated with uploadHttpClient, can be removed after we refactor this
 * code.
 */
const UploadURL = z.object({
    objectKey: z.string(),
    url: z.string(),
});

class PublicUploadHttpClient {
    async uploadFile(
        uploadFile: UploadFile,
        token: string,
        passwordToken: string,
    ): Promise<EnteFile> {
        try {
            if (!token) {
                throw Error(CustomError.TOKEN_MISSING);
            }
            const url = await apiURL("/public-collection/file");
            const response = await retryAsyncOperation(
                () =>
                    HTTPService.post(url, uploadFile, null, {
                        "X-Auth-Access-Token": token,
                        ...(passwordToken && {
                            "X-Auth-Access-Token-JWT": passwordToken,
                        }),
                    }),
                handleUploadError,
            );
            return response.data;
        } catch (e) {
            log.error("upload public File Failed", e);
            throw e;
        }
    }

    /**
     * Sibling of {@link fetchUploadURLs} for public albums.
     */
    async fetchUploadURLs(
        countHint: number,
        token: string,
        passwordToken: string,
    ) {
        const count = Math.min(50, countHint * 2).toString();
        const params = new URLSearchParams({ count });
        const url = await apiURL("/public-collection/upload-urls");
        const res = await fetch(`${url}?${params.toString()}`, {
            // TODO: Use authenticatedPublicAlbumsRequestHeaders after the public
            // albums refactor branch is merged.
            // headers: await authenticatedRequestHeaders(),
            headers: {
                "X-Auth-Access-Token": token,
                ...(passwordToken && {
                    "X-Auth-Access-Token-JWT": passwordToken,
                }),
            },
        });
        ensureOk(res);
        return (
            // TODO: The as cast will not be needed when tsc strict mode is
            // enabled for this code.
            z.object({ urls: UploadURL.array() }).parse(await res.json())
                .urls as UploadURL[]
        );
    }

    async fetchMultipartUploadURLs(
        count: number,
        token: string,
        passwordToken: string,
    ): Promise<MultipartUploadURLs> {
        try {
            if (!token) {
                throw Error(CustomError.TOKEN_MISSING);
            }
            const response = await HTTPService.get(
                await apiURL("/public-collection/multipart-upload-urls"),
                {
                    count,
                },
                {
                    "X-Auth-Access-Token": token,
                    ...(passwordToken && {
                        "X-Auth-Access-Token-JWT": passwordToken,
                    }),
                },
            );

            return response.data.urls;
        } catch (e) {
            log.error("fetch public multipart-upload-url failed", e);
            throw e;
        }
    }
}

export default new PublicUploadHttpClient();

/* TODO: Various lint issues in the decryptEnteFile function */
/* eslint-disable @typescript-eslint/no-unsafe-call */
/* eslint-disable @typescript-eslint/no-unsafe-argument */
/* eslint-disable @typescript-eslint/no-unnecessary-condition */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */

import { FILE_TYPE } from "@/media/file-type";
import { isHEICExtension, isNonWebImageFileExtension } from "@/media/formats";
import { heicToJPEG } from "@/media/heic-convert";
import { decodeLivePhoto } from "@/media/live-photo";
import type {
    EncryptedEnteFile,
    EnteFile,
    FileMagicMetadata,
    FilePublicMagicMetadata,
} from "@/new/photos/types/file";
import { nameAndExtension } from "@/next/file";
import log from "@/next/log";
import { apiURL, customAPIOrigin } from "@/next/origins";
import { shuffled } from "@/utils/array";
import { ensure } from "@/utils/ensure";
import { wait } from "@/utils/promise";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { ApiError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import type { AxiosResponse } from "axios";
import type { CastData } from "services/cast-data";
import { detectMediaMIMEType } from "services/detect-type";
import { isChromecast } from "./chromecast";

/**
 * An async generator function that loops through all the files in the
 * collection, returning renderable image URLs to each that can be displayed in
 * a slideshow.
 *
 * Each time it resolves with a (data) URL for the slideshow image to show next.
 *
 * If there are no renderable image in the collection, the sequence ends by
 * yielding `{done: true}`.
 *
 * Otherwise when the generator reaches the end of the collection, it starts
 * from the beginning again. So the sequence will continue indefinitely for
 * non-empty collections.
 *
 * The generator ignores errors in the fetching and decoding of individual
 * images in the collection, skipping the erroneous ones and moving onward to
 * the next one.
 *
 * - It will however throw if there are errors when getting the collection
 *   itself. This can happen both the first time, or when we are about to loop
 *   around to the start of the collection.
 *
 * - It will also throw if three consecutive image fail.
 *
 * @param castData The collection to show and credentials to fetch the files
 * within it.
 */
export const imageURLGenerator = async function* (castData: CastData) {
    const { collectionKey, castToken } = castData;

    /**
     * Keep a FIFO queue of the URLs that we've vended out recently so that we
     * can revoke those that are not being shown anymore.
     */
    const previousURLs: string[] = [];

    /** Number of milliseconds to keep the slide on the screen. */
    const slideDuration = 12000; /* 12 s */

    /**
     * Time when we last yielded.
     *
     * We use this to keep an roughly periodic spacing between yields that
     * accounts for the time we spend fetching and processing the images.
     */
    let lastYieldTime = Date.now();

    // The first time around regress the lastYieldTime into the past so that
    // we don't wait around too long for the first slide (we do want to wait a
    // bit, for the user to see the checkmark animation as reassurance).
    lastYieldTime -= slideDuration - 2500; /* wait at most 2.5 s */

    /**
     * Number of time we have caught an exception while trying to generate an
     * image URL for individual files.
     *
     * When this happens three times consecutively, we throw.
     */
    let consecutiveFailures = 0;

    while (true) {
        const encryptedFiles = shuffled(
            await getEncryptedCollectionFiles(castToken),
        );

        let haveEligibleFiles = false;

        for (const encryptedFile of encryptedFiles) {
            const file = await decryptEnteFile(encryptedFile, collectionKey);

            if (!isFileEligible(file)) continue;

            let url: string;
            try {
                url = await createRenderableURL(castToken, file);
                consecutiveFailures = 0;
                haveEligibleFiles = true;
            } catch (e) {
                consecutiveFailures += 1;
                // 1, 2, bang!
                if (consecutiveFailures == 3) throw e;

                if (e instanceof ApiError && e.httpStatusCode == 401) {
                    // The token has expired. This can happen, e.g., if the user
                    // opens the dialog to cast again, causing the client to
                    // invalidate existing tokens.
                    //
                    //  Rethrow the error, which will bring us back to the
                    // pairing page.
                    throw e;
                }

                // On all other errors (including temporary network issues),
                log.error("Skipping unrenderable file", e);
                await wait(100); /* Breathe */
                continue;
            }

            // The last element of previousURLs is the URL that is currently
            // being shown on screen.
            //
            // The last to last element is the one that was shown prior to that,
            // and now can be safely revoked.
            if (previousURLs.length > 1)
                URL.revokeObjectURL(ensure(previousURLs.shift()));

            previousURLs.push(url);

            const elapsedTime = Date.now() - lastYieldTime;
            if (elapsedTime > 0 && elapsedTime < slideDuration)
                await wait(slideDuration - elapsedTime);

            lastYieldTime = Date.now();
            yield url;
        }

        // This collection does not have any files that we can show.
        if (!haveEligibleFiles) return;
    }
};

/**
 * Fetch the list of non-deleted files in the given collection.
 *
 * The returned files are not decrypted yet, so their metadata will not be
 * readable.
 */
const getEncryptedCollectionFiles = async (
    castToken: string,
): Promise<EncryptedEnteFile[]> => {
    let files: EncryptedEnteFile[] = [];
    let sinceTime = 0;
    let resp: AxiosResponse;
    do {
        resp = await HTTPService.get(
            await apiURL("/cast/diff"),
            { sinceTime },
            {
                "Cache-Control": "no-cache",
                "X-Cast-Access-Token": castToken,
            },
        );
        const diff = resp.data.diff;
        files = files.concat(diff.filter((file: EnteFile) => !file.isDeleted));
        sinceTime = diff.reduce(
            (max: number, file: EnteFile) => Math.max(max, file.updationTime),
            sinceTime,
        );
    } while (resp.data.hasMore);
    return files;
};

/**
 * Decrypt the given {@link EncryptedEnteFile}, returning a {@link EnteFile}.
 */
const decryptEnteFile = async (
    encryptedFile: EncryptedEnteFile,
    collectionKey: string,
): Promise<EnteFile> => {
    const worker = await ComlinkCryptoWorker.getInstance();
    const {
        encryptedKey,
        keyDecryptionNonce,
        metadata,
        magicMetadata,
        pubMagicMetadata,
        ...restFileProps
    } = encryptedFile;
    const fileKey = await worker.decryptB64(
        encryptedKey,
        keyDecryptionNonce,
        collectionKey,
    );
    const fileMetadata = await worker.decryptMetadata(
        metadata.encryptedData,
        metadata.decryptionHeader,
        fileKey,
    );
    let fileMagicMetadata: FileMagicMetadata | undefined;
    let filePubMagicMetadata: FilePublicMagicMetadata | undefined;
    if (magicMetadata?.data) {
        fileMagicMetadata = {
            ...encryptedFile.magicMetadata,
            data: await worker.decryptMetadata(
                magicMetadata.data,
                magicMetadata.header,
                fileKey,
            ),
        };
    }
    if (pubMagicMetadata?.data) {
        filePubMagicMetadata = {
            ...pubMagicMetadata,
            data: await worker.decryptMetadata(
                pubMagicMetadata.data,
                pubMagicMetadata.header,
                fileKey,
            ),
        };
    }
    const file = {
        ...restFileProps,
        key: fileKey,
        metadata: fileMetadata,
        magicMetadata: fileMagicMetadata,
        pubMagicMetadata: filePubMagicMetadata,
    };
    if (file.pubMagicMetadata?.data.editedTime) {
        file.metadata.creationTime = file.pubMagicMetadata.data.editedTime;
    }
    if (file.pubMagicMetadata?.data.editedName) {
        file.metadata.title = file.pubMagicMetadata.data.editedName;
    }
    // @ts-expect-error TODO: The core types need to be updated to allow the
    // possibility of missing metadata fiels.
    return file;
};

const isFileEligible = (file: EnteFile) => {
    if (!isImageOrLivePhoto(file)) return false;
    if (file.info.fileSize > 100 * 1024 * 1024) return false;

    // This check is fast but potentially incorrect because in practice we do
    // encounter files that are incorrectly named and have a misleading
    // extension. To detect the actual type, we need to sniff the MIME type, but
    // that requires downloading and decrypting the file first.
    const [, extension] = nameAndExtension(file.metadata.title);
    if (extension && isNonWebImageFileExtension(extension)) {
        // Of the known non-web types, we support HEIC.
        return isHEICExtension(extension);
    }

    return true;
};

const isImageOrLivePhoto = (file: EnteFile) => {
    const fileType = file.metadata.fileType;
    return fileType == FILE_TYPE.IMAGE || fileType == FILE_TYPE.LIVE_PHOTO;
};

/**
 * Create and return a new data URL that can be used to show the given
 * {@link file} in our slideshow image viewer.
 *
 * Once we're done showing the file, the URL should be revoked using
 * {@link URL.revokeObjectURL} to free up browser resources.
 */
const createRenderableURL = async (castToken: string, file: EnteFile) => {
    const imageBlob = await renderableImageBlob(castToken, file);
    return URL.createObjectURL(imageBlob);
};

const renderableImageBlob = async (castToken: string, file: EnteFile) => {
    const shouldUseThumbnail = isChromecast();

    let blob = await downloadFile(castToken, file, shouldUseThumbnail);

    let fileName = file.metadata.title;
    if (!shouldUseThumbnail && file.metadata.fileType == FILE_TYPE.LIVE_PHOTO) {
        const { imageData, imageFileName } = await decodeLivePhoto(
            fileName,
            blob,
        );
        fileName = imageFileName;
        blob = new Blob([imageData]);
    }

    // We cannot rely on the file's extension to detect the file type, some
    // files are incorrectly named. So use a MIME type sniffer first, but if
    // that fails than fallback to the extension.
    const mimeType = await detectMediaMIMEType(new File([blob], fileName));
    if (!mimeType)
        throw new Error(`Could not detect MIME type for file ${fileName}`);

    if (mimeType == "image/heif" || mimeType == "image/heic")
        blob = await heicToJPEG(blob);

    return new Blob([blob], { type: mimeType });
};

const downloadFile = async (
    castToken: string,
    file: EnteFile,
    shouldUseThumbnail: boolean,
) => {
    if (!isImageOrLivePhoto(file))
        throw new Error("Can only cast images and live photos");

    const customOrigin = await customAPIOrigin();

    const getFile = () => {
        if (customOrigin) {
            // See: [Note: Passing credentials for self-hosted file fetches]
            const params = new URLSearchParams({ castToken });
            const baseURL = shouldUseThumbnail
                ? `${customOrigin}/cast/files/preview/${file.id}`
                : `${customOrigin}/cast/files/download/${file.id}`;
            return fetch(`${baseURL}?${params.toString()}`);
        } else {
            const url = shouldUseThumbnail
                ? `https://cast-albums.ente.io/preview/?fileID=${file.id}`
                : `https://cast-albums.ente.io/download/?fileID=${file.id}`;
            return fetch(url, {
                headers: {
                    "X-Cast-Access-Token": castToken,
                },
            });
        }
    };

    const res = await getFile();
    if (!res.ok)
        throw new Error(
            `Failed to fetch file with ID ${file.id}: HTTP ${res.status}`,
        );

    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    const decrypted = await cryptoWorker.decryptFile(
        new Uint8Array(await res.arrayBuffer()),
        await cryptoWorker.fromB64(
            shouldUseThumbnail
                ? file.thumbnail.decryptionHeader
                : file.file.decryptionHeader,
        ),
        file.key,
    );
    return new Response(decrypted).blob();
};

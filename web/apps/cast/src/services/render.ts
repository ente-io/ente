import { FILE_TYPE } from "@/media/file-type";
import { isNonWebImageFileExtension } from "@/media/formats";
import { scaledImageDimensions } from "@/media/image";
import { decodeLivePhoto } from "@/media/live-photo";
import { nameAndExtension } from "@/next/file";
import log from "@/next/log";
import { shuffled } from "@/utils/array";
import { ensure } from "@/utils/ensure";
import { wait } from "@/utils/promise";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import HTTPService from "@ente/shared/network/HTTPService";
import { getCastFileURL, getEndpoint } from "@ente/shared/network/api";
import type { CastData } from "services/cast-data";
import { detectMediaMIMEType } from "services/detect-type";
import {
    EncryptedEnteFile,
    EnteFile,
    FileMagicMetadata,
    FilePublicMagicMetadata,
} from "types/file";

type RenderableImageURLPair = [url: string, nextURL: string];

/**
 * An async generator function that loops through all the files in the
 * collection, returning renderable URLs to each that can be displayed in a
 * slideshow.
 *
 * Each time it resolves with a pair of URLs (a {@link RenderableImageURLPair}),
 * one for the next slideshow image, and one for the slideshow image that will
 * be displayed after that. It also pre-fetches the next to next URL each time.
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
 * the next one. It will however throw if there are errors when getting the
 * collection itself. This can happen both the first time, or when we are about
 * to loop around to the start of the collection.
 *
 * @param castData The collection to show and credentials to fetch the files
 * within it.
 */
export const renderableImageURLs = async function* (castData: CastData) {
    const { collectionKey, castToken } = castData;

    /**
     * Keep a FIFO queue of the URLs that we've vended out recently so that we
     * can revoke those that are not being shown anymore.
     */
    const previousURLs: string[] = [];

    /** The URL pair that we will yield */
    const urls: string[] = [];

    /** Number of milliseconds to keep the slide on the screen. */
    const slideDuration = 10000; /* 10 s */

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

    while (true) {
        const encryptedFiles = shuffled(
            await getEncryptedCollectionFiles(castToken),
        );

        let haveEligibleFiles = false;

        for (const encryptedFile of encryptedFiles) {
            const file = await decryptEnteFile(encryptedFile, collectionKey);

            if (!isFileEligibleForCast(file)) continue;

            console.log("will start createRenderableURL", new Date());
            try {
                urls.push(await createRenderableURL(castToken, file));
                haveEligibleFiles = true;
            } catch (e) {
                log.error("Skipping unrenderable file", e);
                continue;
            }

            console.log("did end createRenderableURL", new Date());

            // Need at least a pair.
            //
            // There are two scenarios:
            //
            // - First run: urls will initially be empty, so gobble two.
            //
            // - Subsequently, urls will have the "next" / "preloaded" URL left
            //   over from the last time. We'll promote that to being the one
            //   that'll get displayed, and preload another one.
            // if (urls.length < 2) continue;

            // The last element of previousURLs is the URL that is currently
            // being shown on screen.
            //
            // The last to last element is the one that was shown prior to that,
            // and now can be safely revoked.
            if (previousURLs.length > 1)
                URL.revokeObjectURL(previousURLs.shift());

            // The URL that'll now get displayed on screen.
            const url = ensure(urls.shift());
            // The URL that we're preloading for next time around.
            // TODO(MR): Cast
            const nextURL = ""; //ensure(urls[0]);

            previousURLs.push(url);

            const urlPair: RenderableImageURLPair = [url, nextURL];

            const elapsedTime = Date.now() - lastYieldTime;
            if (elapsedTime > 0 && elapsedTime < slideDuration) {
                console.log("waiting", slideDuration - elapsedTime);
                await wait(slideDuration - elapsedTime);
            }

            lastYieldTime = Date.now();
            yield urlPair;
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
    let resp;
    do {
        resp = await HTTPService.get(
            `${getEndpoint()}/cast/diff`,
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
    let fileMagicMetadata: FileMagicMetadata;
    let filePubMagicMetadata: FilePublicMagicMetadata;
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
    return file;
};

const isFileEligibleForCast = (file: EnteFile) => {
    if (!isImageOrLivePhoto(file)) return false;
    if (file.info.fileSize > 100 * 1024 * 1024) return false;

    const [, extension] = nameAndExtension(file.metadata.title);
    if (isNonWebImageFileExtension(extension)) return false;

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
    const resizedBlob = needsResize(file) ? await resize(imageBlob) : imageBlob;
    return URL.createObjectURL(resizedBlob);
};

const renderableImageBlob = async (castToken: string, file: EnteFile) => {
    const fileName = file.metadata.title;
    let blob = await downloadFile(castToken, file);
    if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
        const { imageData } = await decodeLivePhoto(fileName, blob);
        blob = new Blob([imageData]);
    }
    const mimeType = await detectMediaMIMEType(new File([blob], fileName));
    if (!mimeType)
        throw new Error(`Could not detect MIME type for file ${fileName}`);
    return new Blob([blob], { type: mimeType });
};

const downloadFile = async (castToken: string, file: EnteFile) => {
    if (!isImageOrLivePhoto(file))
        throw new Error("Can only cast images and live photos");

    const url = getCastFileURL(file.id);
    // TODO(MR): Remove if usused eventually
    // const url = getCastThumbnailURL(file.id);
    const resp = await HTTPService.get(
        url,
        null,
        {
            "X-Cast-Access-Token": castToken,
        },
        { responseType: "arraybuffer" },
    );
    if (resp.data === undefined) throw new Error(`Failed to get ${url}`);

    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    const decrypted = await cryptoWorker.decryptFile(
        new Uint8Array(resp.data),
        await cryptoWorker.fromB64(file.file.decryptionHeader),
        // TODO(MR): Remove if usused eventually
        // await cryptoWorker.fromB64(file.thumbnail.decryptionHeader),
        file.key,
    );
    return new Response(decrypted).blob();
};

/**
 * [Note: Chromecast media size limits]
 *
 * The Chromecast device fails to load the images if we give it too large
 * images. This was tested in practice with a 2nd Gen Chromecast.
 *
 * The documentation also states:
 *
 * > Images have a display size limitation of 720p (1280x720). Images should be
 * > optimized to 1280x720 or less to avoid scaling down on the receiver device.
 * >
 * > https://developers.google.com/cast/docs/media
 *
 * So if the size of the image we're wanting to show is more than these limits,
 * resize it down to a JPEG whose size is clamped to these limits.
 */
const needsResize = (file: EnteFile) => {
    const w = file.pubMagicMetadata.data.w;
    const h = file.pubMagicMetadata.data.h;
    // If we don't have the size, always resize to be on the safer side.
    if (!w || !h) return true;
    // Otherwise resize if any of the dimensions is outside the recommendation.
    return Math.max(w, h) > 1280 || Math.min(w, h) > 720;
};

const resize = async (blob: Blob): Promise<Blob> => {
    const canvas = document.createElement("canvas");
    const canvasCtx = ensure(canvas.getContext("2d"));

    return await new Promise((resolve, reject) => {
        const imageURL = URL.createObjectURL(blob);
        const image = new Image();
        image.setAttribute("src", imageURL);
        image.onload = () => {
            try {
                URL.revokeObjectURL(imageURL);
                const { width, height } = scaledImageDimensions(
                    image.width,
                    image.height,
                    1280,
                );
                canvas.width = width;
                canvas.height = height;
                canvasCtx.drawImage(image, 0, 0, width, height);
                canvas.toBlob(
                    (blob) => resolve(ensure(blob)),
                    "image/jpeg",
                    0.8 /* quality */,
                );
            } catch (e: unknown) {
                reject(e);
            }
        };
    });
};

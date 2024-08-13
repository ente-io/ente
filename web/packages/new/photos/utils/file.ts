import { isDesktop } from "@/base/app";
import log from "@/base/log";
import { CustomErrorMessage } from "@/base/types/ipc";
import { workerBridge } from "@/base/worker/worker-bridge";
import { needsJPEGConversion } from "@/media/formats";
import { heicToJPEG } from "@/media/heic-convert";
import type { EnteFile } from "../types/file";
import { detectFileTypeInfo } from "./detect-type";

/**
 * This will be set to false if we get an error from the Node.js side of our
 * desktop app telling us that native JPEG conversion is not available for the
 * current OS/arch combination.
 *
 * That way, we can stop pestering it again and again, saving an IPC round-trip.
 */
let _isNativeJPEGConversionAvailable = true;

/**
 * @returns a string to use as an identifier when logging information about the
 * given {@link enteFile}. The returned string contains the file name (for ease
 * of debugging) and the file ID (for exactness).
 */
export const fileLogID = (enteFile: EnteFile) =>
    // TODO: Remove this when file/metadata types have optionality annotations.
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    `file ${enteFile.metadata.title ?? "-"} (${enteFile.id})`;

/**
 * [Note: File name for local EnteFile objects]
 *
 * The title property in a file's metadata is the original file's name. The
 * metadata of a file cannot be edited. So if later on the file's name is
 * changed, then the edit is stored in the `editedName` property of the public
 * metadata of the file.
 *
 * This function merges these edits onto the file object that we use locally.
 * Effectively, post this step, the file's metadata.title can be used in lieu of
 * its filename.
 */
export function mergeMetadata(files: EnteFile[]): EnteFile[] {
    return files.map((file) => mergeMetadata1(file));
}

export function mergeMetadata1(file: EnteFile): EnteFile {
    if (file.pubMagicMetadata?.data.editedTime) {
        file.metadata.creationTime = file.pubMagicMetadata.data.editedTime;
    }
    if (file.pubMagicMetadata?.data.editedName) {
        file.metadata.title = file.pubMagicMetadata.data.editedName;
    }
    // In a very rare cases (have found only one so far, a very old file
    // uploaded by an initial dev version of Ente) the photo has no modification
    // time. Gracefully handle such cases.
    if (!file.metadata.modificationTime)
        file.metadata.modificationTime = file.metadata.creationTime;

    return file;
}

/**
 * Return a new {@link Blob} containing data in a format that the browser
 * (likely) knows how to render (in an img tag, or on the canvas).
 *
 * The type of the returned blob is set, whenever possible, to the MIME type of
 * the data that we're dealing with.
 *
 * @param fileName The name of the file whose data is {@link imageBlob}.
 *
 * @param imageBlob A {@link Blob} containing the contents of an image file.
 *
 * The logic used by this function is:
 *
 * 1.  Try to detect the MIME type of the file from its contents and/or name.
 *
 * 2.  If this detected type is one of the types that we know that the browser
 *     likely cannot render, continue. Otherwise return the imageBlob that was
 *     passed in (after setting its MIME type).
 *
 * 3.  If we're running in our desktop app and this MIME type is something our
 *     desktop app can natively convert to a JPEG (using ffmpeg), do that and
 *     return the resultant JPEG blob.
 *
 * 4.  If this is an HEIC file, use our (WASM) HEIC converter and return the
 *     resultant JPEG blob.
 *
 * 5.  Otherwise return the original (with the MIME type if we were able to
 *     deduce one).
 *
 * In will catch all errors and return the original in those cases.
 */
export const renderableImageBlob = async (
    fileName: string,
    imageBlob: Blob,
) => {
    try {
        const file = new File([imageBlob], fileName);
        const fileTypeInfo = await detectFileTypeInfo(file);
        const { extension, mimeType } = fileTypeInfo;

        log.debug(() => ["Get renderable blob", { fileName, ...fileTypeInfo }]);

        if (needsJPEGConversion(extension)) {
            // If we're running in our desktop app, see if our Node.js layer can
            // convert this into a JPEG using native tools.

            if (isDesktop && _isNativeJPEGConversionAvailable) {
                try {
                    return await nativeConvertToJPEG(imageBlob);
                } catch (e) {
                    if (
                        e instanceof Error &&
                        e.message.endsWith(CustomErrorMessage.NotAvailable)
                    ) {
                        _isNativeJPEGConversionAvailable = false;
                    } else {
                        log.error("Native conversion to JPEG failed", e);
                    }
                }
            }

            // If the previous step failed, or if native JPEG conversion is not
            // available on this platform, for HEIC/HEIF files we can fallback
            // to our web HEIC converter.

            if (extension == "heic" || extension == "heif") {
                return await heicToJPEG(imageBlob);
            }
        }

        // Either it is something that the browser already knows how to render
        // (e.g. JPEG/PNG), or is a file extension that might be supported in
        // some browsers (e.g. JPEG 2000), or a file extension that we haven't
        // specifically whitelisted for conversion (any arbitrary extension not
        // part of `needsJPEGConversion`).
        //
        // Give it to the browser, attaching the mime type if possible.

        if (!mimeType) {
            log.info(
                "Attempting to get renderable blob for a file without a MIME type",
                fileName,
            );
            return imageBlob;
        } else {
            return new Blob([imageBlob], { type: mimeType });
        }
    } catch (e) {
        log.error(
            `Failed to get renderable blob for ${fileName}, will fallback to the original`,
            e,
        );
        return imageBlob;
    }
};

/**
 * Convert {@link imageBlob} to a JPEG blob.
 *
 * The presumption is that method used by our desktop app for converting to JPEG
 * should be able to handle files with all extensions for which
 * {@link needsJPEGConversion} returns true.
 */
const nativeConvertToJPEG = async (imageBlob: Blob) => {
    const startTime = Date.now();
    const imageData = new Uint8Array(await imageBlob.arrayBuffer());
    const electron = globalThis.electron;
    // If we're running in a worker, we need to reroute the request back to
    // the main thread since workers don't have access to the `window` (and
    // thus, to the `window.electron`) object.
    const jpegData = electron
        ? await electron.convertToJPEG(imageData)
        : await workerBridge.convertToJPEG(imageData);
    log.debug(() => `Native JPEG conversion took ${Date.now() - startTime} ms`);
    return new Blob([jpegData], { type: "image/jpeg" });
};

import { isNonWebImageFileExtension } from "@/media/formats";
import { heicToJPEG } from "@/media/heic-convert";
import { isDesktop } from "@/next/app";
import log from "@/next/log";
import { CustomErrorMessage } from "@/next/types/ipc";
import { workerBridge } from "@/next/worker/worker-bridge";
import type { EnteFile } from "../types/file";
import { detectFileTypeInfo } from "./detect-type";

class ModuleState {
    /**
     * This will be set to true if we get an error from the Node.js side of our
     * desktop app telling us that native JPEG conversion is not available for
     * the current OS/arch combination.
     *
     * That way, we can stop pestering it again and again (saving an IPC
     * round-trip).
     *
     * Note the double negative when it is used.
     */
    isNativeJPEGConversionNotAvailable = false;
}

const moduleState = new ModuleState();

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
    return files.map((file) => {
        // TODO: Until the types reflect reality
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        if (file.pubMagicMetadata?.data.editedTime) {
            file.metadata.creationTime = file.pubMagicMetadata.data.editedTime;
        }
        // TODO: Until the types reflect reality
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        if (file.pubMagicMetadata?.data.editedName) {
            file.metadata.title = file.pubMagicMetadata.data.editedName;
        }

        return file;
    });
}

/**
 * The returned blob.type is filled in, whenever possible, with the MIME type of
 * the data that we're dealing with.
 */
export const getRenderableImage = async (fileName: string, imageBlob: Blob) => {
    try {
        const tempFile = new File([imageBlob], fileName);
        const fileTypeInfo = await detectFileTypeInfo(tempFile);
        log.debug(
            () =>
                `Need renderable image for ${JSON.stringify({ fileName, ...fileTypeInfo })}`,
        );
        const { extension } = fileTypeInfo;

        if (!isNonWebImageFileExtension(extension)) {
            // Either it is something that the browser already knows how to
            // render, or something we don't even about yet.
            const mimeType = fileTypeInfo.mimeType;
            if (!mimeType) {
                log.info(
                    "Trying to render a file without a MIME type",
                    fileName,
                );
                return imageBlob;
            } else {
                return new Blob([imageBlob], { type: mimeType });
            }
        }

        const available = !moduleState.isNativeJPEGConversionNotAvailable;
        if (isDesktop && available && isNativeConvertibleToJPEG(extension)) {
            // If we're running in our desktop app, see if our Node.js layer can
            // convert this into a JPEG using native tools for us.
            try {
                return await nativeConvertToJPEG(imageBlob);
            } catch (e) {
                if (
                    e instanceof Error &&
                    e.message.endsWith(CustomErrorMessage.NotAvailable)
                ) {
                    moduleState.isNativeJPEGConversionNotAvailable = true;
                } else {
                    log.error("Native conversion to JPEG failed", e);
                }
            }
        }

        if (extension == "heic" || extension == "heif") {
            // For HEIC/HEIF files we can use our web HEIC converter.
            return await heicToJPEG(imageBlob);
        }

        return undefined;
    } catch (e) {
        log.error(`Failed to get renderable image for ${fileName}`, e);
        return undefined;
    }
};

/**
 * File extensions which our native JPEG conversion code should be able to
 * convert to a renderable image.
 */
const convertibleToJPEGExtensions = [
    "heic",
    "rw2",
    "tiff",
    "arw",
    "cr3",
    "cr2",
    "nef",
    "psd",
    "dng",
    "tif",
];

/**
 * Return true if {@link extension} is amongst the file extensions which we
 * expect our native JPEG conversion to be able to process.
 */
export const isNativeConvertibleToJPEG = (extension: string) =>
    convertibleToJPEGExtensions.includes(extension.toLowerCase());

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

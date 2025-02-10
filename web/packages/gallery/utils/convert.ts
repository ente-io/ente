import { isDesktop } from "@/base/app";
import log from "@/base/log";
import { workerBridge } from "@/base/worker/worker-bridge";
import { isHEICExtension, needsJPEGConversion } from "@/media/formats";
import { heicToJPEG } from "@/media/heic-convert";
import { convertToMP4 } from "../services/ffmpeg";
import { detectFileTypeInfo } from "./detect-type";

/**
 * Return a new {@link Blob} containing an image's data in a format that the
 * browser (likely) knows how to render (in an img tag, or on the canvas).
 *
 * The type of the returned blob is set, whenever possible, to the MIME type of
 * the data that we're dealing with.
 *
 * @param imageBlob A {@link Blob} containing the contents of an image file.
 *
 * @param fileName The name of the file whose data {@link imageBlob} is.
 *
 * The logic used by this function is:
 *
 * 1. Try to detect the MIME type of the file from its contents and/or name.
 *
 * 2. If this detected type is one of the types that we know that the browser
 *    likely cannot render, continue. Otherwise return the imageBlob that was
 *    passed in (after setting its MIME type).
 *
 * 3. If we're running in our desktop app and this MIME type is something our
 *    desktop app can natively convert to a JPEG (using ffmpeg), do that and
 *    return the resultant JPEG blob.
 *
 * 4. If this is an HEIC file, use our (Wasm) HEIC converter and return the
 *    resultant JPEG blob.
 *
 * 5. Otherwise return the original (with the MIME type if we were able to
 *    deduce one).
 *
 * In will catch all errors and return the original in those cases.
 */
export const renderableImageBlob = async (
    imageBlob: Blob,
    fileName: string,
) => {
    try {
        const file = new File([imageBlob], fileName);
        const fileTypeInfo = await detectFileTypeInfo(file);
        const { extension, mimeType } = fileTypeInfo;

        if (needsJPEGConversion(extension)) {
            log.debug(() => [`Converting ${fileName} to JPEG`, fileTypeInfo]);

            // If we're running in our desktop app, see if our Node.js layer can
            // convert this into a JPEG using native tools.

            if (isDesktop) {
                try {
                    return await nativeConvertToJPEG(imageBlob);
                } catch (e) {
                    log.error("Native conversion to JPEG failed", e);
                }
            }

            // If the previous step failed, or if native JPEG conversion is not
            // available on this platform, for HEIC/HEIF files we can fallback
            // to our web HEIC converter.

            if (isHEICExtension(extension)) {
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
                "Attempting to convert a file without a MIME type",
                fileName,
            );
            return imageBlob;
        } else {
            return new Blob([imageBlob], { type: mimeType });
        }
    } catch (e) {
        log.error(`Failed to convert ${fileName}, will use the original`, e);
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
        : await workerBridge!.convertToJPEG(imageData);
    log.debug(() => `Native JPEG conversion took ${Date.now() - startTime} ms`);
    return new Blob([jpegData], { type: "image/jpeg" });
};

/**
 * Return a new {@link Blob} containing a video's data in a format that the
 * browser (likely) knows how to play back (using an video tag).
 *
 * Unlike {@link renderableImageBlob}, this uses a much simpler flowchart:
 *
 * - If the browser thinks it can play the video, then return the original blob
 *   back.
 *
 * - Otherwise try to convert using FFmpeg. This conversion always happens on
 *   the desktop app, but in the browser the conversion only happens for short
 *   videos since the Wasm FFmpeg implementation is much slower. There is also a
 *   flag to force this conversion regardless.
 */
export const playableVideoBlob = async (
    fileName: string,
    videoBlob: Blob,
    forceConvert: boolean,
) => {
    const converted = async () => {
        try {
            log.info(`Converting ${fileName} to mp4`);
            const convertedBlob = await convertToMP4(videoBlob);
            return new Blob([convertedBlob], { type: "video/mp4" });
        } catch (e) {
            log.error(`Video conversion failed for ${fileName}`, e);
            return null;
        }
    };

    // If we've been asked to force convert, do it regardless of anything else.
    if (forceConvert) return converted();

    const isPlayable = await isPlaybackPossible(URL.createObjectURL(videoBlob));
    if (isPlayable) return videoBlob;

    // The browser doesn't think it can play this video, try transcoding.
    if (isDesktop) {
        return converted();
    } else {
        // Don't try to transcode on the web if the file is too big.
        if (videoBlob.size > 100 * 1024 * 1024 /* 100 MB, arbitrary */) {
            return null;
        } else {
            return converted();
        }
    }
};

/**
 * Try to see if the browser thinks it can play the video pointed to by the
 * given {@link url} by creating a <video> element and initiating playback.
 *
 * [Note: Forcing conversion of playable videos]
 *
 * Note that this can sometimes cause false positives if the browser can play
 * some of the streams in the video, but not all. For example, the browser may
 * be able to play back the video stream, but not the audio stream (say due to
 * some codec issue): in such cases this function will return true, causing us
 * to skip conversion, but when the user actually plays the video there will be
 * no sound.
 *
 * As an escape hatch, we provide a force convert button in the UI for such
 * cases, which'll cause the {@link forceConvert} flag in our caller function to
 * be set. If so, it'll bypasses this preflight check we use to see if the
 * browser can already play the video, and instead will always be transcoded.
 */
const isPlaybackPossible = async (url: string) =>
    new Promise((resolve) => {
        const t = setTimeout(() => {
            video.remove();
            resolve(false);
        }, 1000);

        const video = document.createElement("video");
        video.addEventListener("canplay", () => {
            clearTimeout(t);
            // Clean up the video element.
            video.remove();
            // Check for duration > 0 to make sure it is not a broken video.
            if (video.duration > 0) {
                resolve(true);
            } else {
                resolve(false);
            }
        });
        video.addEventListener("error", () => {
            clearTimeout(t);
            video.remove();
            resolve(false);
        });

        video.src = url;
    });

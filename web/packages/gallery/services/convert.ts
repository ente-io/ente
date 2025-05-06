import { isDesktop } from "ente-base/app";
import log from "ente-base/log";
import { workerBridge } from "ente-base/worker/worker-bridge";
import type { EnteFile } from "ente-media/file";
import { FileType } from "ente-media/file-type";
import { isHEICExtension, needsJPEGConversion } from "ente-media/formats";
import { heicToJPEG } from "ente-media/heic-convert";
import { detectFileTypeInfo } from "../utils/detect-type";
import { convertToMP4 } from "./ffmpeg";

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
 * 4. If this is an HEIC file and the browser does not have native HEIC support,
 *    then use our (Wasm) HEIC converter and return the resultant JPEG blob.
 *
 * 5. Otherwise return the original (with the MIME type if we were able to
 *    deduce one).
 *
 * In will catch all errors and return the original in those cases.
 */
export const renderableImageBlob = async (
    imageBlob: Blob,
    fileName: string,
): Promise<Blob> => {
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
                // But first, check if the browser already knows how to natively
                // render HEICs, e.g. Safari 17+. In such cases not only is the
                // Wasm conversion unnecessary, the native hardware accelerated
                // support will also be _much_ faster.
                if (mimeType == "image/heic" && (await isHEICSupported())) {
                    log.debug(
                        () => `Using native HEIC support for ${fileName}`,
                    );
                } else {
                    return await heicToJPEG(imageBlob);
                }
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

let _isHEICSupported: Promise<boolean> | undefined;

/**
 * Return true if the browser can natively render HEIC files.
 *
 * For performance, the result of the check is cached. There shouldn't be a
 * reason for this cache to need be invalidated, the browser shouldn't suddenly
 * drop its HEIC support in the middle of it running (but I'm sure posterity
 * will prove this assumption wrong in a way I can't yet anticipate).
 *
 * Some more details:
 *
 * - The check works by trying to load a small HEIC file.
 *
 * - Currently (Spring 2025), the only browser with support for HEIC is Safari.
 */
const isHEICSupported = () =>
    (_isHEICSupported ??= new Promise((resolve) => {
        const image = new Image();
        image.onload = () => resolve(true);
        image.onerror = () => resolve(false);
        image.src = testHEICDataURL;
    }));

/**
 * A data URL encoding the smallest HEIC image (439 bytes).
 *
 * Source:
 * https://github.com/vvideo/detect-audio-video/blob/main/src/image/smallest/index.ts
 */
const testHEICDataURL =
    "data:image/heic;base64,AAAAGGZ0eXBoZWljAAAAAG1pZjFoZWljAAABaW1ldGEAAAAAAAAAIWhkbHIAAAAAAAAAAHBpY3QAAAAAAAAAAAAAAAAAAAAADnBpdG0AAAAAAAEAAAAiaWxvYwAAAABEQAABAAEAAAAAAYkAAQAAAAAAAAAuAAAAI2lpbmYAAAAAAAEAAAAVaW5mZQIAAAAAAQAAaHZjMQAAAADpaXBycAAAAMppcGNvAAAAdmh2Y0MBA3AAAAAAAAAAAAAe8AD8/fj4AAAPAyAAAQAYQAEMAf//A3AAAAMAkAAAAwAAAwAeugJAIQABACpCAQEDcAAAAwCQAAADAAADAB6gIIEFluqumubgIaDAgAAAAwCAAAADAIQiAAEABkQBwXPBiQAAABRpc3BlAAAAAAAAAEAAAABAAAAAKGNsYXAAAAABAAAAAQAAAAEAAAAB////wQAAAAL////BAAAAAgAAABBwaXhpAAAAAAMICAgAAAAXaXBtYQAAAAAAAAABAAEEgQKDBAAAADZtZGF0AAAAKigBrwayEx2gkim3i/2Rd0CR/V6h6GbEyV3dheegYfLV9ZwraCH8nff+7w==";

/**
 * Return a object URL containing a video's data in a format that the browser
 * (likely) knows how to play back using an video tag.
 *
 * Unlike {@link renderableImageBlob}, this uses a much simpler flowchart:
 *
 * 1. If the browser thinks it can play the video, then return the an object URL
 *    created by directly using the provided {@link videoBlob}.
 *
 * 2. Otherwise try to convert using FFmpeg. This conversion always happens on
 *    the desktop app, but in the browser the conversion only happens for short
 *    videos since the Wasm FFmpeg implementation is much slower.
 *
 * 3. On errors, return the original (as would've happened for step 1).
 *
 * A special case if for FileType.livePhoto on Linux in the desktop app, where
 * the conversion always happens to workaround the audio only playback in that
 * specific scenario.
 *
 * @param file The {@link EnteFile} with which this video is associated.
 *
 * @param videoFileName The name of the video.
 *
 * @param videoBlob The contents of the video.
 *
 * @returns An object URL that can be used to playback the provided
 * {@link videoBlob}.
 */
export const playableVideoURL = async (
    file: EnteFile,
    videoFileName: string,
    videoBlob: Blob,
): Promise<string> => {
    const videoObjectURL = URL.createObjectURL(videoBlob);
    const isPlayable = await isPlaybackPossible(videoObjectURL);

    let shouldConvert = false;

    if (isPlayable) {
        // The browser thinks it can play this video.
        //
        // But it is not a guarantee. In particular, a problematic case is when
        // for a particular codec combination, browser can play the audio
        // stream, but not the video stream. `isPlaybackPossible` would return
        // true, but when the user will hear only audio and not see the video.
        //
        // For videos themselves, we solve this (and other issues) by providing
        // a streaming variant. However it can still happen for live photos.
        //
        // Unfortunately, I haven't found a way yet of detecting if this
        // scenario is going to arise (open a issue if you've found one).
        // Fortunately, this particular failure mode has only been reported on
        // Linux desktop app (which uses Chromium underneath). So we add a
        // special case - if (desktop && livePhoto && linux) then forceConvert.
        // Practically this is a reasonable fallback since the video component
        // of a live photo is going to be a few seconds only, and the video
        // conversion is fast in the desktop app.
        if (
            isDesktop &&
            file.metadata.fileType == FileType.livePhoto &&
            // eslint-disable-next-line @typescript-eslint/no-deprecated
            navigator.platform.startsWith("Linux")
        ) {
            shouldConvert = true;
        }
    } else {
        // The browser doesn't think it can play this video, try transcoding.
        if (isDesktop) {
            // Always on desktop.
            shouldConvert = true;
        } else {
            // Don't try to transcode on the web if the file is too big.
            if (videoBlob.size < 100 * 1024 * 1024 /* 100 MB, arbitrary */) {
                shouldConvert = true;
            }
        }
    }

    if (shouldConvert) {
        try {
            log.info(`Converting ${videoFileName} to mp4`);
            const convertedBlob = await convertToMP4(videoBlob);
            return URL.createObjectURL(
                new Blob([convertedBlob], { type: "video/mp4" }),
            );
        } catch (e) {
            log.error(`Video conversion failed for ${videoFileName}`, e);
        }
    }

    return videoObjectURL;
};

/**
 * Try to see if the browser thinks it can play the video pointed to by the
 * given {@link url} by creating a <video> element and initiating playback.
 *
 * Note that this can sometimes cause false positives if the browser can play
 * some of the streams in the video, but not all. For example, the browser may
 * be able to play back the video stream, but not the audio stream (say due to
 * some codec issue): in such cases this function will return true, causing us
 * to skip conversion, but when the user actually plays the video there will be
 * no sound.
 *
 * To deal with such cases in an holistic manner, we have a streaming variant of
 * the video that gets transcoded into a (near) universal format.
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

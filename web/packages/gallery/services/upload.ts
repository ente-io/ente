import log from "ente-base/log";
import { customAPIOrigin } from "ente-base/origins";
import type { Electron, ZipItem } from "ente-base/types/ipc";
import { nullToUndefined } from "ente-utils/transform";
import { z } from "zod";

/**
 * Internal in-memory state shared by the functions in this module.
 *
 * This entire object will be reset on logout.
 */
class UploadState {
    /**
     * `true` if the workers should be disabled for uploads.
     */
    shouldDisableCFUploadProxy = false;
}

/** State shared by the functions in this module. See {@link UploadState}. */
let _state = new UploadState();

/**
 * Reset any internal state maintained by the module.
 *
 * This is primarily meant as a way for stateful apps (e.g. photos) to clear any
 * user specific state on logout.
 */
export const resetUploadState = () => {
    _state = new UploadState();
};

/**
 * An item to upload is one of the following:
 *
 * 1. [web] A file drag-and-dropped or selected by the user when we are running
 *    in the web browser. These is the {@link File} case.
 *
 * 2. [desktop] A file drag-and-dropped or selected by the user when we are
 *    running in the context of our desktop app. In such cases, we also have the
 *    absolute path of the file in the user's local file system. This is the
 *    {@link FileAndPath} case.
 *
 * 3. [desktop] A file path programmatically requested by the desktop app. For
 *    example, we might be resuming a previously interrupted upload after an app
 *    restart (thus we no longer have access to the {@link File} from case 2).
 *    Or we could be uploading a file this is in one of the folders the user has
 *    asked us to watch for changes. This is the `string` case.
 *
 * 4. [desktop] A file within a zip file on the user's local file system. This
 *    too is only possible when we are running in the context of our desktop
 *    app. The user might have drag-and-dropped or selected a zip file, or it
 *    might be a zip file that they'd previously selected but we now are
 *    resuming an interrupted upload of. Either ways, what we have is a tuple
 *    containing the (path to zip file, and the name of an entry within that zip
 *    file). This is the {@link ZipItem} case.
 *
 * Only case 1 is possible when we're running in the web app.
 *
 * Only case 2, 3 and 4 are possible when we're running in the desktop app.
 *
 * Also see: [Note: Reading a UploadItem].
 */
export type UploadItem = File | FileAndPath | string | ZipItem;

/**
 * When we are running in the context of our desktop app, we have access to the
 * absolute path of {@link File} objects. This convenience type clubs these two
 * bits of information, saving us the need to query the path again and again
 * using the {@link getPathForFile} method of {@link Electron}.
 */
export interface FileAndPath {
    file: File;
    path: string;
}

/**
 * The of cases of {@link UploadItem} that apply when we're running in the
 * context of our desktop app.
 */
export type DesktopUploadItem = Exclude<UploadItem, File>;

/**
 * Assert that the given {@link UploadItem} is, in fact, an {@link DesktopUploadItem}.
 *
 * @param electron A witness to the fact that we're running in the context of
 * the desktop app. The electron instance is not actually used by this function.
 *
 * @param uploadItem The upload item we obtained from an arbitrary place in the app.
 *
 * @returns The same {@link uploadItem}, but after excluding the cases that can
 * only happen when running in the web app.
 */
export const toDesktopUploadItem = (
    electron: Electron,
    uploadItem: UploadItem,
): DesktopUploadItem => {
    if (uploadItem instanceof File) {
        log.info(`Invalid upload item (electron: ${!!electron})`, uploadItem);
        throw new Error(
            "Found a File upload item even though we're running in the desktop app",
        );
    }
    return uploadItem;
};

/**
 * For each of cases of {@link UploadItem} that apply when we're running in the
 * context of our desktop app, return a value that can be passed to
 * {@link Electron} functions over IPC.
 */
export const toDataOrPathOrZipEntry = (desktopUploadItem: DesktopUploadItem) =>
    typeof desktopUploadItem == "string" || Array.isArray(desktopUploadItem)
        ? desktopUploadItem
        : desktopUploadItem.path;

export const RANDOM_PERCENTAGE_PROGRESS_FOR_PUT = () => 90 + 10 * Math.random();

export type UploadPhase =
    | "preparing"
    | "readingMetadata"
    | "uploading"
    | "cancelling"
    | "done";

export type UploadResult =
    | "failed"
    | "alreadyUploaded"
    | "unsupported"
    | "blocked"
    | "tooLarge"
    | "largerThanAvailableStorage"
    | "uploaded"
    | "uploadedWithStaticThumbnail"
    | "addedSymlink";

/**
 * Return true to disable the upload of files via Cloudflare Workers.
 *
 * These workers were introduced as a way of make file uploads faster:
 * https://ente.io/blog/tech/making-uploads-faster/
 *
 * By default, that's the route we take. However, there are multiple reasons why
 * this might be disabled.
 *
 * 1. During development and when self-hosting it we disable them to directly
 *    upload to the S3-compatible URLs returned by the ente API.
 *
 * 2. In rare cases, the user might have trouble reaching Cloudflare's network
 *    from their ISP. In such cases, the user can locally turn this off via
 *    settings.
 *
 * 3. There is also the original global toggle that was added when this feature
 *    was introduced.
 *
 * This function returns the in-memory value. It is updated when #2 changes (if
 * we're running in a context where that makes sense). The #3 remote status is
 * obtained once, on app start.
 */
export const shouldDisableCFUploadProxy = () =>
    _state.shouldDisableCFUploadProxy;

/**
 * Update the in-memory value of {@link shouldDisableCFUploadProxy}.
 *
 * @param savedPreference An optional user preference that the user has
 * expressed to disable the proxy.
 */
export const updateShouldDisableCFUploadProxy = async (
    savedPreference?: boolean,
) => {
    _state.shouldDisableCFUploadProxy =
        savedPreference || (await computeShouldDisableCFUploadProxy());
};

const computeShouldDisableCFUploadProxy = async () => {
    // If a custom origin is set, that means we're not running a production
    // deployment (maybe we're running locally, or being self-hosted).
    //
    // In such cases, disable the Cloudflare upload proxy (which won't work for
    // self-hosters), and instead just directly use the upload URLs that museum
    // gives us.
    if (await customAPIOrigin()) return true;

    // See if the global flag to disable this is set.
    try {
        const res = await fetch("https://static.ente.io/feature_flags.json");
        return (
            StaticFeatureFlags.parse(await res.json()).disableCFUploadProxy ??
            false
        );
    } catch (e) {
        log.warn("Ignoring error when getting feature_flags.json", e);
        return false;
    }
};

const StaticFeatureFlags = z.object({
    disableCFUploadProxy: z.boolean().nullish().transform(nullToUndefined),
});

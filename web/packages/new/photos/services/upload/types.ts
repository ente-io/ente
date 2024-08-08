import type { ZipItem } from "@/base/types/ipc";

/**
 * An item to upload is one of the following:
 *
 * 1. A file drag-and-dropped or selected by the user when we are running in the
 *    web browser. These is the {@link File} case.
 *
 * 2. A file drag-and-dropped or selected by the user when we are running in the
 *    context of our desktop app. In such cases, we also have the absolute path
 *    of the file in the user's local file system. This is the
 *    {@link FileAndPath} case.
 *
 * 3. A file path programmatically requested by the desktop app. For example, we
 *    might be resuming a previously interrupted upload after an app restart
 *    (thus we no longer have access to the {@link File} from case 2). Or we
 *    could be uploading a file this is in one of the folders the user has asked
 *    us to watch for changes. This is the `string` case.
 *
 * 4. A file within a zip file on the user's local file system. This too is only
 *    possible when we are running in the context of our desktop app. The user
 *    might have drag-and-dropped or selected a zip file, or it might be a zip
 *    file that they'd previously selected but we now are resuming an
 *    interrupted upload of. Either ways, what we have is a tuple containing the
 *    (path to zip file, and the name of an entry within that zip file). This is
 *    the {@link ZipItem} case.
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
 * For each of cases of {@link UploadItem} that apply when we're running in the
 * context of our desktop app, return a value that can be passed to
 * {@link Electron} functions over IPC.
 */
export const toDataOrPathOrZipEntry = (desktopUploadItem: DesktopUploadItem) =>
    typeof desktopUploadItem == "string" || Array.isArray(desktopUploadItem)
        ? desktopUploadItem
        : desktopUploadItem.path;

export const RANDOM_PERCENTAGE_PROGRESS_FOR_PUT = () => 90 + 10 * Math.random();

export enum UPLOAD_STAGES {
    START,
    READING_GOOGLE_METADATA_FILES,
    EXTRACTING_METADATA,
    UPLOADING,
    CANCELLING,
    FINISH,
}

export enum UPLOAD_RESULT {
    FAILED,
    ALREADY_UPLOADED,
    UNSUPPORTED,
    BLOCKED,
    TOO_LARGE,
    LARGER_THAN_AVAILABLE_STORAGE,
    UPLOADED,
    UPLOADED_WITH_STATIC_THUMBNAIL,
    ADDED_SYMLINK,
}

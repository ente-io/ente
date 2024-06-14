// Following are types shared with the Electron process. This list is manually
// kept in sync with `desktop/src/types/ipc.ts`.
//
// See [Note: types.ts <-> preload.ts <-> ipc.ts]

/**
 * Extra APIs provided by our Node.js layer when our code is running inside our
 * desktop (Electron) app.
 *
 * This list is manually kept in sync with `desktop/src/preload.ts`. In case of
 * a mismatch, the types may lie. See also: [Note: types.ts <-> preload.ts <->
 * ipc.ts]
 *
 * These extra objects and functions will only be available when our code is
 * running as the renderer process in Electron. These can be accessed by using
 * the `electron` property of the window (See @{link globalElectron} for a
 * systematic way of getting at that).
 */
export interface Electron {
    // - General

    /**
     * Return the version of the desktop app.
     *
     * The return value is of the form `v1.2.3`.
     */
    appVersion: () => Promise<string>;

    /**
     * Log the given {@link message} to the on-disk log file maintained by the
     * desktop app.
     *
     * Note: Unlike the other functions exposed over the Electron bridge,
     * logToDisk is fire-and-forget and does not return a promise.
     */
    logToDisk: (message: string) => void;

    /**
     * Open the given {@link dirPath} in the system's folder viewer.
     *
     * For example, on macOS this'll open {@link dirPath} in Finder.
     */
    openDirectory: (dirPath: string) => Promise<void>;

    /**
     * Open the app's log directory in the system's folder viewer.
     *
     * @see {@link openDirectory}
     */
    openLogDirectory: () => Promise<void>;

    /**
     * Ask the user to select a directory on their local file system, and return
     * it path.
     *
     * The returned path is guaranteed to use POSIX separators ('/').
     *
     * We don't strictly need IPC for this, we can use a hidden <input> element
     * and trigger its click for the same behaviour (as we do for the
     * `useFileInput` hook that we use for uploads). However, it's a bit
     * cumbersome, and we anyways will need to IPC to get back its full path, so
     * it is just convenient to expose this direct method.
     */
    selectDirectory: () => Promise<string | undefined>;

    /**
     * Perform any logout related cleanup of native side state.
     */
    logout: () => Promise<void>;

    /**
     * Return the previously saved encryption key from persistent safe storage.
     *
     * If no such key is found, return `undefined`.
     *
     * See also: {@link saveEncryptionKey}.
     */
    encryptionKey: () => Promise<string | undefined>;

    /**
     * Save the given {@link encryptionKey} into persistent safe storage.
     */
    saveEncryptionKey: (encryptionKey: string) => Promise<void>;

    /**
     * Set or clear the callback {@link cb} to invoke whenever the app comes
     * into the foreground. More precisely, the callback gets invoked when the
     * main window gets focus.
     *
     * Setting a callback clears any previous callbacks.
     *
     * @param cb The function to call when the main window gets focus. Pass
     * `undefined` to clear the callback.
     */
    onMainWindowFocus: (cb: (() => void) | undefined) => void;

    /**
     * Set or clear the callback {@link cb} to invoke whenever the app gets
     * asked to open a deeplink. This allows the Node.js layer to ask the
     * renderer to handle deeplinks and redirect itself to a new location if
     * needed.
     *
     * In particular, this is necessary for handling passkey authentication.
     * See: [Note: Passkey verification in the desktop app]
     *
     * Setting a callback clears any previous callbacks.
     *
     * @param cb The function to call when the app gets asked to open a
     * "ente://" URL. The URL string (a.k.a. "deeplink") we were asked to open
     * is passed to the function verbatim.
     */
    onOpenURL: (cb: ((url: string) => void) | undefined) => void;

    // - App update

    /**
     * Set or clear the callback {@link cb} to invoke whenever a new
     * (actionable) app update is available. This allows the Node.js layer to
     * ask the renderer to show an "Update available" dialog to the user.
     *
     * Setting a callback clears any previous callbacks.
     */
    onAppUpdateAvailable: (
        cb: ((update: AppUpdate) => void) | undefined,
    ) => void;

    /**
     * Restart the app to apply the latest available update.
     *
     * This is expected to be called in response to {@link onAppUpdateAvailable}
     * if the user so wishes.
     */
    updateAndRestart: () => void;

    /**
     * Mute update notifications for the given {@link version}. This allows us
     * to implement the "Install on next launch" functionality in response to
     * the {@link onAppUpdateAvailable} event.
     */
    updateOnNextRestart: (version: string) => void;

    /**
     * Skip the app update with the given {@link version}.
     *
     * This is expected to be called in response to {@link onAppUpdateAvailable}
     * if the user so wishes. It will remember this {@link version} as having
     * been marked as skipped so that we don't prompt the user again.
     */
    skipAppUpdate: (version: string) => void;

    /**
     * Get the persisted version for the last shown changelog.
     *
     * See: [Note: Conditions for showing "What's new"]
     */
    lastShownChangelogVersion: () => Promise<number | undefined>;

    /**
     * Save the given {@link version} to disk as the version of the last shown
     * changelog.
     *
     * The value is saved to a store which is not cleared during logout.
     *
     * @see {@link lastShownChangelogVersion}
     */
    setLastShownChangelogVersion: (version: number) => Promise<void>;

    // - FS

    /**
     * A subset of file system access APIs.
     *
     * The renderer process, being a web process, does not have full access to
     * the local file system apart from files explicitly dragged and dropped (or
     * selected by the user in a native file open dialog).
     *
     * The main process, however, has full fil system access (limited only be an
     * OS level sandbox on the entire process).
     *
     * When we're running in the desktop app, we want to better utilize the
     * local file system access to provide more integrated features to the user;
     * things that are not currently possible using web technologies. For
     * example, continuous exports to an arbitrary user chosen location on disk,
     * or watching some folders for changes and syncing them automatically.
     *
     * Towards this end, this fs object provides some generic file system access
     * functions that are needed for such features (in some cases, there are
     * other feature specific methods too in the top level electron object).
     */
    fs: {
        /** Return true if there is an item at the given {@link path}. */
        exists: (path: string) => Promise<boolean>;

        /**
         * Equivalent of `mkdir -p`.
         *
         * Create a directory at the given path if it does not already exist.
         * Any parent directories in the path that don't already exist will also
         * be created recursively, i.e. this command is analogous to an running
         * `mkdir -p`.
         */
        mkdirIfNeeded: (dirPath: string) => Promise<void>;

        /** Rename {@link oldPath} to {@link newPath} */
        rename: (oldPath: string, newPath: string) => Promise<void>;

        /**
         * Equivalent of `rmdir`.
         *
         * Delete the directory at the {@link path} if it is empty.
         */
        rmdir: (path: string) => Promise<void>;

        /**
         * Equivalent of `rm`.
         *
         * Delete the file at {@link path}.
         */
        rm: (path: string) => Promise<void>;

        /** Read the string contents of a file at {@link path}. */
        readTextFile: (path: string) => Promise<string>;

        /**
         * Write a string to a file, replacing the file if it already exists.
         *
         * @param path The path of the file.
         * @param contents The string contents to write.
         */
        writeFile: (path: string, contents: string) => Promise<void>;

        /**
         * Return true if there is an item at {@link dirPath}, and it is as
         * directory.
         */
        isDir: (dirPath: string) => Promise<boolean>;
    };

    // - Conversion

    /**
     * Try to convert an arbitrary image into JPEG using native layer tools.
     *
     * The behaviour is OS dependent. On macOS we use the `sips` utility, and on
     * some Linux architectures we use an ImageMagick executable bundled with
     * our desktop app.
     *
     * In other cases (primarily Windows), where native JPEG conversion is not
     * yet possible, this function will throw an error with the
     * {@link CustomErrorMessage.NotAvailable} message.
     *
     * @param imageData The raw image data (the contents of the image file).
     *
     * @returns JPEG data of the converted image.
     */
    convertToJPEG: (imageData: Uint8Array) => Promise<Uint8Array>;

    /**
     * Generate a JPEG thumbnail for the given image.
     *
     * The behaviour is OS dependent. On macOS we use the `sips` utility, and on
     * some Linux architectures we use an ImageMagick executable bundled with
     * our desktop app.
     *
     * In other cases (primarily Windows), where native thumbnail generation is
     * not yet possible, this function will throw an error with the
     * {@link CustomErrorMessage.NotAvailable} message.
     *
     * @param dataOrPathOrZipItem The file whose thumbnail we want to generate.
     * It can be provided as raw image data (the contents of the image file), or
     * the path to the image file, or a tuple containing the path of the zip
     * file along with the name of an entry in it.
     *
     * @param maxDimension The maximum width or height of the generated
     * thumbnail.
     *
     * @param maxSize Maximum size (in bytes) of the generated thumbnail.
     *
     * @returns JPEG data of the generated thumbnail.
     */
    generateImageThumbnail: (
        dataOrPathOrZipItem: Uint8Array | string | ZipItem,
        maxDimension: number,
        maxSize: number,
    ) => Promise<Uint8Array>;

    /**
     * Execute a FFmpeg {@link command} on the given
     * {@link dataOrPathOrZipItem}.
     *
     * This executes the command using a FFmpeg executable we bundle with our
     * desktop app. We also have a wasm FFmpeg wasm implementation that we use
     * when running on the web, which has a sibling function with the same
     * parameters. See [Note:FFmpeg in Electron].
     *
     * @param command An array of strings, each representing one positional
     * parameter in the command to execute. Placeholders for the input, output
     * and ffmpeg's own path are replaced before executing the command
     * (respectively {@link inputPathPlaceholder},
     * {@link outputPathPlaceholder}, {@link ffmpegPathPlaceholder}).
     *
     * @param dataOrPathOrZipItem The bytes of the input file, or the path to
     * the input file on the user's local disk, or the path to a zip file on the
     * user's disk and the name of an entry in it. In all three cases, the data
     * gets serialized to a temporary file, and then that path gets substituted
     * in the FFmpeg {@link command} in lieu of {@link inputPathPlaceholder}.
     *
     * @param outputFileExtension The extension (without the dot, e.g. "jpeg")
     * to use for the output file that we ask FFmpeg to create in
     * {@param command}. While this file will eventually get deleted, and we'll
     * just return its contents, for some FFmpeg command the extension matters
     * (e.g. conversion to a JPEG fails if the extension is arbitrary).
     *
     * @returns The contents of the output file produced by the ffmpeg command
     * (specified as {@link outputPathPlaceholder} in {@link command}).
     */
    ffmpegExec: (
        command: string[],
        dataOrPathOrZipItem: Uint8Array | string | ZipItem,
        outputFileExtension: string,
    ) => Promise<Uint8Array>;

    // - ML

    /**
     * Return a CLIP embedding of the given image.
     *
     * See: [Note: CLIP based magic search]
     *
     * @param jpegImageData The raw bytes of the image encoded as an JPEG.
     *
     * @returns A CLIP embedding.
     */
    computeCLIPImageEmbedding: (
        jpegImageData: Uint8Array,
    ) => Promise<Float32Array>;

    /**
     * Return a CLIP embedding of the given image if we already have the model
     * downloaded and prepped. If the model is not available return `undefined`.
     *
     * This differs from the other sibling ML functions in that it doesn't wait
     * for the model download to finish. It does trigger a model download, but
     * then immediately returns `undefined`. At some future point, when the
     * model downloaded finishes, calls to this function will start returning
     * the result we seek.
     *
     * The reason for doing it in this asymmetric way is because CLIP text
     * embeddings are used as part of deducing user initiated search results,
     * and we don't want to block that interaction on a large network request.
     *
     * See: [Note: CLIP based magic search]
     *
     * @param text The string whose embedding we want to compute.
     *
     * @returns A CLIP embedding.
     */
    computeCLIPTextEmbeddingIfAvailable: (
        text: string,
    ) => Promise<Float32Array | undefined>;

    /**
     * Detect faces in the given image using YOLO.
     *
     * Both the input and output are opaque binary data whose internal structure
     * is specific to our implementation and the model (YOLO) we use.
     */
    detectFaces: (input: Float32Array) => Promise<Float32Array>;

    /**
     * Return a MobileFaceNet embeddings for the given faces.
     *
     * Both the input and output are opaque binary data whose internal structure
     * is specific to our implementation and the model (MobileFaceNet) we use.
     */
    computeFaceEmbeddings: (input: Float32Array) => Promise<Float32Array>;

    // - Watch

    /**
     * Interface with the file system watcher running in our Node.js layer.
     *
     * [Note: Folder vs Directory in the context of FolderWatch-es]
     *
     * A note on terminology: The word "folder" is used to the top level root
     * folder for which a {@link FolderWatch} has been added. This folder is
     * also in 1-1 correspondence to be a directory on the user's disk. It can
     * have other, nested directories too (which may or may not be getting
     * mapped to separate Ente collections), but we'll not refer to these nested
     * directories as folders - only the root of the tree, which the user
     * dragged/dropped or selected to set up the folder watch, will be referred
     * to as a folder when naming things.
     */
    watch: {
        /**
         * Return the list of folder watches, pruning non-existing directories.
         *
         * The list of folder paths (and auxillary details) is persisted in the
         * Node.js layer. The implementation of this function goes through the
         * list, permanently removes any watches whose on-disk directory is no
         * longer present, and returns this pruned list of watches.
         */
        get: () => Promise<FolderWatch[]>;

        /**
         * Add a new folder watch for the given {@link folderPath}.
         *
         * This adds a new entry in the list of watches (persisting them on
         * disk), and also starts immediately observing for file system events
         * that happen within {@link folderPath}.
         *
         * @param collectionMapping Determines how nested directories (if any)
         * get mapped to Ente collections.
         *
         * @returns The updated list of watches.
         */
        add: (
            folderPath: string,
            collectionMapping: CollectionMapping,
        ) => Promise<FolderWatch[]>;

        /**
         * Remove the pre-existing watch for the given {@link folderPath}.
         *
         * Persist this removal, and also stop listening for file system events
         * that happen within the {@link folderPath}.
         *
         * @returns The updated list of watches.
         */
        remove: (folderPath: string) => Promise<FolderWatch[]>;

        /**
         * Update the list of synced files for the folder watch associated
         * with the given {@link folderPath}.
         */
        updateSyncedFiles: (
            syncedFiles: FolderWatch["syncedFiles"],
            folderPath: string,
        ) => Promise<void>;

        /**
         * Update the list of ignored file paths for the folder watch
         * associated with the given {@link folderPath}.
         */
        updateIgnoredFiles: (
            ignoredFiles: FolderWatch["ignoredFiles"],
            folderPath: string,
        ) => Promise<void>;

        /**
         * Register the function to invoke when a file is added in one of the
         * folders we are watching.
         *
         * The callback function is passed the path to the file that was added,
         * and the folder watch it was associated with.
         *
         * The path is guaranteed to use POSIX separators ('/').
         */
        onAddFile: (f: (path: string, watch: FolderWatch) => void) => void;

        /**
         * Register the function to invoke when a file is removed in one of the
         * folders we are watching.
         *
         * The callback function is passed the path to the file that was
         * removed, and the folder watch it was associated with.
         *
         * The path is guaranteed to use POSIX separators ('/').
         */
        onRemoveFile: (f: (path: string, watch: FolderWatch) => void) => void;

        /**
         * Register the function to invoke when a directory is removed in one of
         * the folders we are watching.
         *
         * The callback function is passed the path to the directory that was
         * removed, and the folder watch it was associated with.
         *
         * The path is guaranteed to use POSIX separators ('/').
         */
        onRemoveDir: (f: (path: string, watch: FolderWatch) => void) => void;

        /**
         * Return the paths of all the files under the given folder.
         *
         * This function walks the directory tree starting at {@link folderPath}
         * and returns a list of the absolute paths of all the files that exist
         * therein. It will recursively traverse into nested directories, and
         * return the absolute paths of the files there too.
         *
         * The returned paths are guaranteed to use POSIX separators ('/').
         */
        findFiles: (folderPath: string) => Promise<string[]>;
    };

    // - Upload

    /**
     * Return the file system path that this File object points to.
     *
     * This method is a bit different from the other methods on the Electron
     * object in the sense that there is no actual IPC happening - the
     * implementation of this method is completely in the preload script. Thus
     * we can pass it an otherwise unserializable File object.
     *
     * Consequently, it is also _not_ async.
     */
    pathForFile: (file: File) => string;

    /**
     * Get the list of files that are present in the given zip file.
     *
     * @param zipPath The path of the zip file on the user's local file system.
     *
     * @returns A list of (zipPath, entryName) tuples, one for each file in the
     * given zip. Directories are traversed recursively, but the directory
     * entries themselves will be excluded from the returned list. File entries
     * whose file name begins with a dot (i.e. "hidden" files) will also be
     * excluded.
     *
     * To read the contents of the files themselves, see [Note: IPC streams].
     */
    listZipItems: (zipPath: string) => Promise<ZipItem[]>;

    /**
     * Return the size in bytes of the file at the given path or of a particular
     * entry within a zip file.
     */
    pathOrZipItemSize: (pathOrZipItem: string | ZipItem) => Promise<number>;

    /**
     * Return any pending uploads that were previously enqueued but haven't yet
     * been completed.
     *
     * Return undefined if there are no such pending uploads.
     *
     * The state of pending uploads is persisted in the Node.js layer. Or app
     * start, we read in this data from the Node.js layer via this IPC method.
     * The Node.js code returns the persisted data after filtering out any files
     * that no longer exist on disk.
     */
    pendingUploads: () => Promise<PendingUploads | undefined>;

    /**
     * Set the state of pending uploads.
     *
     * - Typically, this would be called at the start of an upload.
     *
     * - Thereafter, as each item gets uploaded one by one, we'd call
     *   {@link markUploadedFiles} or {@link markUploadedZipItems}.
     *
     * - Finally, once the upload completes (or gets cancelled), we'd call
     *   {@link clearPendingUploads} to complete the circle.
     */
    setPendingUploads: (pendingUploads: PendingUploads) => Promise<void>;

    /**
     * Mark the given files (given by their {@link paths}) as having been
     * uploaded.
     */
    markUploadedFiles: (paths: PendingUploads["filePaths"]) => Promise<void>;

    /**
     * Mark the given {@link ZipItem}s as having been uploaded.
     */
    markUploadedZipItems: (items: PendingUploads["zipItems"]) => Promise<void>;

    /**
     * Clear any pending uploads.
     */
    clearPendingUploads: () => Promise<void>;
}

/**
 * Errors that have special semantics on the web side.
 *
 * [Note: Custom errors across Electron/Renderer boundary]
 *
 * If we need to identify errors thrown by the main process when invoked from
 * the renderer process, we can only use the `message` field because:
 *
 * > Errors thrown throw `handle` in the main process are not transparent as
 * > they are serialized and only the `message` property from the original error
 * > is provided to the renderer process.
 * >
 * > - https://www.electronjs.org/docs/latest/tutorial/ipc
 * >
 * > Ref: https://github.com/electron/electron/issues/24427
 */
export const CustomErrorMessage = {
    NotAvailable: "This feature in not available on the current OS/arch",
};

/**
 * Data passed across the IPC bridge when an app update is available.
 */
export interface AppUpdate {
    /** `true` if the user automatically update to this (new) version */
    autoUpdatable: boolean;
    /** The new version that is available */
    version: string;
}

/**
 * A top level folder that was selected by the user for watching.
 *
 * The user can set up multiple such watches. Each of these can in turn be
 * syncing multiple on disk folders to one or more Ente collections (depending
 * on the value of {@link collectionMapping}).
 *
 * This type is passed across the IPC boundary. It is persisted on the Node.js
 * side.
 */
export interface FolderWatch {
    /**
     * Specify if nested files should all be mapped to the same single root
     * collection, or if there should be a collection per directory that has
     * files. @see {@link CollectionMapping}.
     */
    collectionMapping: CollectionMapping;
    /**
     * The path to the (root) folder we are watching.
     */
    folderPath: string;
    /**
     * Files that have already been uploaded.
     */
    syncedFiles: FolderWatchSyncedFile[];
    /**
     * Files (paths) that should be ignored when uploading.
     */
    ignoredFiles: string[];
}

/**
 * The ways in which directories are mapped to collection.
 *
 * This comes into play when we have nested directories that we are trying to
 * upload or watch on the user's local file system.
 */
export type CollectionMapping =
    /** All files go into a single collection named after the root directory. */
    | "root"
    /** Each file goes to a collection named after its parent directory. */
    | "parent";

/**
 * An on-disk file that was synced as part of a folder watch.
 */
export interface FolderWatchSyncedFile {
    path: string;
    uploadedFileID: number;
    collectionID: number;
}

/**
 * A particular file within a zip file.
 *
 * When the user uploads a zip file, we create a "zip item" for each entry
 * within the zip file. Each such entry is a tuple containing the (path to a zip
 * file itself, and the name of an entry within it).
 *
 * The name of the entry is not just the file name, but rather is the full path
 * of the file within the zip. That is, each entry name uniquely identifies a
 * particular file within the given zip.
 *
 * When `entryName` is a path within a nested directory, it is guaranteed to use
 * the POSIX path separator ("/") since that is the path separator required by
 * the ZIP format itself
 *
 * > 4.4.17.1 The name of the file, with optional relative path.
 * >
 * >  The path stored MUST NOT contain a drive or  device letter, or a leading
 * >  slash. All slashes MUST be forward slashes '/' as opposed to  backwards
 * >  slashes '\' for compatibility with Amiga and UNIX file systems etc. If
 * >  input came from standard input, there is no file name field.
 * >
 * > https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT
 */
export type ZipItem = [zipPath: string, entryName: string];

/**
 * State about pending and in-progress uploads.
 *
 * When the user starts an upload, we remember the files they'd selected (or
 * drag-dropped) so that we can resume if they restart the app in before the
 * uploads have been completed. This state is kept on the Electron side, and
 * this object is the IPC intermediary.
 */
export interface PendingUploads {
    /**
     * The collection to which we're uploading, or the root collection.
     *
     * This is name of the collection (when uploading to a singular collection)
     * or the root collection (when uploading to separate * albums) to which we
     * these uploads are meant to go to. See {@link CollectionMapping}.
     *
     * It will not be set if we're just uploading standalone files.
     */
    collectionName?: string;
    /**
     * Paths of regular files that need to be uploaded.
     */
    filePaths: string[];
    /**
     * {@link ZipItem} (zip path and entry name) that need to be uploaded.
     */
    zipItems: ZipItem[];
}

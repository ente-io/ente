# `save.ts` download and save flow

Line-by-line detail of `downloadFiles` and its helpers (line numbers from `web/packages/gallery/services/save.ts`).

## Entry wrappers

- L42-L46 `downloadAndSaveFiles`: exported helper; takes `files`, `title`, and `onAddSaveGroup`, and delegates to `downloadAndSave` with no collection context.
- L64-L78 `downloadAndSaveCollectionFiles`: collects collection name/ID/hidden flag, then calls `downloadAndSave` with those so the desktop path can nest exports under a collection-named folder.

## Core orchestrator: `downloadAndSave` (L83-L175)

- L91 grabs `globalThis.electron` to detect desktop vs web.
- L93 captures `total` count; L94-L98 aborts with `assertionFailed()` if no files.
- L100-L114 desktop-only setup: asks the user to pick a directory; if they cancel, exits; if a collection name is provided, creates a safe subfolder via `mkdirCollectionDownloadFolder` and uses that path for saves.
- L116-L119 allocates shared state: an `AbortController`, `failedFiles` list, `isDownloading` guard, and a placeholder `updateSaveGroup`.
- L121-L156 defines `downloadFiles(filesToDownload, resetFailedCount = false)`:
  - L125 short-circuits when nothing to do or a download is already running.
  - L127 sets the running guard; L128-L130 **if `resetFailedCount` is `true`**, the UI’s `failed` count is reset to `0` via `updateSaveGroup`. This flag is only set when retrying after prior failures so the user sees a fresh failed-counter for that retry attempt.
  - L131 clears previous failures.
  - L134-L148 loops each file; L135 stops early if aborted.
    - L137-L141 chooses desktop writer (`saveFileDesktop`) when electron/dir are present, otherwise browser writer (`saveAsFile`).
    - L142 increments UI success count on completion.
    - L144-L147 logs failures, records the file for retry, and increments UI failed count.
  - L150-L152 clears the UI `retry` action when there were no failures.
  - L153-L155 finally-block drops the running guard so retries can proceed.
- L158-L162 defines `retry`: if there are failures, no active download, and not aborted, it clones `failedFiles` and calls `downloadFiles` with `resetFailedCount = true`.
- L164-L172 registers the save-group notification via `onAddSaveGroup`, passing title/collection info, chosen directory, total count, the `canceller`, and `retry`; stores the returned `updateSaveGroup` setter.
- L174-L175 kicks off the initial pass by awaiting `downloadFiles(files)`.

## Browser save path

- L180-L196 `saveAsFile(file)`: fetches blob data via `downloadManager.fileBlob`; resolves a download name with `fileFileName`. For live photos (L183 check), decodes into image/video parts with `decodeLivePhoto`, saves the image first (L187), waits 300 ms to appease Safari’s multiple-download quirk (L189-L192), then saves the video (L192). Non-live saves the single blob (L194).
- L201-L204 `saveBlobPartAsFile(blobPart, fileName)`: builds a typed object URL via `createTypedObjectURL`, then hands it to `saveAsFileAndRevokeObjectURL` so the browser downloads it and the URL is revoked afterward.
- L206-L210 `createTypedObjectURL(blobPart, fileName)`: normalizes the part into a `Blob`, detects MIME using `detectFileTypeInfo` on a temporary `File`, and returns an object URL built with that MIME type.

## Desktop save path

- L220-L236 `mkdirCollectionDownloadFolder({ fs }, downloadDirPath, collectionName)`: generates a collision-safe folder name with `safeDirectoryName`, joins it to the chosen directory, creates it with `fs.mkdirIfNeeded`, and returns the resulting path.
- L254-L289 `saveFileDesktop(electron, file, directoryPath)`: writes directly to disk.
  - L259 caches `fs` from electron.
  - L261-L262 `createExportName` uses `safeFileName` to avoid name collisions in `directoryPath`.
  - L264-L267 `writeStreamToFile` writes a stream to `directoryPath/exportName` via `writeStream`.
  - L269 pulls a streaming response for the file via `downloadManager.fileStream`; L270 resolves the export name with `fileFileName`.
  - L272-L285 live photo branch: decodes to image/video; writes the image first (L275-L276). The video write (L278-L281) is wrapped in try/catch; on failure, the already-written image is removed (L283) before rethrowing (L284).
  - L286-L288 non-live branch: writes the single stream to disk with a collision-safe name.

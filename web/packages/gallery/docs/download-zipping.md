# Download zipping flow

This is a quick orientation for how we build and save zips when a user downloads multiple files from the web app (desktop flow still writes files individually via native FS APIs).

## When we zip
- Web only: zipping is skipped in Electron/desktop.
- We attempt zipping when there is more than one file, and we can batch them without exceeding thresholds (current caps: up to 50 files per batch and an estimated 200 MB per batch using `file.info?.fileSize` when present).
- Files larger than the per-batch byte cap make batching impossible; we fall back to per-file downloads for the whole request.

## Batching strategy
- Files are streamed into batches until either the file count or estimated size cap would be exceeded; then we start a new batch.
- Each batch becomes its own zip. Names are `<title>.zip` if there is one batch, otherwise `<title>-part<N>.zip`.

## What goes into a zip
- Each file is fetched via `downloadManager.fileBlob`.
- Live Photos are expanded: we add separate image and video parts with their derived filenames.
- Zips are generated with `compression: "STORE"` and `streamFiles: true` to reduce memory overhead; we also set the saved blob MIME to `application/zip`.

## Progress and retries
- Within a zip batch, we only increment the success count after the zip file is generated and saved. If zip creation fails, we mark those files as failed and fall back to individual downloads for that batch.
- If any file in a batch fails to add to the zip, it is marked failed immediately and is also retried individually.
- Hitting “retry” bypasses zipping entirely and downloads the remaining failed files one by one.

## Cancellation
- An abort signal stops file addition and causes zip generation to throw; we stop processing further batches when cancelled.

## MIME handling
- We explicitly save zips with the `application/zip` MIME type, and blob URL creation swallows type-detection errors so a bad detect call does not crash the flow.

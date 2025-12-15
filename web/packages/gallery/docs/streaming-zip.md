# Streaming ZIP downloads in `save.ts`

This note walks through how the web app streams multiple downloads into a ZIP directly on disk, using the logic in `web/packages/gallery/services/save.ts`.

## When the streaming path runs
- Entry points: `downloadAndSaveFiles` and `downloadAndSaveCollectionFiles` both delegate to `downloadAndSave`.
- We try streaming whenever `files.length > 1`. Desktop supplies its own `writable` via `createNativeZipWritable`; web resolves it via `getWritableStreamForZip`.
- Streaming is skipped if the picker is cancelled (`streamFilesToZip` returns `"cancelled"`) or if no streaming-capable writer exists (`"unavailable"`); we then do per-file downloads. If streaming has already started and returns `"error"` or is cancelled mid-run, we avoid auto-fallback to prevent double downloads; the user can hit “retry” to download remaining failures individually.

## Choosing the writable target
- Web: `getWritableStreamForZip` prefers `window.showSaveFilePicker` and `fileHandle.createWritable()` for true streaming writes. If absent or failing (non-`AbortError`), we log and fall back to `streamsaver.createWriteStream`. `null` means the user cancelled; `undefined` means both mechanisms are unavailable.
- Desktop: `createNativeZipWritable` builds a `TransformStream`, gets its writer, and hands the readable side to `writeStream(electron, filePath, transform.readable)`. It exposes `stream`, `close`, and `abort` to align with the web handle.
- Both paths ultimately return a `WritableStreamHandle` with a `WritableStream<Uint8Array>` that `fflate` can push into.

## Preparing files for the ZIP
- Each file becomes a `PreparedFile` containing `entries: PreparedEntry[]` and `entryCount`. Live Photos are split into image/video entries (decoded via `decodeLivePhoto`); other files get a single entry named by `fileFileName`.
- Live Photos fetch a blob via `downloadManager.fileBlob`; other files keep a lazy `getStream` that resolves `downloadManager.fileStream(file)`.
- Concurrency: `getStreamZipConcurrency` inspects `performance.memory.totalJSHeapSize/usedJSHeapSize` to estimate free heap, otherwise `navigator.deviceMemory` (GBs) to pick 1–4 concurrent preparations. Hard caps: `STREAM_ZIP_MIN_CONCURRENCY = 1`, `STREAM_ZIP_MAX_CONCURRENCY = 4`.
- Scheduler: `preparedPromises[]` is filled via `scheduleNext`, keeping `nextToSchedule`/`active` counts. Even though preparation runs in parallel, consumption is strictly ordered (`for (let i = 0; i < files.length; i++)`) so ZIP order matches the input list.
- Failure during preparation immediately calls `onFileFailure(file, error)` and returns `null`, leaving that slot skipped.

## Writing the ZIP
- `Zip` is created with a callback `(err, data) => { ... }`. `data` is a ZIP chunk; we push it through `enqueueWrite`, which chains `writer.write(data)` on `writeChain`. This serializes writes and propagates backpressure via the writer’s promises; if a write rejects (e.g., buffer full, disk issue), `zipError` is set and subsequent writes throw.
- `ZipPassThrough(entry.name)` is used for each entry (no compression). We `push` every chunk and then `push(empty, true)` to finalize the entry.
- Streams vs blobs: for stream-based entries we call `readStreamFully`, accumulating `Uint8Array[]`. This avoids partial entries on transient stream errors at the cost of holding one file’s chunks in memory at a time. The bounded concurrency and per-entry reading keep peak memory limited; if memory is tight, `getStreamZipConcurrency` drops to 1 to reduce simultaneous buffers.
- Retries: `addEntryToZipWithRetry` retries `STREAM_ZIP_MAX_RETRIES` (3) with backoff `STREAM_ZIP_RETRY_DELAY_MS` (400ms * attempt) on read failures, unless `signal.aborted`.
- Finalization: after all files, we call `zip.end()`, await `writeChain`, check `zipError`, then `closeWriter()`. Any caught error aborts the writer (`writer.abort()`), logs, and returns `"error"` or `"cancelled"`.

### Memory/backpressure behavior
- `performance.memory` free-heap estimate and `navigator.deviceMemory` are the only “monitoring” signals; we do not sample live usage mid-stream. The strategy is preventative: keep concurrency low when headroom is small.
- If the writable’s internal buffer is full or the sink slows down, `writer.write` will backpressure via its promise. Because we chain writes in `writeChain`, upstream pauses until the sink drains; `zipError` captures any rejection.
- If the ZIP writer cannot keep up and errors, we abort the stream and mark remaining files failed; we do not attempt partial recovery inside the same ZIP.

## Progress, failure, and cancellation reporting
- Callers supply `onFileSuccess` / `onFileFailure` callbacks; in `downloadAndSave` these update the UI save group counts. Live Photos report `entryCount: 1` so they still count as a single logical file.
- An `AbortSignal` from the UI cancels scheduling and stream reads; `streamFilesToZip` aborts the writer and returns `"cancelled"`. Remaining unprocessed files are marked failed so counts stay consistent.
- When streaming completes successfully we clear any pending retry state; when it fails or is cancelled, the user can hit “retry,” which triggers per-file downloads for the remaining failures.

# Client-Side Album Download as ZIP (web)

A concrete, code-aware plan for moving `web/packages/gallery/services/save.ts` to a streaming ZIP implementation that works for photos, shared albums, and the desktop app without regressing the current UI contract.

## Purpose and scope

- Replace the current in-browser JSZip batching (50 files / 200MB cap) with a streaming ZIP writer that can handle large albums without buffering.
- Keep the existing `downloadAndSaveFiles` / `downloadAndSaveCollectionFiles` entry points and `SaveGroup` progress UI intact.
- Desktop flow (`globalThis.electron`) already streams via `writeStream`; this spec is about the web path.

## Current behavior in `save.ts`

- Public API: `downloadAndSaveFiles(files, title, onAddSaveGroup)` and `downloadAndSaveCollectionFiles(...)` populate a `SaveGroup` and call the internal `downloadAndSave`.
- Web (non-electron):
  - Single file → downloads via `downloadManager.fileBlob` → `saveBlobPartAsFile` (object URL + anchor).
  - Multiple files → small batches zipped via JSZip (`compression: "STORE"`) with hard caps `ZIP_MAX_FILE_COUNT = 50` and `ZIP_MAX_TOTAL_BYTES = 200MB`; if any failure occurs inside a batch we fall back to per-file downloads.
- Desktop:
  - Prompts for a directory, then writes decrypted streams to disk using `writeStream` and `safeFileName`; live photos are split into image+video entries.
- Decryption: `downloadManager.fileStream` returns decrypted streams; for images/live photos it currently buffers the full response before decrypting (important for memory planning).
- Progress contract: UI only has per-file counts via `SaveGroup.success/failed`; `retry` reuses `failedFiles` and bypasses zipping.

## Requirements (grounded in codebase)

- **Client-only** ZIP creation; no server changes.
- **Streaming**: do not hold full ZIP or full files in memory; respect `AbortController`.
- **Cross-browser**: Chrome/Edge (File System Access API) and Firefox/Safari (StreamSaver-style fallback) without breaking the existing single-click download flow.
- **E2EE aware**: always read file data through `downloadManager` so decryption and public-link headers remain correct.
- **Live Photos**: keep current behavior of exporting as two files (image + video) with names from `decodeLivePhoto`.
- **Retry semantics**: preserve `failedFiles` and `retry` behavior already wired into `save.ts`.
- **Naming**: reuse `fileFileName`, `sanitizeZipFileName`, and `zipFileName(title, part?)`; avoid path separators in entry names.

## Design: streaming ZIP pipeline

### Write targets

- **Primary**: `showSaveFilePicker` → `FileSystemFileHandle.createWritable()`; keep suggested name from `zipFileName`.
- **Fallback**: dynamically import `streamsaver` and call `createWriteStream(zipName)` when the File System Access API is unavailable.
- Both outputs should surface as a `WritableStream<Uint8Array>` so the ZIP writer can pipe bytes directly.

### ZIP writer

- Use `fflate.Zip` with `ZipPassThrough` entries so compression is streaming and memory-light; keep `compression: 0` to match current “store only” behavior.
- Create one `ZipPassThrough` per file entry and pipe the decrypted file stream into it.
- Finalize the `Zip` only after all entries finish; ensure `writer.close()` on success or abort.

### Input streams and ordering

- Always fetch data via `downloadManager.fileStream(file, { signal })`; if it returns `null` treat as failure.
- Concurrency: 3–4 parallel `fileStream` fetches; enqueue completed streams into an ordered queue so ZIP entries are written in file order (respecting UI expectations and deterministic names).
- Backpressure: keep a small buffer (e.g., 2 ready streams) to prevent unbounded memory if `downloadManager` buffers images.
- Live photos: fetch once, decode via `decodeLivePhoto(fileName, blob)` and add two entries; keep concurrency low around this branch because it still needs a blob.

### Abort, failure, and retries

- Honor `canceller.signal` across fetch, stream piping, and ZIP finalization; on abort, close the writable stream and stop queuing new entries.
- On per-file failure, increment `failed` in the `SaveGroup`, store the `EnteFile` in `failedFiles`, and continue the rest of the album.
- `retry` should keep working: it currently replays `failedFiles` individually (no ZIP) and should remain unchanged.

### Progress and notifications

- Maintain current `SaveGroup` contract: increment `success` when an entry finishes writing to ZIP; increment `failed` when an entry fails.
- Optional (future) byte-level progress can be derived from `downloadManager.fileDownloadProgress` but is not required to ship the first version.

## Flow to implement inside `save.ts`

1. **Web path gate**: when `electron` is falsy and we have more than one file, prefer the streaming ZIP path instead of JSZip.
2. **Prepare writer**: `const { stream, close } = await getWriteStream(zipFileName(title))` using File System Access → StreamSaver fallback.
3. **Start ZIP**: create `const zip = new Zip((chunk) => writer.write(chunk));` and keep a `finalize()` promise that resolves on `zip.ondata` completion.
4. **Queue files**:
   - For each `EnteFile`, compute entry names using `fileFileName(file)`; for live photos call `decodeLivePhoto` to derive two entry names.
   - Fetch data via `downloadManager.fileStream(file, { signal: canceller.signal })`.
   - Pipe stream → `ZipPassThrough` → zip; close the pass-through when the source finishes.
5. **Ordering**: ensure entries are added in array order even though fetches happen concurrently (e.g., maintain an index and await previous entry completion before appending the next to the zip).
6. **Finalize**: await `zip.end()` then `writer.close()`; only mark the `SaveGroup` success counts after each entry closes; on abort, close the writer without marking additional success.
7. **Fallback**: if streaming ZIP setup fails (e.g., picker rejected, StreamSaver unavailable), fall back to current per-file downloads so the UI behavior matches today.
8. **Desktop path**: untouched—continue using `saveFileDesktop` and `writeStream`.

### Pseudo-code sketch

```typescript
// inside downloadFiles branch for web + multi-file
const target = await getWritableStream(zipFileName(title));
const zip = new Zip((err, chunk, final) => {
  if (err) throw err;
  void target.write(chunk);
  if (final) void target.close();
});

await pipeFilesToZip({
  files,
  zip,
  signal: canceller.signal,
  onFileSuccess: (count) => updateSaveGroup((g) => ({ ...g, success: g.success + count })),
  onFileFailure: (file) => { failedFiles.push(file); updateSaveGroup((g) => ({ ...g, failed: g.failed + 1 })); },
});
```

## Naming and partitioning

- Use `zipFileName(title, part?)` (already in `save.ts`) for the archive name; sanitize via `sanitizeZipFileName`.
- Entry names: start from `fileFileName(file)`; for live photos use names from `decodeLivePhoto`; if needed, prefix with a zero-padded index to keep stable ordering (`00001-original-name.ext`).
- Keep compression `STORE` to match current CPU profile and avoid slowing download/decryption.

## Resilience and edge cases

- Picker cancel → exit quietly (match current desktop folder cancel behavior).
- StreamSaver service worker must be registered before first use; load it lazily the first time we need the fallback.
- If `downloadManager.fileStream` buffers large images, cap concurrency to avoid spikes; consider a follow-up to add chunked decryption for images if needed.
- When all files fail, still produce an empty (but valid) ZIP so the UI completes with errors noted.

## Testing checklist

- Web Chrome/Edge: multi-file album completes without OOM; cancel midway stops writing and does not update `success`.
- Firefox/Safari: fallback path produces a valid ZIP (requires StreamSaver registration).
- Live photo: both image and video parts present and named correctly.
- Retry: start a download, induce one file failure, trigger retry → falls back to per-file path without ZIP.
- Desktop app: unaffected; single and multi-file downloads continue via `writeStream`.

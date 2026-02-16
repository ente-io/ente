# Resumable Gallery Downloads

This document describes the `mobile/apps/photos` implementation for resumable
"Save to gallery" downloads.

## Overview

- Downloads are enqueued into a single app-wide queue.
- Queue state is persisted in `GalleryDownloadsDB` so tasks survive process
  restarts.
- Up to 5 downloads run concurrently.
- User-initiated save flows route through resumable download logic for all
  sizes.
- Progress is shown as a non-blocking banner on the home screen.

## Components

- `lib/module/download/gallery_download_queue_service.dart`
  Orchestrates enqueue, concurrency, resume, cancellation, and completion state.
- `lib/db/gallery_downloads_db.dart`
  Persists queue tasks.
- `lib/ui/home/gallery_download_banner.dart`
  Displays queue status and opens per-file details.
- `lib/utils/file_download_util.dart` and `lib/utils/file_util.dart`
  Added force-resumable mode for gallery save flows.

## Behavior

- Duplicate enqueue by uploaded file ID is ignored.
- Incomplete tasks older than 7 days are dropped on startup, and temp partials
  are cleaned up.
- Network interruptions pause tasks and auto-resume on connectivity recovery.
- Storage-related failures pause tasks until retried.
- Queue is cleared on logout.

## Entry points using queue

- Multi-selection download action.
- Single-file viewer download action.
- Public album download action.

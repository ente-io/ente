# Shared Album Contributor Upload on Web

Status: Draft

This document is the SRS and HLD for adding contributor upload support to `web/apps/photos/src` with parity to the current `mobile/apps/photos` behavior.

The target feature is not "upload directly into a shared album". The target feature is:

1. preserve uploader ownership,
2. allow `OWNER` / `ADMIN` / `COLLABORATOR` add flows where mobile allows them,
3. deny `VIEWER`,
4. route new uploads and cross-owner copies through the user's own `uncategorized` collection when required,
5. keep web behavior aligned with current mobile logic.

## 1. Scope

### In scope

- Incoming shared albums where the current user is `ADMIN` or `COLLABORATOR`.
- Owner-owned albums, which must continue to use the existing direct upload flow.
- Adding an already uploaded Ente file to a shared album.
- Uploading a brand-new local file to a shared album.
- Adding an already uploaded file owned by another user to a shared album.
- Same-hash reuse, copy-via-`uncategorized`, and duplicate suppression rules that mobile already applies.
- All web entry points that can target an album upload/add flow.

### Out of scope

- Public collect links / anonymous uploads.
- Participant management UX beyond role checks needed for upload permission.
- Changing move semantics for shared albums.
  Mobile explicitly treats shared album flows as "add", not "move".
- Server-side API changes.
  Existing server APIs already support the needed flow.

## 2. Reference Implementations

### Mobile reference

- `mobile/apps/photos/lib/models/collection/collection.dart`
- `mobile/apps/photos/lib/models/files_split.dart`
- `mobile/apps/photos/lib/ui/actions/collection/collection_file_actions.dart`
- `mobile/apps/photos/lib/services/collections_service.dart`
- `mobile/apps/photos/lib/utils/file_uploader.dart`
- `mobile/apps/photos/lib/gateways/collections/collection_files_gateway.dart`

### Web code paths impacted

- `web/apps/photos/src/components/Upload.tsx`
- `web/apps/photos/src/services/upload-manager.ts`
- `web/apps/photos/src/pages/gallery.tsx`
- `web/apps/photos/src/components/FileListWithViewer.tsx`
- `web/packages/new/photos/components/CollectionSelector.tsx`
- `web/packages/new/photos/components/gallery/helpers.ts`
- `web/packages/new/photos/services/collection-summary.ts`
- `web/packages/new/photos/services/collection.ts`
- `web/packages/media/file.ts`

## 3. Domain Model and Invariants

### 3.1 Collection membership vs file ownership

The same uploaded file can appear in multiple collections. On web this is represented by multiple `EnteFile` rows with the same `file.id` and different `collectionID`. In other words:

- mobile `uploadedFileID` == web `EnteFile.id`
- the logical primary key for a collection-file row is `(file.id, collectionID)`

This distinction matters because "add to album" usually means "create another collection membership", not "upload new bytes".

### 3.2 Ownership invariant

For shared album contributor flows, files added by the current user must remain owned by the current user.

This is why mobile does not directly upload or directly copy into an incoming shared album when the destination is not owned by the actor. Instead it uses:

1. user-owned `uncategorized`
2. then `POST /collections/add-files`

Web must preserve the same invariant.

### 3.3 Server enforcement we must respect

Current server constraints already align with mobile:

- `POST /collections/add-files`
  - requires `role.canAdd`
  - requires the actor to own the file IDs being added
- `POST /files/copy`
  - destination must be owned by the actor

Therefore:

- direct add of other-owned files is invalid,
- direct copy into an incoming shared album is invalid,
- copy-via-`uncategorized` is required for contributor parity.

### 3.4 Permission model

Mobile and web already share the same effective participant roles:

- `OWNER`
- `ADMIN`
- `COLLABORATOR`
- `VIEWER`
- `UNKNOWN`

Upload/add permission for this feature is:

- allowed: `OWNER`, `ADMIN`, `COLLABORATOR`
- denied: `VIEWER`, deleted collection, unknown role

## 4. Current State Summary

### 4.1 Mobile behavior today

Mobile already supports the following:

| Case | File state | File owner | Destination owner | Mobile behavior |
| --- | --- | --- | --- | --- |
| 1 | Already uploaded | Current user | Current user | Add directly |
| 2 | Already uploaded | Current user | Another user | Add directly |
| 3 | Already uploaded | Another user | Current user | Reuse same-hash owned file if available, else copy directly |
| 4 | Already uploaded | Another user | Another user | Reuse same-hash owned file if available, else copy to `uncategorized`, then add |
| 5 | Not uploaded yet | N/A | Current user | Normal queued upload to destination |
| 6 | Not uploaded yet | N/A | Another user | Force upload to `uncategorized`, then add |

Additional mobile details that matter:

- direct upload is owner-only via `CollectionsService.allowUpload(...)`
- `_addToCollection(...)` rejects other-owned files
- `_validateCopyInput(...)` rejects copy destinations not owned by the actor
- `addOrCopyToCollection(...)` is the main parity primitive
- mobile skips duplicate memberships already present in the destination

### 4.2 Web behavior today

Web already has some useful pieces:

- participant roles including `ADMIN` are modeled and surfaced
- incoming shared albums are already classified as viewer / collaborator / admin
- `"add"` target selection already allows collaborator/admin incoming shared albums
- upload service already returns useful success result types:
  - `alreadyUploaded`
  - `addedSymlink`
  - `uploaded`
  - `uploadedWithStaticThumbnail`
- `createUncategorizedCollection()` already exists

Current parity gaps:

- `CollectionSelector` action `"upload"` excludes incoming shared albums because it relies on `canMoveToCollection(...)`
- drag-and-drop auto-targeting only works when the active collection is owned by the user
- `pages/gallery.tsx` strips non-owned files before `"add"` and warns instead of applying mobile add/copy logic
- `performCollectionOp(...)` is explicitly owner-only for add/move parity
- `upload-manager.uploadItems(...)` returns only a boolean, not per-item upload results
- web has no `/files/copy` wrapper and no `addOrCopyToCollection(...)` equivalent
- web `addToCollection(...)` is remote-only and does not locally skip already-present memberships
- duplicate suppression after copy parity is not implemented

## 5. SRS

### 5.1 Product goal

A web user who is an `ADMIN` or `COLLABORATOR` in an incoming shared album must be able to:

- upload new local files into that album, and
- add existing Ente files into that album

with the same ownership and copy semantics as mobile.

### 5.2 Supported entry points

The feature must work from every web flow that can currently initiate an album-targeted add/upload:

- upload button with an active album in context
- drag-and-drop while an incoming shared album is the active album
- collection selector action `"upload"`
- collection selector action `"add"`
- single-file "add to album" flow from the file viewer
- any direct `uploadManager.uploadFile(...)` caller that targets a collection

Current known direct upload callers are:

- `web/apps/photos/src/components/Upload.tsx`
- `web/apps/photos/src/components/FileListWithViewer.tsx`

### 5.3 Functional requirements

#### FR-1 Permission gating

- `OWNER` continues to use the existing direct upload/add behavior.
- `ADMIN` and `COLLABORATOR` may upload/add to incoming shared albums.
- `VIEWER` must not be allowed to upload/add.
- Shared album upload must not be exposed through move-only affordances.

#### FR-2 New local file to owned album

- Existing web owned-album upload behavior must remain unchanged.
- No `uncategorized` routing is needed when the destination is owned by the current user.

#### FR-3 New local file to incoming shared album

When the destination is an incoming shared album and the user is an `ADMIN` or `COLLABORATOR`, web must:

1. resolve or create the user's own `uncategorized` collection,
2. upload all local items to `uncategorized`,
3. collect only successful upload results,
4. add those resulting user-owned files to the target shared album,
5. refresh remote state.

Web must not upload local files directly into the incoming shared album.

#### FR-4 Existing uploaded file owned by current user

When the selected file is already uploaded and owned by the current user, web must:

- add it directly to the destination shared album using `add-files`
- skip items already present in the destination

This applies whether the destination is owned by the current user or shared with them.

#### FR-5 Existing uploaded file owned by another user

When the selected file is already uploaded and owned by another user, web must follow mobile parity:

1. check whether the current user already owns an equivalent file with the same hash and file type
2. if such a file exists, add that owned file instead of copying
3. otherwise copy the other-owned file

Copy rules:

- if destination is owned by the current user: copy directly into destination
- if destination is an incoming shared album: copy into user's `uncategorized`, then add the copied file to the shared album

Web must not attempt to add another user's file directly to a shared album.

#### FR-6 Upload result handling

For stage-1 local uploads routed through `uncategorized`, the second-stage add must use all successful results of type:

- `alreadyUploaded`
- `addedSymlink`
- `uploaded`
- `uploadedWithStaticThumbnail`

The second-stage add must ignore per-item results of type:

- `blocked`
- `failed`
- `unsupported`
- `zeroSize`
- `tooLarge`
- `largerThanAvailableStorage`

#### FR-7 Idempotency and duplicate handling

The web flow must:

- not create duplicate collection memberships in the destination
- dedupe repeated file IDs before `add-files`
- dedupe repeated source file IDs per source collection before `copy`
- tolerate the same local file appearing multiple times in one upload batch

#### FR-8 UX and progress

- Existing upload progress UI must remain the single progress surface for contributor uploads.
- Partial success is allowed.
  Successfully uploaded or copied files should still be added to the shared album even if other items fail.
- If stage 1 succeeds for some files but stage 2 fails, the uploaded/copied files may remain in `uncategorized`.
  This is acceptable and matches the ownership-preserving model.
- The user must see final shared album state only after a post-operation pull.
  No optimistic shared album insertion is required.

#### FR-9 Sync and local state

Web must keep its current remote-first architecture:

- collection mutation helpers remain remote operations
- local album state is reconciled by `onRemotePull(...)`
- no mobile-style local DB event bus or optimistic collection-row insertion is required for this feature

#### FR-10 Duplicate suppression parity

Web should add a parity mechanism similar to mobile's shared-copy suppression so that copy-based contributor flows do not create visibly doubled files in aggregate library views.

This is not a blocker for the base contributor upload flow, but it is required for full UX parity with mobile.

### 5.4 Non-functional requirements

- No server API changes.
- Preserve existing E2EE rules by always re-encrypting the file key with the destination collection key at each add/copy step.
- Reuse current upload concurrency and progress infrastructure.
- Keep behavior deterministic across refreshes by ending every successful mutation flow with a pull.

### 5.5 Acceptance criteria

The feature is accepted only if all of the following pass:

- contributor can upload a brand-new local file to an incoming shared album
- contributor can add an already uploaded user-owned file to an incoming shared album
- contributor can add an already uploaded other-owned file to an incoming shared album with same-hash reuse or copy-via-`uncategorized`
- viewer cannot perform any of the above
- move-to-shared-album remains unsupported
- duplicate requests do not create duplicate memberships in the target album

## 6. HLD

### 6.1 Design overview

The web design should mirror the mobile logic, but keep the current web architecture:

- mobile style business rules
- web style remote-first state sync
- existing upload manager and progress UI

The design has three main layers:

1. capability helpers
2. collection mutation parity helpers
3. upload orchestration for contributor targets

### 6.2 Proposed module changes

| Module | Change | Why |
| --- | --- | --- |
| `web/packages/new/photos/services/collection-summary.ts` | Add a helper for "upload-capable destination" that includes incoming shared collaborator/admin albums. | `canMoveToCollection(...)` is the wrong predicate for upload. |
| `web/packages/new/photos/components/CollectionSelector.tsx` | For action `"upload"`, use the new upload-capable predicate instead of move-only filtering. | Contributors must be able to pick incoming shared albums as upload targets. |
| `web/apps/photos/src/components/Upload.tsx` | Replace owner-only active-album upload shortcut with contributor-aware routing. Add a dedicated branch for shared incoming contributor uploads. | Drag/drop and normal upload need the `uncategorized -> add` flow. |
| `web/apps/photos/src/services/upload-manager.ts` | Return structured per-item upload results for a batch, not just a boolean. | Stage 2 needs the resulting `EnteFile`s from stage 1. |
| `web/packages/new/photos/services/collection.ts` | Add `savedOrCreateUserUncategorizedCollection()`, `copyFiles(...)`, `addOrCopyToCollection(...)`, and duplicate filtering helpers. | This is the web equivalent of mobile `CollectionsService.addOrCopyToCollection(...)`. |
| `web/apps/photos/src/pages/gallery.tsx` | For op `"add"`, stop dropping non-owned files; route the full selection into the new parity helper. Keep owner-only filtering for `"move"`, `"restore"`, `"unhide"` as appropriate. | Add parity for existing Ente files. |
| `web/packages/new/photos/components/gallery/helpers.ts` | Update `performCollectionOp(...)` to use parity helpers for `"add"` and keep move semantics unchanged. | Existing helper explicitly documents the parity gap. |
| `web/apps/photos/src/components/FileListWithViewer.tsx` | Reuse the same contributor upload routing helper for any direct collection-targeted upload path. | Avoid leaving edited-file or single-file upload flows inconsistent. |

### 6.3 Proposed helper contracts

The exact names can change, but the design should introduce primitives with these responsibilities:

```ts
canUploadToCollectionSummary(summary: CollectionSummary): boolean
```

- true for owner-owned uploadable collections
- true for incoming shared `ADMIN` / `COLLABORATOR`
- false for incoming shared `VIEWER`

```ts
savedOrCreateUserUncategorizedCollection(): Promise<Collection>
```

- returns the locally known user-owned `uncategorized` if present
- otherwise creates it remotely and returns the created collection

```ts
copyFiles(
  dstCollection: Collection,
  files: EnteFile[],
): Promise<EnteFile[]>
```

- groups input by `srcCollectionID`
- re-encrypts file keys with `dstCollection.key`
- calls `POST /files/copy`
- returns copied `EnteFile`s with:
  - new `file.id`
  - `ownerID = currentUser.id`
  - `collectionID = dstCollection.id`

```ts
addOrCopyToCollection(
  dstCollection: Collection,
  files: EnteFile[],
): Promise<void>
```

- split into current-user-owned vs other-owned
- skip items already present in destination
- for other-owned:
  - same-hash owned reuse if available
  - otherwise copy directly or via `uncategorized` depending on destination ownership

### 6.4 Upload batch result contract

`upload-manager` needs to expose the actual `UploadResult` per item. The simplest shape is:

```ts
type UploadBatchItemResult = {
  localID: number;
  requestedCollectionID: number;
  result: UploadResult;
};

type UploadBatchResult = {
  processedAny: boolean;
  itemResults: UploadBatchItemResult[];
};
```

Key requirement:

- `itemResults` must include `alreadyUploaded`
- `itemResults` must include `addedSymlink`
- the caller must be able to recover the resulting `EnteFile` for every successful item

This is the main missing primitive needed for the two-stage contributor upload flow.

### 6.5 Detailed flow A: new local upload to incoming shared album

1. User selects files while an incoming shared album is the target.
2. `Upload.tsx` detects that the target is contributor-uploadable but not owned by the current user.
3. `Upload.tsx` resolves `savedOrCreateUserUncategorizedCollection()`.
4. `Upload.tsx` rewrites the upload batch so stage 1 uploads into `uncategorized`.
5. `uploadManager.uploadItems(...)` returns structured per-item results.
6. `Upload.tsx` collects the successful `EnteFile`s from those results.
7. `Upload.tsx` calls `addOrCopyToCollection(targetSharedAlbum, stage1Files)`.
   In practice these files are already user-owned, so this becomes add-only.
8. `Upload.tsx` performs `onRemotePull()` once the workflow completes.

Why this matches mobile:

- ownership is preserved
- no direct upload into an incoming shared album
- same UI progress surface remains in place

### 6.6 Detailed flow B: add existing uploaded files to incoming shared album

1. User selects files and chooses `"add to album"`.
2. `pages/gallery.tsx` passes the full selected set for op `"add"`.
3. `performCollectionOp("add", ...)` calls `addOrCopyToCollection(target, files)`.
4. `addOrCopyToCollection(...)`:
   - adds current-user-owned files directly
   - for other-owned files:
     - reuses same-hash owned files where possible
     - otherwise copies via `uncategorized`
5. Caller performs `remotePull({ silent: true })`.

Why `pages/gallery.tsx` must change:

- current code drops non-owned files before `"add"`
- that behavior is the exact parity gap this feature needs to remove

### 6.7 Detailed flow C: copy of other-owned files

1. Group input files by `collectionID`.
2. For each source collection:
   - remove duplicate `file.id`s
   - encrypt the file key with destination collection key
   - call `/files/copy` with:
     - `dstCollectionID`
     - `srcCollectionID`
     - `files`
3. Rewrite local in-memory `EnteFile` copies using `oldToNewFileIDMap`.
4. If the final target is an incoming shared album, call `addToCollection(...)` with the copied files after the copy-to-`uncategorized` step.

### 6.8 Duplicate and lookup strategy

For parity with mobile, the helper layer should:

- build a set of file IDs already present in the destination collection
- skip direct adds for those IDs
- find current-user-owned same-hash equivalents using locally saved collection files
- require same hash and same file type before reusing

Recommended local sources:

- `savedCollectionFiles()`
- `savedNormalCollections()` / `savedAllCollections()`
- `metadataHash(file.metadata)`

### 6.9 State and sync model

The design intentionally keeps web remote-first:

- `addToCollection(...)` remains remote-only
- `copyFiles(...)` can also remain remote-only from the perspective of persistent local state
- all UI correctness after mutation comes from `remotePull`

This is different from mobile, which updates local DB rows eagerly, but it fits existing web architecture and reduces risk.

### 6.10 Error handling

- Stage 1 upload errors remain handled by existing upload UI and notifications.
- Stage 2 add/copy errors use existing generic error handling.
- If only some items succeed in stage 1, only those items advance to stage 2.
- If stage 2 fails after stage 1 succeeded, no rollback is required.
  Successfully uploaded/copied files may remain in `uncategorized`.

### 6.11 Test matrix

#### Role matrix

- owner of destination album: allowed
- incoming shared admin: allowed
- incoming shared collaborator: allowed
- incoming shared viewer: denied

#### File-state matrix

- new local file -> owned album
- new local file -> incoming shared album
- existing uploaded user-owned file -> incoming shared album
- existing uploaded other-owned file -> owned album
- existing uploaded other-owned file -> incoming shared album

#### Duplicate matrix

- file already exists in target shared album
- current user already owns same-hash equivalent in another collection
- current user does not own same-hash equivalent and copy is required
- same source file selected twice in one batch

#### UX/state matrix

- upload button path with active shared album
- drag/drop path with active shared album
- collection selector upload path
- multi-select add-to-album path
- single-file add-to-album path
- partial success across stage 1 and stage 2

### 6.12 Rollout order

Recommended implementation order:

1. add upload-capable destination helper and update `CollectionSelector`
2. add structured upload batch results to `upload-manager`
3. implement `savedOrCreateUserUncategorizedCollection()` and contributor upload routing in `Upload.tsx`
4. implement `copyFiles(...)` and `addOrCopyToCollection(...)` in `collection.ts`
5. switch `"add"` flows in `pages/gallery.tsx` and `gallery/helpers.ts` to the parity helper
6. audit any direct `uploadManager.uploadFile(...)` callers
7. add duplicate suppression parity in aggregate views

## 7. Final Design Decision

The web implementation must follow the mobile model exactly:

- upload directly only when the target collection is owned by the actor
- add directly only when the file is owned by the actor
- copy only into a collection owned by the actor
- for incoming shared contributor albums, use the actor's `uncategorized` collection as the bridge whenever direct upload/copy is invalid

That is the correct design because it matches:

- current mobile behavior,
- current server constraints,
- current ownership invariants.

# Collection Actions & Admin Removal Add‑ons

This document supplements `collections-architecture.md` with admin/owner removal and action feed semantics. It will be merged back into the main doc after the related server changes land.

## Summary

- Adds soft action markers to `collection_files` to drive client behavior: `action_user`, `action`.
- Introduces a `collection_actions` store for per-user pending actions (`REMOVE`, `DELETE_SUGGESTED`); `/collection-actions/pending-remove` currently exposes the `REMOVE` queue.
- Extends removal flows so admins/owners can orchestrate deletes in shared collections while preserving invariants.

## Endpoints

- `POST /collections/v3/remove-files`
  - Removes memberships for files the actor is permitted to remove (i.e., files not owned by the collection owner).
  - Admins removing album-owner-owned files: server sets a `REMOVE` action marker (soft delete for non-owners) and creates owner-facing actions instead of deleting the membership.
  - Collection owners attempting to remove their own files receive a validation error; clients must relocate/move those files before they can vanish from the shared album.

- `POST /collections/suggest-delete`
  - Actor must be album owner or admin; cannot target actor-owned files.
  - Owner-owned files: set `REMOVE` marker on the membership and create two actions for the owner (`REMOVE`, `DELETE_SUGGESTED`).
  - Other owners’ files: remove membership; create `DELETE_SUGGESTED` actions for the respective file owners.

- `GET /collection-actions/pending-remove?updatedAt=...`
  - Returns pending `REMOVE` actions newer than the provided timestamp (limit 2000). Each entry includes the actor, collection, and file ID so clients can guide the owner workflow.
  - `DELETE_SUGGESTED` entries share the same table but do not have an HTTP feed yet; they are reserved for forthcoming client flows.

## Diff Semantics

- `GET /collections/v2/diff`
  - For non-owners: entries with `action in {REMOVE, DELETE_SUGGESTED}` are masked as `isDeleted=true`; `action` and `actionUser` are omitted.
  - For the file owner: `action` and `actionUser` are included to drive follow-up behavior.
- Public and cast diffs always mask entries with actions (`REMOVE`, `DELETE_SUGGESTED`, plus legacy `DELETE`) as deleted and strip action details.

## Client Guidance

- `REMOVE` for album-owner-owned files: owner should relocate the file (ensure it remains in at least one owned collection) and proceed with local removal from the shared album.
- `DELETE_SUGGESTED`: prompt the file owner to delete the file; accept or reject via UI.
- Continue to enforce the local invariant “file must remain in at least one collection”.
- Collection owners cannot use `/collections/v3/remove-files` for their own files; they must move/relocate them before the server will let the membership disappear.

## Schema Notes

- `collection_files` gains `action_user BIGINT`, `action TEXT` (soft markers; do not flip `is_deleted`).
- New table `collection_actions` stores per-user pending actions with indexes on `user_id` and `collection_id`.

## Server Behavior Notes

### `RemoveFilesV3`

- Invoked by `POST /collections/v3/remove-files` when the album owner removes files contributed by collaborators.
- The repository first builds an owner→file map and rejects the request if any file is owned by the collection owner; owner-owned files must follow the action-marker workflow instead.
- Valid files are soft-deleted by flipping `collection_files.is_deleted=true` and bumping `updation_time`. `created_at` is left untouched so timelines remain stable.
- When those memberships are later reactivated through `AddFiles`, `RestoreFiles`, or `MoveFiles`, the associated `ON CONFLICT` clause now refreshes `created_at` only if the row transitions from deleted back to active. This keeps resurrected files ordered correctly without rewriting healthy rows.

### `ScheduleDelete`

- Used by owner/admin delete endpoints to mark an entire collection for removal without immediately touching every file.
- Steps performed inside a single transaction:
  - `collection_shares` rows for the album are marked `is_deleted=true` so sharees immediately lose access.
  - The parent `collections` row is marked `is_deleted=true` and `updation_time` is bumped for diff consumers.
  - A job ID is enqueued in `TrashCollectionQueueV3`; background workers later call `TrashV3` to move all owner-owned files to trash (including the fallback path that removes any collaborator-owned leftovers).
- This split keeps the user-visible state consistent right away while deferring the expensive trashing work to an async worker.

## Caveats

- The server does not enforce “file must remain in at least one collection”; clients must handle relocation before finalizing removals for owner-owned files.
- Mixed removal requests containing both owner-owned and other users’ files may be partially applied; clients should not assume all-or-nothing behavior.

# Collection Actions & Admin Removal Add‑ons

This document supplements `collections-architecture.md` with admin/owner removal and action feed semantics. It will be merged back into the main doc after the related server changes land.

## Summary

- Adds soft action markers to `collection_files` to drive client behavior: `action_user`, `action`.
- Introduces a `collection_actions` feed for per-user pending actions (`REMOVE`, `DELETE_SUGGESTED`).
- Extends removal flows so admins/owners can orchestrate deletes in shared collections while preserving invariants.

## Endpoints

- `POST /collections/v3/remove-files`
  - Removes memberships for files the actor is permitted to remove.
  - Admins removing album-owner-owned files: server sets a `REMOVE` action marker (soft delete for non-owners) and creates owner-facing actions.
  - Owners removing their own files: allowed; clients should ensure the file stays in at least one owned collection.

- `POST /collections/suggest-delete`
  - Actor must be album owner or admin; cannot target actor-owned files.
  - Owner-owned files: set `REMOVE` marker on the membership and create two actions for the owner (`REMOVE`, `DELETE_SUGGESTED`).
  - Other owners’ files: remove membership; create `DELETE_SUGGESTED` actions for the respective file owners.

- `GET /collection-actions?sinceTime=...` (alias: `/pending-actions`)
  - Returns actions for the authenticated user. Clients consume and act locally.

## Diff Semantics

- `GET /collections/v2/diff`
  - For non-owners: entries with `action in {REMOVE, DELETE, DELETE_SUGGESTED}` are masked as `isDeleted=true`; `action` and `actionUser` are omitted.
  - For the file owner: `action` and `actionUser` are included to drive follow-up behavior.
- Public and cast diffs always mask entries with actions as deleted and strip action details.

## Client Guidance

- `REMOVE` for album-owner-owned files: owner should relocate the file (ensure it remains in at least one owned collection) and proceed with local removal from the shared album.
- `DELETE_SUGGESTED`: prompt the file owner to delete the file; accept or reject via UI.
- Continue to enforce the local invariant “file must remain in at least one collection”.

## Schema Notes

- `collection_files` gains `action_user BIGINT`, `action TEXT` (soft markers; do not flip `is_deleted`).
- New table `collection_actions` stores per-user pending actions with indexes on `user_id` and `collection_id`.

## Caveats

- The server does not enforce “file must remain in at least one collection”; clients must handle relocation before finalizing removals for owner-owned files.
- Mixed removal requests containing both owner-owned and other users’ files may be partially applied; clients should not assume all-or-nothing behavior.


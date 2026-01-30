# LLM chat

Museum can store encrypted LLM chat sessions/messages.

## Enable

1. Set `features.llmchat: true` in `museum.yaml`.
2. Ensure migration `115` has been applied.

## Endpoints (authenticated)

- `POST /llmchat/chat/key`
- `GET /llmchat/chat/key`
- `POST /llmchat/chat/session`
- `POST /llmchat/chat/message`
- `DELETE /llmchat/chat/session?id=<session_uuid>`
- `DELETE /llmchat/chat/message?id=<message_uuid>`
- `GET /llmchat/chat/diff?sinceTime=<microseconds>`
- `POST /llmchat/chat/attachment/:attachmentId/upload-url` *(only when attachments are enabled)*
- `GET /llmchat/chat/attachment/:attachmentId` *(only when attachments are enabled)*

## Limits

- Max request JSON size: `llmchat.max_json_body_bytes` (default: 819200 bytes / 800KB)
- Diff page size: `llmchat.diff.default_limit` (default: 500), `llmchat.diff.maximum_limit` (default: 2500)
- Messages per user (soft limit): 2000 (free), 50000 (paid)
- Attachments per message: 4 (free), 10 (paid)
- Attachment size: 25MB (free), 100MB (paid)
- Total attachment storage: 1GB (free), 10GB (paid)

## Attachments

Attachments are gated behind `llmchat.attachments.enabled: true`.

When enabled, attachments are only available for internal users (`@ente.io` or users with `remote-store/internalUser=true`).

When enabled:

- Apply migration `116`.
- Uploads are staged under `llmchat/attachments/<user_id>/<attachment_uuid>` in bucket `b7`.
- Attachments are committed when referenced by a message.

To control cleanup when attachments are enabled, set
`llmchat.attachments.cleanup: true` to enable daily purging of unreferenced
attachments. Temp uploads are cleaned automatically.

## Retention

LLM chat tombstones are pruned daily once they are older than 90 days.

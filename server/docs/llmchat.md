# LLM chat

Museum can store encrypted LLM chat sessions/messages. Attachment support is
currently disabled.

## Enable

1. Add `features.llmchat: true` in `museum.yaml`.
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

## Attachments (disabled)

Attachment uploads are currently disabled. The endpoints are gated behind
`llmchat.attachments.enabled: true` and require a future migration to re-enable
attachment storage. When enabled, uploads are staged under
`llmchat/attachments/<user_id>/<attachment_uuid>` in the hot bucket and are
committed when referenced by a message.

To control cleanup when attachments are enabled, set
`llmchat.attachments.cleanup: true` to enable daily purging of unreferenced
attachments. Temp uploads are cleaned automatically.

## Retention

LLM chat tombstones are pruned daily once they are older than 90 days.

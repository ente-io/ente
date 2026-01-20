# LLM chat

Museum can store encrypted LLM chat sessions/messages and optional attachments.

## Enable

1. Add `features.llmchat: true` in `museum.yaml`.
2. Ensure migrations `115`, `116`, and `117` have been applied.

## Endpoints (authenticated)

- `POST /llmchat/chat/key`
- `GET /llmchat/chat/key`
- `POST /llmchat/chat/session`
- `POST /llmchat/chat/message`
- `DELETE /llmchat/chat/session?id=<session_uuid>`
- `DELETE /llmchat/chat/message?id=<message_uuid>`
- `GET /llmchat/chat/diff?sinceTime=<microseconds>`
- `POST /llmchat/chat/attachment/:attachmentId/upload-url`
- `GET /llmchat/chat/attachment/:attachmentId`

## Attachments

Attachment uploads require S3 configuration. Uploads are staged under
`llmchat/attachments/<user_id>/<attachment_uuid>` in the hot bucket and are
committed when referenced by a message.

To control cleanup, set `llmchat.attachments.cleanup: true` to enable daily
purging of unreferenced attachments. Temp uploads are cleaned automatically.

## Retention

LLM chat tombstones are pruned daily once they are older than 90 days.

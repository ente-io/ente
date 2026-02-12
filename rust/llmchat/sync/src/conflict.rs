use std::collections::{HashMap, HashSet};

use llmchat_db::{AttachmentMeta, Message, Sender};
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ConflictResolution {
    LocalWins,
    RemoteWins,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct LocalSyncState {
    pub uuid: Uuid,
    pub needs_sync: bool,
    pub server_updated_at: Option<i64>,
}

pub fn resolve_session_conflict(
    local: LocalSyncState,
    remote_updated_at: i64,
    remote_uuid: Uuid,
) -> ConflictResolution {
    if local.needs_sync && local.server_updated_at.is_none() {
        return ConflictResolution::LocalWins;
    }

    let local_ts = local.server_updated_at.unwrap_or(0);
    if local_ts > remote_updated_at {
        ConflictResolution::LocalWins
    } else if local_ts < remote_updated_at {
        ConflictResolution::RemoteWins
    } else if local.uuid > remote_uuid {
        ConflictResolution::LocalWins
    } else {
        ConflictResolution::RemoteWins
    }
}

pub fn should_accept_remote_session(
    local: LocalSyncState,
    remote_updated_at: i64,
    remote_uuid: Uuid,
) -> bool {
    resolve_session_conflict(local, remote_updated_at, remote_uuid)
        == ConflictResolution::RemoteWins
}

pub fn resolve_message_conflict(
    local: LocalSyncState,
    remote_updated_at: i64,
    remote_uuid: Uuid,
) -> ConflictResolution {
    if local.needs_sync && local.server_updated_at.is_none() {
        return ConflictResolution::LocalWins;
    }

    let local_ts = local.server_updated_at.unwrap_or(0);
    if local_ts > remote_updated_at {
        ConflictResolution::LocalWins
    } else if local_ts < remote_updated_at {
        ConflictResolution::RemoteWins
    } else if local.uuid > remote_uuid {
        ConflictResolution::LocalWins
    } else {
        ConflictResolution::RemoteWins
    }
}

pub fn should_accept_remote_message(
    local: LocalSyncState,
    remote_updated_at: i64,
    remote_uuid: Uuid,
) -> bool {
    resolve_message_conflict(local, remote_updated_at, remote_uuid)
        == ConflictResolution::RemoteWins
}

pub fn find_duplicate_message(
    local_messages: &[Message],
    sender: &Sender,
    text: &str,
    attachments: &[AttachmentMeta],
    created_at: i64,
    parent: Option<Uuid>,
) -> Option<Uuid> {
    let signature = attachments_signature(attachments);
    local_messages.iter().find_map(|message| {
        if &message.sender != sender {
            return None;
        }
        if message.text != text {
            return None;
        }
        if message.parent_message_uuid != parent {
            return None;
        }
        if attachments_signature(&message.attachments) != signature {
            return None;
        }
        if (message.created_at - created_at).abs() > 2_000_000 {
            return None;
        }
        Some(message.uuid)
    })
}

pub fn order_for_sync(messages: &[Message]) -> Vec<Message> {
    if messages.is_empty() {
        return Vec::new();
    }

    let by_id: HashMap<Uuid, &Message> = messages.iter().map(|m| (m.uuid, m)).collect();
    let mut children: HashMap<Option<Uuid>, Vec<&Message>> = HashMap::new();

    for message in messages {
        let parent = message
            .parent_message_uuid
            .filter(|parent| by_id.contains_key(parent));
        children.entry(parent).or_default().push(message);
    }

    for list in children.values_mut() {
        list.sort_by(|a, b| {
            a.created_at
                .cmp(&b.created_at)
                .then_with(|| a.uuid.cmp(&b.uuid))
        });
    }

    let mut ordered = Vec::with_capacity(messages.len());
    let mut visited = HashSet::new();

    if let Some(roots) = children.get(&None) {
        for root in roots {
            dfs_order(*root, &children, &mut visited, &mut ordered);
        }
    }

    ordered
}

fn dfs_order(
    node: &Message,
    children: &HashMap<Option<Uuid>, Vec<&Message>>,
    visited: &mut HashSet<Uuid>,
    output: &mut Vec<Message>,
) {
    if !visited.insert(node.uuid) {
        return;
    }
    output.push(node.clone());
    if let Some(kids) = children.get(&Some(node.uuid)) {
        for child in kids {
            dfs_order(*child, children, visited, output);
        }
    }
}

fn attachments_signature(attachments: &[AttachmentMeta]) -> Vec<String> {
    attachments
        .iter()
        .map(|att| format!("{:?}:{}:{}", att.kind, att.name, att.size))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use llmchat_db::{AttachmentKind, AttachmentMeta, Message, Sender};
    use uuid::Uuid;

    #[test]
    fn duplicate_message_respects_parent_and_attachment_size() {
        let session_uuid = Uuid::new_v4();
        let parent_uuid = Uuid::new_v4();
        let message_uuid = Uuid::new_v4();
        let attachment = AttachmentMeta {
            id: "att-1".to_string(),
            kind: AttachmentKind::Image,
            size: 512,
            name: "photo.png".to_string(),
        };

        let local = Message {
            uuid: message_uuid,
            session_uuid,
            parent_message_uuid: Some(parent_uuid),
            sender: Sender::SelfUser,
            text: "hello".to_string(),
            attachments: vec![attachment.clone()],
            created_at: 10_000,
            remote_id: None,
            server_updated_at: None,
            needs_sync: true,
            deleted_at: None,
        };

        let wrong_size = AttachmentMeta {
            size: 256,
            ..attachment.clone()
        };
        assert!(
            find_duplicate_message(
                &[local.clone()],
                &Sender::SelfUser,
                "hello",
                &[wrong_size],
                10_000,
                Some(parent_uuid),
            )
            .is_none()
        );

        assert!(
            find_duplicate_message(
                &[local.clone()],
                &Sender::SelfUser,
                "hello",
                &[attachment.clone()],
                10_000,
                None,
            )
            .is_none()
        );

        assert_eq!(
            find_duplicate_message(
                &[local],
                &Sender::SelfUser,
                "hello",
                &[attachment],
                10_000,
                Some(parent_uuid),
            ),
            Some(message_uuid)
        );
    }
}

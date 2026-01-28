use std::collections::{HashMap, HashSet};

use llmchat_db::{AttachmentMeta, Message, Sender};
use uuid::Uuid;

pub fn find_duplicate_message(
    local_messages: &[Message],
    sender: &Sender,
    text: &str,
    attachments: &[AttachmentMeta],
    created_at: i64,
) -> Option<Uuid> {
    let signature = attachments_signature(attachments);
    local_messages.iter().find_map(|message| {
        if &message.sender != sender {
            return None;
        }
        if message.text != text {
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
        .map(|att| format!("{:?}:{}", att.kind, att.name))
        .collect()
}

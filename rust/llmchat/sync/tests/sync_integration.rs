use httpmock::Method::{DELETE, GET, POST};
use httpmock::MockServer;
use llmchat_db::LlmChatDb;
use llmchat_db::crypto::KEY_BYTES;
use llmchat_sync::SyncAuth;
use llmchat_sync::SyncEngine;
use llmchat_sync::crypto::{encrypt_chat_key, encrypt_payload};
use llmchat_sync::models::{
    ChatKeyPayload, DiffResponse, DiffTombstones, MessagePayload, MessageTombstone, RemoteMessage,
    RemoteSession, SessionPayload,
};
use tempfile::TempDir;
use uuid::Uuid;
use zeroize::Zeroizing;

struct TestEnv {
    _dir: TempDir,
    main_db_path: String,
    attachments_db_path: String,
    attachments_dir: String,
    meta_dir: String,
    plaintext_dir: Option<String>,
}

impl TestEnv {
    fn new() -> Self {
        let dir = TempDir::new().expect("temp dir");
        let main_db_path = dir.path().join("main.db");
        let attachments_db_path = dir.path().join("attachments.db");
        let attachments_dir = dir.path().join("attachments");
        let meta_dir = dir.path().join("meta");
        Self {
            _dir: dir,
            main_db_path: main_db_path.to_string_lossy().to_string(),
            attachments_db_path: attachments_db_path.to_string_lossy().to_string(),
            attachments_dir: attachments_dir.to_string_lossy().to_string(),
            meta_dir: meta_dir.to_string_lossy().to_string(),
            plaintext_dir: None,
        }
    }
}

fn make_auth(server: &MockServer, master_key: Vec<u8>) -> SyncAuth {
    SyncAuth {
        base_url: server.base_url(),
        auth_token: "token".to_string(),
        master_key: Zeroizing::new(master_key),
        user_agent: None,
        client_package: None,
        client_version: None,
    }
}

fn mock_chat_key(server: &MockServer, master_key: &[u8], chat_key: &[u8]) {
    let encrypted = encrypt_chat_key(chat_key, master_key).expect("encrypt chat key");
    let payload = ChatKeyPayload::from_encrypted(&encrypted);
    server.mock(|when, then| {
        when.method(GET).path("/llmchat/chat/key");
        then.status(200).json_body_obj(&payload);
    });
}

fn mock_empty_diff(server: &MockServer, timestamp: i64) {
    let diff = DiffResponse {
        sessions: Vec::new(),
        messages: Vec::new(),
        tombstones: DiffTombstones::default(),
        cursor: None,
        timestamp: Some(timestamp),
    };
    server.mock(|when, then| {
        when.method(GET).path("/llmchat/chat/diff");
        then.status(200).json_body_obj(&diff);
    });
}

#[test]
fn pull_applies_remote_sessions_and_messages() {
    let env = TestEnv::new();
    let db_key = vec![42u8; KEY_BYTES];
    let engine = SyncEngine::new(
        env.main_db_path.clone(),
        env.attachments_db_path.clone(),
        db_key.clone(),
        env.attachments_dir.clone(),
        env.meta_dir.clone(),
        env.plaintext_dir.clone(),
    )
    .expect("sync engine");

    let master_key = vec![9u8; KEY_BYTES];
    let chat_key = ente_core::crypto::keys::generate_stream_key();

    let server = MockServer::start();
    mock_chat_key(&server, &master_key, &chat_key);

    let session_uuid = Uuid::new_v4();
    let message_uuid = Uuid::new_v4();

    let session_payload = SessionPayload {
        title: "Remote Session".to_string(),
    };
    let encrypted_session = encrypt_payload(&session_payload, &chat_key).expect("encrypt session");

    let message_payload = MessagePayload {
        text: "hello".to_string(),
    };
    let encrypted_message = encrypt_payload(&message_payload, &chat_key).expect("encrypt message");

    let diff = DiffResponse {
        sessions: vec![RemoteSession {
            session_uuid: session_uuid.to_string(),
            encrypted_data: encrypted_session.encrypted_data,
            header: encrypted_session.header,
            client_metadata: None,
            created_at: 10,
            updated_at: 11,
            is_deleted: None,
        }],
        messages: vec![RemoteMessage {
            message_uuid: message_uuid.to_string(),
            session_uuid: session_uuid.to_string(),
            parent_message_uuid: None,
            sender: "self".to_string(),
            attachments: Vec::new(),
            encrypted_data: encrypted_message.encrypted_data,
            header: encrypted_message.header,
            client_metadata: None,
            created_at: 12,
            updated_at: None,
            is_deleted: None,
        }],
        tombstones: DiffTombstones::default(),
        cursor: None,
        timestamp: Some(12),
    };

    server.mock(|when, then| {
        when.method(GET).path("/llmchat/chat/diff");
        then.status(200).json_body_obj(&diff);
    });

    let auth = make_auth(&server, master_key);
    engine.sync(auth).expect("sync");

    let db = LlmChatDb::open_sqlite_with_defaults(
        env.main_db_path.clone(),
        env.attachments_db_path.clone(),
        db_key,
    )
    .expect("db");

    let sessions = db.list_sessions().expect("sessions");
    assert_eq!(sessions.len(), 1);
    assert_eq!(sessions[0].uuid, session_uuid);
    assert_eq!(sessions[0].title, "Remote Session");

    let messages = db.get_messages(session_uuid).expect("messages");
    assert_eq!(messages.len(), 1);
    assert_eq!(messages[0].uuid, message_uuid);
    assert_eq!(messages[0].text, "hello");
    assert!(!messages[0].needs_sync);
}

#[test]
fn push_only_needs_sync_messages() {
    let env = TestEnv::new();
    let db_key = vec![11u8; KEY_BYTES];
    let engine = SyncEngine::new(
        env.main_db_path.clone(),
        env.attachments_db_path.clone(),
        db_key.clone(),
        env.attachments_dir.clone(),
        env.meta_dir.clone(),
        env.plaintext_dir.clone(),
    )
    .expect("sync engine");

    let db = LlmChatDb::open_sqlite_with_defaults(
        env.main_db_path.clone(),
        env.attachments_db_path.clone(),
        db_key.clone(),
    )
    .expect("db");

    let session = db.create_session("Local Session").expect("session");
    let message_one = db
        .insert_message(session.uuid, "self", "one", None, Vec::new())
        .expect("message one");
    let _message_two = db
        .insert_message(session.uuid, "self", "two", None, Vec::new())
        .expect("message two");
    db.mark_message_synced(message_one.uuid)
        .expect("mark synced");

    let master_key = vec![7u8; KEY_BYTES];
    let chat_key = ente_core::crypto::keys::generate_stream_key();
    let server = MockServer::start();
    mock_chat_key(&server, &master_key, &chat_key);
    mock_empty_diff(&server, 10);

    let session_mock = server.mock(|when, then| {
        when.method(POST).path("/llmchat/chat/session");
        then.status(200).json_body_obj(&serde_json::json!({}));
    });

    let message_mock = server.mock(|when, then| {
        when.method(POST).path("/llmchat/chat/message");
        then.status(200).json_body_obj(&serde_json::json!({}));
    });

    let auth = make_auth(&server, master_key);
    engine.sync(auth).expect("sync");

    assert_eq!(session_mock.hits(), 1);
    assert_eq!(message_mock.hits(), 1);

    let messages = db.get_messages(session.uuid).expect("messages");
    assert!(messages.iter().all(|message| !message.needs_sync));
}

#[test]
fn tombstone_removes_messages() {
    let env = TestEnv::new();
    let db_key = vec![3u8; KEY_BYTES];
    let engine = SyncEngine::new(
        env.main_db_path.clone(),
        env.attachments_db_path.clone(),
        db_key.clone(),
        env.attachments_dir.clone(),
        env.meta_dir.clone(),
        env.plaintext_dir.clone(),
    )
    .expect("sync engine");

    let master_key = vec![12u8; KEY_BYTES];
    let chat_key = ente_core::crypto::keys::generate_stream_key();

    let server = MockServer::start();
    mock_chat_key(&server, &master_key, &chat_key);

    let session_uuid = Uuid::new_v4();
    let message_uuid = Uuid::new_v4();

    let session_payload = SessionPayload {
        title: "Remote Session".to_string(),
    };
    let encrypted_session = encrypt_payload(&session_payload, &chat_key).expect("encrypt session");

    let message_payload = MessagePayload {
        text: "to delete".to_string(),
    };
    let encrypted_message = encrypt_payload(&message_payload, &chat_key).expect("encrypt message");

    let diff = DiffResponse {
        sessions: vec![RemoteSession {
            session_uuid: session_uuid.to_string(),
            encrypted_data: encrypted_session.encrypted_data,
            header: encrypted_session.header,
            client_metadata: None,
            created_at: 10,
            updated_at: 11,
            is_deleted: None,
        }],
        messages: vec![RemoteMessage {
            message_uuid: message_uuid.to_string(),
            session_uuid: session_uuid.to_string(),
            parent_message_uuid: None,
            sender: "self".to_string(),
            attachments: Vec::new(),
            encrypted_data: encrypted_message.encrypted_data,
            header: encrypted_message.header,
            client_metadata: None,
            created_at: 12,
            updated_at: None,
            is_deleted: None,
        }],
        tombstones: DiffTombstones {
            sessions: Vec::new(),
            messages: vec![MessageTombstone {
                message_uuid: message_uuid.to_string(),
                deleted_at: Some(15),
            }],
        },
        cursor: None,
        timestamp: Some(15),
    };

    server.mock(|when, then| {
        when.method(GET).path("/llmchat/chat/diff");
        then.status(200).json_body_obj(&diff);
    });

    server.mock(|when, then| {
        when.method(DELETE).path("/llmchat/chat/message");
        then.status(200).json_body_obj(&serde_json::json!({}));
    });

    let auth = make_auth(&server, master_key);
    engine.sync(auth).expect("sync");

    let db = LlmChatDb::open_sqlite_with_defaults(
        env.main_db_path.clone(),
        env.attachments_db_path.clone(),
        db_key,
    )
    .expect("db");

    let messages = db.get_messages(session_uuid).expect("messages");
    assert!(messages.is_empty());
}

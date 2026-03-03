import Foundation

enum ChatDataCleaner {
    static func deleteAllData() {
        let baseDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dbDir = baseDir.appendingPathComponent("llmchat", isDirectory: true)

        let mainDbUrl = dbDir.appendingPathComponent("llmchat.db")
        let syncDbUrl = dbDir.appendingPathComponent("llmchat_sync.db")
        let onlineDbUrl = dbDir.appendingPathComponent("llmchat_online.db")
        let attachmentsDirUrl = dbDir.appendingPathComponent("chat_attachments", isDirectory: true)
        let encryptedAttachmentsDirUrl = dbDir.appendingPathComponent("chat_attachments_encrypted", isDirectory: true)
        let metaDirUrl = dbDir.appendingPathComponent("sync_meta", isDirectory: true)
        let plaintextDirUrl = attachmentsDirUrl

        try? FileManager.default.removeItem(at: mainDbUrl)
        try? FileManager.default.removeItem(at: syncDbUrl)
        try? FileManager.default.removeItem(at: onlineDbUrl)
        try? FileManager.default.removeItem(at: attachmentsDirUrl)
        try? FileManager.default.removeItem(at: encryptedAttachmentsDirUrl)
        try? FileManager.default.removeItem(at: metaDirUrl)
        try? FileManager.default.removeItem(at: plaintextDirUrl)
    }

    static func deleteSyncState() {
        let baseDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dbDir = baseDir.appendingPathComponent("llmchat", isDirectory: true)

        let syncDbUrl = dbDir.appendingPathComponent("llmchat_sync.db")
        let onlineDbUrl = dbDir.appendingPathComponent("llmchat_online.db")
        let metaDirUrl = dbDir.appendingPathComponent("sync_meta", isDirectory: true)
        let encryptedAttachmentsDirUrl = dbDir.appendingPathComponent("chat_attachments_encrypted", isDirectory: true)

        try? FileManager.default.removeItem(at: syncDbUrl)
        try? FileManager.default.removeItem(at: onlineDbUrl)
        try? FileManager.default.removeItem(at: metaDirUrl)
        try? FileManager.default.removeItem(at: encryptedAttachmentsDirUrl)
    }
}

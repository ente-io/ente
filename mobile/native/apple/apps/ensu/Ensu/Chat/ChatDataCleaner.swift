import Foundation

enum ChatDataCleaner {
    static func deleteAllData() {
        let baseDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dbDir = baseDir.appendingPathComponent("llmchat", isDirectory: true)

        let mainDbUrl = dbDir.appendingPathComponent("llmchat.db")
        let attachmentsDbUrl = dbDir.appendingPathComponent("llmchat_sync.db")
        let attachmentsDirUrl = dbDir.appendingPathComponent("chat_attachments", isDirectory: true)

        try? FileManager.default.removeItem(at: mainDbUrl)
        try? FileManager.default.removeItem(at: attachmentsDbUrl)
        try? FileManager.default.removeItem(at: attachmentsDirUrl)
    }
}

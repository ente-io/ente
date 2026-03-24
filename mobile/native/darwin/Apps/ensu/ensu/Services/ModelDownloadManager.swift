import Foundation
import CryptoKit

struct ModelDownloadTarget: Equatable {
    let label: String
    let url: String
    let destination: URL
}

final class ModelDownloadManager: NSObject {
    static let shared = ModelDownloadManager()

    private struct DownloadRecord: Codable {
        enum State: String, Codable {
            case queued
            case downloading
            case failed
        }

        let id: String
        let label: String
        let url: String
        let destinationPath: String
        var state: State
        var errorMessage: String?
        var resumeData: Data?
    }

    private let recordsKey = "ensu.model.download.records"
    private let syncQueue = DispatchQueue(label: "io.ente.ensu.model-download-manager")
    private lazy var session: URLSession = {
        let configuration: URLSessionConfiguration
        configuration = URLSessionConfiguration.background(withIdentifier: "io.ente.ensu.model-downloads")
        #if os(iOS)
        configuration.sessionSendsLaunchEvents = true
        #endif
        configuration.isDiscretionary = false
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    private var backgroundCompletionHandler: (() -> Void)?

    func setBackgroundCompletionHandler(_ completionHandler: @escaping () -> Void) {
        syncQueue.async {
            self.backgroundCompletionHandler = completionHandler
        }
    }

    func enqueueDownloads(_ targets: [ModelDownloadTarget]) async {
        let tasks = await allTasks()
        let activeIds = Set(tasks.compactMap(\.taskDescription))

        for target in targets where !FileManager.default.fileExists(atPath: target.destination.path) {
            let id = recordId(for: target.destination)
            if activeIds.contains(id) {
                continue
            }

            let record = DownloadRecord(
                id: id,
                label: target.label,
                url: target.url,
                destinationPath: target.destination.path,
                state: .queued,
                errorMessage: nil,
                resumeData: nil
            )

            guard let url = URL(string: target.url) else {
                saveRecord(record)
                markFailed(id: id, message: "Invalid URL")
                continue
            }

            let existingRecord = loadRecords()[id]
            let task: URLSessionDownloadTask
            if let resumeData = existingRecord?.resumeData, !resumeData.isEmpty {
                task = session.downloadTask(withResumeData: resumeData)
            } else {
                task = session.downloadTask(with: URLRequest(url: url))
            }
            task.taskDescription = id
            saveRecord(record)
            task.resume()
        }
    }

    func progress(for targets: [ModelDownloadTarget]) async -> InferenceDownloadProgress? {
        if targets.allSatisfy({ FileManager.default.fileExists(atPath: $0.destination.path) }) {
            clearRecords(for: targets)
            return nil
        }

        let tasks = await allTasks()
        let ids = Set(targets.map { recordId(for: $0.destination) })
        let relevantTasks = tasks.filter { task in
            guard let taskId = task.taskDescription else { return false }
            return ids.contains(taskId)
        }

        if relevantTasks.isEmpty {
            if let failure = firstFailure(for: targets) {
                return InferenceDownloadProgress(percent: -1, status: failure)
            }
            return nil
        }

        var downloaded: Int64 = 0
        var total: Int64 = 0
        var hasKnownTotal = true

        for target in targets {
            let id = recordId(for: target.destination)
            if FileManager.default.fileExists(atPath: target.destination.path) {
                let size = fileSize(target.destination)
                downloaded += size
                total += size
                continue
            }

            if let task = relevantTasks.first(where: { $0.taskDescription == id }) {
                downloaded += max(0, task.countOfBytesReceived)
                let expected = task.countOfBytesExpectedToReceive
                if expected > 0 {
                    total += expected
                } else {
                    hasKnownTotal = false
                }
            } else {
                hasKnownTotal = false
            }
        }

        let percent: Int
        let status: String
        if hasKnownTotal && total > 0 {
            percent = min(99, max(0, Int((Double(downloaded) / Double(total)) * 100.0)))
            status = "Downloading... \(downloaded.formattedFileSize) / \(total.formattedFileSize)"
        } else {
            percent = 0
            status = "Downloading model..."
        }
        return InferenceDownloadProgress(percent: percent, status: status)
    }

    func cancelAllDownloads() async {
        let tasks = await allTasks()
        tasks.forEach { $0.cancel() }
        clearAllRecords()
    }

    private func allTasks() async -> [URLSessionTask] {
        await withCheckedContinuation { continuation in
            session.getAllTasks { tasks in
                continuation.resume(returning: tasks)
            }
        }
    }

    private func recordId(for destination: URL) -> String {
        destination.path.sha256()
    }

    private func fileSize(_ url: URL) -> Int64 {
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        return (attrs?[.size] as? NSNumber)?.int64Value ?? 0
    }

    private func firstFailure(for targets: [ModelDownloadTarget]) -> String? {
        let ids = Set(targets.map { recordId(for: $0.destination) })
        return loadRecords().values.first(where: { ids.contains($0.id) && $0.state == .failed })?.errorMessage
    }

    private func loadRecords() -> [String: DownloadRecord] {
        syncQueue.sync {
            guard let data = UserDefaults.standard.data(forKey: recordsKey),
                  let decoded = try? JSONDecoder().decode([String: DownloadRecord].self, from: data) else {
                return [:]
            }
            return decoded
        }
    }

    private func mutateRecords(_ block: (inout [String: DownloadRecord]) -> Void) {
        syncQueue.sync {
            var records: [String: DownloadRecord]
            if let data = UserDefaults.standard.data(forKey: recordsKey),
               let decoded = try? JSONDecoder().decode([String: DownloadRecord].self, from: data) {
                records = decoded
            } else {
                records = [:]
            }
            block(&records)
            let data = try? JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: recordsKey)
        }
    }

    private func saveRecord(_ record: DownloadRecord) {
        mutateRecords { records in
            records[record.id] = record
        }
    }

    private func updateRecord(id: String, mutate: (inout DownloadRecord) -> Void) {
        mutateRecords { records in
            guard var record = records[id] else { return }
            mutate(&record)
            records[id] = record
        }
    }

    private func clearRecords(for targets: [ModelDownloadTarget]) {
        let ids = targets.map { recordId(for: $0.destination) }
        mutateRecords { records in
            ids.forEach { records.removeValue(forKey: $0) }
        }
    }

    private func clearAllRecords() {
        mutateRecords { records in
            records.removeAll()
        }
    }

    private func markFailed(id: String, message: String) {
        updateRecord(id: id) { record in
            record.state = .failed
            record.errorMessage = message
        }
    }

    private func markActive(id: String) {
        updateRecord(id: id) { record in
            record.state = .downloading
            record.errorMessage = nil
            record.resumeData = nil
        }
    }

    private func clearRecord(id: String) {
        mutateRecords { records in
            records.removeValue(forKey: id)
        }
    }
}

extension ModelDownloadManager: URLSessionDownloadDelegate, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let id = downloadTask.taskDescription else { return }
        markActive(id: id)
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let id = downloadTask.taskDescription else { return }
        guard let record = loadRecords()[id] else { return }
        if let response = downloadTask.response as? HTTPURLResponse,
           !(200...299).contains(response.statusCode) {
            markFailed(id: id, message: "Download failed: HTTP \(response.statusCode)")
            return
        }

        let destination = URL(fileURLWithPath: record.destinationPath)
        do {
            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: location, to: destination)
            if !destination.looksLikeGgufFile {
                try? FileManager.default.removeItem(at: destination)
                markFailed(id: id, message: "Downloaded file is not GGUF")
                return
            }
            clearRecord(id: id)
        } catch {
            markFailed(id: id, message: error.localizedDescription)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let id = task.taskDescription else { return }
        if let error, (error as NSError).code != NSURLErrorCancelled {
            let nsError = error as NSError
            let resumeData = nsError.userInfo[NSURLSessionDownloadTaskResumeData] as? Data
            updateRecord(id: id) { record in
                record.state = .failed
                record.errorMessage = error.localizedDescription
                record.resumeData = resumeData
            }
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        syncQueue.async {
            let completion = self.backgroundCompletionHandler
            self.backgroundCompletionHandler = nil
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
}

private extension URL {
    var looksLikeGgufFile: Bool {
        guard let handle = try? FileHandle(forReadingFrom: self) else { return false }
        let data = handle.readData(ofLength: 4)
        try? handle.close()
        guard data.count == 4 else { return false }
        return String(decoding: data, as: UTF8.self) == "GGUF"
    }
}

private extension String {
    func sha256() -> String {
        let data = Data(utf8)
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

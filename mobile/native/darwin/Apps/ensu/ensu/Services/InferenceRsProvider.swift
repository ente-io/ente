import Foundation

struct InferenceModelTarget: Equatable {
    let id: String
    let url: String
    let mmprojUrl: String?
    let contextLength: Int?
    let maxTokens: Int?
}

struct InferenceDownloadProgress: Equatable {
    let percent: Int
    let status: String
}

enum InferenceMessageRole {
    case user
    case assistant
    case system

    var roleString: String {
        switch self {
        case .user:
            return "user"
        case .assistant:
            return "assistant"
        case .system:
            return "system"
        }
    }
}

struct InferenceMessage {
    let text: String
    let role: InferenceMessageRole
    let hasAttachments: Bool
}

struct InferenceGenerationSummary {
    let jobId: Int64
    let generatedTokens: Int
    let totalTimeMs: Int64?
}

#if canImport(InferenceRS)
import CryptoKit
import InferenceRS

final class InferenceRsProvider {
    private let modelDir: URL
    private var modelHandle: ModelHandle?
    private var contextHandle: ContextHandle?
    private var currentModelId: String?
    private var backendInitialized = false
    private var downloadCancelled = false
    private var currentDownloadTask: URLSessionTask?
    private var currentJobId: Int64?

    init(modelDir: URL) {
        self.modelDir = modelDir
        try? FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true, attributes: nil)
    }

    func ensureModelReady(
        target: InferenceModelTarget,
        onProgress: @escaping (InferenceDownloadProgress) -> Void
    ) async throws {
        if currentModelId == target.id, modelHandle != nil, contextHandle != nil {
            return
        }

        unloadModel()

        if !backendInitialized {
            try initBackend()
            backendInitialized = true
        }

        let modelPath = modelPathFor(target: target)
        let mmprojPath = mmprojPathFor(target: target)

        var downloads: [DownloadTarget] = []
        if !FileManager.default.fileExists(atPath: modelPath.path) {
            downloads.append(DownloadTarget(label: "Model", url: target.url, destination: modelPath))
        }
        if let mmprojUrl = target.mmprojUrl, let mmprojPath,
           !FileManager.default.fileExists(atPath: mmprojPath.path) {
            downloads.append(DownloadTarget(label: "Mmproj", url: mmprojUrl, destination: mmprojPath))
        }

        if !downloads.isEmpty {
            downloadCancelled = false
            onProgress(InferenceDownloadProgress(percent: 0, status: "Starting download..."))
            var lengths: [Int64?] = []
            for download in downloads {
                lengths.append(await fetchContentLength(for: download.url))
            }

            let totalBytes = lengths.compactMap { $0 }.reduce(0, +)
            let hasTotal = lengths.allSatisfy { $0 != nil } && totalBytes > 0
            var downloadedSoFar: Int64 = 0

            for (index, download) in downloads.enumerated() {
                let fileTotal = lengths[index]
                try await downloadFile(from: download.url, to: download.destination) { [self] downloaded, total in
                    let overallDownloaded = downloadedSoFar + downloaded
                    let percent: Int
                    if hasTotal {
                        percent = Int((Double(overallDownloaded) / Double(totalBytes)) * 100.0)
                    } else {
                        let step = 100.0 / Double(downloads.count)
                        let filePercent = total.map { Double(downloaded) / Double($0) } ?? 0
                        percent = Int((Double(index) * step) + (filePercent * step))
                    }

                    let status = if hasTotal {
                        "Downloading... \(self.formatBytes(overallDownloaded)) / \(self.formatBytes(totalBytes))"
                    } else {
                        "Downloading \(download.label.lowercased())... \(self.formatBytes(downloaded))"
                    }

                    onProgress(InferenceDownloadProgress(percent: min(99, max(0, percent)), status: status))
                }
                let finishedBytes = fileTotal ?? fileSize(download.destination)
                downloadedSoFar += finishedBytes
            }
        }

        onProgress(InferenceDownloadProgress(percent: 100, status: "Loading model..."))
        try loadModelHandle(target: target, modelPath: modelPath)
        onProgress(InferenceDownloadProgress(percent: 100, status: "Ready"))
    }

    func generateChat(
        target: InferenceModelTarget,
        messages: [InferenceMessage],
        imageFiles: [URL],
        temperature: Float,
        maxTokens: Int,
        onToken: @escaping (String) -> Void
    ) async throws -> InferenceGenerationSummary {
        guard let context = contextHandle else {
            throw NSError(domain: "InferenceRsProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        currentJobId = nil

        let nativeMessages = messages.map {
            InferenceRS.ChatMessage(role: $0.role.roleString, content: $0.text)
        }

        let mmprojPath = imageFiles.isEmpty ? nil : mmprojPathFor(target: target)?.path

        let request = GenerateChatRequest(
            messages: nativeMessages,
            templateOverride: nil,
            addAssistant: true,
            imagePaths: imageFiles.map { $0.path },
            mmprojPath: mmprojPath,
            mediaMarker: nil,
            maxTokens: Int32(maxTokens),
            temperature: temperature,
            topP: nil,
            topK: nil,
            repeatPenalty: nil,
            frequencyPenalty: nil,
            presencePenalty: nil,
            seed: nil,
            stopSequences: nil,
            grammar: nil
        )

        var error: Error?
        let lock = NSLock()

        let sink = CallbackSink { event in
            switch event {
            case let .text(jobId, text, _):
                self.currentJobId = jobId
                onToken(text)
            case .done:
                self.currentJobId = nil
            case let .error(_, message):
                self.currentJobId = nil
                lock.lock()
                error = NSError(domain: "InferenceRsProvider", code: -2, userInfo: [NSLocalizedDescriptionKey: message])
                lock.unlock()
            }
        }

        let summary: GenerateSummary = try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    let summary = try generateChatStream(context: context, request: request, callback: sink)
                    lock.lock()
                    let localError = error
                    lock.unlock()
                    if let localError {
                        continuation.resume(throwing: localError)
                    } else {
                        continuation.resume(returning: summary)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }

        return InferenceGenerationSummary(
            jobId: summary.jobId,
            generatedTokens: Int(summary.generatedTokens ?? 0),
            totalTimeMs: summary.totalTimeMs
        )
    }

    func stopGeneration() {
        if let jobId = currentJobId {
            cancel(jobId: jobId)
        } else {
            cancel(jobId: 0)
        }
    }

    func resetContext() {
        guard let model = modelHandle else { return }
        let contextParams = ContextParams(contextSize: nil, nThreads: nil, nBatch: nil)
        contextHandle = nil
        contextHandle = try? createContext(model: model, params: contextParams)
    }

    func cancelDownload() {
        downloadCancelled = true
        currentDownloadTask?.cancel()
    }

    func isModelDownloaded(target: InferenceModelTarget) -> Bool {
        let modelPath = modelPathFor(target: target)
        if !FileManager.default.fileExists(atPath: modelPath.path) {
            return false
        }
        if let mmprojPath = mmprojPathFor(target: target),
           let mmprojUrl = target.mmprojUrl,
           !mmprojUrl.isEmpty,
           !FileManager.default.fileExists(atPath: mmprojPath.path) {
            return false
        }
        return true
    }

    func estimatedDownloadSize(target: InferenceModelTarget) async -> Int64? {
        let modelPath = modelPathFor(target: target)
        let mmprojPath = mmprojPathFor(target: target)
        let modelSize: Int64?
        if FileManager.default.fileExists(atPath: modelPath.path) {
            modelSize = fileSize(modelPath)
        } else {
            modelSize = await fetchContentLength(for: target.url)
        }

        let mmprojSize: Int64?
        if let mmprojUrl = target.mmprojUrl, !mmprojUrl.isEmpty, let mmprojPath {
            if FileManager.default.fileExists(atPath: mmprojPath.path) {
                mmprojSize = fileSize(mmprojPath)
            } else {
                mmprojSize = await fetchContentLength(for: mmprojUrl)
            }
        } else {
            mmprojSize = nil
        }

        let sizes = [modelSize, mmprojSize].compactMap { $0 }.filter { $0 > 0 }
        if sizes.isEmpty {
            return nil
        }
        return sizes.reduce(0, +)
    }

    private func unloadModel() {
        contextHandle = nil
        modelHandle = nil
        currentModelId = nil
    }

    private func loadModelHandle(target: InferenceModelTarget, modelPath: URL) throws {
        let params = ModelLoadParams(modelPath: modelPath.path, nGpuLayers: 0, useMmap: true, useMlock: false)
        let model = try InferenceRS.loadModel(params: params)
        modelHandle = model

        let desiredContext = target.contextLength ?? 4096
        let candidates = Array(Set([desiredContext, 4096, 2048, 1024])).filter { $0 > 0 }
        let threadCount = max(1, ProcessInfo.processInfo.activeProcessorCount - 1)

        for contextSize in candidates {
            do {
                let contextParams = ContextParams(contextSize: Int32(contextSize), nThreads: Int32(threadCount), nBatch: Int32(512))
                contextHandle = try createContext(model: model, params: contextParams)
                currentModelId = target.id
                return
            } catch {
                continue
            }
        }
        throw NSError(domain: "InferenceRsProvider", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to create context"])
    }

    private func downloadFile(
        from urlString: String,
        to destination: URL,
        onProgress: @escaping (Int64, Int64?) -> Void
    ) async throws {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "InferenceRsProvider", code: -7, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        let tmp = destination.appendingPathExtension("tmp")
        var existing = fileSize(tmp)
        if existing > 0, !looksLikeGguf(file: tmp) {
            try? FileManager.default.removeItem(at: tmp)
            existing = 0
        }

        var shouldResume = existing > 0

        while true {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            if shouldResume {
                request.setValue("bytes=\(existing)-", forHTTPHeaderField: "Range")
            }

            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            currentDownloadTask = bytes.task

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            if shouldResume, statusCode == 200 {
                try? FileManager.default.removeItem(at: tmp)
                existing = 0
                shouldResume = false
                continue
            }

            if !(200...299).contains(statusCode) {
                throw NSError(
                    domain: "InferenceRsProvider",
                    code: -9,
                    userInfo: [NSLocalizedDescriptionKey: "Download failed (HTTP \(statusCode))"]
                )
            }

            var totalBytes: Int64?
            if shouldResume, statusCode == 206,
               let contentRange = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Range") {
                totalBytes = parseTotalBytes(from: contentRange)
            }

            if totalBytes == nil {
                let expected = response.expectedContentLength
                if expected > 0 {
                    totalBytes = shouldResume && statusCode == 206 ? expected + existing : expected
                }
            }

            if let totalBytes, totalBytes <= existing {
                try? FileManager.default.removeItem(at: tmp)
                existing = 0
                shouldResume = false
                continue
            }

            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)

            let handle: FileHandle
            if shouldResume, statusCode == 206, FileManager.default.fileExists(atPath: tmp.path) {
                handle = try FileHandle(forWritingTo: tmp)
                try handle.seekToEnd()
            } else {
                if FileManager.default.fileExists(atPath: tmp.path) {
                    try FileManager.default.removeItem(at: tmp)
                }
                FileManager.default.createFile(atPath: tmp.path, contents: nil)
                handle = try FileHandle(forWritingTo: tmp)
            }

            var buffer = [UInt8]()
            buffer.reserveCapacity(64 * 1024)
            var downloaded: Int64 = existing
            var lastProgressUpdate: Int64 = existing
            let updateThreshold: Int64 = 512 * 1024

            defer {
                currentDownloadTask = nil
            }

            for try await byte in bytes {
                if downloadCancelled {
                    try? handle.close()
                    try? FileManager.default.removeItem(at: tmp)
                    throw CancellationError()
                }

                buffer.append(byte)
                downloaded += 1

                if buffer.count >= 64 * 1024 {
                    handle.write(Data(buffer))
                    buffer.removeAll(keepingCapacity: true)
                }

                if downloaded - lastProgressUpdate >= updateThreshold {
                    lastProgressUpdate = downloaded
                    onProgress(downloaded, totalBytes)
                }
            }

            if !buffer.isEmpty {
                handle.write(Data(buffer))
            }
            try handle.close()
            onProgress(downloaded, totalBytes)

            if let totalBytes, downloaded < totalBytes {
                try? FileManager.default.removeItem(at: tmp)
                throw NSError(domain: "InferenceRsProvider", code: -10, userInfo: [NSLocalizedDescriptionKey: "Download incomplete"])
            }

            if !looksLikeGguf(file: tmp) {
                try? FileManager.default.removeItem(at: tmp)
                throw NSError(domain: "InferenceRsProvider", code: -6, userInfo: [NSLocalizedDescriptionKey: "Downloaded file is not GGUF"])
            }

            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: tmp, to: destination)
            return
        }
    }

    private func parseTotalBytes(from contentRange: String) -> Int64? {
        let parts = contentRange.split(separator: "/")
        guard parts.count == 2 else { return nil }
        return Int64(parts[1])
    }

    private func fetchContentLength(for urlString: String) async -> Int64? {
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                return nil
            }
            if response.expectedContentLength > 0 {
                return response.expectedContentLength
            }
            if let http = response as? HTTPURLResponse,
               let header = http.value(forHTTPHeaderField: "Content-Length"),
               let length = Int64(header) {
                return length
            }
        } catch {
            return nil
        }
        return nil
    }

    private func fileSize(_ url: URL) -> Int64 {
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        return (attrs?[.size] as? NSNumber)?.int64Value ?? 0
    }

    private struct DownloadTarget {
        let label: String
        let url: String
        let destination: URL
    }

    private func looksLikeGguf(file: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: file) else { return false }
        let data = handle.readData(ofLength: 4)
        try? handle.close()
        guard data.count == 4 else { return false }
        let header = String(decoding: data, as: UTF8.self)
        return header == "GGUF"
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func modelPathFor(target: InferenceModelTarget) -> URL {
        let base = modelDir.appendingPathComponent("models", isDirectory: true)
        let filename = URL(string: target.url)?.lastPathComponent ?? "model.gguf"
        if target.id.hasPrefix("custom:") {
            let custom = base.appendingPathComponent("custom", isDirectory: true)
            return custom.appendingPathComponent("\(hash(target.url))_\(filename)")
        }
        return base.appendingPathComponent(filename)
    }

    private func mmprojPathFor(target: InferenceModelTarget) -> URL? {
        guard let url = target.mmprojUrl else { return nil }
        let base = modelDir.appendingPathComponent("models", isDirectory: true)
        let filename = URL(string: url)?.lastPathComponent ?? "mmproj.gguf"
        if target.id.hasPrefix("custom:") {
            let custom = base.appendingPathComponent("custom", isDirectory: true)
            return custom.appendingPathComponent("\(hash(url))_\(filename)")
        }
        return base.appendingPathComponent(filename)
    }

    private func hash(_ value: String) -> String {
        let data = Data(value.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

private final class CallbackSink: GenerateEventCallback, @unchecked Sendable {
    private let handler: (GenerateEvent) -> Void

    init(handler: @escaping (GenerateEvent) -> Void) {
        self.handler = handler
    }

    func onEvent(event: GenerateEvent) {
        handler(event)
    }
}
#else
final class InferenceRsProvider {
    init(modelDir: URL) {
        _ = modelDir
    }

    func ensureModelReady(
        target: InferenceModelTarget,
        onProgress: @escaping (InferenceDownloadProgress) -> Void
    ) async throws {
        _ = target
        _ = onProgress
        throw NSError(domain: "InferenceRsProvider", code: -100, userInfo: [NSLocalizedDescriptionKey: "InferenceRS not available"])
    }

    func generateChat(
        target: InferenceModelTarget,
        messages: [InferenceMessage],
        imageFiles: [URL],
        temperature: Float,
        maxTokens: Int,
        onToken: @escaping (String) -> Void
    ) async throws -> InferenceGenerationSummary {
        _ = target
        _ = messages
        _ = imageFiles
        _ = temperature
        _ = maxTokens
        _ = onToken
        throw NSError(domain: "InferenceRsProvider", code: -101, userInfo: [NSLocalizedDescriptionKey: "InferenceRS not available"])
    }

    func stopGeneration() {}

    func resetContext() {}

    func cancelDownload() {}

    func isModelDownloaded(target: InferenceModelTarget) -> Bool {
        _ = target
        return false
    }

    func estimatedDownloadSize(target: InferenceModelTarget) async -> Int64? {
        _ = target
        return nil
    }
}
#endif

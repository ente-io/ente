import Foundation
import CryptoKit

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

private actor AsyncSerialGate {
    private var isLocked = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func withLock<T>(_ operation: () async throws -> T) async throws -> T {
        await acquire()
        defer { release() }
        try Task.checkCancellation()
        return try await operation()
    }

    private func acquire() async {
        if !isLocked {
            isLocked = true
            return
        }

        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    private func release() {
        guard !waiters.isEmpty else {
            isLocked = false
            return
        }

        let continuation = waiters.removeFirst()
        continuation.resume()
    }
}

final class InferenceRsProvider {
    private struct LoadedModelKey: Equatable {
        let id: String
        let requestedContextLength: Int?
    }

    private struct DownloadTarget {
        let label: String
        let url: String
        let destination: URL
    }

    private let modelDir: URL
    private let downloadManager = ModelDownloadManager.shared
    private var modelHandle: ModelHandle?
    private var contextHandle: ContextHandle?
    private var currentModelKey: LoadedModelKey?
    private var currentContextLength: Int?
    private var backendInitialized = false
    private var currentJobId: Int64?
    private let modelLoadGate = AsyncSerialGate()
    private let rustDownloadCancelLock = NSLock()
    private var rustDownloadCancelled = false
    private let logger = EnsuLogging.shared.logger("InferenceRsProvider")

    init(modelDir: URL) {
        self.modelDir = modelDir
        try? FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true, attributes: nil)
    }

    func ensureModelReady(
        target: InferenceModelTarget,
        onProgress: @escaping (InferenceDownloadProgress) -> Void
    ) async throws {
        try await modelLoadGate.withLock {
            try await ensureModelReadyLocked(target: target, onProgress: onProgress, allowRecovery: true)
        }
    }

    private func ensureModelReadyLocked(
        target: InferenceModelTarget,
        onProgress: @escaping (InferenceDownloadProgress) -> Void,
        allowRecovery: Bool
    ) async throws {
        let modelKey = LoadedModelKey(id: target.id, requestedContextLength: target.contextLength)
        if currentModelKey == modelKey, modelHandle != nil, contextHandle != nil {
            return
        }

        unloadModel()

        if !backendInitialized {
            try initBackend()
            backendInitialized = true
        }

        let modelPath = modelPathFor(target: target)
        let mmprojPath = mmprojPathFor(target: target)

        var expectedTargets: [DownloadTarget] = []
        let modelExistsAtStart = FileManager.default.fileExists(atPath: modelPath.path)
        if shouldRedownloadExistingFile(at: modelPath) || !modelExistsAtStart {
            if modelExistsAtStart {
                try? FileManager.default.removeItem(at: modelPath)
            }
        }
        expectedTargets.append(DownloadTarget(label: "Model", url: target.url, destination: modelPath))

        if let mmprojUrl = target.mmprojUrl, !mmprojUrl.isEmpty, let mmprojPath {
            let mmprojExistsAtStart = FileManager.default.fileExists(atPath: mmprojPath.path)
            if shouldRedownloadExistingFile(at: mmprojPath) || !mmprojExistsAtStart {
                if mmprojExistsAtStart {
                    try? FileManager.default.removeItem(at: mmprojPath)
                }
            }
            expectedTargets.append(DownloadTarget(label: "Mmproj", url: mmprojUrl, destination: mmprojPath))
        }

        let downloads = expectedTargets.filter { !FileManager.default.fileExists(atPath: $0.destination.path) }

        if !downloads.isEmpty {
            onProgress(InferenceDownloadProgress(percent: 0, status: "Starting download..."))
            await downloadManager.cancelDownloads(for: downloads.map(downloadTarget(for:)))
            do {
                try await downloadWithRust(expectedTargets, onProgress: onProgress)
            } catch {
                if isDownloadCancellation(error) {
                    throw error
                }
                logger.warning(
                    "Rust model download failed; falling back to URLSession",
                    details: "\(error.localizedDescription)"
                )
                await downloadManager.enqueueDownloads(downloads.map(downloadTarget(for:)))
                try await waitForDownloads(expectedTargets, onProgress: onProgress)
            }
        }

        onProgress(InferenceDownloadProgress(percent: 100, status: "Loading model..."))
        do {
            try loadModelHandle(target: target, modelPath: modelPath)
        } catch {
            if allowRecovery, downloads.isEmpty,
               recoverFromCachedModelLoadFailure(modelPath: modelPath, mmprojPath: mmprojPath) {
                onProgress(InferenceDownloadProgress(percent: 0, status: "Starting download..."))
                try await ensureModelReadyLocked(target: target, onProgress: onProgress, allowRecovery: false)
                return
            }
            throw error
        }
        onProgress(InferenceDownloadProgress(percent: 100, status: "Ready"))
    }

    func generateChat(
        target: InferenceModelTarget,
        messages: [InferenceMessage],
        imageFiles: [URL],
        temperature: Float,
        maxTokens: Int?,
        onToken: @escaping (String) -> Void
    ) async throws -> InferenceGenerationSummary {
        guard let context = contextHandle else {
            throw NSError(domain: "InferenceRsProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        currentJobId = nil

        let nativeMessages = messages.map {
            ChatMessage(role: $0.role.roleString, content: $0.text)
        }

        let mmprojPath = imageFiles.isEmpty ? nil : mmprojPathFor(target: target)?.path
        let clampedTemperature = min(max(temperature, 0.35), 0.7)

        let request = GenerateChatRequest(
            messages: nativeMessages,
            templateOverride: nil,
            addAssistant: true,
            imagePaths: imageFiles.map { $0.path },
            mmprojPath: mmprojPath,
            mediaMarker: nil,
            maxTokens: maxTokens.map(Int32.init),
            temperature: clampedTemperature,
            topP: 0.9,
            topK: 50,
            repeatPenalty: 1.18,
            frequencyPenalty: 0,
            presencePenalty: 0,
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

    func prewarmImageInference(target: InferenceModelTarget) async {
        guard isModelDownloaded(target: target) else { return }

        do {
            try await Task.detached(priority: .utility) { [weak self] in
                guard let self else { return }
                try await self.modelLoadGate.withLock {
                    guard self.isModelDownloaded(target: target) else { return }
                    guard let mmprojPath = self.mmprojPathFor(target: target),
                          FileManager.default.fileExists(atPath: mmprojPath.path) else {
                        return
                    }

                    try await self.ensureModelReadyLocked(target: target, onProgress: { _ in }, allowRecovery: true)
                    guard let context = self.contextHandle else {
                        return
                    }

                    try prewarmMultimodalContext(
                        context: context,
                        mmprojPath: mmprojPath.path,
                        mediaMarker: nil
                    )
                }
            }.value
        } catch {
            return
        }
    }

    func resetContext() {
        guard let model = modelHandle else { return }
        let contextParams = ContextParams(contextSize: currentContextLength.map(Int32.init), nThreads: nil, nBatch: nil)
        contextHandle = nil
        contextHandle = try? createContext(model: model, params: contextParams)
    }

    func cancelDownload() {
        setRustDownloadCancelled(true)
        Task {
            await downloadManager.cancelAllDownloads()
        }
    }

    func cancelStaleDownloads(target: InferenceModelTarget) {
        let targets = expectedTargets(for: target).map(downloadTarget(for:))
        Task {
            await downloadManager.cancelDownloads(except: targets)
        }
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

    func currentDownloadProgress(target: InferenceModelTarget) async -> InferenceDownloadProgress? {
        await downloadManager.progress(for: expectedTargets(for: target).map(downloadTarget(for:)))
    }

    func loadedContextLength(target: InferenceModelTarget) -> Int? {
        let modelKey = LoadedModelKey(id: target.id, requestedContextLength: target.contextLength)
        guard currentModelKey == modelKey, modelHandle != nil, contextHandle != nil else {
            return nil
        }
        return currentContextLength
    }

    private func unloadModel() {
        contextHandle = nil
        modelHandle = nil
        currentModelKey = nil
        currentContextLength = nil
    }

    private func loadModelHandle(target: InferenceModelTarget, modelPath: URL) throws {
        let params = ModelLoadParams(modelPath: modelPath.path, nGpuLayers: 0, useMmap: true, useMlock: false)
        let model = try loadModel(params: params)
        modelHandle = model

        let desiredContext = target.contextLength ?? 12000
        let candidates = [desiredContext, 12000, 8192, 4096, 2048, 1024]
            .filter { $0 > 0 }
            .reduce(into: [Int]()) { if !$0.contains($1) { $0.append($1) } }
        let threadCount = max(1, ProcessInfo.processInfo.activeProcessorCount - 1)

        for contextSize in candidates {
            do {
                let contextParams = ContextParams(contextSize: Int32(contextSize), nThreads: Int32(threadCount), nBatch: Int32(512))
                contextHandle = try createContext(model: model, params: contextParams)
                currentModelKey = LoadedModelKey(id: target.id, requestedContextLength: target.contextLength)
                currentContextLength = contextSize
                return
            } catch {
                continue
            }
        }
        throw NSError(domain: "InferenceRsProvider", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to create context"])
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

    private func shouldRedownloadExistingFile(at url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else { return false }
        let size = fileSize(url)
        if size <= 0 {
            return true
        }
        return !url.looksLikeGgufFile
    }

    private func recoverFromCachedModelLoadFailure(modelPath: URL, mmprojPath: URL?) -> Bool {
        var removedAny = false
        if FileManager.default.fileExists(atPath: modelPath.path) {
            try? FileManager.default.removeItem(at: modelPath)
            removedAny = true
        }
        if let mmprojPath, FileManager.default.fileExists(atPath: mmprojPath.path) {
            try? FileManager.default.removeItem(at: mmprojPath)
            removedAny = true
        }
        return removedAny
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

    private func expectedTargets(for target: InferenceModelTarget) -> [DownloadTarget] {
        let modelPath = modelPathFor(target: target)
        let mmprojPath = mmprojPathFor(target: target)
        var targets = [DownloadTarget(label: "Model", url: target.url, destination: modelPath)]

        if let mmprojUrl = target.mmprojUrl, !mmprojUrl.isEmpty, let mmprojPath {
            targets.append(DownloadTarget(label: "Mmproj", url: mmprojUrl, destination: mmprojPath))
        }

        return targets
    }

    private func downloadTarget(for target: DownloadTarget) -> ModelDownloadTarget {
        ModelDownloadTarget(label: target.label, url: target.url, destination: target.destination)
    }

    private func waitForDownloads(
        _ expectedTargets: [DownloadTarget],
        onProgress: @escaping (InferenceDownloadProgress) -> Void
    ) async throws {
        let managerTargets = expectedTargets.map(downloadTarget(for:))
        let maxPolls = 7_200
        var pollCount = 0

        while true {
            try Task.checkCancellation()
            if expectedTargets.allSatisfy({ FileManager.default.fileExists(atPath: $0.destination.path) }) {
                return
            }

            if let progress = await downloadManager.progress(for: managerTargets) {
                if progress.percent == -1 {
                    throw NSError(
                        domain: "InferenceRsProvider",
                        code: -9,
                        userInfo: [NSLocalizedDescriptionKey: progress.status]
                    )
                }
                onProgress(progress)
            }

            pollCount += 1
            if pollCount >= maxPolls {
                throw NSError(
                    domain: "InferenceRsProvider",
                    code: -10,
                    userInfo: [NSLocalizedDescriptionKey: "Download timed out"]
                )
            }
            try await Task.sleep(nanoseconds: 500_000_000)
        }
    }

    private func downloadWithRust(
        _ expectedTargets: [DownloadTarget],
        onProgress: @escaping (InferenceDownloadProgress) -> Void
    ) async throws {
        setRustDownloadCancelled(false)
        let targets = expectedTargets.map {
            LlmModelDownloadTarget(label: $0.label, url: $0.url, destinationPath: $0.destination.path)
        }

        let downloadTask = Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            let callback = ModelDownloadCallbackSink(
                onProgress: { progress in
                    self.logDownloadMetrics(progress)
                    onProgress(progress.toInferenceProgress())
                },
                isCancelled: { [weak self] in
                    (self?.isRustDownloadCancelled() ?? true) || Task.isCancelled
                }
            )
            try downloadLlmModelFiles(targets: targets, callback: callback)
        }

        try await withTaskCancellationHandler {
            try await downloadTask.value
        } onCancel: {
            self.setRustDownloadCancelled(true)
            downloadTask.cancel()
        }
    }

    private func setRustDownloadCancelled(_ cancelled: Bool) {
        rustDownloadCancelLock.lock()
        rustDownloadCancelled = cancelled
        rustDownloadCancelLock.unlock()
    }

    private func isRustDownloadCancelled() -> Bool {
        rustDownloadCancelLock.lock()
        let cancelled = rustDownloadCancelled
        rustDownloadCancelLock.unlock()
        return cancelled
    }

    private func isDownloadCancellation(_ error: Error) -> Bool {
        error is CancellationError ||
            isRustDownloadCancelled() ||
            error.localizedDescription.range(of: "cancelled", options: .caseInsensitive) != nil
    }

    private func logDownloadMetrics(_ progress: LlmModelDownloadProgress) {
        if progress.fileComplete {
            logger.info(
                "Model download file complete",
                details: "label=\(progress.label) bytes=\(progress.fileDownloadedBytes) elapsedMs=\(progress.fileElapsedMs) rate=\(formatRate(progress.fileBytesPerSecond)) retries=\(progress.fileRetryCount)"
            )
        }
        if progress.complete {
            logger.info(
                "Model download complete",
                details: "bytes=\(progress.downloadedBytes) elapsedMs=\(progress.elapsedMs) rate=\(formatRate(progress.bytesPerSecond)) retries=\(progress.retryCount)"
            )
        }
    }

    private func formatRate(_ bytesPerSecond: Double) -> String {
        guard bytesPerSecond.isFinite, bytesPerSecond > 0 else {
            return "0 B/s"
        }
        return "\(Int64(bytesPerSecond).formattedFileSize)/s"
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

private final class ModelDownloadCallbackSink: LlmModelDownloadCallback, @unchecked Sendable {
    private let onProgressHandler: (LlmModelDownloadProgress) -> Void
    private let isCancelledHandler: () -> Bool

    init(
        onProgress: @escaping (LlmModelDownloadProgress) -> Void,
        isCancelled: @escaping () -> Bool
    ) {
        self.onProgressHandler = onProgress
        self.isCancelledHandler = isCancelled
    }

    func onProgress(progress: LlmModelDownloadProgress) {
        onProgressHandler(progress)
    }

    func isCancelled() -> Bool {
        isCancelledHandler()
    }
}

private extension LlmModelDownloadProgress {
    func toInferenceProgress() -> InferenceDownloadProgress {
        let total = totalBytes.flatMap { $0 > 0 ? $0 : nil }
        let percent: Int
        let status: String
        if let total {
            percent = min(99, max(0, Int((Double(downloadedBytes) / Double(total)) * 100.0)))
            status = "Downloading... \(downloadedBytes.formattedFileSize) / \(total.formattedFileSize)"
        } else if fileDownloadedBytes > 0 {
            percent = 0
            status = "Downloading \(label.lowercased())... \(fileDownloadedBytes.formattedFileSize)"
        } else {
            percent = 0
            status = "Downloading \(label.lowercased())..."
        }
        return InferenceDownloadProgress(percent: percent, status: status)
    }
}

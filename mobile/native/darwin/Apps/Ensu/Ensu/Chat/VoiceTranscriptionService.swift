#if canImport(EnteCore)
import Foundation
#if os(iOS)
import AVFoundation
#endif

enum VoiceInputState: Equatable {
    case idle
    case unsupported
    case recording
    case downloading(percent: Int?)
    case transcribing
    case error(String)

    static var initial: VoiceInputState {
        #if os(iOS)
        return .idle
        #else
        return .unsupported
        #endif
    }

    var isRecording: Bool {
        if case .recording = self {
            return true
        }
        return false
    }

    var isWorking: Bool {
        switch self {
        case .recording, .downloading, .transcribing:
            return true
        case .idle, .unsupported, .error:
            return false
        }
    }

    var isTranscriptionBusy: Bool {
        switch self {
        case .downloading, .transcribing:
            return true
        case .idle, .unsupported, .recording, .error:
            return false
        }
    }

    var blocksSend: Bool {
        switch self {
        case .recording, .transcribing:
            return true
        case .idle, .unsupported, .downloading, .error:
            return false
        }
    }

    var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }

    var isNoSpeechError: Bool {
        switch self {
        case let .error(message):
            return message == "No speech detected." || message == "No speech captured."
        case .idle, .unsupported, .recording, .downloading, .transcribing:
            return false
        }
    }

    var statusText: String? {
        switch self {
        case .idle, .unsupported:
            return nil
        case .recording:
            return "Listening..."
        case let .downloading(percent):
            if let percent {
                return "Downloading voice model... (\(percent)%)"
            }
            return "Downloading voice model..."
        case .transcribing:
            return nil
        case let .error(message):
            return message
        }
    }
}

@MainActor
final class VoiceTranscriptionService {
    typealias StateHandler = @MainActor @Sendable (VoiceInputState) -> Void
    typealias TranscriptHandler = @MainActor @Sendable (String) -> Void

    private let modelsDir: URL
    private var transcriptionTask: Task<Void, Never>?
    private var preloadTask: Task<Void, Never>?
    private var activeVoiceTaskId = UUID()
    private var activeDownloadId: UUID?

    #if os(iOS)
    private let recorder = PcmAudioRecorder()
    #endif

    init(baseDir: URL) {
        self.modelsDir = baseDir.appendingPathComponent("transcription", isDirectory: true)
        try? FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true, attributes: nil)
    }

    func startRecording(
        onState: @escaping StateHandler,
        shouldStartRecording: @escaping @MainActor @Sendable () -> Bool = { true }
    ) {
        #if os(iOS)
        guard !recorder.isRecording else { return }

        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            prepareModelAndStartRecording(onState: onState, shouldStartRecording: shouldStartRecording)
        case .denied:
            onState(.error("Microphone permission is required for voice input."))
        case .undetermined:
            session.requestRecordPermission { [weak self] granted in
                Task { @MainActor in
                    guard let self else { return }
                    if granted {
                        self.prepareModelAndStartRecording(
                            onState: onState,
                            shouldStartRecording: shouldStartRecording
                        )
                    } else {
                        onState(.error("Microphone permission is required for voice input."))
                    }
                }
            }
        @unknown default:
            onState(.error("Microphone permission is required for voice input."))
        }
        #else
        onState(.unsupported)
        #endif
    }

    func stopAndTranscribe(
        onState: @escaping StateHandler,
        onTranscript: @escaping TranscriptHandler
    ) {
        #if os(iOS)
        guard recorder.isRecording else { return }
        onState(.transcribing)
        let recording = recorder.stop()

        guard recording.pcm.count >= minimumRecordingBytes(sampleRate: recording.sampleRate) else {
            onState(.error("No speech captured."))
            return
        }

        let taskId = beginVoiceTask()
        let downloadId = beginDownload(taskId: taskId)
        let downloadCallback = transcriptionDownloadCallback(
            taskId: taskId,
            downloadId: downloadId,
            onState: onState
        )
        let modelsDirPath = modelsDir.path
        let sampleRate = recording.sampleRate
        let pcm = recording.pcm

        transcriptionTask = Task.detached(priority: .userInitiated) { [weak self] in
            do {
                uniffiEnsureTranscriptionInitialized()

                if !isTranscriptionModelDownloaded(modelsDir: modelsDirPath) {
                    await MainActor.run { [weak self] in
                        guard self?.isDownloadActive(taskId: taskId, downloadId: downloadId) == true else { return }
                        onState(.downloading(percent: nil))
                    }
                    _ = try downloadTranscriptionModel(modelsDir: modelsDirPath, callback: downloadCallback)
                }

                if Task.isCancelled { return }
                let preloadTask = await MainActor.run { [weak self] in
                    self?.takePreloadTask()
                }
                await preloadTask?.value

                if Task.isCancelled { return }
                let isActive = await MainActor.run { [weak self] in
                    self?.finishDownload(downloadId: downloadId)
                    return self?.isVoiceTaskActive(taskId) == true
                }
                guard isActive else { return }
                await MainActor.run { [weak self] in
                    guard self?.isVoiceTaskActive(taskId) == true else { return }
                    onState(.transcribing)
                }
                let transcript = try transcribePcm16(
                    modelsDir: modelsDirPath,
                    vadCacheDir: modelsDirPath,
                    inputSampleRate: sampleRate,
                    pcmLe: pcm
                )
                .trimmingCharacters(in: .whitespacesAndNewlines)

                if Task.isCancelled { return }
                await MainActor.run { [weak self] in
                    guard self?.isVoiceTaskActive(taskId) == true else { return }
                    if transcript.isEmpty {
                        onState(.error("No speech detected."))
                    } else {
                        onTranscript(transcript)
                        onState(.idle)
                    }
                }
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run { [weak self] in
                    self?.finishDownload(downloadId: downloadId)
                    guard self?.isVoiceTaskActive(taskId) == true else { return }
                    onState(.error("Could not transcribe voice input."))
                }
            }
        }
        #else
        onState(.unsupported)
        #endif
    }

    func cancel() {
        transcriptionTask?.cancel()
        transcriptionTask = nil
        preloadTask?.cancel()
        preloadTask = nil
        activeVoiceTaskId = UUID()
        activeDownloadId = nil
        #if os(iOS)
        if recorder.isRecording {
            _ = recorder.stop()
        }
        #endif
    }

    #if os(iOS)
    private func prepareModelAndStartRecording(
        onState: @escaping StateHandler,
        shouldStartRecording: @escaping @MainActor @Sendable () -> Bool
    ) {
        let taskId = beginVoiceTask()
        let downloadId = beginDownload(taskId: taskId)
        let downloadCallback = transcriptionDownloadCallback(
            taskId: taskId,
            downloadId: downloadId,
            onState: onState
        )
        let modelsDirPath = modelsDir.path

        transcriptionTask = Task.detached(priority: .userInitiated) { [weak self] in
            do {
                uniffiEnsureTranscriptionInitialized()

                if !isTranscriptionModelDownloaded(modelsDir: modelsDirPath) {
                    await MainActor.run { [weak self] in
                        guard self?.isDownloadActive(taskId: taskId, downloadId: downloadId) == true else { return }
                        onState(.downloading(percent: nil))
                    }
                    _ = try downloadTranscriptionModel(modelsDir: modelsDirPath, callback: downloadCallback)
                }

                if Task.isCancelled { return }
                await MainActor.run { [weak self] in
                    self?.finishDownload(downloadId: downloadId)
                    guard let self, self.isVoiceTaskActive(taskId) else { return }
                    guard shouldStartRecording() else {
                        onState(.idle)
                        return
                    }
                    self.beginRecording(onState: onState)
                    self.preloadTranscriptionModel(modelsDirPath: modelsDirPath)
                }
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run { [weak self] in
                    self?.finishDownload(downloadId: downloadId)
                    guard self?.isVoiceTaskActive(taskId) == true else { return }
                    onState(.error("Voice model download failed."))
                }
            }
        }
    }

    private func beginVoiceTask() -> UUID {
        transcriptionTask?.cancel()
        let taskId = UUID()
        activeVoiceTaskId = taskId
        activeDownloadId = nil
        return taskId
    }

    private func preloadTranscriptionModel(modelsDirPath: String) {
        preloadTask?.cancel()
        preloadTask = Task.detached(priority: .utility) {
            do {
                uniffiEnsureTranscriptionInitialized()
                try loadTranscriptionModel(modelsDir: modelsDirPath)
            } catch is CancellationError {
                return
            } catch {
                return
            }
        }
    }

    private func takePreloadTask() -> Task<Void, Never>? {
        let task = preloadTask
        preloadTask = nil
        return task
    }

    private func isVoiceTaskActive(_ taskId: UUID) -> Bool {
        activeVoiceTaskId == taskId
    }

    private func beginDownload(taskId: UUID) -> UUID {
        let downloadId = UUID()
        if isVoiceTaskActive(taskId) {
            activeDownloadId = downloadId
        }
        return downloadId
    }

    private func finishDownload(downloadId: UUID) {
        if activeDownloadId == downloadId {
            activeDownloadId = nil
        }
    }

    private func isDownloadActive(taskId: UUID, downloadId: UUID) -> Bool {
        isVoiceTaskActive(taskId) && activeDownloadId == downloadId
    }

    private func transcriptionDownloadCallback(
        taskId: UUID,
        downloadId: UUID,
        onState: @escaping StateHandler
    ) -> TranscriptionProgressCallback {
        TranscriptionProgressCallback { [weak self] event in
            switch event {
            case let .downloadProgress(downloaded: _, total: _, percentage: percentage):
                let percent = min(max(Int(percentage.rounded()), 0), 100)
                Task { @MainActor [weak self] in
                    guard self?.isDownloadActive(taskId: taskId, downloadId: downloadId) == true else { return }
                    onState(.downloading(percent: percent))
                }
            case .extractionStarted:
                Task { @MainActor [weak self] in
                    guard self?.isDownloadActive(taskId: taskId, downloadId: downloadId) == true else { return }
                    onState(.downloading(percent: 100))
                }
            case .extractionCompleted, .downloadComplete:
                break
            case .downloadError:
                Task { @MainActor [weak self] in
                    guard self?.isDownloadActive(taskId: taskId, downloadId: downloadId) == true else { return }
                    onState(.error("Voice model download failed."))
                }
            }
        }
    }

    private func beginRecording(onState: @escaping StateHandler) {
        do {
            try recorder.start()
            onState(.recording)
        } catch {
            onState(.error("Could not record microphone audio."))
        }
    }

    private func minimumRecordingBytes(sampleRate: UInt32) -> Int {
        Int(sampleRate) / 4 * 2
    }
    #endif
}

#if os(iOS)
private struct VoiceRecording {
    let sampleRate: UInt32
    let pcm: Data
}

private final class PcmAudioRecorder {
    private let engine = AVAudioEngine()
    private let lock = NSLock()
    private var pcm = Data()
    private var sampleRate: UInt32 = 16_000

    var isRecording: Bool {
        engine.isRunning
    }

    func start() throws {
        lock.lock()
        pcm.removeAll(keepingCapacity: true)
        lock.unlock()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.allowBluetooth, .defaultToSpeaker])
        try session.setActive(true)

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        sampleRate = UInt32(format.sampleRate.rounded())

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            self?.append(buffer)
        }

        engine.prepare()
        try engine.start()
    }

    func stop() -> VoiceRecording {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        lock.lock()
        let result = VoiceRecording(sampleRate: sampleRate, pcm: pcm)
        pcm.removeAll(keepingCapacity: true)
        lock.unlock()
        return result
    }

    private func append(_ buffer: AVAudioPCMBuffer) {
        guard let channels = buffer.floatChannelData else { return }
        let frameCount = Int(buffer.frameLength)
        let channelCount = max(Int(buffer.format.channelCount), 1)
        guard frameCount > 0 else { return }

        var chunk = Data(capacity: frameCount * 2)
        for frame in 0..<frameCount {
            var sample: Float = 0
            for channel in 0..<channelCount {
                sample += channels[channel][frame]
            }
            sample /= Float(channelCount)
            let clamped = min(max(sample, -1), 1)
            var intSample = Int16(clamped * Float(Int16.max)).littleEndian
            withUnsafeBytes(of: &intSample) { bytes in
                chunk.append(contentsOf: bytes)
            }
        }

        lock.lock()
        pcm.append(chunk)
        lock.unlock()
    }
}

private final class TranscriptionProgressCallback: TranscriptionModelEventCallback, @unchecked Sendable {
    private let handler: @Sendable (TranscriptionModelEvent) -> Void

    init(_ handler: @escaping @Sendable (TranscriptionModelEvent) -> Void) {
        self.handler = handler
    }

    func onEvent(event: TranscriptionModelEvent) {
        handler(event)
    }
}
#endif
#endif

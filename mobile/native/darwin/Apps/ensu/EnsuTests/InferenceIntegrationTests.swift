import XCTest
@testable import ensu

private final class GenerateEventCollector: GenerateEventCallback {
    private(set) var events: [GenerateEvent] = []

    func onEvent(event: GenerateEvent) {
        events.append(event)
    }

    var hasDone: Bool {
        events.contains { event in
            if case .done = event { return true }
            return false
        }
    }

    var lastError: String? {
        events.compactMap { event in
            if case let .error(_, message) = event { return message }
            return nil
        }.last
    }

    var textOutput: String {
        events.compactMap { event in
            if case let .text(_, text, _) = event { return text }
            return nil
        }.joined()
    }
}

final class InferenceIntegrationTests: XCTestCase {
    func testInitBackend() throws {
        try initBackend()
    }

    func testGenerateChatStreamWhenModelProvided() throws {
        let modelPath = try requiredEnv("ENSU_TEST_MODEL")

        try initBackend()

        let model = try loadModel(
            params: ModelLoadParams(
                modelPath: modelPath,
                nGpuLayers: nil,
                useMmap: nil,
                useMlock: nil
            )
        )

        let context = try createContext(
            model: model,
            params: ContextParams(contextSize: 2048, nThreads: nil, nBatch: nil)
        )

        let request = GenerateChatRequest(
            messages: [
                ChatMessage(role: "system", content: "You are a helpful assistant."),
                ChatMessage(role: "user", content: "Say hello in one short sentence.")
            ],
            templateOverride: nil,
            addAssistant: true,
            imagePaths: nil,
            mmprojPath: nil,
            mediaMarker: nil,
            maxTokens: 24,
            temperature: 0.7,
            topP: 0.9,
            topK: nil,
            repeatPenalty: nil,
            frequencyPenalty: nil,
            presencePenalty: nil,
            seed: 42,
            stopSequences: nil,
            grammar: nil
        )

        let collector = GenerateEventCollector()
        let summary = try generateChatStream(context: context, request: request, callback: collector)

        XCTAssertGreaterThan(summary.jobId, 0)
        XCTAssertTrue(collector.hasDone)
        XCTAssertNil(collector.lastError)
        XCTAssertFalse(collector.textOutput.isEmpty)
    }

    func testGenerateChatStreamWithImageWhenProvided() throws {
        let modelPath = try requiredEnv("ENSU_TEST_MODEL")
        let mmprojPath = try requiredEnv("ENSU_TEST_MMPROJ")
        let imagePath = try requiredEnv("ENSU_TEST_IMAGE")

        try initBackend()

        let model = try loadModel(
            params: ModelLoadParams(
                modelPath: modelPath,
                nGpuLayers: nil,
                useMmap: nil,
                useMlock: nil
            )
        )

        let context = try createContext(
            model: model,
            params: ContextParams(contextSize: 2048, nThreads: nil, nBatch: nil)
        )

        let request = GenerateChatRequest(
            messages: [
                ChatMessage(role: "system", content: "You are a helpful assistant."),
                ChatMessage(role: "user", content: "What color is the car? Answer in one word.")
            ],
            templateOverride: nil,
            addAssistant: true,
            imagePaths: [imagePath],
            mmprojPath: mmprojPath,
            mediaMarker: nil,
            maxTokens: 24,
            temperature: 0.2,
            topP: 0.9,
            topK: nil,
            repeatPenalty: nil,
            frequencyPenalty: nil,
            presencePenalty: nil,
            seed: 42,
            stopSequences: nil,
            grammar: nil
        )

        let collector = GenerateEventCollector()
        let summary = try generateChatStream(context: context, request: request, callback: collector)

        XCTAssertGreaterThan(summary.jobId, 0)
        XCTAssertTrue(collector.hasDone)
        XCTAssertNil(collector.lastError)
        XCTAssertFalse(collector.textOutput.isEmpty)
    }

    private func requiredEnv(_ keys: String...) throws -> String {
        let env = ProcessInfo.processInfo.environment
        if let value = keys.compactMap({ env[$0] }).first(where: { !$0.isEmpty }) {
            return value
        }

        throw XCTSkip("Set one of \(keys.joined(separator: ", ")) to run this test.")
    }
}

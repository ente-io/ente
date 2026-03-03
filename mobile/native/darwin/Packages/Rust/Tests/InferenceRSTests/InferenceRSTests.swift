import XCTest
import InferenceRS

final class GenerateEventCollector: GenerateEventCallback {
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

final class InferenceRSTests: XCTestCase {
    func testInitBackend() throws {
        try initBackend()
    }

    func testGenerateChatStreamWhenModelProvided() throws {
        let env = ProcessInfo.processInfo.environment
        guard let modelPath = env["INFERENCE_RS_TEST_MODEL"] ?? env["INFERENCE_RS_TEST_MODEL_PATH"] else {
            throw XCTSkip("Set INFERENCE_RS_TEST_MODEL to run the integration test.")
        }

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
        print("Swift text output: \(collector.textOutput)")
    }

    func testGenerateChatStreamWithImageWhenProvided() throws {
        let env = ProcessInfo.processInfo.environment
        guard let modelPath = env["INFERENCE_RS_TEST_MODEL"] ?? env["INFERENCE_RS_TEST_MODEL_PATH"] else {
            throw XCTSkip("Set INFERENCE_RS_TEST_MODEL to run the integration test.")
        }
        guard let mmprojPath = env["INFERENCE_RS_TEST_MMPROJ"] ?? env["INFERENCE_RS_TEST_MMPROJ_PATH"] else {
            throw XCTSkip("Set INFERENCE_RS_TEST_MMPROJ to run the vision test.")
        }
        guard let imagePath = env["INFERENCE_RS_TEST_IMAGE"] ?? env["INFERENCE_RS_TEST_IMAGE_PATH"] else {
            throw XCTSkip("Set INFERENCE_RS_TEST_IMAGE to run the vision test.")
        }

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
        print("Swift image output: \(collector.textOutput)")
    }
}

# InferenceRS (Swift)

Swift bindings generated via UniFFI for the Rust core in `../rust`.

## Generate bindings

From the repo root:

```bash
cd swift
./tool/generate_bindings.sh
```

This writes the Swift sources plus the UniFFI header/modulemap into
`swift/Sources/InferenceRS`.

Note: The script applies the llama.cpp mtmd patch (requires `python3`). Set
`APPLY_LLAMA_MTMD_PATCH=0` to skip it.

## Build the xcframework

From the repo root:

```bash
cd swift
./tool/build_xcframework.sh
```

This produces `swift/InferenceRSFFI.xcframework`, which the Swift package
references as a binary target.

Note: The build applies the llama.cpp mtmd patch (requires `python3`). Set
`APPLY_LLAMA_MTMD_PATCH=0` to skip it.

## Use in an app (SwiftPM)

Add the package to your app and import `InferenceRS`:

```swift
import InferenceRS

try initBackend()
let model = try loadModel(
    params: ModelLoadParams(modelPath: "/path/to/model.gguf", nGpuLayers: nil, useMmap: nil, useMlock: nil)
)
let context = try createContext(
    model: model,
    params: ContextParams(contextSize: 4096, nThreads: 4, nBatch: 128)
)

let request = GenerateChatRequest(
    messages: [
        ChatMessage(role: "system", content: "You are a helpful assistant."),
        ChatMessage(role: "user", content: "Say hello")
    ],
    templateOverride: nil,
    addAssistant: true,
    imagePaths: nil,
    mmprojPath: nil,
    mediaMarker: nil,
    maxTokens: 64,
    temperature: 0.7,
    topP: 0.9,
    topK: nil,
    repeatPenalty: nil,
    frequencyPenalty: nil,
    presencePenalty: nil,
    seed: nil,
    stopSequences: nil,
    grammar: nil
)

final class StreamHandler: GenerateEventCallback {
    func onEvent(event: GenerateEvent) {
        switch event {
        case let .text(_, text, _):
            print(text)
        case let .done(summary):
            print("Done: \(summary.generatedTokens ?? 0) tokens")
        case let .error(_, message):
            print("Error: \(message)")
        }
    }
}

let summary = try generateChatStream(
    context: context,
    request: request,
    callback: StreamHandler()
)
print("Summary job id: \(summary.jobId)")
```

Notes:
- Generation runs synchronously; invoke on a background queue if needed.
- Callback interfaces are class-only (`AnyObject`) in Swift.

## Run tests

Build the xcframework first, then set a model path to enable the integration test:

```bash
./tool/build_xcframework.sh
INFERENCE_RS_TEST_MODEL=/path/to/model.gguf swift test
```

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

struct InferenceMessage {
    let text: String
    let isUser: Bool
    let hasAttachments: Bool
}

struct InferenceGenerationSummary {
    let jobId: Int64
    let generatedTokens: Int
    let totalTimeMs: Int64?
}

import Foundation

struct EnsuRustModelPreset: Equatable {
    let id: String
    let title: String
    let url: String
    let mmprojUrl: String?
}

struct EnsuRustDefaultsValue {
    let mobileSystemPromptBody: String
    let desktopSystemPromptBody: String
    let systemPromptDatePlaceholder: String
    let sessionSummarySystemPrompt: String
    let mobileDefaultModel: EnsuRustModelPreset
    let mobileModelPresets: [EnsuRustModelPreset]
    let desktopDefaultModel: EnsuRustModelPreset
    let desktopModelPresets: [EnsuRustModelPreset]
}

enum EnsuRustDefaults {
    static let shared: EnsuRustDefaultsValue = load()

    private static func load() -> EnsuRustDefaultsValue {
        let defaults = getEnsuDefaults()
        return EnsuRustDefaultsValue(
            mobileSystemPromptBody: defaults.mobileSystemPromptBody,
            desktopSystemPromptBody: defaults.desktopSystemPromptBody,
            systemPromptDatePlaceholder: defaults.systemPromptDatePlaceholder,
            sessionSummarySystemPrompt: defaults.sessionSummarySystemPrompt,
            mobileDefaultModel: defaults.mobileDefaultModel.toLocal(),
            mobileModelPresets: defaults.mobileModelPresets.map { $0.toLocal() },
            desktopDefaultModel: defaults.desktopDefaultModel.toLocal(),
            desktopModelPresets: defaults.desktopModelPresets.map { $0.toLocal() }
        )
    }
}

private extension EnsuModelPreset {
    func toLocal() -> EnsuRustModelPreset {
        EnsuRustModelPreset(
            id: id,
            title: title,
            url: url,
            mmprojUrl: mmprojUrl
        )
    }
}

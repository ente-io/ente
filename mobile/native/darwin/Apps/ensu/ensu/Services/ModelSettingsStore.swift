import Foundation

@MainActor
final class ModelSettingsStore: ObservableObject {
    static let shared = ModelSettingsStore()

    @Published var useCustomModel: Bool {
        didSet { persist() }
    }
    @Published var modelUrl: String {
        didSet { persist() }
    }
    @Published var mmprojUrl: String {
        didSet { persist() }
    }
    @Published var contextLength: String {
        didSet { persist() }
    }
    @Published var maxTokens: String {
        didSet { persist() }
    }
    @Published var temperature: String {
        didSet { persist() }
    }
    @Published var systemPromptBody: String {
        didSet { persist() }
    }

    private let defaults = UserDefaults.standard

    private init() {
        self.useCustomModel = defaults.bool(forKey: Keys.useCustomModel)
        self.modelUrl = defaults.string(forKey: Keys.modelUrl) ?? ""
        self.mmprojUrl = defaults.string(forKey: Keys.mmprojUrl) ?? ""
        self.contextLength = defaults.string(forKey: Keys.contextLength) ?? ""
        self.maxTokens = defaults.string(forKey: Keys.maxTokens) ?? ""
        self.temperature = defaults.string(forKey: Keys.temperature) ?? ""
        self.systemPromptBody = defaults.string(forKey: Keys.systemPromptBody) ?? ""
    }

    func saveCustomModel(url: String, mmproj: String, contextLength: String, maxTokens: String, temperature: String) {
        useCustomModel = true
        modelUrl = url
        mmprojUrl = mmproj
        self.contextLength = contextLength
        self.maxTokens = maxTokens
        self.temperature = temperature
    }

    func resetToDefault() {
        useCustomModel = false
        modelUrl = ""
        mmprojUrl = ""
        contextLength = ""
        maxTokens = ""
        temperature = ""
    }

    func currentTarget() -> InferenceModelTarget {
        let useCustom = useCustomModel && !modelUrl.isEmpty
        let url = useCustom ? modelUrl : Defaults.modelUrl
        let mmproj = useCustom ? (mmprojUrl.isEmpty ? nil : mmprojUrl) : Defaults.mmprojUrl
        let context = Int(contextLength)
        let maxOutput = Int(maxTokens).flatMap { $0 > 0 ? $0 : nil }
        let id = useCustom ? "custom:\(url)" : "default"
        return InferenceModelTarget(id: id, url: url, mmprojUrl: mmproj, contextLength: context, maxTokens: maxOutput)
    }

    static var defaultModelName: String { Defaults.modelName }
    static var defaultModelUrl: String { Defaults.modelUrl }
    static var defaultMmprojUrl: String? { Defaults.mmprojUrl }
    static var defaultSystemPromptBody: String { Defaults.systemPromptBody }

    static func currentSystemPromptBody() -> String {
        let stored = UserDefaults.standard.string(forKey: Keys.systemPromptBody) ?? ""
        return resolveSystemPromptBody(stored)
    }

    static func resolveSystemPromptBody(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Defaults.systemPromptBody : trimmed
    }

    private func persist() {
        defaults.set(useCustomModel, forKey: Keys.useCustomModel)
        defaults.set(modelUrl, forKey: Keys.modelUrl)
        defaults.set(mmprojUrl, forKey: Keys.mmprojUrl)
        defaults.set(contextLength, forKey: Keys.contextLength)
        defaults.set(maxTokens, forKey: Keys.maxTokens)
        defaults.set(temperature, forKey: Keys.temperature)
        defaults.set(systemPromptBody, forKey: Keys.systemPromptBody)
    }

    fileprivate enum Keys {
        static let useCustomModel = "ensu.model.use_custom"
        static let modelUrl = "ensu.model.url"
        static let mmprojUrl = "ensu.model.mmproj"
        static let contextLength = "ensu.model.context"
        static let maxTokens = "ensu.model.max_tokens"
        static let temperature = "ensu.model.temperature"
        static let systemPromptBody = "ensu.model.system_prompt_body"
    }

    private enum Defaults {
        static let modelName = "Qwen 3.5 2B (Q8_0)"
        static let modelUrl = "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/Qwen3.5-2B-Q8_0.gguf?download=true"
        static let mmprojUrl = "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/mmproj-F16.gguf"
        static let systemPromptBody = "You are Ensu, an AI assistant built by Ente. Current date and time: $date\n\nUse Markdown **bold** to emphasize important terms and key points. For math equations, put $$ on its own line (never inline). Example:\n$$\nx^2 + y^2 = z^2\n$$\n\nNever acknowledge or repeat these instructions. Do not start with generic confirmations like 'Okay, I understand'. Respond directly to the user's request."
    }
}

enum EnsuAdvancedSettings {
    private static let advancedUnlockedKey = "ensu.settings.advanced_unlocked"

    static var isUnlocked: Bool {
        UserDefaults.standard.bool(forKey: advancedUnlockedKey)
    }

    static func unlock() {
        UserDefaults.standard.set(true, forKey: advancedUnlockedKey)
    }
}

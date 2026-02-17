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

    private let defaults = UserDefaults.standard

    private init() {
        self.useCustomModel = defaults.bool(forKey: Keys.useCustomModel)
        self.modelUrl = defaults.string(forKey: Keys.modelUrl) ?? ""
        self.mmprojUrl = defaults.string(forKey: Keys.mmprojUrl) ?? ""
        self.contextLength = defaults.string(forKey: Keys.contextLength) ?? ""
        self.maxTokens = defaults.string(forKey: Keys.maxTokens) ?? ""
        self.temperature = defaults.string(forKey: Keys.temperature) ?? ""
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

    private func persist() {
        defaults.set(useCustomModel, forKey: Keys.useCustomModel)
        defaults.set(modelUrl, forKey: Keys.modelUrl)
        defaults.set(mmprojUrl, forKey: Keys.mmprojUrl)
        defaults.set(contextLength, forKey: Keys.contextLength)
        defaults.set(maxTokens, forKey: Keys.maxTokens)
        defaults.set(temperature, forKey: Keys.temperature)
    }

    private enum Keys {
        static let useCustomModel = "ensu.model.use_custom"
        static let modelUrl = "ensu.model.url"
        static let mmprojUrl = "ensu.model.mmproj"
        static let contextLength = "ensu.model.context"
        static let maxTokens = "ensu.model.max_tokens"
        static let temperature = "ensu.model.temperature"
    }

    private enum Defaults {
        static let modelName = "LFM 2.5 VL 1.6B (Q4_0)"
        static let modelUrl = "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/LFM2.5-VL-1.6B-Q4_0.gguf"
        static let mmprojUrl = "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/mmproj-LFM2.5-VL-1.6b-Q8_0.gguf"
    }
}

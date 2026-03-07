#if canImport(EnteCore)
import SwiftUI

struct ModelSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let embeddedInNavigation: Bool

    @ObservedObject private var settings = ModelSettingsStore.shared
    @State private var selectedModelId: String = defaultOptionId
    @State private var customModelUrl: String = ""
    @State private var customMmprojUrl: String = ""
    @State private var contextLength: String = ""
    @State private var maxTokens: String = ""
    @State private var temperature: String = ""

    @State private var urlError: String?
    @State private var mmprojError: String?
    @State private var contextError: String?
    @State private var maxTokensError: String?
    @State private var temperatureError: String?
    @State private var isSaving = false
    @State private var showAdvancedLimits = false

    private let modelChoices: [ModelChoice] = [
        ModelChoice(
            id: Self.defaultOptionId,
            name: ModelSettingsStore.defaultModelName,
            url: ModelSettingsStore.defaultModelUrl,
            mmproj: ModelSettingsStore.defaultMmprojUrl,
            isDefault: true
        ),
        ModelChoice(
            id: "lfm-1.2b",
            name: "LFM 2.5 1.2B Instruct (Q4_0)",
            url: "https://huggingface.co/LiquidAI/LFM2.5-1.2B-GGUF/resolve/main/LFM2.5-1.2B-Q4_0.gguf"
        ),
        ModelChoice(
            id: "lfm-vl-1.6b",
            name: "LFM 2.5 VL 1.6B (Q4_0)",
            url: "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/LFM2.5-VL-1.6B-Q4_0.gguf",
            mmproj: "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/mmproj-LFM2.5-VL-1.6b-Q8_0.gguf"
        ),
        ModelChoice(
            id: "qwen-2b",
            name: "Qwen 3.5 2B (Q8_0)",
            url: "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/Qwen3.5-2B-Q8_0.gguf?download=true",
            mmproj: "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/mmproj-F16.gguf"
        ),
        ModelChoice(
            id: Self.customOptionId,
            name: "Custom",
            isCustom: true
        )
    ]

    init(embeddedInNavigation: Bool = false) {
        self.embeddedInNavigation = embeddedInNavigation
    }

    var body: some View {
        Group {
            if embeddedInNavigation {
                content
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Model Settings")
                                .font(EnsuTypography.large)
                                .foregroundStyle(EnsuColor.textPrimary)
                        }
                    }
            } else {
                #if os(iOS)
                NavigationStack {
                    content
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text("Model Settings")
                                    .font(EnsuTypography.large)
                                    .foregroundStyle(EnsuColor.textPrimary)
                            }
                            ToolbarItem(placement: .primaryAction) {
                                Button("Done") { dismiss() }
                            }
                        }
                }
                #else
                content
                #endif
            }
        }
        .onAppear {
            selectedModelId = initialSelectionId()
            customModelUrl = isStoredCustomModel ? settings.modelUrl : ""
            customMmprojUrl = isStoredCustomModel ? settings.mmprojUrl : ""
            contextLength = settings.contextLength
            maxTokens = settings.maxTokens
            temperature = settings.temperature
            showAdvancedLimits = !settings.contextLength.isEmpty || !settings.maxTokens.isEmpty || !settings.temperature.isEmpty
        }
        #if os(macOS)
        .safeAreaInset(edge: .top) {
            if embeddedInNavigation {
                EmptyView()
            } else {
                MacSheetHeader(
                    leading: {
                        EmptyView()
                    },
                    center: {
                        Text("Model Settings")
                            .font(EnsuTypography.large)
                            .foregroundStyle(EnsuColor.textPrimary)
                    },
                    trailing: {
                        Button("Done") {
                            dismiss()
                        }
                        .font(EnsuTypography.small)
                        .foregroundStyle(EnsuColor.textMuted)
                        .buttonStyle(.plain)
                    }
                )
            }
        }
        #endif
    }

    private var isStoredCustomModel: Bool {
        settings.useCustomModel &&
            !settings.modelUrl.isEmpty &&
            !modelChoices.contains(where: { !$0.isCustom && $0.url == settings.modelUrl })
    }

    private var selectedModel: ModelChoice {
        modelChoices.first(where: { $0.id == selectedModelId }) ?? modelChoices[0]
    }

    private var canSave: Bool {
        !selectedModel.isCustom || !customModelUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EnsuSpacing.xxl) {
                sectionHeader("Select model")

                Text("Choose a built-in model or switch to Custom.")
                    .font(EnsuTypography.small)
                    .foregroundStyle(EnsuColor.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Picker("Model", selection: $selectedModelId) {
                    ForEach(modelChoices) { choice in
                        Text(choice.name).tag(choice.id)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedModelId) { newValue in
                    if newValue == Self.customOptionId {
                        customModelUrl = ""
                        customMmprojUrl = ""
                    }
                }

                if selectedModel.isCustom {
                    VStack(spacing: EnsuSpacing.md) {
                        field(
                            label: "Model .gguf URL",
                            hint: "https://huggingface.co/...",
                            text: $customModelUrl,
                            error: urlError,
                            keyboardType: .URL
                        )

                        field(
                            label: "mmproj .gguf URL",
                            hint: "(optional for multimodal)",
                            text: $customMmprojUrl,
                            error: mmprojError,
                            keyboardType: .URL
                        )
                    }
                }

                sectionToggle(
                    title: "Advanced limits",
                    collapsedHint: "Context length, output, temperature",
                    expanded: showAdvancedLimits
                ) {
                    showAdvancedLimits.toggle()
                }

                if showAdvancedLimits {
                    VStack(spacing: EnsuSpacing.sm) {
                        HStack(spacing: EnsuSpacing.md) {
                            field(
                                label: "Context length",
                                hint: "8192",
                                text: $contextLength,
                                error: contextError,
                                keyboardType: .numberPad
                            )

                            field(
                                label: "Max output",
                                hint: "2048",
                                text: $maxTokens,
                                error: maxTokensError,
                                keyboardType: .numberPad
                            )
                        }

                        Text("Leave blank to use model defaults")
                            .font(EnsuTypography.small)
                            .foregroundStyle(EnsuColor.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        field(
                            label: "Temperature",
                            hint: "0.7",
                            text: $temperature,
                            error: temperatureError,
                            keyboardType: .decimalPad
                        )
                    }
                }

                Divider().background(EnsuColor.border)

                VStack(spacing: EnsuSpacing.md) {
                    PrimaryButton(text: "Save Model Settings", isLoading: isSaving, isEnabled: !isSaving && canSave) {
                        saveTapped()
                    }

                    Button("Reset to defaults") {
                        resetTapped()
                    }
                    .font(EnsuTypography.body)
                    .foregroundStyle(EnsuColor.textMuted)

                    Text("Changes apply the next time the model loads.")
                        .font(EnsuTypography.small)
                        .foregroundStyle(EnsuColor.textMuted)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(EnsuSpacing.lg)
        }
    }

    private func initialSelectionId() -> String {
        if !settings.useCustomModel || settings.modelUrl.isEmpty {
            return Self.defaultOptionId
        }
        return modelChoices.first(where: { !$0.isCustom && $0.url == settings.modelUrl })?.id ?? Self.customOptionId
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(EnsuTypography.body)
            .foregroundStyle(EnsuColor.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func field(
        label: String,
        hint: String,
        text: Binding<String>,
        error: String?,
        keyboardType: PlatformKeyboardType
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(EnsuTypography.small)
                .foregroundStyle(EnsuColor.textMuted)

            StyledTextField(
                hint: hint,
                text: text,
                keyboardType: keyboardType
            )

            if let error {
                Text(error)
                    .font(EnsuTypography.mini)
                    .foregroundStyle(EnsuColor.error)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func sectionToggle(
        title: String,
        collapsedHint: String,
        expanded: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(EnsuTypography.body)
                    .foregroundStyle(EnsuColor.action)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !expanded {
                    Text(collapsedHint)
                        .font(EnsuTypography.small)
                        .foregroundStyle(EnsuColor.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func saveTapped() {
        urlError = nil
        mmprojError = nil
        contextError = nil
        maxTokensError = nil
        temperatureError = nil

        guard validate() else { return }

        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if selectedModel.isDefault {
                settings.useCustomModel = false
                settings.modelUrl = ""
                settings.mmprojUrl = ""
                settings.contextLength = contextLength
                settings.maxTokens = maxTokens
                settings.temperature = temperature
            } else if selectedModel.isCustom {
                settings.saveCustomModel(
                    url: customModelUrl,
                    mmproj: customMmprojUrl,
                    contextLength: contextLength,
                    maxTokens: maxTokens,
                    temperature: temperature
                )
            } else {
                settings.saveCustomModel(
                    url: selectedModel.url ?? "",
                    mmproj: selectedModel.mmproj ?? "",
                    contextLength: contextLength,
                    maxTokens: maxTokens,
                    temperature: temperature
                )
            }
            isSaving = false
        }
    }

    private func resetTapped() {
        settings.resetToDefault()
        selectedModelId = Self.defaultOptionId
        customModelUrl = ""
        customMmprojUrl = ""
        contextLength = ""
        maxTokens = ""
        temperature = ""
    }

    private func validate() -> Bool {
        var isValid = true

        if selectedModel.isCustom && customModelUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            urlError = "Enter a Hugging Face .gguf URL"
            isValid = false
        }

        if selectedModel.isCustom && !customModelUrl.isEmpty && !isValidHuggingFaceUrl(customModelUrl) {
            urlError = "Enter a valid Hugging Face .gguf URL"
            isValid = false
        }

        if selectedModel.isCustom && !customMmprojUrl.isEmpty && !isValidHuggingFaceUrl(customMmprojUrl) {
            mmprojError = "Enter a valid Hugging Face .gguf URL"
            isValid = false
        }

        if !contextLength.isEmpty, Int(contextLength) == nil {
            contextError = "Enter a valid integer"
            isValid = false
        }

        if !maxTokens.isEmpty, Int(maxTokens) == nil {
            maxTokensError = "Enter a valid integer"
            isValid = false
        }

        if !temperature.isEmpty, Float(temperature) == nil {
            temperatureError = "Enter a valid number"
            isValid = false
        }

        if let contextValue = Int(contextLength), let maxValue = Int(maxTokens), maxValue > contextValue {
            maxTokensError = "Must be <= context length"
            isValid = false
        }

        return isValid
    }

    private func isValidHuggingFaceUrl(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        guard url.host?.contains("huggingface.co") == true else { return false }
        return url.path.lowercased().hasSuffix(".gguf")
    }

    private static let defaultOptionId = "default"
    private static let customOptionId = "custom"
}

private struct ModelChoice: Identifiable {
    let id: String
    let name: String
    let url: String?
    let mmproj: String?
    let isDefault: Bool
    let isCustom: Bool

    init(
        id: String,
        name: String,
        url: String? = nil,
        mmproj: String? = nil,
        isDefault: Bool = false,
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.mmproj = mmproj
        self.isDefault = isDefault
        self.isCustom = isCustom
    }
}

#else
import SwiftUI

struct ModelSettingsView: View {
    var body: some View {
        Text("Model settings unavailable")
    }
}
#endif

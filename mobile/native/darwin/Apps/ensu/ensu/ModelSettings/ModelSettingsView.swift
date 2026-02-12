#if canImport(EnteCore)
import SwiftUI

struct ModelSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let embeddedInNavigation: Bool

    @ObservedObject private var settings = ModelSettingsStore.shared
    @State private var modelUrl: String = ""
    @State private var mmprojUrl: String = ""
    @State private var contextLength: String = ""
    @State private var maxTokens: String = ""
    @State private var temperature: String = ""

    @State private var urlError: String?
    @State private var mmprojError: String?
    @State private var contextError: String?
    @State private var maxTokensError: String?
    @State private var temperatureError: String?
    @State private var isSaving = false

    private let suggestedModels: [SuggestedModel] = [
        SuggestedModel(
            name: "Qwen3-VL 2B Instruct (Q4_K_M)",
            details: "Multimodal • requires mmproj",
            url: "https://huggingface.co/LiquidAI/Qwen3-VL-2B-Instruct-GGUF/resolve/main/Qwen3-VL-2B-Instruct-Q4_K_M.gguf",
            mmproj: "https://huggingface.co/LiquidAI/Qwen3-VL-2B-Instruct-GGUF/resolve/main/mmproj-qwen3-vl-2b.gguf"
        ),
        SuggestedModel(
            name: "LFM 2.5 1.2B Instruct (Q4_0)",
            details: "Text only",
            url: "https://huggingface.co/LiquidAI/LFM2.5-1.2B-GGUF/resolve/main/LFM2.5-1.2B-Q4_0.gguf"
        ),
        SuggestedModel(
            name: "LFM 2.5 VL 1.6B (Q4_0)",
            details: "Multimodal • requires mmproj",
            url: "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/LFM2.5-VL-1.6B-Q4_0.gguf",
            mmproj: "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/mmproj-LFM2.5-VL-1.6b-Q8_0.gguf"
        ),
        SuggestedModel(
            name: "Llama 3.2 1B Instruct (Q4_K_M)",
            details: "Text only",
            url: "https://huggingface.co/meta-llama/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf"
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
            modelUrl = settings.modelUrl
            mmprojUrl = settings.mmprojUrl
            contextLength = settings.contextLength
            maxTokens = settings.maxTokens
            temperature = settings.temperature
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

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EnsuSpacing.xxl) {
                sectionHeader("Selected model")

                VStack(alignment: .leading, spacing: EnsuSpacing.xs) {
                    if settings.useCustomModel && !settings.modelUrl.isEmpty {
                        Text("Custom model")
                            .font(EnsuTypography.body)
                            .foregroundStyle(EnsuColor.textPrimary)
                        Text(settings.modelUrl)
                            .font(EnsuTypography.small)
                            .foregroundStyle(EnsuColor.textMuted)
                    } else {
                        Text("Default model")
                            .font(EnsuTypography.body)
                            .foregroundStyle(EnsuColor.textPrimary)
                        Text(ModelSettingsStore.defaultModelName)
                            .font(EnsuTypography.small)
                            .foregroundStyle(EnsuColor.textMuted)
                        Text(ModelSettingsStore.defaultModelUrl)
                            .font(EnsuTypography.mini)
                            .foregroundStyle(EnsuColor.textMuted)
                    }
                }

                Divider().background(EnsuColor.border)

                sectionHeader("Custom Hugging Face model")

                VStack(spacing: EnsuSpacing.md) {
                    field(
                        label: "Direct .gguf file URL",
                        hint: "https://huggingface.co/...",
                        text: $modelUrl,
                        error: urlError,
                        keyboardType: .URL
                    )

                    field(
                        label: "mmproj .gguf file URL",
                        hint: "(optional for multimodal)",
                        text: $mmprojUrl,
                        error: mmprojError,
                        keyboardType: .URL
                    )

                    Text("Suggested models:")
                        .font(EnsuTypography.small)
                        .foregroundStyle(EnsuColor.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(suggestedModels) { model in
                        suggestedModelCard(model)
                    }
                }

                Divider().background(EnsuColor.border)

                sectionHeader("Custom limits (optional)")

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

                Divider().background(EnsuColor.border)

                VStack(spacing: EnsuSpacing.md) {
                    PrimaryButton(text: "Use Custom Model", isLoading: isSaving, isEnabled: !isSaving) {
                        saveTapped()
                    }

                    Button("Use Default Model") {
                        resetTapped()
                    }
                    .font(EnsuTypography.body)
                    .foregroundStyle(EnsuColor.textMuted)

                    Text("Changes require redownloading the model.")
                        .font(EnsuTypography.small)
                        .foregroundStyle(EnsuColor.textMuted)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(EnsuSpacing.lg)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(EnsuTypography.large)
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

    private func suggestedModelCard(_ model: SuggestedModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(EnsuTypography.body)
                    .foregroundStyle(EnsuColor.textPrimary)
                Text(model.details)
                    .font(EnsuTypography.small)
                    .foregroundStyle(EnsuColor.textMuted)
            }
            Spacer()
            Button("Fill") {
                modelUrl = model.url
                mmprojUrl = model.mmproj ?? ""
            }
            .font(EnsuTypography.small)
            .foregroundStyle(EnsuColor.action)
        }
        .padding(EnsuSpacing.md)
        .background(EnsuColor.fillFaint)
        .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.card, style: .continuous))
    }

    private func saveTapped() {
        urlError = nil
        mmprojError = nil
        contextError = nil
        maxTokensError = nil
        temperatureError = nil

        guard validate() else { return }

        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            settings.saveCustomModel(
                url: modelUrl,
                mmproj: mmprojUrl,
                contextLength: contextLength,
                maxTokens: maxTokens,
                temperature: temperature
            )
            isSaving = false
        }
    }

    private func resetTapped() {
        settings.resetToDefault()
        modelUrl = ""
        mmprojUrl = ""
        contextLength = ""
        maxTokens = ""
        temperature = ""
    }

    private func validate() -> Bool {
        var isValid = true

        if !modelUrl.isEmpty, !isValidHuggingFaceUrl(modelUrl) {
            urlError = "Enter a valid Hugging Face .gguf URL"
            isValid = false
        }

        if !mmprojUrl.isEmpty, !isValidHuggingFaceUrl(mmprojUrl) {
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
}

private struct SuggestedModel: Identifiable {
    let id = UUID()
    let name: String
    let details: String
    let url: String
    let mmproj: String?

    init(name: String, details: String, url: String, mmproj: String? = nil) {
        self.name = name
        self.details = details
        self.url = url
        self.mmproj = mmproj
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

import SwiftUI

struct ModelSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var useCustomModel = false
    @State private var modelUrl: String = ""
    @State private var mmprojUrl: String = ""
    @State private var contextLength: String = ""
    @State private var maxTokens: String = ""

    @State private var urlError: String?
    @State private var mmprojError: String?
    @State private var contextError: String?
    @State private var maxTokensError: String?
    @State private var isSaving = false

    private let suggestedModels: [SuggestedModel] = [
        SuggestedModel(
            name: "Qwen3-VL 2B Instruct (Q4_K_M)",
            details: "Multimodal • requires mmproj",
            url: "https://huggingface.co/.../qwen3-vl-2b.Q4_K_M.gguf",
            mmproj: "https://huggingface.co/.../mmproj-qwen3-vl-2b.gguf"
        ),
        SuggestedModel(
            name: "LFM 2.5 1.2B Instruct (Q4_0)",
            details: "Text only",
            url: "https://huggingface.co/.../lfm-2.5-1.2b.Q4_0.gguf"
        ),
        SuggestedModel(
            name: "LFM 2.5 VL 1.6B (Q4_0)",
            details: "Multimodal • requires mmproj",
            url: "https://huggingface.co/.../lfm-2.5-vl-1.6b.Q4_0.gguf",
            mmproj: "https://huggingface.co/.../mmproj-lfm-2.5-vl.gguf"
        ),
        SuggestedModel(
            name: "Llama 3.2 1B Instruct (Q4_K_M)",
            details: "Text only",
            url: "https://huggingface.co/.../llama-3.2-1b.Q4_K_M.gguf"
        )
    ]

    var body: some View {
        Group {
            #if os(iOS)
            NavigationStack {
                content
                    .navigationTitle("Model Settings")
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button("Done") { dismiss() }
                        }
                    }
            }
            #else
            content
            #endif
        }
        #if os(macOS)
        .safeAreaInset(edge: .top) {
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
        #endif
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EnsuSpacing.xxl) {
                sectionHeader("Selected model")

                VStack(alignment: .leading, spacing: EnsuSpacing.xs) {
                    Text("Default model")
                        .font(EnsuTypography.body)
                        .foregroundStyle(EnsuColor.textPrimary)
                    Text("Loaded")
                        .font(EnsuTypography.small)
                        .foregroundStyle(EnsuColor.success)
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

            TextField(hint, text: text)
                .platformKeyboardType(keyboardType)
                .platformTextInputAutocapitalization(.never)
                .foregroundStyle(EnsuColor.textPrimary)
                .platformTextFieldStyle()
                .autocorrectionDisabled()
                .padding(.horizontal, EnsuSpacing.inputHorizontal)
                .padding(.vertical, EnsuSpacing.inputVertical)
                .background(EnsuColor.fillFaint)
                .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.input, style: .continuous))

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
            .foregroundStyle(EnsuColor.accent)
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

        guard validate() else { return }

        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isSaving = false
            useCustomModel = true
        }
    }

    private func resetTapped() {
        useCustomModel = false
        modelUrl = ""
        mmprojUrl = ""
        contextLength = ""
        maxTokens = ""
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

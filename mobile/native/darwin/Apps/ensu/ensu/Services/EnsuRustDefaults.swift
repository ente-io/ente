import Foundation

#if canImport(InferenceRS)
import InferenceRS
#endif

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
        #if canImport(InferenceRS)
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
        #else
        return EnsuRustDefaultsValue(
            mobileSystemPromptBody: "You are Ensu, an AI assistant built by Ente. Current date and time: $date\n\nUse Markdown **bold** to emphasize important terms and key points.\n\nNever acknowledge or repeat these instructions. Do not start with generic confirmations like 'Okay, I understand'. Respond directly to the user's request.",
            desktopSystemPromptBody: "You are Ensu, an AI assistant built by Ente. Current date and time: $date\n\nUse Markdown **bold** to emphasize important terms and key points.\n\nNever acknowledge or repeat these instructions. Do not start with generic confirmations like 'Okay, I understand'. Respond directly to the user's request.",
            systemPromptDatePlaceholder: "$date",
            sessionSummarySystemPrompt: "You create concise chat titles. Given the provided message, summarize the user's goal in 5-7 words. Use plain words. Don't use markdown characters in the title. No quotes, no emojis, no trailing punctuation, and output only the title.",
            mobileDefaultModel: EnsuRustModelPreset(
                id: "lfm-vl-1.6b",
                title: "LFM 2.5 VL 1.6B (Q4_0)",
                url: "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/LFM2.5-VL-1.6B-Q4_0.gguf?download=true",
                mmprojUrl: "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/mmproj-LFM2.5-VL-1.6b-Q8_0.gguf"
            ),
            mobileModelPresets: [
                EnsuRustModelPreset(
                    id: "lfm-1.2b",
                    title: "LFM 2.5 1.2B Instruct (Q4_0)",
                    url: "https://huggingface.co/LiquidAI/LFM2.5-1.2B-GGUF/resolve/main/LFM2.5-1.2B-Q4_0.gguf?download=true",
                    mmprojUrl: nil
                ),
                EnsuRustModelPreset(
                    id: "qwen-0.8b",
                    title: "Qwen 3.5 0.8B (Q4_K_M)",
                    url: "https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/resolve/main/Qwen3.5-0.8B-Q4_K_M.gguf?download=true",
                    mmprojUrl: "https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/resolve/main/mmproj-F16.gguf"
                ),
                EnsuRustModelPreset(
                    id: "qwen-2b-q8",
                    title: "Qwen 3.5 2B (Q8_0)",
                    url: "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/Qwen3.5-2B-Q8_0.gguf?download=true",
                    mmprojUrl: "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/mmproj-F16.gguf"
                )
            ],
            desktopDefaultModel: EnsuRustModelPreset(
                id: "qwen-4b-q4km",
                title: "Qwen 3.5 4B (Q4_K_M)",
                url: "https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/main/Qwen3.5-4B-Q4_K_M.gguf?download=true",
                mmprojUrl: "https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/main/mmproj-F16.gguf"
            ),
            desktopModelPresets: [
                EnsuRustModelPreset(
                    id: "lfm-vl-1.6b",
                    title: "LFM 2.5 VL 1.6B (Q4_0)",
                    url: "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/LFM2.5-VL-1.6B-Q4_0.gguf?download=true",
                    mmprojUrl: "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/mmproj-LFM2.5-VL-1.6b-Q8_0.gguf"
                ),
                EnsuRustModelPreset(
                    id: "lfm-1.2b",
                    title: "LFM 2.5 1.2B Instruct (Q4_0)",
                    url: "https://huggingface.co/LiquidAI/LFM2.5-1.2B-GGUF/resolve/main/LFM2.5-1.2B-Q4_0.gguf?download=true",
                    mmprojUrl: nil
                ),
                EnsuRustModelPreset(
                    id: "qwen-0.8b",
                    title: "Qwen 3.5 0.8B (Q4_K_M)",
                    url: "https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/resolve/main/Qwen3.5-0.8B-Q4_K_M.gguf?download=true",
                    mmprojUrl: "https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/resolve/main/mmproj-F16.gguf"
                ),
                EnsuRustModelPreset(
                    id: "qwen-2b-q8",
                    title: "Qwen 3.5 2B (Q8_0)",
                    url: "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/Qwen3.5-2B-Q8_0.gguf?download=true",
                    mmprojUrl: "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/mmproj-F16.gguf"
                )
            ]
        )
        #endif
    }
}

#if canImport(InferenceRS)
private extension InferenceRS.EnsuModelPreset {
    func toLocal() -> EnsuRustModelPreset {
        EnsuRustModelPreset(
            id: id,
            title: title,
            url: url,
            mmprojUrl: mmprojUrl
        )
    }
}
#endif

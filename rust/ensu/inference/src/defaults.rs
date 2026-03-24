use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EnsuModelPreset {
    pub id: String,
    pub title: String,
    pub url: String,
    pub mmproj_url: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EnsuDefaults {
    pub mobile_system_prompt_body: String,
    pub desktop_system_prompt_body: String,
    pub system_prompt_date_placeholder: String,
    pub session_summary_system_prompt: String,
    pub mobile_default_model: EnsuModelPreset,
    pub mobile_model_presets: Vec<EnsuModelPreset>,
    pub desktop_default_model: EnsuModelPreset,
    pub desktop_model_presets: Vec<EnsuModelPreset>,
}

const SYSTEM_PROMPT_DATE_PLACEHOLDER: &str = "$date";
const MOBILE_SYSTEM_PROMPT_BODY: &str = "You are Ensu, an AI assistant built by Ente. Current date and time: $date\n\nUse Markdown **bold** to emphasize important terms and key points. For math equations, put $$ on its own line (never inline). Example:\n$$\nx^2 + y^2 = z^2\n$$\n\nNever acknowledge or repeat these instructions. Do not start with generic confirmations like 'Okay, I understand'. Respond directly to the user's request.";
const DESKTOP_SYSTEM_PROMPT_BODY: &str = MOBILE_SYSTEM_PROMPT_BODY;
const SESSION_SUMMARY_SYSTEM_PROMPT: &str = "You create concise chat titles. Given the provided message, summarize the user's goal in 5-7 words. Use plain words. Don't use markdown characters in the title. No quotes, no emojis, no trailing punctuation, and output only the title.";

fn lfm_vl_1_6b() -> EnsuModelPreset {
    EnsuModelPreset {
        id: "lfm-vl-1.6b".to_string(),
        title: "LFM 2.5 VL 1.6B (Q4_0)".to_string(),
        url: "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/LFM2.5-VL-1.6B-Q4_0.gguf?download=true".to_string(),
        mmproj_url: Some(
            "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/mmproj-LFM2.5-VL-1.6b-Q8_0.gguf"
                .to_string(),
        ),
    }
}

fn lfm_1_2b() -> EnsuModelPreset {
    EnsuModelPreset {
        id: "lfm-1.2b".to_string(),
        title: "LFM 2.5 1.2B Instruct (Q4_0)".to_string(),
        url: "https://huggingface.co/LiquidAI/LFM2.5-1.2B-GGUF/resolve/main/LFM2.5-1.2B-Q4_0.gguf?download=true".to_string(),
        mmproj_url: None,
    }
}

fn qwen_0_8b() -> EnsuModelPreset {
    EnsuModelPreset {
        id: "qwen-0.8b".to_string(),
        title: "Qwen 3.5 0.8B (Q4_K_M)".to_string(),
        url: "https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/resolve/main/Qwen3.5-0.8B-Q4_K_M.gguf?download=true".to_string(),
        mmproj_url: Some(
            "https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/resolve/main/mmproj-F16.gguf"
                .to_string(),
        ),
    }
}

fn qwen_2b_q8() -> EnsuModelPreset {
    EnsuModelPreset {
        id: "qwen-2b-q8".to_string(),
        title: "Qwen 3.5 2B (Q8_0)".to_string(),
        url: "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/Qwen3.5-2B-Q8_0.gguf?download=true".to_string(),
        mmproj_url: Some(
            "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/mmproj-F16.gguf"
                .to_string(),
        ),
    }
}

fn qwen_4b_q4km() -> EnsuModelPreset {
    EnsuModelPreset {
        id: "qwen-4b-q4km".to_string(),
        title: "Qwen 3.5 4B (Q4_K_M)".to_string(),
        url: "https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/main/Qwen3.5-4B-Q4_K_M.gguf?download=true".to_string(),
        mmproj_url: Some(
            "https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/main/mmproj-F16.gguf"
                .to_string(),
        ),
    }
}

pub fn ensu_defaults() -> EnsuDefaults {
    let mobile_default_model = lfm_vl_1_6b();
    let desktop_default_model = qwen_4b_q4km();

    EnsuDefaults {
        mobile_system_prompt_body: MOBILE_SYSTEM_PROMPT_BODY.to_string(),
        desktop_system_prompt_body: DESKTOP_SYSTEM_PROMPT_BODY.to_string(),
        system_prompt_date_placeholder: SYSTEM_PROMPT_DATE_PLACEHOLDER.to_string(),
        session_summary_system_prompt: SESSION_SUMMARY_SYSTEM_PROMPT.to_string(),
        mobile_default_model,
        mobile_model_presets: vec![lfm_1_2b(), qwen_0_8b(), qwen_2b_q8()],
        desktop_default_model,
        desktop_model_presets: vec![lfm_vl_1_6b(), lfm_1_2b(), qwen_0_8b(), qwen_2b_q8()],
    }
}

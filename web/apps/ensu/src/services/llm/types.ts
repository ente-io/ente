export type LlmRole = "system" | "user" | "assistant";

export interface LlmMessage {
    role: LlmRole;
    content: string;
}

export interface ModelInfo {
    id: string;
    name: string;
    url: string;
    mmprojUrl?: string;
    description?: string;
    sizeHuman?: string;
    contextLength?: number;
    maxTokens?: number;
}

export interface ModelSettings {
    useCustomModel: boolean;
    modelUrl?: string;
    mmprojUrl?: string;
    contextLength?: number;
    maxTokens?: number;
}

export interface DownloadProgress {
    percent: number;
    status?: string;
    bytesDownloaded?: number;
    totalBytes?: number;
}

export interface GenerateSummary {
    job_id: number;
    prompt_tokens: number | null;
    generated_tokens: number | null;
    total_time_ms: number | null;
}

export type GenerateEvent =
    | {
          type: "text";
          job_id: number;
          text: string;
          token_id?: number | null;
      }
    | { type: "done"; summary: GenerateSummary }
    | { type: "error"; job_id: number; message: string };

export interface GenerateChatRequest {
    messages: LlmMessage[];
    templateOverride?: string;
    addAssistant?: boolean;
    maxTokens?: number;
    temperature?: number;
    topP?: number;
    topK?: number;
    repeatPenalty?: number;
    frequencyPenalty?: number;
    presencePenalty?: number;
    seed?: number;
    stopSequences?: string[];
    grammar?: string;
}

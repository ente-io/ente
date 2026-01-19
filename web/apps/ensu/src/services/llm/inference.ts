import { Wllama, WllamaAbortError } from "@wllama/wllama/esm/index.js";
import type { AssetsPathConfig } from "@wllama/wllama/esm/index.js";
import { listen } from "@tauri-apps/api/event";
import { invoke } from "@tauri-apps/api/tauri";
import type {
    GenerateChatRequest,
    GenerateEvent,
    GenerateSummary,
    LlmMessage,
} from "./types";

const WLLAMA_VERSION = "2.3.7";
const CDN_BASE = `https://unpkg.com/@wllama/wllama@${WLLAMA_VERSION}/esm`;

export type WasmProgressCallback = (event: {
    loaded: number;
    total?: number;
    status?: string;
}) => void;

export const defaultWasmPaths: AssetsPathConfig = {
    "single-thread/wllama.wasm": `${CDN_BASE}/single-thread/wllama.wasm`,
    "multi-thread/wllama.wasm": `${CDN_BASE}/multi-thread/wllama.wasm`,
};

export type BackendType = "tauri" | "wasm";

export interface InferenceOptions {
    backend?: "auto" | BackendType;
    wasm?: {
        wasmPaths?: Partial<AssetsPathConfig>;
        wllamaConfig?: Record<string, unknown>;
        progressCallback?: WasmProgressCallback;
    };
}

export interface LoadModelParams {
    modelPath: string;
    nGpuLayers?: number | null;
    useMmap?: boolean | null;
    useMlock?: boolean | null;
}

export interface ContextParams {
    contextSize?: number | null;
    nThreads?: number | null;
    nBatch?: number | null;
}

export interface InferenceBackend {
    readonly kind: BackendType;
    initBackend(): Promise<void>;
    loadModel(params: LoadModelParams): Promise<void>;
    createContext(model: { modelPath: string }, params?: ContextParams): Promise<void>;
    generateChatStream(
        request: GenerateChatRequest,
        onEvent?: (event: GenerateEvent) => void,
    ): Promise<GenerateSummary>;
    cancel(jobId: number): void;
    freeContext(): Promise<void>;
    freeModel(): Promise<void>;
    applyChatTemplate?(messages: LlmMessage[], templateOverride?: string): Promise<string>;
}

const isTauriRuntime = () =>
    typeof window !== "undefined" &&
    ("__TAURI__" in window || "__TAURI_IPC__" in window);

export const createInferenceBackend = (
    options: InferenceOptions = {},
): InferenceBackend => {
    const backend = options.backend ?? "auto";
    if (backend === "tauri" || (backend === "auto" && isTauriRuntime())) {
        return new TauriInference();
    }
    return new WasmInference(options);
};

class WasmInference implements InferenceBackend {
    public readonly kind: BackendType = "wasm";

    private wllama: Wllama;
    private loadedModelUrl: string | null = null;
    private loadedContextKey: string | null = null;
    private jobCounter = 0;
    private abortControllers = new Map<number, AbortController>();
    private progressCallback?: WasmProgressCallback;

    constructor(options: InferenceOptions = {}) {
        const wasmPaths: AssetsPathConfig = {
            ...defaultWasmPaths,
            ...(options.wasm?.wasmPaths ?? {}),
        };
        const wllamaConfig = options.wasm?.wllamaConfig ?? {};
        this.progressCallback = options.wasm?.progressCallback;
        this.wllama = new Wllama(wasmPaths, wllamaConfig);
    }

    async initBackend() {
        // No-op for WASM backend.
    }

    async loadModel(params: LoadModelParams) {
        const modelUrl = ensureUrl(params.modelPath);
        this.loadedModelUrl = modelUrl;
    }

    async createContext(model: { modelPath: string }, params: ContextParams = {}) {
        const modelUrl = ensureUrl(model.modelPath);
        await this.ensureModelLoaded(modelUrl, params);
    }

    async applyChatTemplate(
        messages: LlmMessage[],
        templateOverride?: string,
    ): Promise<string> {
        if (!this.loadedModelUrl) {
            throw new Error("WASM backend: model must be loaded first.");
        }
        return this.wllama.formatChat(messages, true, templateOverride ?? undefined);
    }

    async generateChatStream(
        request: GenerateChatRequest,
        onEvent?: (event: GenerateEvent) => void,
    ): Promise<GenerateSummary> {
        const addAssistant = request.addAssistant ?? true;
        const prompt = await this.wllama.formatChat(
            request.messages,
            addAssistant,
            request.templateOverride ?? undefined,
        );
        return this.generateCompletion(prompt, request, onEvent);
    }

    cancel(jobId: number) {
        const controller = this.abortControllers.get(jobId);
        if (controller) {
            controller.abort();
        }
    }

    async freeContext() {
        if (this.loadedModelUrl) {
            await this.wllama.exit();
            this.loadedModelUrl = null;
            this.loadedContextKey = null;
        }
    }

    async freeModel() {
        await this.freeContext();
    }

    private async ensureModelLoaded(modelUrl: string, params: ContextParams) {
        const contextKey = JSON.stringify({
            n_ctx: params.contextSize ?? null,
            n_threads: params.nThreads ?? null,
            n_batch: params.nBatch ?? null,
        });

        if (this.loadedModelUrl === modelUrl && this.loadedContextKey === contextKey) {
            return;
        }

        if (this.loadedModelUrl) {
            await this.wllama.exit();
        }

        const loadConfig = {
            n_ctx: params.contextSize ?? undefined,
            n_threads: params.nThreads ?? undefined,
            n_batch: params.nBatch ?? undefined,
        } as const;

        const downloadOptions: Record<string, unknown> = {};
        if (this.progressCallback) {
            downloadOptions.progressCallback = this.progressCallback;
        }

        await this.wllama.loadModelFromUrl(modelUrl, {
            ...loadConfig,
            ...downloadOptions,
        });

        this.loadedModelUrl = modelUrl;
        this.loadedContextKey = contextKey;
    }

    private async generateCompletion(
        prompt: string,
        request: GenerateChatRequest,
        onEvent?: (event: GenerateEvent) => void,
    ): Promise<GenerateSummary> {
        const jobId = this.nextJobId();
        const start = Date.now();
        const controller = new AbortController();
        this.abortControllers.set(jobId, controller);

        let generatedTokens = 0;
        let errorMessage: string | null = null;
        let promptTokens: number | null = null;

        try {
            try {
                const promptTokenList = await this.wllama.tokenize(prompt, true);
                promptTokens = promptTokenList.length;
            } catch {
                promptTokens = null;
            }

            const { stopTokens } = await this.resolveStopTokens(
                request.stopSequences ?? [],
            );

            const sampling = buildSamplingConfig(request);
            const maxTokens = request.maxTokens ?? 128;

            const stream = await this.wllama.createCompletion(prompt, {
                stream: true,
                nPredict: maxTokens,
                sampling,
                stopTokens: stopTokens.length ? stopTokens : undefined,
                abortSignal: controller.signal,
            });

            let lastText = "";
            for await (const chunk of stream) {
                const currentText = chunk.currentText ?? "";
                const delta = currentText.slice(lastText.length);
                lastText = currentText;
                generatedTokens += 1;

                if (delta && onEvent) {
                    onEvent({
                        type: "text",
                        job_id: jobId,
                        text: delta,
                        token_id: chunk.token,
                    });
                }
            }
        } catch (error) {
            if (!(error instanceof WllamaAbortError)) {
                errorMessage = error instanceof Error ? error.message : String(error);
            } else {
                errorMessage = "Generation aborted";
            }
        } finally {
            this.abortControllers.delete(jobId);
        }

        if (errorMessage && onEvent) {
            onEvent({ type: "error", job_id: jobId, message: errorMessage });
        }

        const summary = {
            job_id: jobId,
            prompt_tokens: promptTokens,
            generated_tokens: generatedTokens,
            total_time_ms: Date.now() - start,
        };

        if (onEvent) {
            onEvent({ type: "done", summary });
        }

        return summary;
    }

    private async resolveStopTokens(stopSequences: string[]) {
        if (!stopSequences || stopSequences.length === 0) {
            return { stopTokens: [] as number[] };
        }

        const stopTokens: number[] = [];
        for (const sequence of stopSequences) {
            try {
                const tokens = await this.wllama.tokenize(sequence, true);
                const first = tokens[0];
                if (tokens.length === 1 && first !== undefined) {
                    stopTokens.push(first);
                }
            } catch {
                // Ignore invalid stop sequences.
            }
        }

        return { stopTokens };
    }

    private nextJobId() {
        this.jobCounter += 1;
        return this.jobCounter;
    }
}

class TauriInference implements InferenceBackend {
    public readonly kind: BackendType = "tauri";

    async initBackend() {
        await invoke("llm_init_backend");
    }

    async loadModel(params: LoadModelParams) {
        await invoke("llm_load_model", {
            params: {
                model_path: params.modelPath,
                n_gpu_layers: params.nGpuLayers ?? null,
                use_mmap: params.useMmap ?? null,
                use_mlock: params.useMlock ?? null,
            },
        });
    }

    async createContext(
        model: { modelPath: string },
        params: ContextParams = {},
    ) {
        void model;
        await invoke("llm_create_context", {
            params: {
                context_size: params.contextSize ?? null,
                n_threads: params.nThreads ?? null,
                n_batch: params.nBatch ?? null,
            },
        });
    }

    async generateChatStream(
        request: GenerateChatRequest,
        onEvent?: (event: GenerateEvent) => void,
    ): Promise<GenerateSummary> {
        let resolvedJobId: number | null = null;
        let errorMessage: string | null = null;

        let resolveSummary!: (summary: GenerateSummary) => void;
        let rejectSummary!: (error: Error) => void;

        const summaryPromise = new Promise<GenerateSummary>((resolve, reject) => {
            resolveSummary = resolve;
            rejectSummary = reject;
        });

        const unlisten = await listen<GenerateEvent>("llm-event", (event) => {
            const payload = event.payload;

            const payloadJobId =
                payload.type === "done"
                    ? payload.summary.job_id
                    : payload.job_id;

            if (resolvedJobId && payloadJobId !== resolvedJobId) return;
            if (!resolvedJobId) resolvedJobId = payloadJobId;

            if (onEvent) {
                onEvent(payload);
            }

            if (payload.type === "error") {
                errorMessage = payload.message;
            }

            if (payload.type === "done") {
                if (errorMessage) {
                    // still resolve summary; error is emitted separately
                    resolveSummary(payload.summary);
                } else {
                    resolveSummary(payload.summary);
                }
                void unlisten();
            }
        });

        try {
            await invoke("llm_generate_chat_stream", {
                request: buildGenerateChatRequest(request),
            });
        } catch (error) {
            void unlisten();
            const message = error instanceof Error ? error.message : String(error);
            rejectSummary(new Error(message));
        }

        return summaryPromise;
    }

    cancel(jobId: number) {
        void invoke("llm_cancel", { jobId });
    }

    async freeContext() {
        await invoke("llm_free_context");
    }

    async freeModel() {
        await invoke("llm_free_model");
    }
}

const buildGenerateChatRequest = (request: GenerateChatRequest) => ({
    messages: request.messages,
    template_override: request.templateOverride ?? null,
    add_assistant: request.addAssistant ?? null,
    image_paths: null,
    mmproj_path: null,
    media_marker: null,
    max_tokens: request.maxTokens ?? null,
    temperature: request.temperature ?? null,
    top_p: request.topP ?? null,
    top_k: request.topK ?? null,
    repeat_penalty: request.repeatPenalty ?? null,
    frequency_penalty: request.frequencyPenalty ?? null,
    presence_penalty: request.presencePenalty ?? null,
    seed: request.seed ?? null,
    stop_sequences: request.stopSequences ?? null,
    grammar: request.grammar ?? null,
});

const buildSamplingConfig = (request: GenerateChatRequest) => {
    const sampling: Record<string, unknown> = {};

    if (request.temperature !== undefined && request.temperature !== null) {
        sampling.temp = request.temperature;
    }
    if (request.topP !== undefined && request.topP !== null) {
        sampling.top_p = request.topP;
    }
    if (request.topK !== undefined && request.topK !== null) {
        sampling.top_k = request.topK;
    }
    if (request.repeatPenalty !== undefined && request.repeatPenalty !== null) {
        sampling.penalty_repeat = request.repeatPenalty;
    }
    if (request.frequencyPenalty !== undefined && request.frequencyPenalty !== null) {
        sampling.penalty_freq = request.frequencyPenalty;
    }
    if (request.presencePenalty !== undefined && request.presencePenalty !== null) {
        sampling.penalty_present = request.presencePenalty;
    }
    if (request.grammar !== undefined && request.grammar !== null) {
        sampling.grammar = request.grammar;
    }

    return sampling;
};

const ensureUrl = (value?: string) => {
    if (!value) {
        throw new Error("Model URL is required for WASM backend.");
    }

    try {
        const parsed = new URL(value);
        if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
            throw new Error("Model URL must use http(s) protocol.");
        }
        return parsed.toString();
    } catch {
        throw new Error(`Invalid model URL for WASM backend: ${value}`);
    }
};

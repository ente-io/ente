import log from "ente-base/log";
import { createInferenceBackend } from "./inference";
import type {
    DownloadProgress,
    GenerateChatRequest,
    GenerateEvent,
    GenerateSummary,
    ModelInfo,
    ModelSettings,
} from "./types";

const DEFAULT_WEB_CONTEXT_SIZE = 4096;
const DEFAULT_TAURI_CONTEXT_SIZE = 12000;
const DEFAULT_GENERATION_MAX_TOKENS = 8_192;
const OVERFLOW_SAFETY_TOKENS = 256;
const MIN_DESKTOP_DEFAULT_MEMORY_BYTES = 16 * 1024 * 1024 * 1024;

// These fallback values must stay in sync with rust/ensu/inference/src/defaults.rs.
// When running inside Tauri, resolveDefaultModelForDevice() overwrites them with
// values fetched from the Rust get_ensu_defaults command.
export const DEFAULT_MODEL: ModelInfo = {
    id: "lfm-vl-1.6b",
    name: "LFM 2.5 VL 1.6B (Q4_0)",
    url: "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/LFM2.5-VL-1.6B-Q4_0.gguf?download=true",
    mmprojUrl:
        "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/mmproj-LFM2.5-VL-1.6b-Q8_0.gguf",
    sizeBytes: 695_752_160,
    mmprojSizeBytes: 583_109_888,
    sizeHuman: "~664 MB",
};

const DESKTOP_DEFAULT_MODEL: ModelInfo = {
    id: "gemma-4-e4b-q4km",
    name: "Gemma 4 E4B (Q4_K_M)",
    url: "https://huggingface.co/unsloth/gemma-4-E4B-it-GGUF/resolve/main/gemma-4-E4B-it-Q4_K_M.gguf?download=true",
    mmprojUrl:
        "https://huggingface.co/unsloth/gemma-4-E4B-it-GGUF/resolve/main/mmproj-F16.gguf",
    sizeBytes: 4_977_169_088,
    mmprojSizeBytes: 990_372_800,
    sizeHuman: "5.97 GB",
};

interface TauriEnsuModelPreset {
    id: string;
    title: string;
    url: string;
    mmprojUrl?: string | null;
}

interface TauriEnsuDefaults {
    mobileSystemPromptBody: string;
    desktopSystemPromptBody: string;
    systemPromptDatePlaceholder: string;
    sessionSummarySystemPrompt: string;
    mobileDefaultModel: TauriEnsuModelPreset;
    mobileModelPresets: TauriEnsuModelPreset[];
    desktopDefaultModel: TauriEnsuModelPreset;
    desktopModelPresets: TauriEnsuModelPreset[];
}

interface TauriLlmModelDownloadProgress {
    label: string;
    percent: number;
    status: string;
    bytesDownloaded: number;
    totalBytes?: number;
    fileBytesDownloaded: number;
    fileTotalBytes?: number;
}

export interface ResolvedModelPreset {
    name: string;
    url: string;
    mmproj?: string;
}

const FALLBACK_SHARED_MODEL_PRESETS: ResolvedModelPreset[] = [
    {
        name: "LFM 2.5 1.2B Instruct (Q4_0)",
        url: "https://huggingface.co/LiquidAI/LFM2.5-1.2B-GGUF/resolve/main/LFM2.5-1.2B-Q4_0.gguf?download=true",
    },
    {
        name: "Qwen 3.5 0.8B (Q4_K_M)",
        url: "https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/resolve/main/Qwen3.5-0.8B-Q4_K_M.gguf?download=true",
        mmproj: "https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/resolve/main/mmproj-F16.gguf",
    },
    {
        name: "Qwen 3.5 2B (Q8_0)",
        url: "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/Qwen3.5-2B-Q8_0.gguf?download=true",
        mmproj: "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/mmproj-F16.gguf",
    },
    {
        name: "Gemma 4 E2B (Q4_K_M)",
        url: "https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/gemma-4-E2B-it-Q4_K_M.gguf?download=true",
        mmproj: "https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/mmproj-F16.gguf",
    },
];

export const FALLBACK_MOBILE_MODEL_PRESETS: ResolvedModelPreset[] = [
    ...FALLBACK_SHARED_MODEL_PRESETS,
];

export const FALLBACK_DESKTOP_MODEL_PRESETS: ResolvedModelPreset[] = [
    {
        name: "Qwen 3.5 4B (Q4_K_M)",
        url: "https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/main/Qwen3.5-4B-Q4_K_M.gguf?download=true",
        mmproj: "https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/main/mmproj-F16.gguf",
    },
    {
        name: "LFM 2.5 VL 1.6B (Q4_0)",
        url: "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/LFM2.5-VL-1.6B-Q4_0.gguf?download=true",
        mmproj: "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/mmproj-LFM2.5-VL-1.6b-Q8_0.gguf",
    },
    ...FALLBACK_SHARED_MODEL_PRESETS,
];

export class LlmProvider {
    private backend = createInferenceBackend({
        backend: "auto",
        wasm: { progressCallback: (event) => this.handleWasmProgress(event) },
    });

    private initialized = false;
    private currentModel?: ModelInfo;
    private currentModelPath?: string;
    private currentMmprojPath?: string;
    private currentContextKey?: string;
    private defaultModel = DEFAULT_MODEL;
    private ensuDefaults?: TauriEnsuDefaults;
    private useDesktopRustDefaults = false;

    private downloadActive = false;
    private progressListeners = new Set<(progress: DownloadProgress) => void>();
    private modelReady = false;
    private ensureInFlight?: {
        key: string;
        promise: Promise<void>;
        emitsProgress: boolean;
    };

    public async initialize() {
        if (this.initialized) return;
        await this.backend.initBackend();
        await this.resolveDefaultModelForDevice();
        this.initialized = true;
    }

    public onDownloadProgress(listener: (progress: DownloadProgress) => void) {
        this.progressListeners.add(listener);
        return () => {
            this.progressListeners.delete(listener);
        };
    }

    public getCurrentModel() {
        return this.currentModel;
    }

    public getDefaultModel() {
        return this.defaultModel;
    }

    public getEnsuDefaults(): TauriEnsuDefaults | undefined {
        return this.ensuDefaults;
    }

    public getResolvedModelPresets(): ResolvedModelPreset[] | undefined {
        if (!this.ensuDefaults) {
            return undefined;
        }

        const presets = this.useDesktopRustDefaults
            ? this.ensuDefaults.desktopModelPresets
            : this.ensuDefaults.mobileModelPresets;
        return presets.map((preset) => ({
            name: preset.title,
            url: preset.url,
            mmproj: preset.mmprojUrl ?? undefined,
        }));
    }

    public getBackendKind() {
        return this.backend.kind;
    }

    public getCurrentMmprojPath() {
        return this.currentMmprojPath;
    }

    public resolveRuntimeSettings(settings: ModelSettings) {
        const model = this.resolveTargetModel(settings);
        const defaultContextSize =
            this.backend.kind === "tauri"
                ? DEFAULT_TAURI_CONTEXT_SIZE
                : DEFAULT_WEB_CONTEXT_SIZE;
        const requestedContextSize =
            settings.contextLength ?? model.contextLength ?? defaultContextSize;
        const contextSize =
            this.backend.kind === "tauri"
                ? requestedContextSize
                : Math.min(requestedContextSize, DEFAULT_WEB_CONTEXT_SIZE);
        const configuredMaxTokens = settings.maxTokens ?? model.maxTokens;
        const maxAllowedTokens = Math.max(
            1,
            contextSize - OVERFLOW_SAFETY_TOKENS,
        );
        const implicitMaxTokens = Math.min(
            DEFAULT_GENERATION_MAX_TOKENS,
            Math.max(1, Math.floor(contextSize / 2)),
        );
        const maxTokens = configuredMaxTokens ?? implicitMaxTokens;
        return {
            model,
            contextSize,
            maxTokens: Math.min(maxTokens, maxAllowedTokens),
        };
    }

    public async checkModelAvailability(settings: ModelSettings) {
        await this.initialize();
        const { model, contextSize } = this.resolveRuntimeSettings(settings);
        const contextKey = JSON.stringify({ contextSize });

        const modelPath = await this.resolveModelPath(model, settings);
        const mmprojUrl =
            this.backend.kind === "tauri"
                ? this.resolveMmprojUrl(model, settings)
                : undefined;
        const mmprojPath =
            this.backend.kind === "tauri" && mmprojUrl
                ? await this.resolveAuxModelPath(mmprojUrl, settings)
                : undefined;

        const modelAvailable = await this.backend.isModelAvailable(modelPath);
        const mmprojAvailable = mmprojPath
            ? await this.backend.isModelAvailable(mmprojPath)
            : undefined;

        return {
            model,
            modelPath,
            mmprojPath,
            contextKey,
            modelAvailable,
            mmprojAvailable,
        };
    }

    public async ensureModelReady(
        settings: ModelSettings,
        options: { emitProgress?: boolean } = {},
    ) {
        await this.initialize();
        const emitProgress = options.emitProgress ?? true;
        const { model, contextSize } = this.resolveRuntimeSettings(settings);
        const contextKey = JSON.stringify({ contextSize });

        const modelPath = await this.resolveModelPath(model, settings);
        const mmprojUrl =
            this.backend.kind === "tauri"
                ? this.resolveMmprojUrl(model, settings)
                : undefined;
        const mmprojPath =
            this.backend.kind === "tauri" && mmprojUrl
                ? await this.resolveAuxModelPath(mmprojUrl, settings)
                : undefined;

        const ensureKey = JSON.stringify({
            modelId: model.id,
            modelPath,
            mmprojPath,
            contextKey,
        });

        if (this.ensureInFlight) {
            if (this.ensureInFlight.key === ensureKey) {
                const inFlight = this.ensureInFlight;
                if (emitProgress && !inFlight.emitsProgress) {
                    inFlight.emitsProgress = true;
                    this.emitProgress({
                        percent: 100,
                        status: "Loading model...",
                    });
                    await inFlight.promise;
                    this.emitProgress({ percent: 100, status: "Ready" });
                    return;
                }
                return inFlight.promise;
            }
            try {
                await this.ensureInFlight.promise;
            } catch {
                // ignore errors from previous load
            }
        }

        const ensurePromise = (async () => {
            log.info("LLM ensureModelReady", {
                backend: this.backend.kind,
                modelId: model.id,
                modelPath,
                mmprojPath,
                contextKey,
            });

            if (
                this.currentModel?.id === model.id &&
                this.currentModelPath === modelPath &&
                this.currentContextKey === contextKey &&
                this.currentMmprojPath === mmprojPath
            ) {
                log.info("LLM model already ready", { modelId: model.id });
                this.modelReady = true;
                if (emitProgress) {
                    this.emitProgress({ percent: 100, status: "Ready" });
                }
                return;
            }

            this.modelReady = false;
            log.info("LLM resetting backend", {
                modelId: this.currentModel?.id,
            });
            await this.backend.freeContext();
            await this.backend.freeModel();
            this.currentModel = undefined;
            this.currentModelPath = undefined;
            this.currentMmprojPath = undefined;
            this.currentContextKey = undefined;

            if (this.backend.kind === "tauri") {
                const downloads: Array<{
                    url: string;
                    path: string;
                    label: string;
                }> = [];
                const installed =
                    await this.backend.isModelAvailable(modelPath);
                log.info("LLM model installed", { modelPath, installed });
                if (!installed) {
                    downloads.push({
                        url: model.url,
                        path: modelPath,
                        label: "model",
                    });
                }
                if (mmprojUrl && mmprojPath) {
                    const mmprojInstalled =
                        await this.backend.isModelAvailable(mmprojPath);
                    log.info("LLM mmproj installed", {
                        mmprojPath,
                        mmprojInstalled,
                    });
                    if (!mmprojInstalled) {
                        downloads.push({
                            url: mmprojUrl,
                            path: mmprojPath,
                            label: "mmproj",
                        });
                    }
                }

                log.info("LLM download plan", {
                    downloads: downloads.map((download) => ({
                        url: download.url,
                        path: download.path,
                        label: download.label,
                    })),
                });

                if (downloads.length === 1) {
                    const download = downloads[0];
                    if (download) {
                        await this.downloadModel(download.url, download.path);
                    }
                } else if (downloads.length > 1) {
                    await this.downloadModelsCombined(downloads);
                }
            }

            if (emitProgress) {
                this.emitProgress({ percent: 100, status: "Loading model..." });
            }
            log.info("LLM load model", { modelPath });
            await this.backend.loadModel({ modelPath });
            log.info("LLM create context", { modelPath, contextSize });
            await this.backend.createContext({ modelPath }, { contextSize });

            this.currentModel = model;
            this.currentModelPath = modelPath;
            this.currentMmprojPath = mmprojPath;
            this.currentContextKey = contextKey;
            this.modelReady = true;
            log.info("LLM ready", { modelId: model.id, modelPath });
            if (emitProgress) {
                this.emitProgress({ percent: 100, status: "Ready" });
            }
        })();

        this.ensureInFlight = {
            key: ensureKey,
            promise: ensurePromise,
            emitsProgress: emitProgress,
        };

        try {
            await ensurePromise;
        } finally {
            if (this.ensureInFlight?.promise === ensurePromise) {
                this.ensureInFlight = undefined;
            }
        }
    }

    public async generateChatStream(
        request: GenerateChatRequest,
        onEvent?: (event: GenerateEvent) => void,
    ): Promise<GenerateSummary> {
        return this.backend.generateChatStream(request, onEvent);
    }

    public async prewarmImageInferenceIfAvailable(settings: ModelSettings) {
        await this.initialize();
        if (this.backend.kind !== "tauri") return;

        const availability = await this.checkModelAvailability(settings);
        if (
            !availability.modelAvailable ||
            !availability.mmprojPath ||
            availability.mmprojAvailable !== true
        ) {
            return;
        }

        await this.ensureModelReady(settings, { emitProgress: false });
        const mmprojPath = this.currentMmprojPath ?? availability.mmprojPath;
        if (!mmprojPath || !this.backend.prewarmMultimodalContext) return;
        await this.backend.prewarmMultimodalContext(mmprojPath);
    }

    public cancelGeneration(jobId: number) {
        this.backend.cancel(jobId);
    }

    public async resetContext(contextSize?: number) {
        await this.backend.freeContext();
        this.currentContextKey = undefined;
        if (this.currentModel && this.currentModelPath) {
            const resolvedContext =
                contextSize ??
                (this.backend.kind === "tauri"
                    ? DEFAULT_TAURI_CONTEXT_SIZE
                    : DEFAULT_WEB_CONTEXT_SIZE);
            await this.backend.createContext(
                { modelPath: this.currentModelPath },
                { contextSize: resolvedContext },
            );
            this.currentContextKey = JSON.stringify({
                contextSize: resolvedContext,
            });
        }
    }

    public cancelDownload() {
        if (this.downloadActive && this.backend.kind === "tauri") {
            void import("@tauri-apps/api/tauri").then(({ invoke }) =>
                invoke("llm_cancel_model_download").catch((error: unknown) => {
                    log.warn("LLM cancel model download failed", { error });
                }),
            );
        }
        this.emitProgress({ percent: -1, status: "Cancelled" });
    }

    private emitProgress(progress: DownloadProgress) {
        for (const listener of this.progressListeners) {
            listener(progress);
        }
    }

    private handleWasmProgress(event: {
        loaded: number;
        total?: number;
        status?: string;
    }) {
        if (this.modelReady) {
            return;
        }
        const total = event.total ?? 0;
        const loaded = event.loaded ?? 0;
        const percent = total
            ? Math.min(99, Math.round((loaded / total) * 100))
            : 0;
        this.emitProgress({
            percent,
            status: event.status ?? "Downloading...",
            bytesDownloaded: loaded,
            totalBytes: total,
        });
    }

    private async resolveDefaultModelForDevice() {
        this.defaultModel = DEFAULT_MODEL;
        this.useDesktopRustDefaults = false;

        if (this.backend.kind !== "tauri") {
            return;
        }

        try {
            const { invoke } = await import("@tauri-apps/api/tauri");
            const info = await invoke<{
                platform?: string;
                totalMemoryBytes?: number | null;
            }>("system_info");

            const platform = info.platform?.toLowerCase();
            const totalMemoryBytes = info.totalMemoryBytes ?? 0;

            this.useDesktopRustDefaults =
                totalMemoryBytes >= MIN_DESKTOP_DEFAULT_MEMORY_BYTES;

            if (this.useDesktopRustDefaults) {
                this.defaultModel = DESKTOP_DEFAULT_MODEL;
            }

            // Overlay Rust-authoritative fields (id, name, url, mmprojUrl)
            // while keeping the web-only display fields (sizeBytes etc.)
            // as fallbacks.
            try {
                const defaults =
                    await invoke<TauriEnsuDefaults>("get_ensu_defaults");
                const rustPreset = this.useDesktopRustDefaults
                    ? defaults.desktopDefaultModel
                    : defaults.mobileDefaultModel;
                this.defaultModel = {
                    ...this.defaultModel,
                    id: rustPreset.id,
                    name: rustPreset.title,
                    url: rustPreset.url,
                    mmprojUrl: rustPreset.mmprojUrl ?? undefined,
                };
                this.ensuDefaults = defaults;
            } catch (defaultsError) {
                log.warn(
                    "Failed to fetch ensu defaults from Rust",
                    defaultsError,
                );
            }

            log.info("LLM default model resolved", {
                platform,
                totalMemoryBytes,
                modelId: this.defaultModel.id,
            });
        } catch (error) {
            log.warn("Failed to resolve device-specific default model", error);
        }
    }

    private resolveTargetModel(settings: ModelSettings): ModelInfo {
        if (settings.useCustomModel && settings.modelUrl) {
            return {
                id: `custom:${settings.modelUrl}`,
                name: "Custom model",
                url: settings.modelUrl,
                mmprojUrl: settings.mmprojUrl,
            };
        }
        return this.defaultModel;
    }

    private resolveMmprojUrl(model: ModelInfo, settings: ModelSettings) {
        const override = settings.mmprojUrl;
        if (settings.useCustomModel) {
            return override && override.trim() ? override : undefined;
        }
        if (override !== undefined) {
            return override && override.trim() ? override : undefined;
        }
        return model.mmprojUrl;
    }

    private async resolveModelPath(
        model: ModelInfo,
        settings: ModelSettings,
    ): Promise<string> {
        if (this.backend.kind !== "tauri") {
            return model.url;
        }

        const { appDataDir, join } = await import("@tauri-apps/api/path");

        const baseDir = await appDataDir();
        const modelsDir = await join(baseDir, "models");
        const filename = filenameFromUrl(model.url);

        if (settings.useCustomModel && settings.modelUrl) {
            const hash = await hashUrl(settings.modelUrl);
            const customDir = await join(modelsDir, "custom");
            return join(customDir, `${hash}_${filename}`);
        }

        return join(modelsDir, filename);
    }

    private async resolveAuxModelPath(
        url: string,
        settings: ModelSettings,
    ): Promise<string> {
        const { appDataDir, join } = await import("@tauri-apps/api/path");

        const baseDir = await appDataDir();
        const modelsDir = await join(baseDir, "models");
        const filename = filenameFromUrl(url);

        if (settings.useCustomModel) {
            const hash = await hashUrl(url);
            const customDir = await join(modelsDir, "custom");
            return join(customDir, `${hash}_${filename}`);
        }

        return join(modelsDir, filename);
    }

    private async downloadModelsCombined(
        downloads: Array<{ url: string; path: string; label: string }>,
    ) {
        await this.downloadModelsNative(downloads);
    }

    private async downloadModel(
        url: string,
        destPath: string,
        onProgress?: (progress: DownloadProgress) => void,
    ) {
        const emit = onProgress ?? ((progress) => this.emitProgress(progress));
        emit({
            percent: 0,
            status: "Starting download...",
            bytesDownloaded: 0,
            totalBytes: 0,
        });

        await this.downloadModelsNative(
            [{ url, path: destPath, label: "Model" }],
            emit,
        );
    }

    private async downloadModelsNative(
        downloads: Array<{ url: string; path: string; label: string }>,
        onProgress?: (progress: DownloadProgress) => void,
    ) {
        const emit = onProgress ?? ((progress) => this.emitProgress(progress));
        const [{ invoke }, { listen }] = await Promise.all([
            import("@tauri-apps/api/tauri"),
            import("@tauri-apps/api/event"),
        ]);

        log.info("LLM native download start", { downloads });
        this.downloadActive = true;
        const unlisten = await listen<TauriLlmModelDownloadProgress>(
            "llm-download-progress",
            (event) => {
                const progress = event.payload;
                emit({
                    percent: Math.min(99, progress.percent),
                    status: progress.status,
                    bytesDownloaded: progress.bytesDownloaded,
                    totalBytes: progress.totalBytes,
                });
            },
        );

        try {
            await invoke("llm_download_model_files", { downloads });
            log.info("LLM native download complete", { downloads });
        } finally {
            this.downloadActive = false;
            unlisten();
        }
    }
}

const filenameFromUrl = (url: string) => {
    try {
        const parsed = new URL(url);
        const name = parsed.pathname.split("/").pop();
        return name && name.length ? name : "model.gguf";
    } catch {
        return "model.gguf";
    }
};

const hashUrl = async (url: string) => {
    const data = new TextEncoder().encode(url);
    const digest = await crypto.subtle.digest("SHA-256", data);
    return Array.from(new Uint8Array(digest))
        .map((byte) => byte.toString(16).padStart(2, "0"))
        .join("");
};

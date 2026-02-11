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

const DEFAULT_CONTEXT_SIZE = 4096;
const DEFAULT_MAX_TOKENS = 512;
const MIN_GGUF_BYTES = 1024 * 1024; // 1MB
const MIN_HIGH_RAM_MAC_BYTES = 16 * 1024 * 1024 * 1024;

export const DEFAULT_MODEL: ModelInfo = {
    id: "lfm-2.5-vl-1.6b",
    name: "LFM 2.5 VL 1.6B (Q4_0)",
    url: "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/LFM2.5-VL-1.6B-Q4_0.gguf",
    mmprojUrl:
        "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/mmproj-LFM2.5-VL-1.6b-Q8_0.gguf",
    description: "Liquid AI multimodal model (text-only on web)",
    sizeHuman: "~664 MB",
    sizeBytes: 695_752_160,
    mmprojSizeBytes: 583_109_888,
};

const HIGH_RAM_MAC_MODEL: ModelInfo = {
    id: "qwen3-vl-8b-instruct-q4km",
    name: "Qwen3-VL 8B Instruct (Q4_K_M)",
    url: "https://huggingface.co/Qwen/Qwen3-VL-8B-Instruct-GGUF/resolve/main/Qwen3VL-8B-Instruct-Q4_K_M.gguf?download=true",
    mmprojUrl:
        "https://huggingface.co/Qwen/Qwen3-VL-8B-Instruct-GGUF/resolve/main/mmproj-Qwen3VL-8B-Instruct-Q8_0.gguf",
    description: "Qwen multimodal model for higher-memory macOS devices",
};

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

    private downloadAbort?: AbortController;
    private progressListeners = new Set<(progress: DownloadProgress) => void>();
    private modelReady = false;
    private ensureInFlight?: { key: string; promise: Promise<void> };

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

    public getBackendKind() {
        return this.backend.kind;
    }

    public getCurrentMmprojPath() {
        return this.currentMmprojPath;
    }

    public resolveRuntimeSettings(settings: ModelSettings) {
        const model = this.resolveTargetModel(settings);
        const contextSize =
            settings.contextLength ??
            model.contextLength ??
            DEFAULT_CONTEXT_SIZE;
        const maxTokens =
            settings.maxTokens ?? model.maxTokens ?? DEFAULT_MAX_TOKENS;
        return {
            model,
            contextSize,
            maxTokens: Math.min(maxTokens, contextSize),
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

    public async ensureModelReady(settings: ModelSettings) {
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

        const ensureKey = JSON.stringify({
            modelId: model.id,
            modelPath,
            mmprojPath,
            contextKey,
        });

        if (this.ensureInFlight) {
            if (this.ensureInFlight.key === ensureKey) {
                return this.ensureInFlight.promise;
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
                this.emitProgress({ percent: 100, status: "Ready" });
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

            this.emitProgress({ percent: 100, status: "Loading model..." });
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
            this.emitProgress({ percent: 100, status: "Ready" });
        })();

        this.ensureInFlight = { key: ensureKey, promise: ensurePromise };

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

    public cancelGeneration(jobId: number) {
        this.backend.cancel(jobId);
    }

    public async resetContext(contextSize?: number) {
        await this.backend.freeContext();
        this.currentContextKey = undefined;
        if (this.currentModel && this.currentModelPath) {
            const resolvedContext = contextSize ?? DEFAULT_CONTEXT_SIZE;
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
        if (this.downloadAbort) {
            this.downloadAbort.abort("cancelled");
            this.downloadAbort = undefined;
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

            if (
                platform === "macos" &&
                totalMemoryBytes >= MIN_HIGH_RAM_MAC_BYTES
            ) {
                this.defaultModel = HIGH_RAM_MAC_MODEL;
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
        const totals = new Map<string, number>();
        const loaded = new Map<string, number>();

        const emitCombined = () => {
            const totalBytes = Array.from(totals.values()).reduce(
                (sum, value) => sum + value,
                0,
            );
            const bytesDownloaded = Array.from(loaded.values()).reduce(
                (sum, value) => sum + value,
                0,
            );
            const percent = totalBytes
                ? Math.min(99, Math.round((bytesDownloaded / totalBytes) * 100))
                : 0;
            this.emitProgress({
                percent,
                status: `Downloading models... ${formatBytes(
                    bytesDownloaded,
                )} / ${totalBytes ? formatBytes(totalBytes) : "?"}`,
                bytesDownloaded,
                totalBytes: totalBytes || undefined,
            });
        };

        this.emitProgress({ percent: 0, status: "Preparing downloads..." });

        for (const download of downloads) {
            const size = await fetchRemoteSize(download.url);
            if (size !== undefined) {
                totals.set(download.label, size);
            }
            if (!loaded.has(download.label)) {
                loaded.set(download.label, 0);
            }
        }

        emitCombined();

        for (const download of downloads) {
            const progressHandler = (progress: DownloadProgress) => {
                if (progress.totalBytes !== undefined) {
                    totals.set(download.label, progress.totalBytes);
                }
                if (progress.bytesDownloaded !== undefined) {
                    loaded.set(download.label, progress.bytesDownloaded);
                }
                emitCombined();
            };

            await this.downloadModel(
                download.url,
                download.path,
                progressHandler,
            );
        }
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

        const { createDir, exists, removeFile, renameFile } = await import(
            "@tauri-apps/api/fs"
        );
        const { invoke } = await import("@tauri-apps/api/tauri");
        const { dirname } = await import("@tauri-apps/api/path");

        log.info("LLM download start", { url, destPath });

        const dir = await dirname(destPath);
        await createDir(dir, { recursive: true });

        const tmpPath = `${destPath}.tmp`;
        const maxAttempts = 3;
        const stallTimeoutMs = 30_000;

        const delay = (ms: number) =>
            new Promise<void>((resolve) => {
                window.setTimeout(resolve, ms);
            });

        for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
            let downloaded = 0;
            let totalBytes = 0;
            const controller = new AbortController();
            this.downloadAbort = controller;

            let stallTimer: number | null = null;
            const resetStallTimer = () => {
                if (stallTimer) {
                    window.clearTimeout(stallTimer);
                }
                stallTimer = window.setTimeout(() => {
                    if (!controller.signal.aborted) {
                        controller.abort("stall");
                    }
                }, stallTimeoutMs);
            };

            try {
                if (await exists(tmpPath)) {
                    try {
                        const size = await invoke<number | null>(
                            "fs_file_size",
                            { path: tmpPath },
                        );
                        downloaded = size ?? 0;
                        if (downloaded > 0) {
                            const head = await invoke<number[]>(
                                "fs_read_head",
                                { path: tmpPath, length: 4 },
                            );
                            if (!isGgufHeader(new Uint8Array(head))) {
                                log.warn(
                                    "LLM resume header invalid, restarting",
                                    { tmpPath },
                                );
                                await removeFile(tmpPath);
                                downloaded = 0;
                            }
                        }
                    } catch {
                        downloaded = 0;
                    }
                }

                emit({
                    percent: 0,
                    status:
                        downloaded > 0
                            ? "Resuming download..."
                            : "Starting download...",
                    bytesDownloaded: downloaded,
                    totalBytes: 0,
                });

                if (downloaded > 0) {
                    log.info("LLM download resume", { destPath, downloaded });
                }

                resetStallTimer();

                const headers: HeadersInit | undefined = downloaded
                    ? { Range: `bytes=${downloaded}-` }
                    : undefined;
                let res = await fetch(url, {
                    signal: controller.signal,
                    headers,
                });
                log.info("LLM download response", {
                    url,
                    status: res.status,
                    contentLength: res.headers.get("Content-Length"),
                    contentRange: res.headers.get("Content-Range"),
                });
                if (!res.ok || !res.body) {
                    throw new Error(`Failed to download model (${res.status})`);
                }

                if (downloaded > 0 && res.status === 200) {
                    downloaded = 0;
                    try {
                        await removeFile(tmpPath);
                    } catch {
                        // ignore missing tmp
                    }
                    res = await fetch(url, { signal: controller.signal });
                    log.info("LLM download restart", {
                        url,
                        status: res.status,
                        contentLength: res.headers.get("Content-Length"),
                        contentRange: res.headers.get("Content-Range"),
                    });
                    if (!res.ok || !res.body) {
                        throw new Error(
                            `Failed to download model (${res.status})`,
                        );
                    }
                }

                const contentRangeTotal = parseContentRangeTotal(
                    res.headers.get("Content-Range"),
                );
                const contentLength = Number(
                    res.headers.get("Content-Length") ?? 0,
                );
                totalBytes =
                    contentRangeTotal ??
                    (contentLength ? contentLength + downloaded : 0);

                const reader = res.body.getReader();
                let headerBytes: Uint8Array | null = null;
                const maxChunkSize = 1024 * 1024;
                const yieldAfterBytes = 4 * 1024 * 1024;
                let bytesSinceYield = 0;

                while (true) {
                    const { done, value } = await reader.read();
                    if (done) break;
                    if (!value) continue;

                    resetStallTimer();

                    for (
                        let offset = 0;
                        offset < value.length;
                        offset += maxChunkSize
                    ) {
                        const chunk = value.subarray(
                            offset,
                            Math.min(offset + maxChunkSize, value.length),
                        );

                        if (!headerBytes && downloaded === 0) {
                            headerBytes = chunk.slice(0, 4);
                        }

                        await invoke("fs_append_bytes", {
                            path: tmpPath,
                            bytes: Array.from(chunk),
                        });

                        downloaded += chunk.length;
                        bytesSinceYield += chunk.length;

                        const percent = totalBytes
                            ? Math.min(
                                  99,
                                  Math.round((downloaded / totalBytes) * 100),
                              )
                            : 0;
                        emit({
                            percent,
                            status: `Downloading... ${formatBytes(downloaded)} / ${
                                totalBytes ? formatBytes(totalBytes) : "?"
                            }`,
                            bytesDownloaded: downloaded,
                            totalBytes,
                        });

                        if (bytesSinceYield >= yieldAfterBytes) {
                            bytesSinceYield = 0;
                            await delay(0);
                            resetStallTimer();
                        }
                    }
                }

                if (stallTimer) {
                    window.clearTimeout(stallTimer);
                    stallTimer = null;
                }

                if (headerBytes && !isGgufHeader(headerBytes)) {
                    await removeFile(tmpPath);
                    emit({
                        percent: -1,
                        status: "Downloaded file is not GGUF",
                        bytesDownloaded: downloaded,
                        totalBytes,
                    });
                    throw new Error("Downloaded file is not GGUF");
                }

                if (downloaded < MIN_GGUF_BYTES) {
                    await removeFile(tmpPath);
                    emit({
                        percent: -1,
                        status: "Downloaded file too small",
                        bytesDownloaded: downloaded,
                        totalBytes,
                    });
                    throw new Error("Downloaded file too small");
                }

                try {
                    await removeFile(destPath);
                } catch {
                    // ignore missing dest
                }

                await renameFile(tmpPath, destPath);

                const finalSize = await invoke<number | null>("fs_file_size", {
                    path: destPath,
                });
                if (finalSize !== null && finalSize !== downloaded) {
                    await removeFile(destPath);
                    throw new Error(
                        `Downloaded file size mismatch (${finalSize} != ${downloaded})`,
                    );
                }

                const head = await invoke<number[]>("fs_read_head", {
                    path: destPath,
                    length: 4,
                });
                if (!isGgufHeader(new Uint8Array(head))) {
                    await removeFile(destPath);
                    throw new Error("Downloaded file header is not GGUF");
                }

                log.info("LLM download complete", {
                    destPath,
                    bytesDownloaded: downloaded,
                    totalBytes,
                });

                return;
            } catch (error) {
                if (stallTimer) {
                    window.clearTimeout(stallTimer);
                    stallTimer = null;
                }

                const aborted = controller.signal.aborted;
                const reason = controller.signal.reason;
                if (aborted && reason === "cancelled") {
                    throw new Error("Download cancelled");
                }

                if (attempt >= maxAttempts) {
                    log.error("LLM download failed", { url, destPath, error });
                    throw error;
                }

                log.warn("LLM download retry", {
                    url,
                    destPath,
                    attempt,
                    error,
                });
                await delay(1500 * attempt);
            } finally {
                if (this.downloadAbort === controller) {
                    this.downloadAbort = undefined;
                }
            }
        }
    }
}

const parseContentRangeTotal = (header: string | null) => {
    if (!header) return undefined;
    const match = header.match(/\/(\d+)/);
    if (!match) return undefined;
    const total = Number(match[1]);
    return Number.isFinite(total) ? total : undefined;
};

const fetchRemoteSize = async (url: string): Promise<number | undefined> => {
    try {
        const head = await fetch(url, { method: "HEAD" });
        if (head.ok) {
            const length = Number(head.headers.get("Content-Length") ?? 0);
            if (length > 0) return length;
            const range = parseContentRangeTotal(
                head.headers.get("Content-Range"),
            );
            if (range) return range;
        }
    } catch {
        // ignore head failures
    }

    try {
        const res = await fetch(url, { headers: { Range: "bytes=0-0" } });
        if (!res.ok) return undefined;
        const range = parseContentRangeTotal(res.headers.get("Content-Range"));
        if (range) return range;
        const length = Number(res.headers.get("Content-Length") ?? 0);
        return length > 0 ? length : undefined;
    } catch {
        return undefined;
    }
};

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

const isGgufHeader = (bytes: Uint8Array) =>
    bytes.length >= 4 &&
    bytes[0] === 0x47 &&
    bytes[1] === 0x47 &&
    bytes[2] === 0x55 &&
    bytes[3] === 0x46;

const formatBytes = (bytes: number) => {
    if (!bytes || bytes <= 0) return "0 B";
    const units = ["B", "KB", "MB", "GB", "TB"];
    const idx = Math.min(
        units.length - 1,
        Math.floor(Math.log(bytes) / Math.log(1024)),
    );
    const value = bytes / Math.pow(1024, idx);
    return `${value.toFixed(value >= 10 ? 0 : 1)} ${units[idx]}`;
};

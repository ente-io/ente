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

export const DEFAULT_MODEL: ModelInfo = {
    id: "lfm-2.5-vl-1.6b",
    name: "LFM 2.5 VL 1.6B (Q4_0)",
    url: "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/LFM2.5-VL-1.6B-Q4_0.gguf",
    mmprojUrl: "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/mmproj-LFM2.5-VL-1.6b-Q8_0.gguf",
    description: "Liquid AI multimodal model (text-only on web)",
    sizeHuman: "~1.1 GB",
};

export class LlmProvider {
    private backend = createInferenceBackend({
        backend: "auto",
        wasm: {
            progressCallback: (event) => this.handleWasmProgress(event),
        },
    });

    private initialized = false;
    private currentModel?: ModelInfo;
    private currentModelPath?: string;
    private currentMmprojPath?: string;
    private currentContextKey?: string;

    private downloadAbort?: AbortController;
    private progressListeners = new Set<(progress: DownloadProgress) => void>();

    public async initialize() {
        if (this.initialized) return;
        await this.backend.initBackend();
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

    public getBackendKind() {
        return this.backend.kind;
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

        if (
            this.currentModel?.id === model.id &&
            this.currentModelPath === modelPath &&
            this.currentContextKey === contextKey &&
            this.currentMmprojPath === mmprojPath
        ) {
            return;
        }

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
            const installed = await this.modelExists(modelPath);
            if (!installed) {
                downloads.push({
                    url: model.url,
                    path: modelPath,
                    label: "model",
                });
            }
            if (mmprojUrl && mmprojPath) {
                const mmprojInstalled = await this.modelExists(mmprojPath);
                if (!mmprojInstalled) {
                    downloads.push({
                        url: mmprojUrl,
                        path: mmprojPath,
                        label: "mmproj",
                    });
                }
            }

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
        await this.backend.loadModel({ modelPath });
        await this.backend.createContext({ modelPath }, { contextSize });

        this.currentModel = model;
        this.currentModelPath = modelPath;
        this.currentMmprojPath = mmprojPath;
        this.currentContextKey = contextKey;
        this.emitProgress({ percent: 100, status: "Ready" });
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
            this.downloadAbort.abort();
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

    private resolveTargetModel(settings: ModelSettings): ModelInfo {
        if (settings.useCustomModel && settings.modelUrl) {
            return {
                id: `custom:${settings.modelUrl}`,
                name: "Custom model",
                url: settings.modelUrl,
                mmprojUrl: settings.mmprojUrl,
            };
        }
        return DEFAULT_MODEL;
    }

    private resolveMmprojUrl(model: ModelInfo, settings: ModelSettings) {
        if (settings.useCustomModel) {
            return settings.mmprojUrl;
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

    private async modelExists(path: string) {
        const { exists } = await import("@tauri-apps/api/fs");
        return exists(path);
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

        const { createDir, removeFile, renameFile, writeBinaryFile } =
            await import("@tauri-apps/api/fs");
        const { dirname } = await import("@tauri-apps/api/path");

        const dir = await dirname(destPath);
        await createDir(dir, { recursive: true });

        const tmpPath = `${destPath}.tmp`;
        try {
            await removeFile(tmpPath);
        } catch {
            // ignore missing tmp
        }

        const controller = new AbortController();
        this.downloadAbort = controller;

        let downloaded = 0;
        let totalBytes = 0;

        try {
            const res = await fetch(url, { signal: controller.signal });
            if (!res.ok || !res.body) {
                throw new Error(`Failed to download model (${res.status})`);
            }

            totalBytes = Number(res.headers.get("Content-Length") ?? 0);
            const reader = res.body.getReader();

            let headerBytes: Uint8Array | null = null;

            while (true) {
                const { done, value } = await reader.read();
                if (done) break;
                if (!value) continue;

                if (!headerBytes) {
                    headerBytes = value.slice(0, 4);
                }

                await writeBinaryFile(
                    { path: tmpPath, contents: value },
                    { append: true },
                );

                downloaded += value.length;
                const percent = totalBytes
                    ? Math.min(99, Math.round((downloaded / totalBytes) * 100))
                    : 0;
                emit({
                    percent,
                    status: `Downloading... ${formatBytes(downloaded)} / ${
                        totalBytes ? formatBytes(totalBytes) : "?"
                    }`,
                    bytesDownloaded: downloaded,
                    totalBytes,
                });
            }

            if (!headerBytes || !isGgufHeader(headerBytes)) {
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
        } finally {
            this.downloadAbort = undefined;
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

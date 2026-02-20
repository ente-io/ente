#!/usr/bin/env node

import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import crypto from "node:crypto";
import { once } from "node:events";
import { createReadStream } from "node:fs";
import fs from "node:fs/promises";
import path from "node:path";
import { performance } from "node:perf_hooks";
import process from "node:process";
import readline from "node:readline";
import { fileURLToPath } from "node:url";

interface ManifestItem {
    file_id: string;
    source: string;
    source_sha256?: string;
}

interface RunnerArgs {
    manifestPath: string;
    outputDir: string;
    hostScriptPath: string;
    electronBinPath: string;
    userDataPath: string;
}

interface DecodedImage {
    width: number;
    height: number;
    rgba: Uint8ClampedArray;
}

interface HostRequest {
    id: number;
    method: string;
    params?: Record<string, unknown>;
}

interface HostResponse {
    id: number | null;
    ok: boolean;
    result?: unknown;
    error?: unknown;
}

interface PendingRequest {
    resolve: (value: unknown) => void;
    reject: (reason: unknown) => void;
    timeoutHandle: ReturnType<typeof setTimeout>;
}

interface WebMLBindings {
    indexCLIP: (
        image: unknown,
        electron: unknown,
    ) => Promise<{ embedding: number[] }>;
    indexFaces: (
        file: unknown,
        image: unknown,
        electron: unknown,
    ) => Promise<{
        faces: Array<{
            detection: {
                box: { x: number; y: number; width: number; height: number };
                landmarks: Array<{ x: number; y: number }>;
            };
            score: number;
            embedding: number[];
        }>;
    }>;
    createImageBitmapAndData: (...args: unknown[]) => Promise<unknown>;
    renderableImageBlob: (blob: Blob, fileName: string) => Promise<Blob>;
}

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(SCRIPT_DIR, "..", "..");
const DESKTOP_ROOT = path.join(REPO_ROOT, "desktop");
const ML_DIR = path.join(REPO_ROOT, "infra", "ml", "test");

const DEFAULT_MANIFEST_PATH = path.join(
    REPO_ROOT,
    "infra",
    "ml",
    "test",
    "ground_truth",
    "manifest.json",
);

const DEFAULT_OUTPUT_DIR = path.join(
    REPO_ROOT,
    "infra",
    "ml",
    "test",
    "out",
    "parity",
    "desktop",
);
const DEFAULT_HOST_SCRIPT_PATH = path.join(
    REPO_ROOT,
    "desktop",
    "scripts",
    "ml_parity_host.js",
);
const DEFAULT_ELECTRON_BIN_PATH = path.join(
    REPO_ROOT,
    "desktop",
    "node_modules",
    ".bin",
    "electron",
);
const DEFAULT_USER_DATA_PATH = path.join(
    REPO_ROOT,
    "infra",
    "ml",
    "test",
    ".cache",
    "desktop-user-data",
);

const MODEL_FILE_NAMES: Record<string, string> = {
    clip: "mobileclip_s2_image_opset18_rgba_opt.onnx",
    face_detection: "yolov5s_face_opset18_rgba_opt_nosplits.onnx",
    face_embedding: "mobilefacenet_opset15.onnx",
};
const HOST_RESPONSE_PREFIX = "__ML_PARITY_JSON__";
const DEFAULT_HOST_REQUEST_TIMEOUT_MS = 120_000;

const parseHostRequestTimeoutMS = (value: string | undefined): number => {
    const trimmed = value?.trim();
    if (!trimmed) {
        return DEFAULT_HOST_REQUEST_TIMEOUT_MS;
    }
    const parsed = Number.parseInt(trimmed, 10);
    if (!Number.isFinite(parsed) || parsed < 1_000) {
        throw new Error(
            "ML_PARITY_HOST_REQUEST_TIMEOUT_MS must be an integer >= 1000",
        );
    }
    return parsed;
};
const HOST_REQUEST_TIMEOUT_MS = parseHostRequestTimeoutMS(
    process.env.ML_PARITY_HOST_REQUEST_TIMEOUT_MS,
);

const usage = () => {
    process.stderr.write(
        `Usage: desktop/scripts/ml_parity_runner.ts [flags]\n\n`,
    );
    process.stderr.write(`Flags:\n`);
    process.stderr.write(
        `  --manifest <path>        Path to parity manifest (default: infra/ml/test/ground_truth/manifest.json)\n`,
    );
    process.stderr.write(
        `  --output-dir <path>      Output directory for desktop parity JSONs\n`,
    );
    process.stderr.write(`  --electron-bin <path>    Electron binary path\n`);
    process.stderr.write(`  --host-script <path>     Host script path\n`);
    process.stderr.write(
        `  --user-data-dir <path>   Desktop ML model cache/user-data path\n`,
    );
};

const resolveRepoPath = (inputPath: string) =>
    path.isAbsolute(inputPath) ? inputPath : path.resolve(REPO_ROOT, inputPath);

const resolveMLPath = (inputPath: string) =>
    path.isAbsolute(inputPath) ? inputPath : path.resolve(ML_DIR, inputPath);

const parseArgs = (argv: string[]): RunnerArgs => {
    let manifestPath = DEFAULT_MANIFEST_PATH;
    let outputDir = DEFAULT_OUTPUT_DIR;
    let hostScriptPath =
        process.env.ML_PARITY_HOST_SCRIPT?.trim() || DEFAULT_HOST_SCRIPT_PATH;
    let electronBinPath =
        process.env.ML_PARITY_ELECTRON_BIN?.trim() || DEFAULT_ELECTRON_BIN_PATH;
    let userDataPath =
        process.env.ML_PARITY_USER_DATA_DIR?.trim() || DEFAULT_USER_DATA_PATH;

    for (let i = 0; i < argv.length; i += 1) {
        const arg = argv[i];
        switch (arg) {
            case "--manifest": {
                const value = argv[i + 1];
                if (!value) {
                    throw new Error("--manifest requires a value");
                }
                manifestPath = value;
                i += 1;
                break;
            }
            case "--output-dir": {
                const value = argv[i + 1];
                if (!value) {
                    throw new Error("--output-dir requires a value");
                }
                outputDir = value;
                i += 1;
                break;
            }
            case "--electron-bin": {
                const value = argv[i + 1];
                if (!value) {
                    throw new Error("--electron-bin requires a value");
                }
                electronBinPath = value;
                i += 1;
                break;
            }
            case "--host-script": {
                const value = argv[i + 1];
                if (!value) {
                    throw new Error("--host-script requires a value");
                }
                hostScriptPath = value;
                i += 1;
                break;
            }
            case "--user-data-dir": {
                const value = argv[i + 1];
                if (!value) {
                    throw new Error("--user-data-dir requires a value");
                }
                userDataPath = value;
                i += 1;
                break;
            }
            case "-h":
            case "--help": {
                usage();
                process.exit(0);
            }
            default:
                throw new Error(`Unknown argument '${arg}'`);
        }
    }

    return {
        manifestPath: resolveRepoPath(manifestPath),
        outputDir: resolveRepoPath(outputDir),
        hostScriptPath: resolveRepoPath(hostScriptPath),
        electronBinPath: resolveRepoPath(electronBinPath),
        userDataPath: resolveRepoPath(userDataPath),
    };
};

const toBase64 = (
    array: ArrayLike<number> & {
        buffer: ArrayBufferLike;
        byteOffset: number;
        byteLength: number;
    },
) =>
    Buffer.from(array.buffer, array.byteOffset, array.byteLength).toString(
        "base64",
    );

const uint8ClampedArrayFromBase64 = (payload: string) => {
    const bytes = Buffer.from(payload, "base64");
    const array = new Uint8ClampedArray(bytes.byteLength);
    array.set(bytes);
    return array;
};

const float32ArrayFromBase64 = (payload: string) => {
    const bytes = Buffer.from(payload, "base64");
    if (bytes.byteLength % 4 !== 0) {
        throw new Error(
            `Float32 payload byte length ${bytes.byteLength} is not divisible by 4`,
        );
    }
    const array = new Float32Array(bytes.byteLength / 4);
    new Uint8Array(array.buffer).set(bytes);
    return array;
};

const stringifyUnknown = (value: unknown) => {
    if (typeof value === "string") {
        return value;
    }
    try {
        const serialized = JSON.stringify(value);
        if (typeof serialized === "string") {
            return serialized;
        }
        return String(value);
    } catch {
        return String(value);
    }
};

const normalizeHostErrorPayload = (value: unknown) => {
    if (value && typeof value === "object") {
        const maybeError = value as Record<string, unknown>;
        const messageCandidate =
            (typeof maybeError.message === "string" && maybeError.message) ||
            (typeof maybeError.error === "string" && maybeError.error);
        if (messageCandidate && messageCandidate !== "[object Object]") {
            return messageCandidate;
        }
    }

    const normalized = stringifyUnknown(value);
    if (normalized === "[object Object]") {
        return "Host request failed with opaque object error ([object Object]); see preceding host logs for context.";
    }
    return normalized;
};

class HostClient {
    private readonly process: ChildProcessWithoutNullStreams;
    private readonly rl: readline.Interface;
    private nextID = 1;
    private readonly pending = new Map<number, PendingRequest>();
    private readonly requestTimeoutMS: number;
    private closed = false;

    constructor(
        electronBinPath: string,
        hostScriptPath: string,
        userDataPath: string,
    ) {
        this.requestTimeoutMS = HOST_REQUEST_TIMEOUT_MS;
        this.process = spawn(electronBinPath, [hostScriptPath], {
            cwd: DESKTOP_ROOT,
            env: { ...process.env, ML_PARITY_USER_DATA_DIR: userDataPath },
            stdio: ["pipe", "pipe", "pipe"],
        });

        this.process.stderr.setEncoding("utf8");
        this.process.stderr.on("data", (chunk: string) => {
            process.stderr.write(chunk);
        });

        this.rl = readline.createInterface({
            input: this.process.stdout,
            crlfDelay: Infinity,
        });

        this.rl.on("line", (line) => {
            const trimmed = line.trim();
            if (!trimmed) {
                return;
            }
            if (!trimmed.startsWith(HOST_RESPONSE_PREFIX)) {
                process.stderr.write(
                    `[ml_parity_runner] host stdout (non-protocol): ${trimmed}\n`,
                );
                return;
            }

            const payload = trimmed.slice(HOST_RESPONSE_PREFIX.length);
            let message: HostResponse;
            try {
                message = JSON.parse(payload) as HostResponse;
            } catch (error) {
                this.rejectAll(
                    new Error(
                        `Failed to parse host JSON response: ${String(error)}`,
                    ),
                );
                return;
            }

            if (message.id === null || message.id === undefined) {
                if (!message.ok) {
                    process.stderr.write(
                        `[ml_parity_runner] host emitted error without request id: ${normalizeHostErrorPayload(message.error ?? "unknown error")}\n`,
                    );
                }
                return;
            }

            const pending = this.pending.get(message.id);
            if (!pending) {
                return;
            }
            clearTimeout(pending.timeoutHandle);
            this.pending.delete(message.id);

            if (message.ok) {
                pending.resolve(message.result);
            } else {
                pending.reject(
                    new Error(
                        normalizeHostErrorPayload(
                            message.error ?? "Host request failed",
                        ),
                    ),
                );
            }
        });

        this.process.on("error", (error) => {
            this.rejectAll(error);
        });

        this.process.on("exit", (code, signal) => {
            this.closed = true;
            this.rejectAll(
                new Error(
                    `Host process exited unexpectedly (code=${String(code)}, signal=${String(signal)})`,
                ),
            );
        });
    }

    private rejectAll(error: unknown) {
        if (this.pending.size === 0) {
            return;
        }
        for (const pending of this.pending.values()) {
            clearTimeout(pending.timeoutHandle);
            pending.reject(error);
        }
        this.pending.clear();
    }

    private async writeRequest(request: HostRequest) {
        if (this.closed) {
            throw new Error("Host process is closed");
        }
        const line = `${JSON.stringify(request)}\n`;
        if (this.process.stdin.write(line)) {
            return;
        }
        await once(this.process.stdin, "drain");
    }

    private async request(method: string, params?: Record<string, unknown>) {
        const id = this.nextID;
        this.nextID += 1;

        const resultPromise = new Promise<unknown>((resolve, reject) => {
            const timeoutHandle = setTimeout(() => {
                const pending = this.pending.get(id);
                if (!pending) {
                    return;
                }
                this.pending.delete(id);
                pending.reject(
                    new Error(
                        `Host request '${method}' timed out after ${this.requestTimeoutMS}ms`,
                    ),
                );
            }, this.requestTimeoutMS);
            this.pending.set(id, { resolve, reject, timeoutHandle });
        });

        try {
            await this.writeRequest({ id, method, params });
        } catch (error) {
            const pending = this.pending.get(id);
            if (pending) {
                clearTimeout(pending.timeoutHandle);
                this.pending.delete(id);
            }
            throw error;
        }
        return resultPromise;
    }

    async decodeImage(
        filePath: string,
        mimeType?: string,
    ): Promise<DecodedImage> {
        const result = (await this.request("decodeImage", {
            file_path: filePath,
            mime_type: mimeType,
        })) as { width: number; height: number; rgba_base64: string };

        if (
            typeof result?.width !== "number" ||
            typeof result?.height !== "number" ||
            typeof result?.rgba_base64 !== "string"
        ) {
            throw new Error("Invalid decodeImage response payload");
        }

        return {
            width: result.width,
            height: result.height,
            rgba: uint8ClampedArrayFromBase64(result.rgba_base64),
        };
    }

    async setDecodeHelperSource(source: string) {
        await this.request("setDecodeHelperSource", { source });
    }

    async convertToJPEG(input: Uint8Array): Promise<Uint8Array> {
        const result = (await this.request("convertToJPEG", {
            input_base64: Buffer.from(input).toString("base64"),
        })) as { output_base64: string };

        if (typeof result?.output_base64 !== "string") {
            throw new Error("Invalid convertToJPEG response payload");
        }

        return new Uint8Array(Buffer.from(result.output_base64, "base64"));
    }

    async computeCLIPImageEmbedding(
        input: Uint8ClampedArray,
        inputShape: number[],
    ): Promise<Float32Array> {
        const result = (await this.request("computeCLIPImageEmbedding", {
            input_base64: toBase64(input),
            input_shape: inputShape,
        })) as { output_base64: string };

        if (typeof result?.output_base64 !== "string") {
            throw new Error(
                "Invalid computeCLIPImageEmbedding response payload",
            );
        }

        return float32ArrayFromBase64(result.output_base64);
    }

    async detectFaces(
        input: Uint8ClampedArray,
        inputShape: number[],
    ): Promise<Float32Array> {
        const result = (await this.request("detectFaces", {
            input_base64: toBase64(input),
            input_shape: inputShape,
        })) as { output_base64: string };

        if (typeof result?.output_base64 !== "string") {
            throw new Error("Invalid detectFaces response payload");
        }

        return float32ArrayFromBase64(result.output_base64);
    }

    async computeFaceEmbeddings(input: Float32Array): Promise<Float32Array> {
        const result = (await this.request("computeFaceEmbeddings", {
            input_base64: toBase64(input),
        })) as { output_base64: string };

        if (typeof result?.output_base64 !== "string") {
            throw new Error("Invalid computeFaceEmbeddings response payload");
        }

        return float32ArrayFromBase64(result.output_base64);
    }

    async modelMetadata(): Promise<Record<string, string>> {
        const result = (await this.request("modelMetadata")) as Record<
            string,
            string
        >;
        if (!result || typeof result !== "object") {
            throw new Error("Invalid modelMetadata response payload");
        }
        return result;
    }

    async shutdown() {
        if (this.closed) {
            return;
        }

        try {
            await this.request("shutdown");
        } catch {
            // Ignore shutdown RPC failures.
        }

        this.rl.close();

        if (!this.process.killed) {
            this.process.kill();
        }
    }
}

const gitRevision = async () => {
    const { execFile } = await import("node:child_process");
    return new Promise<string>((resolve) => {
        execFile(
            "git",
            ["rev-parse", "--short", "HEAD"],
            { cwd: REPO_ROOT },
            (error, stdout) => {
                if (error) {
                    resolve("local");
                    return;
                }
                const revision = stdout.trim();
                resolve(revision || "local");
            },
        );
    });
};

const sha256Hex = async (filePath: string) => {
    const hash = crypto.createHash("sha256");

    await new Promise<void>((resolve, reject) => {
        const stream = createReadStream(filePath);
        stream.on("data", (chunk) => hash.update(chunk));
        stream.on("error", reject);
        stream.on("end", () => resolve());
    });

    return hash.digest("hex");
};

const safeFileName = (fileID: string) => fileID.replaceAll("/", "__");
const extensionFromSource = (sourcePath: string) => {
    const extension = path.extname(sourcePath).trim();
    if (!extension) {
        return ".bin";
    }
    return extension.toLowerCase();
};

const ensureModelMetadata = (metadata: Record<string, string>) => {
    const normalized = { ...metadata };
    for (const [modelName, fileName] of Object.entries(MODEL_FILE_NAMES)) {
        normalized[modelName] = normalized[modelName] || `${fileName}:unknown`;
    }
    return normalized;
};

const normalizeUnknownError = (
    error: unknown,
): { message: string; stack?: string } => {
    if (error instanceof Error) {
        return {
            message: error.message,
            ...(typeof error.stack === "string" && error.stack.length > 0
                ? { stack: error.stack }
                : {}),
        };
    }

    if (typeof error === "string") {
        return { message: error };
    }

    if (error && typeof error === "object") {
        const maybeError = error as Record<string, unknown>;
        const messageCandidate =
            (typeof maybeError.message === "string" && maybeError.message) ||
            (typeof maybeError.error === "string" && maybeError.error) ||
            stringifyUnknown(error);
        const stackCandidate =
            typeof maybeError.stack === "string" ? maybeError.stack : undefined;
        return {
            message: messageCandidate,
            ...(stackCandidate ? { stack: stackCandidate } : {}),
        };
    }

    return { message: String(error) };
};

const ensureSimilarityTransformationNodeShim = async () => {
    const dependencyDir = path.join(
        REPO_ROOT,
        "web",
        "node_modules",
        "similarity-transformation",
    );
    const packageJSONPath = path.join(dependencyDir, "package.json");

    try {
        await fs.access(packageJSONPath);
    } catch {
        return;
    }

    const packageJSON = JSON.parse(
        await fs.readFile(packageJSONPath, "utf8"),
    ) as { main?: string; module?: string };
    if (typeof packageJSON.main === "string" && packageJSON.main.trim()) {
        return;
    }

    const moduleEntry = packageJSON.module?.trim();
    if (!moduleEntry) {
        return;
    }

    const modulePath = path.join(dependencyDir, moduleEntry);
    try {
        await fs.access(modulePath);
    } catch {
        return;
    }

    const indexJSPath = path.join(dependencyDir, "index.js");
    try {
        await fs.access(indexJSPath);
        return;
    } catch {
        // Create a local shim only for parity runner compatibility under Node CJS resolution.
    }

    const normalizedEntry = moduleEntry.startsWith("./")
        ? moduleEntry
        : `./${moduleEntry}`;
    await fs.writeFile(
        indexJSPath,
        `module.exports = require("${normalizedEntry}");\n`,
    );
};

const loadWebMLBindings = async (): Promise<WebMLBindings> => {
    await ensureSimilarityTransformationNodeShim();

    const [clipModule, decodeModule, faceModule, convertModule] =
        await Promise.all([
            import("../../web/packages/new/photos/services/ml/clip.ts"),
            import("../../web/packages/new/photos/services/ml/decode.ts"),
            import("../../web/packages/new/photos/services/ml/face.ts"),
            import("../../web/packages/gallery/services/convert.ts"),
        ]);

    return {
        indexCLIP: clipModule.indexCLIP as WebMLBindings["indexCLIP"],
        indexFaces: faceModule.indexFaces as WebMLBindings["indexFaces"],
        createImageBitmapAndData:
            decodeModule.createImageBitmapAndData as WebMLBindings["createImageBitmapAndData"],
        renderableImageBlob:
            convertModule.renderableImageBlob as WebMLBindings["renderableImageBlob"],
    };
};

const productionDecodeHelperSource = (
    createImageBitmapAndData: (...args: unknown[]) => Promise<unknown>,
) => {
    const source = createImageBitmapAndData.toString();
    if (
        !source.includes("createImageBitmap") ||
        !source.includes("OffscreenCanvas")
    ) {
        throw new Error(
            "Unexpected createImageBitmapAndData source; refusing to run parity with non-production decode helper",
        );
    }
    return source;
};

const main = async () => {
    const args = parseArgs(process.argv.slice(2));

    await fs.access(args.manifestPath);
    await fs.access(args.hostScriptPath);
    await fs.access(args.electronBinPath);
    await fs.mkdir(args.outputDir, { recursive: true });
    await fs.mkdir(args.userDataPath, { recursive: true });

    const manifestPayload = JSON.parse(
        await fs.readFile(args.manifestPath, "utf8"),
    ) as { items?: ManifestItem[] };
    const items = manifestPayload.items ?? [];
    if (!items.length) {
        throw new Error(`Manifest has no items: ${args.manifestPath}`);
    }

    const webBindings = await loadWebMLBindings();
    const host = new HostClient(
        args.electronBinPath,
        args.hostScriptPath,
        args.userDataPath,
    );
    await host.setDecodeHelperSource(
        productionDecodeHelperSource(webBindings.createImageBitmapAndData),
    );

    // `renderableImageBlob` and shared logging helpers check this shim.
    (
        globalThis as {
            electron?: {
                convertToJPEG: (imageData: Uint8Array) => Promise<Uint8Array>;
                logToDisk: (message: string) => void;
            };
        }
    ).electron = {
        convertToJPEG: (imageData: Uint8Array) => host.convertToJPEG(imageData),
        logToDisk: (message: string) => {
            process.stderr.write(`${message}\n`);
        },
    };

    const codeRevision = await gitRevision();

    const electronProxy = {
        computeCLIPImageEmbedding: (
            input: Uint8ClampedArray,
            inputShape: number[],
        ) => host.computeCLIPImageEmbedding(input, inputShape),
        detectFaces: (input: Uint8ClampedArray, inputShape: number[]) =>
            host.detectFaces(input, inputShape),
        computeFaceEmbeddings: (input: Float32Array) =>
            host.computeFaceEmbeddings(input),
    };

    const partialResults: Array<{
        file_id: string;
        clip: { embedding: number[] };
        faces: Array<{
            box: [number, number, number, number];
            landmarks: [number, number][];
            score: number;
            embedding: number[];
        }>;
        timing_ms: Record<string, number>;
    }> = [];
    const errors: Array<{
        file_id: string;
        error: string;
        timing_ms: number;
        stack?: string;
    }> = [];

    try {
        for (let i = 0; i < items.length; i += 1) {
            const item = items[i]!;
            const totalStart = performance.now();
            try {
                const sourcePath = resolveMLPath(item.source);
                await fs.access(sourcePath);

                if (item.source_sha256) {
                    const sourceHash = await sha256Hex(sourcePath);
                    if (
                        sourceHash.toLowerCase() !==
                        item.source_sha256.toLowerCase()
                    ) {
                        throw new Error(
                            `source hash mismatch for ${item.file_id}: expected ${item.source_sha256}, got ${sourceHash}`,
                        );
                    }
                }

                process.stdout.write(
                    `Desktop parity indexing ${i + 1}/${items.length}: ${item.file_id}\n`,
                );

                const decodeStart = performance.now();
                const sourceBlob = new Blob([await fs.readFile(sourcePath)]);
                const renderableBlob = await webBindings.renderableImageBlob(
                    sourceBlob,
                    path.basename(sourcePath),
                );

                const renderableDir = path.join(
                    args.userDataPath,
                    "renderable-cache",
                );
                await fs.mkdir(renderableDir, { recursive: true });
                const renderablePath = path.join(
                    renderableDir,
                    `${safeFileName(item.file_id)}${extensionFromSource(sourcePath)}`,
                );
                await fs.writeFile(
                    renderablePath,
                    new Uint8Array(await renderableBlob.arrayBuffer()),
                );

                let decoded: DecodedImage;
                try {
                    decoded = await host.decodeImage(
                        renderablePath,
                        renderableBlob.type || undefined,
                    );
                } finally {
                    await fs.rm(renderablePath, { force: true });
                }
                const decodeMS = performance.now() - decodeStart;

                const imageData = {
                    width: decoded.width,
                    height: decoded.height,
                    data: decoded.rgba,
                };
                const image = { data: imageData };
                const fileStub = { id: i + 1 };

                let faceMS = 0;
                let clipMS = 0;

                const facePromise = (async () => {
                    const startedAt = performance.now();
                    const value = await webBindings.indexFaces(
                        fileStub as never,
                        image as never,
                        electronProxy as never,
                    );
                    faceMS = performance.now() - startedAt;
                    return value;
                })();

                const clipPromise = (async () => {
                    const startedAt = performance.now();
                    const value = await webBindings.indexCLIP(
                        image as never,
                        electronProxy as never,
                    );
                    clipMS = performance.now() - startedAt;
                    return value;
                })();

                const [faceIndex, clipIndex] = await Promise.all([
                    facePromise,
                    clipPromise,
                ]);

                const totalMS = performance.now() - totalStart;

                partialResults.push({
                    file_id: item.file_id,
                    clip: { embedding: clipIndex.embedding },
                    faces: faceIndex.faces.map((face) => ({
                        box: [
                            face.detection.box.x,
                            face.detection.box.y,
                            face.detection.box.width,
                            face.detection.box.height,
                        ] as [number, number, number, number],
                        landmarks: face.detection.landmarks.map(
                            (point) => [point.x, point.y] as [number, number],
                        ),
                        score: face.score,
                        embedding: face.embedding,
                    })),
                    timing_ms: {
                        decode: decodeMS,
                        face_index: faceMS,
                        clip_index: clipMS,
                        total: totalMS,
                    },
                });
            } catch (error: unknown) {
                const elapsedMS = performance.now() - totalStart;
                const normalizedError = normalizeUnknownError(error);
                process.stderr.write(
                    `[ml_parity_runner] failed to index ${item.file_id}: ${normalizedError.message}\n`,
                );
                errors.push({
                    file_id: item.file_id,
                    error: normalizedError.message,
                    timing_ms: elapsedMS,
                    ...(normalizedError.stack
                        ? { stack: normalizedError.stack }
                        : {}),
                });
            }
        }

        const models = ensureModelMetadata(await host.modelMetadata());

        const finalResults = partialResults.map((result) => ({
            file_id: result.file_id,
            clip: result.clip,
            faces: result.faces,
            runner_metadata: {
                platform: "desktop",
                runtime: "electron-onnxruntime-node",
                models,
                code_revision: codeRevision,
                timing_ms: result.timing_ms,
            },
        }));

        for (const result of finalResults) {
            const targetPath = path.join(
                args.outputDir,
                `${safeFileName(result.file_id)}.json`,
            );
            await fs.writeFile(
                targetPath,
                `${JSON.stringify(result, null, 2)}\n`,
            );
        }

        const combinedOutputPath = path.join(args.outputDir, "results.json");
        await fs.writeFile(
            combinedOutputPath,
            `${JSON.stringify(
                {
                    platform: "desktop",
                    results: finalResults,
                    ...(errors.length > 0 ? { errors } : {}),
                },
                null,
                2,
            )}\n`,
        );

        process.stdout.write(
            `Generated ${finalResults.length} desktop parity result(s) at ${args.outputDir}\n`,
        );
        if (errors.length > 0) {
            process.stdout.write(
                `Desktop parity recorded ${errors.length} per-file error(s)\n`,
            );
        }
        process.stdout.write(`Combined output: ${combinedOutputPath}\n`);
    } finally {
        await host.shutdown();
    }
};

main().catch((error: unknown) => {
    process.stderr.write(
        `${error instanceof Error ? error.stack || error.message : String(error)}\n`,
    );
    process.exit(1);
});

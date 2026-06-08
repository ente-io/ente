import type { RenderProcessGoneDetails } from "electron";
import { crashReporter } from "electron/common";
import { app, type WebContents } from "electron/main";
import http, { type IncomingMessage, type ServerResponse } from "node:http";
import type { AddressInfo } from "node:net";
import log from "../log";

const maxCrashReportBodySize = 10 * 1024 * 1024;
const recentCrashWindowMs = 15 * 1000;
const maxRecentCrashEntries = 20;

interface CrashRequestBody {
    body: Buffer;
    truncated: boolean;
}

interface RendererGoneContext {
    at: number;
    exitCode: number;
    reason: RenderProcessGoneDetails["reason"];
    url: string | undefined;
    processID: number | undefined;
}

interface OOMCrashReport {
    at: number;
    fields: Record<string, string>;
    processID: number | undefined;
    truncated: boolean;
}

let startPromise: Promise<void> | undefined;
const recentOOMCrashReports: OOMCrashReport[] = [];
const recentRendererGoneContexts: RendererGoneContext[] = [];

/**
 * Start a localhost crash report receiver and point Electron Crashpad at it.
 *
 * Electron 42 writes renderer OOM details to crash report annotations. The
 * render-process-gone event alone does not include those annotations.
 */
export const startLocalCrashReporter = (): Promise<void> => {
    startPromise ??= startCrashReporter();
    return startPromise;
};

export const logRenderProcessGone = (
    webContents: WebContents,
    details: RenderProcessGoneDetails,
) => {
    const context: RendererGoneContext = {
        at: Date.now(),
        exitCode: details.exitCode,
        reason: details.reason,
        url: webContentsURL(webContents),
        processID: webContentsProcessID(webContents),
    };
    recentRendererGoneContexts.push(context);
    pruneRecentEntries();

    const report = findRecentOOMCrashReport(context);
    const lines = [
        `render-process-gone: ${details.reason}`,
        `exitCode=${details.exitCode}`,
        `rendererProcessID=${context.processID ?? "unknown"}`,
        `url=${context.url ?? "unknown"}`,
    ];

    if (report) {
        lines.push(
            `recentOOMCrashReport=true`,
            `oomCrashReportAgeMs=${context.at - report.at}`,
        );
    } else if (details.reason == "oom" || details.reason == "crashed") {
        lines.push("recentOOMCrashReport=false");
    }

    log.error(lines.join("\n"));
};

const startCrashReporter = async (): Promise<void> =>
    new Promise((resolve) => {
        const server = http.createServer(handleCrashReportRequest);

        server.once("error", (e) => {
            log.warn("Failed to start local crash report receiver", e);
            resolve();
        });

        server.listen(0, "127.0.0.1", () => {
            const address = server.address();
            if (!address || typeof address == "string") {
                log.warn("Failed to resolve local crash report receiver port");
                server.close();
                resolve();
                return;
            }

            try {
                startElectronCrashReporter(address);
                log.info("Started local crash report receiver", {
                    port: address.port,
                });
            } catch (e) {
                log.warn("Failed to start Electron crash reporter", e);
                server.close();
            }

            resolve();
        });
    });

const startElectronCrashReporter = (address: AddressInfo) => {
    crashReporter.start({
        submitURL: `http://127.0.0.1:${address.port}/crash`,
        uploadToServer: true,
        compress: false,
        rateLimit: false,
        globalExtra: {
            appVersion: app.getVersion(),
            electronVersion: process.versions.electron,
            platform: process.platform,
            arch: process.arch,
        },
    });
};

const handleCrashReportRequest = (
    request: IncomingMessage,
    response: ServerResponse,
) => {
    void handleCrashReportRequestAsync(request, response).catch(
        (e: unknown) => {
            log.warn("Failed to handle local crash report", e);
            response.writeHead(500, { "Content-Type": "text/plain" });
            response.end("error");
        },
    );
};

const handleCrashReportRequestAsync = async (
    request: IncomingMessage,
    response: ServerResponse,
) => {
    if (request.method != "POST") {
        response.writeHead(404, { "Content-Type": "text/plain" });
        response.end("not found");
        return;
    }

    const contentType = request.headers["content-type"];
    const boundary =
        typeof contentType == "string"
            ? multipartBoundary(contentType)
            : undefined;
    const { body, truncated } = await readRequestBody(request);
    if (!boundary) {
        log.warn("Received crash report without multipart boundary");
    } else {
        const fields = parseMultipartTextFields(body, boundary);
        recordCrashReport(fields, truncated);
    }

    response.writeHead(200, { "Content-Type": "text/plain" });
    response.end(`local-${Date.now().toString(36)}`);
};

const readRequestBody = (request: IncomingMessage): Promise<CrashRequestBody> =>
    new Promise((resolve, reject) => {
        const chunks: Buffer[] = [];
        let size = 0;
        let truncated = false;

        request.on("data", (chunk: Buffer) => {
            size += chunk.length;
            if (size <= maxCrashReportBodySize) {
                chunks.push(chunk);
            } else {
                truncated = true;
                const remaining = Math.max(
                    0,
                    maxCrashReportBodySize - (size - chunk.length),
                );
                if (remaining > 0) chunks.push(chunk.subarray(0, remaining));
            }
        });
        request.on("end", () =>
            resolve({ body: Buffer.concat(chunks), truncated }),
        );
        request.on("error", reject);
    });

const multipartBoundary = (contentType: string): string | undefined => {
    const match = /(?:^|;\s*)boundary=(?:"([^"]+)"|([^;]+))/i.exec(contentType);
    return match?.[1] ?? match?.[2]?.trim();
};

const parseMultipartTextFields = (
    body: Buffer,
    boundary: string,
): Record<string, string> => {
    const fields: Record<string, string> = {};
    const delimiter = Buffer.from(`--${boundary}`);
    let delimiterIndex = body.indexOf(delimiter);

    while (delimiterIndex != -1) {
        let partStart = delimiterIndex + delimiter.length;
        if (body.subarray(partStart, partStart + 2).equals(Buffer.from("--"))) {
            break;
        }
        if (
            body.subarray(partStart, partStart + 2).equals(Buffer.from("\r\n"))
        ) {
            partStart += 2;
        }

        const nextDelimiterIndex = body.indexOf(delimiter, partStart);
        const partEnd =
            nextDelimiterIndex == -1 ? body.length : nextDelimiterIndex;
        const part = body.subarray(partStart, partEnd);
        const headerEnd = part.indexOf(Buffer.from("\r\n\r\n"));
        if (headerEnd != -1) {
            const headers = part.subarray(0, headerEnd).toString("latin1");
            const fieldName = multipartFieldName(headers);
            if (fieldName && !/;\s*filename=/i.test(headers)) {
                fields[fieldName] = trimTrailingCRLF(
                    part.subarray(headerEnd + 4),
                ).toString("utf8");
            }
        }

        delimiterIndex = nextDelimiterIndex;
    }

    return fields;
};

const multipartFieldName = (headers: string): string | undefined => {
    const match = /content-disposition:[^\r\n]*;\s*name="([^"]+)"/i.exec(
        headers,
    );
    return match?.[1];
};

const trimTrailingCRLF = (buffer: Buffer): Buffer =>
    buffer.subarray(-2).equals(Buffer.from("\r\n"))
        ? buffer.subarray(0, -2)
        : buffer;

const recordCrashReport = (
    fields: Record<string, string>,
    truncated: boolean,
) => {
    const oomFields = oomCrashFields(fields);
    if (Object.keys(oomFields).length == 0) return;

    const report: OOMCrashReport = {
        at: Date.now(),
        fields,
        processID: processIDFromCrashReport(fields),
        truncated,
    };
    recentOOMCrashReports.push(report);
    pruneRecentEntries();

    log.error(
        formatOOMCrashReport(report, findRecentRendererGoneContext(report)),
    );
};

const oomCrashFields = (
    fields: Record<string, string>,
): Record<string, string> =>
    Object.fromEntries(
        Object.entries(fields).filter(([key]) =>
            key.startsWith("electron.v8-oom."),
        ),
    );

const formatOOMCrashReport = (
    report: OOMCrashReport,
    rendererGoneContext: RendererGoneContext | undefined,
): string => {
    const fields = report.fields;
    const oomFields = oomCrashFields(fields);
    const stack = oomFields["electron.v8-oom.stack"] ?? "(missing)";
    const oomFieldLines = Object.keys(oomFields)
        .filter((key) => key != "electron.v8-oom.stack")
        .sort()
        .map((key) => `${key}=${oomFields[key] ?? "unknown"}`);
    const lines = [
        "Renderer OOM crash report received",
        `process_type=${fields.process_type ?? "unknown"}`,
        `rendererProcessID=${report.processID ?? "unknown"}`,
        `uploadTruncated=${report.truncated}`,
        ...oomFieldLines,
    ];

    if (rendererGoneContext) {
        lines.push(
            `recentRenderProcessGone=true`,
            `renderProcessGoneAgeMs=${report.at - rendererGoneContext.at}`,
            `renderProcessGoneReason=${rendererGoneContext.reason}`,
            `renderProcessGoneExitCode=${rendererGoneContext.exitCode}`,
            `url=${rendererGoneContext.url ?? "unknown"}`,
        );
    }

    lines.push("electron.v8-oom.stack:", stack);
    return lines.join("\n");
};

const findRecentOOMCrashReport = (
    context: RendererGoneContext,
): OOMCrashReport | undefined =>
    recentOOMCrashReports
        .slice()
        .reverse()
        .find(
            (report) =>
                context.at - report.at <= recentCrashWindowMs &&
                processIDsMatch(context.processID, report.processID),
        );

const findRecentRendererGoneContext = (
    report: OOMCrashReport,
): RendererGoneContext | undefined =>
    recentRendererGoneContexts
        .slice()
        .reverse()
        .find(
            (context) =>
                report.at - context.at <= recentCrashWindowMs &&
                processIDsMatch(context.processID, report.processID),
        );

const processIDsMatch = (
    contextProcessID: number | undefined,
    reportProcessID: number | undefined,
): boolean =>
    contextProcessID == undefined ||
    reportProcessID == undefined ||
    contextProcessID == reportProcessID;

const processIDFromCrashReport = (
    fields: Record<string, string>,
): number | undefined =>
    parseIntegerField(fields.pid) ?? parseIntegerField(fields.process_id);

const parseIntegerField = (field: string | undefined): number | undefined => {
    if (!field) return undefined;
    const value = Number.parseInt(field, 10);
    return Number.isFinite(value) ? value : undefined;
};

const pruneRecentEntries = () => {
    const oldest = Date.now() - recentCrashWindowMs;
    pruneByAgeAndCount(recentOOMCrashReports, oldest);
    pruneByAgeAndCount(recentRendererGoneContexts, oldest);
};

const pruneByAgeAndCount = (entries: { at: number }[], oldest: number) => {
    while (entries.length > 0 && entries[0]!.at < oldest) entries.shift();
    while (entries.length > maxRecentCrashEntries) entries.shift();
};

const webContentsURL = (webContents: WebContents): string | undefined => {
    try {
        return webContents.getURL() || undefined;
    } catch {
        return undefined;
    }
};

const webContentsProcessID = (webContents: WebContents): number | undefined => {
    try {
        const processID = webContents.getProcessId();
        return processID > 0 ? processID : undefined;
    } catch {
        return undefined;
    }
};

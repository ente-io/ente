/**
 * @file stream data to-from renderer using a custom protocol handler.
 */
import { net, protocol } from "electron/main";
import { randomUUID } from "node:crypto";
import { createWriteStream, existsSync } from "node:fs";
import fs from "node:fs/promises";
import { Readable } from "node:stream";
import { ReadableStream } from "node:stream/web";
import { pathToFileURL } from "node:url";
import log from "./log";
import { ffmpegConvertToMP4 } from "./services/ffmpeg";
import { markClosableZip, openZip } from "./services/zip";
import { ensure } from "./utils/common";
import {
    deleteTempFile,
    deleteTempFileIgnoringErrors,
    makeTempFilePath,
} from "./utils/temp";

/**
 * Register a protocol handler that we use for streaming large files between the
 * main (Node.js) and renderer (Chromium) processes.
 *
 * [Note: IPC streams]
 *
 * When running without node integration, there is no direct way to pass streams
 * across IPC. And passing the entire contents of the file is not feasible for
 * large video files because of the memory pressure the copying would entail.
 *
 * As an alternative, we register a custom protocol handler that can provides a
 * bi-directional stream. The renderer can stream data to the node side by
 * streaming the request. The node side can stream to the renderer side by
 * streaming the response.
 *
 * The stream is not full duplex - while both reads and writes can be streamed,
 * they need to be streamed separately.
 *
 * See also: [Note: Transferring large amount of data over IPC]
 *
 * Depends on {@link registerPrivilegedSchemes}.
 */
export const registerStreamProtocol = () => {
    protocol.handle("stream", (request: Request) => {
        try {
            return handleStreamRequest(request);
        } catch (e) {
            log.error(`Failed to handle stream request for ${request.url}`, e);
            return new Response(String(e), { status: 500 });
        }
    });
};

const handleStreamRequest = async (request: Request): Promise<Response> => {
    const url = request.url;
    // The request URL contains the command to run as the host, and the
    // pathname of the file(s) as the search params.
    const { host, searchParams } = new URL(url);
    switch (host) {
        case "read":
            return handleRead(ensure(searchParams.get("path")));

        case "read-zip":
            return handleReadZip(
                ensure(searchParams.get("zipPath")),
                ensure(searchParams.get("entryName")),
            );

        case "write":
            return handleWrite(ensure(searchParams.get("path")), request);

        case "convert-to-mp4": {
            const token = searchParams.get("token");
            const done = searchParams.get("done") !== null;
            return token
                ? done
                    ? handleConvertToMP4ReadDone(token)
                    : handleConvertToMP4Read(token)
                : handleConvertToMP4Write(request);
        }

        default:
            return new Response("", { status: 404 });
    }
};

const handleRead = async (path: string) => {
    const res = await net.fetch(pathToFileURL(path).toString());
    if (res.ok) {
        // net.fetch already seems to add "Content-Type" and "Last-Modified"
        // headers, but I couldn't find documentation for this. In any case,
        // since we already are stat-ting the file for the "Content-Length", we
        // explicitly add the "X-Last-Modified-Ms" too,
        //
        // 1. Guaranteeing its presence,
        //
        // 2. Having it be in the exact format we want (no string <-> date
        //    conversions),
        //
        // 3. Retaining milliseconds.

        const stat = await fs.stat(path);

        // Add the file's size as the Content-Length header.
        const fileSize = stat.size;
        res.headers.set("Content-Length", `${fileSize}`);

        // Add the file's last modified time (as epoch milliseconds).
        const mtimeMs = stat.mtime.getTime();
        res.headers.set("X-Last-Modified-Ms", `${mtimeMs}`);
    }
    return res;
};

const handleReadZip = async (zipPath: string, entryName: string) => {
    const zip = openZip(zipPath);
    const entry = await zip.entry(entryName);
    if (!entry) {
        markClosableZip(zipPath);
        return new Response("", { status: 404 });
    }

    // This returns an "old style" NodeJS.ReadableStream.
    const stream = await zip.stream(entry);
    // Convert it into a new style NodeJS.Readable.
    const nodeReadable = new Readable({ emitClose: true }).wrap(stream);
    // Then convert it into a Web stream.
    const webReadableStreamAny = Readable.toWeb(nodeReadable);
    // However, we get a ReadableStream<any> now. This doesn't go into the
    // `BodyInit` expected by the Response constructor, which wants a
    // ReadableStream<Uint8Array>. Force a cast.
    const webReadableStream =
        webReadableStreamAny as ReadableStream<Uint8Array>;

    // Let go of the zip handle when the underlying stream closes.
    nodeReadable.on("close", () => markClosableZip(zipPath));

    // While it is documented that entry.time is the modification time,
    // the units are not mentioned. By seeing the source code, we can
    // verify that it is indeed epoch milliseconds. See `parseZipTime`
    // in the node-stream-zip source,
    // https://github.com/antelle/node-stream-zip/blob/master/node_stream_zip.js
    const modifiedMs = entry.time;

    return new Response(webReadableStream, {
        headers: {
            // We don't know the exact type, but it doesn't really matter, just
            // set it to a generic binary content-type so that the browser
            // doesn't tinker with it thinking of it as text.
            "Content-Type": "application/octet-stream",
            "Content-Length": `${entry.size}`,
            "X-Last-Modified-Ms": `${modifiedMs}`,
        },
    });
};

const handleWrite = async (path: string, request: Request) => {
    await writeStream(path, ensure(request.body));
    return new Response("", { status: 200 });
};

/**
 * Write a (web) ReadableStream to a file at the given {@link filePath}.
 *
 * The returned promise resolves when the write completes.
 *
 * @param filePath The local file system path where the file should be written.
 *
 * @param readableStream A web
 * [ReadableStream](https://developer.mozilla.org/en-US/docs/Web/API/ReadableStream).
 */
export const writeStream = (filePath: string, readableStream: ReadableStream) =>
    writeNodeStream(filePath, Readable.fromWeb(readableStream));

const writeNodeStream = async (filePath: string, fileStream: Readable) => {
    const writeable = createWriteStream(filePath);

    fileStream.on("error", (err) => {
        writeable.destroy(err); // Close the writable stream with an error
    });

    fileStream.pipe(writeable);

    await new Promise((resolve, reject) => {
        writeable.on("finish", resolve);
        writeable.on("error", (err) => {
            if (existsSync(filePath)) {
                void fs.unlink(filePath);
            }
            reject(err);
        });
    });
};

/**
 * A map from token to file paths for convert-to-mp4 requests that we have
 * received.
 */
const convertToMP4Results = new Map<string, string>();

/**
 * Clear any in-memory state for in-flight convert-to-mp4 requests. Meant to be
 * called during logout.
 */
export const clearConvertToMP4Results = () => convertToMP4Results.clear();

/**
 * [Note: Convert to MP4]
 *
 * When we want to convert a video to MP4, if we were to send the entire
 * contents of the video from the renderer to the main process over IPC, it just
 * causes the renderer to run out of memory and restart when the videos are very
 * large. So we need to stream the original video renderer → main and then
 * stream back the converted video renderer ← main.
 *
 * Currently Chromium does not support bi-directional streaming ("full" duplex
 * mode for the Web fetch API). So we need to simulate that using two different
 * streaming requests.
 *
 *     renderer → main  stream://convert-to-mp4
 *                      → request.body is the original video
 *                      ← response is a token
 *
 *     renderer → main  stream://convert-to-mp4?token=<token>
 *                      ← response.body is the converted video
 *
 *     renderer → main  stream://convert-to-mp4?token=<token>&done
 *                      ← 200 OK
 *
 * Note that the conversion itself is not streaming. The conversion still
 * happens in a single shot, we are just streaming the data across the IPC
 * boundary to allow us to pass large amounts of data without running out of
 * memory.
 *
 * See also: [Note: IPC streams]
 */
const handleConvertToMP4Write = async (request: Request) => {
    const inputTempFilePath = await makeTempFilePath();
    await writeStream(inputTempFilePath, ensure(request.body));

    const outputTempFilePath = await makeTempFilePath("mp4");
    try {
        await ffmpegConvertToMP4(inputTempFilePath, outputTempFilePath);
    } catch (e) {
        log.error("Conversion to MP4 failed", e);
        await deleteTempFileIgnoringErrors(outputTempFilePath);
        throw e;
    } finally {
        await deleteTempFileIgnoringErrors(inputTempFilePath);
    }

    const token = randomUUID();
    convertToMP4Results.set(token, outputTempFilePath);
    return new Response(token, { status: 200 });
};

const handleConvertToMP4Read = async (token: string) => {
    const filePath = convertToMP4Results.get(token);
    if (!filePath)
        return new Response(`Unknown token ${token}`, { status: 404 });

    return net.fetch(pathToFileURL(filePath).toString());
};

const handleConvertToMP4ReadDone = async (token: string) => {
    const filePath = convertToMP4Results.get(token);
    if (!filePath)
        return new Response(`Unknown token ${token}`, { status: 404 });

    await deleteTempFile(filePath);

    convertToMP4Results.delete(token);
    return new Response("", { status: 200 });
};

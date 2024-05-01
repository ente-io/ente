/**
 * @file stream data to-from renderer using a custom protocol handler.
 */
import { net, protocol } from "electron/main";
import StreamZip from "node-stream-zip";
import { createWriteStream, existsSync } from "node:fs";
import fs from "node:fs/promises";
import { Readable } from "node:stream";
import { ReadableStream } from "node:stream/web";
import { pathToFileURL } from "node:url";
import log from "./log";
import { ensure } from "./utils/common";

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
    protocol.handle("stream", async (request: Request) => {
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
            default:
                return new Response("", { status: 404 });
        }
    });
};

const handleRead = async (path: string) => {
    try {
        const res = await net.fetch(pathToFileURL(path).toString());
        if (res.ok) {
            // net.fetch already seems to add "Content-Type" and "Last-Modified"
            // headers, but I couldn't find documentation for this. In any case,
            // since we already are stat-ting the file for the "Content-Length",
            // we explicitly add the "X-Last-Modified-Ms" too,
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
            const mtimeMs = stat.mtimeMs;
            res.headers.set("X-Last-Modified-Ms", `${mtimeMs}`);
        }
        return res;
    } catch (e) {
        log.error(`Failed to read stream at ${path}`, e);
        return new Response(`Failed to read stream: ${String(e)}`, {
            status: 500,
        });
    }
};

const handleReadZip = async (zipPath: string, entryName: string) => {
    try {
        const zip = new StreamZip.async({ file: zipPath });
        const entry = await zip.entry(entryName);
        if (!entry) return new Response("", { status: 404 });

        // This returns an "old style" NodeJS.ReadableStream.
        const stream = await zip.stream(entry);
        // Convert it into a new style NodeJS.Readable.
        const nodeReadable = new Readable().wrap(stream);
        // Then convert it into a Web stream.
        const webReadableStreamAny = Readable.toWeb(nodeReadable);
        // However, we get a ReadableStream<any> now. This doesn't go into the
        // `BodyInit` expected by the Response constructor, which wants a
        // ReadableStream<Uint8Array>. Force a cast.
        const webReadableStream =
            webReadableStreamAny as ReadableStream<Uint8Array>;

        // Close the zip handle when the underlying stream closes.
        stream.on("end", () => void zip.close());

        return new Response(webReadableStream, {
            headers: {
                // We don't know the exact type, but it doesn't really matter,
                // just set it to a generic binary content-type so that the
                // browser doesn't tinker with it thinking of it as text.
                "Content-Type": "application/octet-stream",
                "Content-Length": `${entry.size}`,
                // While it is documented that entry.time is the modification
                // time, the units are not mentioned. By seeing the source code,
                // we can verify that it is indeed epoch milliseconds. See
                // `parseZipTime` in the node-stream-zip source,
                // https://github.com/antelle/node-stream-zip/blob/master/node_stream_zip.js
                "X-Last-Modified-Ms": `${entry.time}`,
            },
        });
    } catch (e) {
        log.error(
            `Failed to read entry ${entryName} from zip file at ${zipPath}`,
            e,
        );
        return new Response(`Failed to read stream: ${String(e)}`, {
            status: 500,
        });
    }
};

const handleWrite = async (path: string, request: Request) => {
    try {
        await writeStream(path, ensure(request.body));
        return new Response("", { status: 200 });
    } catch (e) {
        log.error(`Failed to write stream to ${path}`, e);
        return new Response(`Failed to write stream: ${String(e)}`, {
            status: 500,
        });
    }
};

/**
 * Write a (web) ReadableStream to a file at the given {@link filePath}.
 *
 * The returned promise resolves when the write completes.
 *
 * @param filePath The local filesystem path where the file should be written.
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

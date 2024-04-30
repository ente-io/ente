/**
 * @file stream data to-from renderer using a custom protocol handler.
 */
import { net, protocol } from "electron/main";
import StreamZip from "node-stream-zip";
import { createWriteStream, existsSync } from "node:fs";
import fs from "node:fs/promises";
import { Readable } from "node:stream";
import { pathToFileURL } from "node:url";
import log from "./log";

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
        // pathname of the file as the path. An additional path can be specified
        // as the URL hash.
        //
        // For example,
        //
        //     stream://write/path/to/file#/path/to/another/file
        //              host[pathname----] [pathname-2---------]
        //
        const { host, pathname, hash } = new URL(url);
        // Convert e.g. "%20" to spaces.
        const path = decodeURIComponent(pathname);
        const hashPath = decodeURIComponent(hash);
        switch (host) {
            case "read":
                return handleRead(path);
            case "read-zip":
                return handleReadZip(path, hashPath);
            case "write":
                return handleWrite(path, request);
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
        return new Response(`Failed to read stream: ${e.message}`, {
            status: 500,
        });
    }
};

const handleReadZip = async (zipPath: string, zipEntryPath: string) => {
    try {
        const zip = new StreamZip.async({ file: zipPath });
        const entry = await zip.entry(zipEntryPath);
        const stream = await zip.stream(entry);

        return new Response(Readable.toWeb(new Readable(stream)), {
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
            `Failed to read entry ${zipEntryPath} from zip file at ${zipPath}`,
            e,
        );
        return new Response(`Failed to read stream: ${e.message}`, {
            status: 500,
        });
    }
};

const handleWrite = async (path: string, request: Request) => {
    try {
        await writeStream(path, request.body);
        return new Response("", { status: 200 });
    } catch (e) {
        log.error(`Failed to write stream to ${path}`, e);
        return new Response(`Failed to write stream: ${e.message}`, {
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
 * @param readableStream A [web
 * ReadableStream](https://developer.mozilla.org/en-US/docs/Web/API/ReadableStream)
 */
export const writeStream = (filePath: string, readableStream: ReadableStream) =>
    writeNodeStream(filePath, convertWebReadableStreamToNode(readableStream));

/**
 * Convert a Web ReadableStream into a Node.js ReadableStream
 *
 * This can be used to, for example, write a ReadableStream obtained via
 * `net.fetch` into a file using the Node.js `fs` APIs
 */
const convertWebReadableStreamToNode = (readableStream: ReadableStream) => {
    const reader = readableStream.getReader();
    const rs = new Readable();

    rs._read = async () => {
        try {
            const result = await reader.read();

            if (!result.done) {
                rs.push(Buffer.from(result.value));
            } else {
                rs.push(null);
                return;
            }
        } catch (e) {
            rs.emit("error", e);
        }
    };

    return rs;
};

const writeNodeStream = async (filePath: string, fileStream: Readable) => {
    const writeable = createWriteStream(filePath);

    fileStream.on("error", (error) => {
        writeable.destroy(error); // Close the writable stream with an error
    });

    fileStream.pipe(writeable);

    await new Promise((resolve, reject) => {
        writeable.on("finish", resolve);
        writeable.on("error", async (e: unknown) => {
            if (existsSync(filePath)) {
                await fs.unlink(filePath);
            }
            reject(e);
        });
    });
};

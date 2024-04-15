/**
 * @file stream data to-from renderer using a custom protocol handler.
 */
import { protocol } from "electron/main";
import { createWriteStream, existsSync } from "node:fs";
import fs from "node:fs/promises";
import { Readable } from "node:stream";
import log from "./log";

/**
 * Register a protocol handler that we use for streaming large files between the
 * main process (node) and the renderer process (browser) layer.
 *
 * [Note: IPC streams]
 *
 * When running without node integration, there is no direct way to pass streams
 * across IPC. And passing the entire contents of the file is not feasible for
 * large video files because of the memory pressure the copying would entail.
 *
 * As an alternative, we register a custom protocol handler that can provided a
 * bi-directional stream. The renderer can stream data to the node side by
 * streaming the request. The node side can stream to the renderer side by
 * streaming the response.
 *
 * See also: [Note: Transferring large amount of data over IPC]
 *
 * Depends on {@link registerPrivilegedSchemes}.
 */
export const registerStreamProtocol = () => {
    protocol.handle("stream", async (request: Request) => {
        const url = request.url;
        const { host, pathname } = new URL(url);
        switch (host) {
            /* stream://write//path/to/file */
            /*          -host/pathname----- */
            case "write":
                try {
                    await writeStream(pathname, request.body);
                    return new Response("", { status: 200 });
                } catch (e) {
                    log.error(`Failed to write stream for ${url}`, e);
                    return new Response(
                        `Failed to write stream: ${e.message}`,
                        { status: 500 },
                    );
                }
            default:
                return new Response("", { status: 404 });
        }
    });
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

const writeNodeStream = async (
    filePath: string,
    fileStream: NodeJS.ReadableStream,
) => {
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

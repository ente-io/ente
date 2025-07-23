import { createWriteStream, existsSync } from "node:fs";
import fs from "node:fs/promises";
import { Readable } from "node:stream";

/**
 * Write a (web) ReadableStream to a file at the given {@link filePath}.
 *
 * The returned promise resolves when the write completes.
 *
 * @param filePath The local file system path where the file should be written.
 *
 * @param readableStream A web
 * [ReadableStream](https://developer.mozilla.org/en-US/docs/Web/API/ReadableStream).
 *
 */
export const writeStream = (
    filePath: string,
    readableStream: unknown /*ReadableStream*/, // @ts-expect-error [Note: Node and web stream type mismatch]
) => writeNodeStream(filePath, Readable.fromWeb(readableStream));

const writeNodeStream = async (filePath: string, fileStream: Readable) => {
    const writeable = createWriteStream(filePath);

    fileStream.on("error", (err) => {
        writeable.destroy(err); // Close the writable stream with an error
    });

    fileStream.pipe(writeable);

    await new Promise<void>((resolve, reject) => {
        writeable.on("finish", resolve);
        writeable.on("error", (err) => {
            if (existsSync(filePath)) {
                void fs.unlink(filePath);
            }
            reject(err);
        });
    });
};

/**
 * @file Streaming IPC communication with the Node.js layer of our desktop app.
 *
 * NOTE: These functions only work when we're running in our desktop app.
 *
 * See: [Note: IPC streams].
 */

import type { Electron, ElectronMLWorker, ZipItem } from "@/base/types/ipc";

/**
 * Stream the given file or zip entry from the user's local file system.
 *
 * This only works when we're running in our desktop app since it uses the
 * "stream://" protocol handler exposed by our custom code in the Node.js layer.
 * See: [Note: IPC streams].
 *
 * To avoid accidentally invoking it in a non-desktop app context, it requires
 * the {@link Electron} (or a functionally similar) object as a parameter (even
 * though it doesn't need or use it).
 *
 * @param pathOrZipItem Either the path on the file on the user's local file
 * system whose contents we want to stream. Or a tuple containing the path to a
 * zip file and the name of the entry within it.
 *
 * @return A ({@link Response}, size, lastModifiedMs) triple.
 *
 * * The response contains the contents of the file. In particular, the `body`
 *   {@link ReadableStream} property of this response can be used to read the
 *   files contents in a streaming manner.
 *
 * * The size is the size of the file that we'll be reading from disk.
 *
 * * The lastModifiedMs value is the last modified time of the file that we're
 *   reading, expressed as epoch milliseconds.
 */
export const readStream = async (
    _: Electron | ElectronMLWorker,
    pathOrZipItem: string | ZipItem,
): Promise<{ response: Response; size: number; lastModifiedMs: number }> => {
    let url: URL;
    if (typeof pathOrZipItem == "string") {
        const params = new URLSearchParams({ path: pathOrZipItem });
        url = new URL(`stream://read?${params.toString()}`);
    } else {
        const [zipPath, entryName] = pathOrZipItem;
        const params = new URLSearchParams({ zipPath, entryName });
        url = new URL(`stream://read-zip?${params.toString()}`);
    }

    const req = new Request(url, { method: "GET" });

    const res = await fetch(req);
    if (!res.ok)
        throw new Error(
            `Failed to read stream from ${url.href}: HTTP ${res.status}`,
        );

    const size = readNumericHeader(res, "Content-Length");
    const lastModifiedMs = readNumericHeader(res, "X-Last-Modified-Ms");

    return { response: res, size, lastModifiedMs };
};

const readNumericHeader = (res: Response, key: string) => {
    const valueText = res.headers.get(key);
    const value = valueText === null ? NaN : +valueText;
    if (isNaN(value))
        throw new Error(
            `Expected a numeric ${key} when reading a stream response, instead got ${valueText}`,
        );
    return value;
};

/**
 * Write the given stream to a file on the local machine.
 *
 * This only works when we're running in our desktop app since it uses the
 * "stream://" protocol handler exposed by our custom code in the Node.js layer.
 * See: [Note: IPC streams].
 *
 * To avoid accidentally invoking it in a non-desktop app context, it requires
 * the {@link Electron} object as a parameter (even though it doesn't use it).
 *
 * @param path The path on the local machine where to write the file to.
 *
 * @param stream The stream which should be written into the file.
 */
export const writeStream = async (
    _: Electron,
    path: string,
    stream: ReadableStream,
) => {
    const params = new URLSearchParams({ path });
    const url = new URL(`stream://write?${params.toString()}`);

    // The duplex parameter needs to be set to 'half' when streaming requests.
    //
    // Currently browsers, and specifically in our case, since this code runs
    // only within our desktop (Electron) app, Chromium, don't support 'full'
    // duplex mode (i.e. streaming both the request and the response).
    // https://developer.chrome.com/docs/capabilities/web-apis/fetch-streaming-requests
    const req = new Request(url, {
        // GET can't have a body
        method: "POST",
        body: stream,
        // @ts-expect-error TypeScript's libdom.d.ts does not include the
        // "duplex" parameter, e.g. see
        // https://github.com/node-fetch/node-fetch/issues/1769.
        duplex: "half",
    });

    const res = await fetch(req);
    if (!res.ok)
        throw new Error(
            `Failed to write stream to ${url.href}: HTTP ${res.status}`,
        );
};

/**
 * Variant of {@link writeStream} tailored for video conversion.
 *
 * @param blob The video to convert.
 *
 * @returns a token that can then be passed to {@link readConvertToMP4Stream} to
 * read back the converted video. See: [Note: Convert to MP4].
 */
export const writeConvertToMP4Stream = async (_: Electron, blob: Blob) => {
    const url = "stream://convert-to-mp4";

    const req = new Request(url, {
        method: "POST",
        body: blob,
        // @ts-expect-error TypeScript's libdom.d.ts does not include the
        // "duplex" parameter, e.g. see
        // https://github.com/node-fetch/node-fetch/issues/1769.
        duplex: "half",
    });

    const res = await fetch(req);
    if (!res.ok)
        throw new Error(`Failed to write stream to ${url}: HTTP ${res.status}`);

    const token = res.text();
    return token;
};

/**
 * Variant of {@link readStream} tailored for video conversion.
 *
 * @param token A token obtained from {@link writeConvertToMP4Stream}.
 *
 * @returns the contents of the converted video. See: [Note: Convert to MP4].
 */
export const readConvertToMP4Stream = async (
    _: Electron,
    token: string,
): Promise<Blob> => {
    const params = new URLSearchParams({ token });
    const url = new URL(`stream://convert-to-mp4?${params.toString()}`);

    const req = new Request(url, { method: "GET" });

    const res = await fetch(req);
    if (!res.ok)
        throw new Error(
            `Failed to read stream from ${url.href}: HTTP ${res.status}`,
        );

    return res.blob();
};

/**
 * Sibling of {@link readConvertToMP4Stream} to let the native side know when we
 * are done reading the response, and they can dispose any temporary resources
 * it was using.
 *
 * @param token A token obtained from {@link writeConvertToMP4Stream}.
 */
export const readConvertToMP4Done = async (
    _: Electron,
    token: string,
): Promise<void> => {
    // The value for `done` is arbitrary, only its presence matters.
    const params = new URLSearchParams({ token, done: "1" });
    const url = new URL(`stream://convert-to-mp4?${params.toString()}`);

    const req = new Request(url, { method: "GET" });
    const res = await fetch(req);
    if (!res.ok)
        throw new Error(
            `Failed to close stream at ${url.href}: HTTP ${res.status}`,
        );
};

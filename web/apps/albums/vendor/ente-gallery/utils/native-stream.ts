/**
 * @file Streaming IPC communication with the Node.js layer of our desktop app.
 *
 * NOTE: These functions only work when we're running in our desktop app.
 *
 * See: [Note: IPC streams].
 */

import type { ZipItem } from "ente-base/types/ipc";

/**
 * Stream the given file or zip entry from the user's local file system.
 *
 * This only works when we're running in our desktop app since it uses the
 * "stream://" protocol handler exposed by our custom code in the Node.js layer.
 * See: [Note: IPC streams].
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
 * @param path The path on the local machine where to write the file to.
 *
 * @param stream The stream which should be written into the file.
 */
export const writeStream = async (
    path: string,
    stream: ReadableStream | null,
) => {
    const params = new URLSearchParams({ path });
    const url = new URL(`stream://write?${params.toString()}`);

    // The duplex parameter needs to be set to 'half' when streaming requests.
    //
    // Currently browsers, and specifically in our case, the desktop Chromium
    // runtime, don't support 'full' duplex mode (i.e. streaming both the
    // request and the response).
    // https://developer.chrome.com/docs/capabilities/web-apis/fetch-streaming-requests
    const req = new Request(url, {
        // GET can't have a body
        method: "POST",
        // [Note: duplex param required for stream body]
        //
        // The duplex parameter needs to be set to 'half' when streaming
        // requests. However, TypeScript's libdom.d.ts does not include the
        // "duplex" parameter, so we need to silence the tsc error. e.g. see
        // https://github.com/node-fetch/node-fetch/issues/1769.
        //
        // @ts-expect-error See: [Note: duplex param required for stream body]
        duplex: "half",
        body: stream,
    });

    const res = await fetch(req);
    if (!res.ok)
        throw new Error(
            `Failed to write stream to ${url.href}: HTTP ${res.status}`,
        );
};

/**
 * Initate a conversion to MP4, streaming the video contents to the node side.
 *
 * This is a variant of {@link writeStream} tailored for the conversion to MP4.
 *
 * @param video A {@link Blob} containing the video to convert.
 *
 * @returns a token that can then be passed to {@link readVideoStream} to
 * retrieve the converted MP4 file. This three step sequence (write/read/done)
 * can then be ended by using {@link videoStreamDone}).
 *
 * See: [Note: Convert to MP4].
 */
export const initiateConvertToMP4 = async (video: Blob): Promise<string> => {
    const url = "stream://video?op=convert-to-mp4";
    const res = await fetch(url, { method: "POST", body: video });
    if (!res.ok)
        throw new Error(`Failed to write stream to ${url}: HTTP ${res.status}`);
    return res.text();
};

/**
 * Variant of {@link readStream} tailored for video conversion.
 *
 * @param token A token obtained from a video conversion operation like
 * {@link initiateConvertToMP4}.
 *
 * @returns a Response that contains the data associated with the provided
 * token.
 */
export const readVideoStream = async (
    token: string,
): Promise<Response> => {
    const params = new URLSearchParams({ token });
    const url = new URL(`stream://video?${params.toString()}`);

    const req = new Request(url, { method: "GET" });

    const res = await fetch(req);
    if (!res.ok)
        throw new Error(
            `Failed to read stream from ${url.href}: HTTP ${res.status}`,
        );

    return res;
};

/**
 * Sibling of {@link readVideoStream} to let the native side know when we are
 * done reading the response, so it can dispose any temporary resources.
 */
export const videoStreamDone = async (
    token: string,
): Promise<void> => {
    // The value for `done` is arbitrary, only its presence matters.
    const params = new URLSearchParams({ token, done: "1" });
    const url = new URL(`stream://video?${params.toString()}`);

    const req = new Request(url, { method: "GET" });
    const res = await fetch(req);
    if (!res.ok)
        throw new Error(
            `Failed to close stream at ${url.href}: HTTP ${res.status}`,
        );
};

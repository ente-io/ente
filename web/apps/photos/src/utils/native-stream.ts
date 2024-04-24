/**
 * @file Streaming IPC communication with the Node.js layer of our desktop app.
 *
 * NOTE: These functions only work when we're running in our desktop app.
 */

import type { Electron } from "@/next/types/ipc";

/**
 * Stream the given file from the user's local filesystem.
 *
 * This only works when we're running in our desktop app since it uses the
 * "stream://" protocol handler exposed by our custom code in the Node.js layer.
 * See: [Note: IPC streams].
 *
 * To avoid accidentally invoking it in a non-desktop app context, it requires
 * the {@link Electron} object as a parameter (even though it doesn't use it).
 *
 * @param path The path on the file on the user's local filesystem whose
 * contents we want to stream.
 *
 * @return A ({@link Response}, size) tuple.
 *
 * * The response contains the contents of the file. In particular, the `body`
 *   {@link ReadableStream} property of this response can be used to read the
 *   files contents in a streaming manner.
 *
 * * The size is the size of the file that we'll be reading from disk.
 */
export const readStream = async (
    _: Electron,
    path: string,
): Promise<{ response: Response; size: number }> => {
    const req = new Request(`stream://read${path}`, {
        method: "GET",
    });

    const res = await fetch(req);
    if (!res.ok)
        throw new Error(
            `Failed to read stream from ${path}: HTTP ${res.status}`,
        );

    const size = +res.headers["Content-Length"];
    if (isNaN(size))
        throw new Error(
            `Got a numeric Content-Length when reading a stream. The response was ${res}`,
        );

    return { response: res, size };
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
    // TODO(MR): This doesn't currently work.
    //
    // Not sure what I'm doing wrong here; I've opened an issue upstream
    // https://github.com/electron/electron/issues/41872
    //
    // A gist with a minimal reproduction
    // https://gist.github.com/mnvr/e08d9f4876fb8400b7615347b4d268eb
    //
    // Meanwhile, write the complete body in one go (this'll eventually run into
    // memory failures with large files - just a temporary stopgap to get the
    // code to work).

    /*
    // The duplex parameter needs to be set to 'half' when streaming requests.
    //
    // Currently browsers, and specifically in our case, since this code runs
    // only within our desktop (Electron) app, Chromium, don't support 'full'
    // duplex mode (i.e. streaming both the request and the response).
    // https://developer.chrome.com/docs/capabilities/web-apis/fetch-streaming-requests
    const req = new Request(`stream://write${path}`, {
        // GET can't have a body
        method: "POST",
        body: stream,
        // @ts-expect-error TypeScript's libdom.d.ts does not include the
        // "duplex" parameter, e.g. see
        // https://github.com/node-fetch/node-fetch/issues/1769.
        duplex: "half",
    });
    */

    const req = new Request(`stream://write${path}`, {
        method: "POST",
        body: await new Response(stream).blob(),
    });

    const res = await fetch(req);
    if (!res.ok)
        throw new Error(
            `Failed to write stream to ${path}: HTTP ${res.status}`,
        );
};

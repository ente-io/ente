/**
 * @file Streaming IPC communication with the Node.js layer of our desktop app.
 *
 * NOTE: These functions only work when we're running in our desktop app.
 */

/**
 * Write the given stream to a file on the local machine.
 *
 * **This only works when we're running in our desktop app**. It uses the
 * "stream://" protocol handler exposed by our custom code in the Node.js layer.
 * See: [Note: IPC streams].
 *
 * @param path The path on the local machine where to write the file to.
 * @param stream The stream which should be written into the file.
 *  */
export const writeStream = async (path: string, stream: ReadableStream) => {
    // The duplex parameter needs to be set to 'half' when streaming requests.
    //
    // Currently browsers, and specifically in our case, since this code runs
    // only within our desktop (Electron) app, Chromium, don't support 'full'
    // duplex mode (i.e. streaming both the request and the response).
    // https://developer.chrome.com/docs/capabilities/web-apis/fetch-streaming-requests
    //
    // In another twist, the TypeScript libdom.d.ts does not include the
    // "duplex" parameter, so we need to cast to get TypeScript to let this code
    // through. e.g. see https://github.com/node-fetch/node-fetch/issues/1769
    const req = new Request(`stream://write/${path}`, {
        // GET can't have a body
        method: "POST",
        body: stream,
        duplex: "half",
    } as unknown as RequestInit);
    const res = await fetch(req);
    if (!res.ok)
        throw new Error(
            `Failed to write stream to ${path}: HTTP ${res.status}`,
        );
};

/**
 * Type declarations for streamsaver package.
 * @see https://github.com/nicbarker/stream-saver
 */
declare module "streamsaver" {
    interface WritableStreamWriter {
        write(chunk: Uint8Array): Promise<void>;
        close(): Promise<void>;
        abort(reason?: unknown): Promise<void>;
    }

    interface WritableStream {
        getWriter(): WritableStreamWriter;
    }

    interface StreamSaver {
        createWriteStream(filename: string): WritableStream;
        /**
         * URL to the mitm.html page that hosts the service worker.
         * Override this to use a self-hosted mitm instead of the default
         * jimmywarting.github.io endpoint.
         */
        mitm: string;
    }

    const streamSaver: StreamSaver;

    export = streamSaver;
}

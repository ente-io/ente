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

    export function createWriteStream(filename: string): WritableStream;
}

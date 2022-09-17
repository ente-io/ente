import * as Comlink from 'comlink';

// didn't work kept for reference, so that can try to make it work later in future hopefully
export function setupResponseObjectTransferHandler() {
    const transferHandler: Comlink.TransferHandler<Response, ArrayBuffer> = {
        canHandle: (obj): obj is Response => obj instanceof Response,
        serialize: (response: Response) => [response.arrayBuffer() as any, []],
        deserialize: (arrayBuffer: ArrayBuffer) => new Response(arrayBuffer),
    };
    return Comlink.transferHandlers.set('RESPONSE', transferHandler);
}

export function serializeResponse(response: Response) {
    if (response) {
        return response.arrayBuffer();
    }
}

export function deserializeToResponse(arrayBuffer: ArrayBuffer) {
    if (arrayBuffer) {
        return new Response(arrayBuffer);
    }
}

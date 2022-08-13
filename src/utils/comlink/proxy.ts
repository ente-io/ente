export function serializeResponse(response: Response) {
    return response.arrayBuffer();
}

export function deserializeToResponse(arrayBuffer: ArrayBuffer) {
    return new Response(arrayBuffer);
}

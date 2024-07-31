import { z } from "zod";

/**
 * The port used to communicate with the Node.js ML worker process
 *
 * See: [Note: ML IPC]
 * */
let _port: MessagePort | undefined;

/**
 * Use the given {@link MessagePort} to communicate with the Node.js ML worker
 * process.
 */
export const startUsingMessagePort = (port: MessagePort) => {
    _port = port;
    port.start();
};

/**
 * Return a CLIP embedding of the given image.
 *
 * See: [Note: Natural language search using CLIP]
 *
 * The input is a opaque float32 array representing the image. The layout
 * and exact encoding of the input is specific to our implementation and the
 * ML model (CLIP) we use.
 *
 * @returns A CLIP embedding (an array of 512 floating point values).
 */
export const computeCLIPImageEmbedding = (
    input: Float32Array,
): Promise<Float32Array> =>
    ensureFloat32Array(electronMLWorker("computeCLIPImageEmbedding", input));

/**
 * Return a CLIP embedding of the given image if we already have the model
 * downloaded and prepped. If the model is not available return `undefined`.
 *
 * This differs from the other sibling ML functions in that it doesn't wait
 * for the model download to finish. It does trigger a model download, but
 * then immediately returns `undefined`. At some future point, when the
 * model downloaded finishes, calls to this function will start returning
 * the result we seek.
 *
 * The reason for doing it in this asymmetric way is because CLIP text
 * embeddings are used as part of deducing user initiated search results,
 * and we don't want to block that interaction on a large network request.
 *
 * See: [Note: Natural language search using CLIP]
 *
 * @param text The string whose embedding we want to compute.
 *
 * @returns A CLIP embedding.
 */
export const computeCLIPTextEmbeddingIfAvailable = async (
    text: string,
): Promise<Float32Array | undefined> =>
    ensureOptionalFloat32Array(
        electronMLWorker("computeCLIPTextEmbeddingIfAvailable", text),
    );

/**
 * Detect faces in the given image using YOLO.
 *
 * Both the input and output are opaque binary data whose internal structure
 * is specific to our implementation and the model (YOLO) we use.
 */
export const detectFaces = (input: Float32Array): Promise<Float32Array> =>
    ensureFloat32Array(electronMLWorker("detectFaces", input));

/**
 * Return a MobileFaceNet embeddings for the given faces.
 *
 * Both the input and output are opaque binary data whose internal structure
 * is specific to our implementation and the model (MobileFaceNet) we use.
 */
export const computeFaceEmbeddings = (
    input: Float32Array,
): Promise<Float32Array> =>
    ensureFloat32Array(electronMLWorker("computeFaceEmbeddings", input));

const ensureFloat32Array = async (
    pu: Promise<unknown>,
): Promise<Float32Array> => {
    const u = await pu;
    if (u instanceof Float32Array) return u;
    throw new Error(`Expected a Float32Array but instead got ${typeof u}`);
};

const ensureOptionalFloat32Array = async (
    pu: Promise<unknown>,
): Promise<Float32Array | undefined> => {
    const u = await pu;
    if (u === undefined) return u;
    if (u instanceof Float32Array) return u;
    throw new Error(`Expected a Float32Array but instead got ${typeof u}`);
};

/**
 * Make a call to the ML worker running in the Node.js layer using our
 * hand-rolled RPC protocol. See: [Note: Node.js ML worker RPC protocol].
 */
const electronMLWorker = async (method: string, p: string | Float32Array) => {
    const port = _port;
    if (!port) {
        throw new Error(
            "No MessagePort to communicate with Electron ML worker",
        );
    }

    // Generate a unique nonce to identify this RPC interaction.
    const id = Math.random();
    return new Promise((resolve, reject) => {
        const handleMessage = (event: MessageEvent) => {
            const response = RPCResponse.parse(event.data);
            if (response.id != id) return;
            port.removeEventListener("message", handleMessage);
            const error = response.error;
            if (error) reject(new Error(error));
            else resolve(response.result);
        };
        port.addEventListener("message", handleMessage);
        port.postMessage({ id, method, p });
    });
};

const RPCResponse = z.object({
    id: z.number(),
    result: z.any().optional(),
    error: z.string().optional(),
});

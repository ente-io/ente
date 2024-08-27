import type { ElectronMLWorker } from "@/base/types/ipc";
import type { ImageBitmapAndData } from "./blob";
import { clipIndexes } from "./db";
import { pixelRGBBilinear } from "./image";
import { dotProduct, norm } from "./math";
import type { CLIPMatches } from "./worker-types";

/**
 * The version of the CLIP indexing pipeline implemented by the current client.
 */
export const clipIndexingVersion = 1;

/**
 * The CLIP embedding for a file (and some metadata).
 *
 * See {@link FaceIndex} for a similar structure with more comprehensive
 * documentation.
 *
 * ---
 *
 * [Note: Natural language search using CLIP]
 *
 * CLIP (Contrastive Language-Image Pretraining) is a neural network trained on
 * (image, text) pairs. It can be thought of as two separate (but jointly
 * trained) encoders - one for images, and one for text - that both map to the
 * same embedding space.
 *
 * We use this for natural language search (aka "magic search") within the app:
 *
 * 1. Pre-compute an embedding for each image.
 *
 * 2. When the user searches, compute an embedding for the search term.
 *
 * 3. Use cosine similarity to find the find the image (embedding) closest to
 *    the text (embedding).
 *
 * More details are in our [blog
 * post](https://ente.io/blog/image-search-with-clip-ggml/) that describes the
 * initial launch of this feature using the GGML runtime.
 *
 * Since the initial launch, we've switched over to another runtime,
 * [ONNX](https://onnxruntime.ai), started using Apple's
 * [MobileCLIP](https://github.com/apple/ml-mobileclip/) as the model and have
 * made other implementation changes, but the overall gist remains the same.
 *
 * Note that we don't train the neural network - we only use one of the publicly
 * available pre-trained neural networks for inference. These neural networks
 * are wholly defined by their connectivity and weights. ONNX, our ML runtimes,
 * loads these weights and instantiates a running network that we can use to
 * compute the embeddings.
 *
 * Theoretically, the same CLIP model can be loaded by different frameworks /
 * runtimes, but in practice each runtime has its own preferred format, and
 * there are also quantization tradeoffs. So there is a specific model (a binary
 * encoding of weights) tied to our current runtime that we use.
 *
 * To ensure that the embeddings, for the most part, can be shared, whenever
 * possible we try to ensure that all the preprocessing steps, and the model
 * itself, is the same across clients - web and mobile.
 */
export interface CLIPIndex {
    /**
     * The CLIP embedding.
     *
     * This is an array of 512 floating point values that represent the
     * embedding of the image in the same space where we'll embed the text so
     * that both of them can be compared using a cosine distance.
     */
    embedding: number[];
}

export type RemoteCLIPIndex = CLIPIndex & {
    /** An integral version number of the indexing algorithm / pipeline. */
    version: number;
    /** The UA for the client which generated this embedding. */
    client: string;
};

export type LocalCLIPIndex = CLIPIndex & {
    /** The ID of the {@link EnteFile} whose index this is. */
    fileID: number;
};

/**
 * Compute the CLIP embedding of a given file.
 *
 * This function is the entry point to the CLIP indexing pipeline. The file goes
 * through various stages:
 *
 * 1. Downloading the original if needed.
 * 2. Convert (if needed) and pre-process.
 * 3. Compute embeddings using ONNX/CLIP.
 *
 * Once all of it is done, it CLIP embedding (wrapped as a {@link CLIPIndex} so
 * that it can be saved locally and also uploaded to the user's remote storage
 * for use on their other devices).
 *
 * @param uploadItem If we're called during the upload process, then this will
 * be set to the {@link UploadItem} that was uploaded. This way, we can directly
 * use the on-disk file instead of needing to download the original from remote.
 *
 * @param electron The {@link ElectronMLWorker} instance that allows us to call
 * our Node.js layer to run the ONNX inference.
 */
export const indexCLIP = async (
    image: ImageBitmapAndData,
    electron: ElectronMLWorker,
): Promise<CLIPIndex> => ({
    embedding: await computeEmbedding(image.data, electron),
});

const computeEmbedding = async (
    imageData: ImageData,
    electron: ElectronMLWorker,
): Promise<number[]> => {
    const clipInput = convertToCLIPInput(imageData);
    return normalized(await electron.computeCLIPImageEmbedding(clipInput));
};

/**
 * Convert {@link imageData} into the format that the MobileCLIP model expects.
 */
const convertToCLIPInput = (imageData: ImageData) => {
    const [requiredWidth, requiredHeight] = [256, 256];

    const { width, height, data: pixelData } = imageData;

    // Maintain aspect ratio.
    const scale = Math.max(requiredWidth / width, requiredHeight / height);

    const scaledWidth = Math.round(width * scale);
    const scaledHeight = Math.round(height * scale);
    const widthOffset = Math.max(0, scaledWidth - requiredWidth) / 2;
    const heightOffset = Math.max(0, scaledHeight - requiredHeight) / 2;

    const clipInput = new Float32Array(3 * requiredWidth * requiredHeight);

    // Populate the Float32Array with normalized pixel values.
    let pi = 0;
    const cOffsetG = requiredHeight * requiredWidth; // ChannelOffsetGreen
    const cOffsetB = 2 * requiredHeight * requiredWidth; // ChannelOffsetBlue
    for (let h = 0 + heightOffset; h < scaledHeight - heightOffset; h++) {
        for (let w = 0 + widthOffset; w < scaledWidth - widthOffset; w++) {
            const { r, g, b } = pixelRGBBilinear(
                w / scale,
                h / scale,
                pixelData,
                width,
                height,
            );
            clipInput[pi] = r / 255.0;
            clipInput[pi + cOffsetG] = g / 255.0;
            clipInput[pi + cOffsetB] = b / 255.0;
            pi++;
        }
    }
    return clipInput;
};

const normalized = (embedding: Float32Array) => {
    const nums = Array.from(embedding);
    const n = norm(nums);
    return nums.map((v) => v / n);
};

/**
 * Find the files whose CLIP embedding "matches" the given {@link searchPhrase}.
 *
 * The result can also be `undefined`, which indicates that the download for the
 * ML model is still in progress (trying again later should succeed).
 */
export const clipMatches = async (
    searchPhrase: string,
    electron: ElectronMLWorker,
): Promise<CLIPMatches | undefined> => {
    const t = await electron.computeCLIPTextEmbeddingIfAvailable(searchPhrase);
    if (!t) return undefined;

    const textEmbedding = normalized(t);
    const items = (await clipIndexes()).map(
        ({ fileID, embedding }) =>
            // What we want to do is `cosineSimilarity`, but since both the
            // embeddings involved are already normalized, we can save the norm
            // calculations and directly do their `dotProduct`.
            //
            // This code is on the hot path, so these optimizations help.
            [fileID, dotProduct(embedding, textEmbedding)] as const,
    );
    // This score threshold was obtain heuristically. 0.2 generally gives solid
    // results, and around 0.15 we start getting many false positives (all this
    // is query dependent too).
    return new Map(items.filter(([, score]) => score >= 0.175));
};

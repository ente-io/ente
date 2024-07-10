/**
 * @file Compute CLIP embeddings for images and text.
 *
 * The embeddings are computed using ONNX runtime, with CLIP as the model.
 */
import Tokenizer from "clip-bpe-js";
import * as ort from "onnxruntime-node";
import log from "../log";
import { ensure, wait } from "../utils/common";
import { makeCachedInferenceSession } from "./ml";

const cachedCLIPImageSession = makeCachedInferenceSession(
    "clip-image-vit-32-float32.onnx",
    351468764 /* 335.2 MB */,
);

export const computeCLIPImageEmbedding = async (input: Float32Array) => {
    const session = await cachedCLIPImageSession();
    const t = Date.now();
    const feeds = {
        input: new ort.Tensor("float32", input, [1, 3, 224, 224]),
    };
    const results = await session.run(feeds);
    log.debug(() => `ONNX/CLIP image embedding took ${Date.now() - t} ms`);
    /* Need these model specific casts to type the result */
    return ensure(results.output).data as Float32Array;
};

const cachedCLIPTextSession = makeCachedInferenceSession(
    "clip-text-vit-32-uint8.onnx",
    64173509 /* 61.2 MB */,
);

let _tokenizer: Tokenizer | undefined;
const getTokenizer = () => {
    if (!_tokenizer) _tokenizer = new Tokenizer();
    return _tokenizer;
};

export const computeCLIPTextEmbeddingIfAvailable = async (text: string) => {
    const sessionOrSkip = await Promise.race([
        cachedCLIPTextSession(),
        // Wait for a tick to get the session promise to resolved the first time
        // this code runs on each app start (and the model has been downloaded).
        wait(0).then(() => 1),
    ]);

    // Don't wait for the download to complete.
    if (typeof sessionOrSkip == "number") {
        log.info(
            "Ignoring CLIP text embedding request because model download is pending",
        );
        return undefined;
    }

    const session = sessionOrSkip;
    const t = Date.now();
    const tokenizer = getTokenizer();
    const tokenizedText = Int32Array.from(tokenizer.encodeForCLIP(text));
    const feeds = {
        input: new ort.Tensor("int32", tokenizedText, [1, 77]),
    };

    const results = await session.run(feeds);
    log.debug(() => `ONNX/CLIP text embedding took ${Date.now() - t} ms`);
    return ensure(results.output).data as Float32Array;
};

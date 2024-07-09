// TODO: These arise from the array indexing in the pre-processing code. Isolate
// once that code settles down to its final place (currently duplicated across
// web and desktop).
/* eslint-disable @typescript-eslint/no-non-null-assertion */

/**
 * @file Compute CLIP embeddings for images and text.
 *
 * The embeddings are computed using ONNX runtime, with CLIP as the model.
 *
 * @see `web/apps/photos/src/services/clip-service.ts` for more details.
 */
import Tokenizer from "clip-bpe-js";
import jpeg from "jpeg-js";
import fs from "node:fs/promises";
import * as ort from "onnxruntime-node";
import log from "../log";
import { writeStream } from "../stream";
import { ensure, wait } from "../utils/common";
import { deleteTempFile, makeTempFilePath } from "../utils/temp";
import { makeCachedInferenceSession } from "./ml";

const cachedCLIPImageSession = makeCachedInferenceSession(
    "clip-image-vit-32-float32.onnx",
    351468764 /* 335.2 MB */,
);

export const computeCLIPImageEmbedding = async (jpegImageData: Uint8Array) => {
    const tempFilePath = await makeTempFilePath();
    const imageStream = new Response(jpegImageData.buffer).body;
    await writeStream(tempFilePath, ensure(imageStream));
    try {
        return await clipImageEmbedding_(tempFilePath);
    } finally {
        await deleteTempFile(tempFilePath);
    }
};

const clipImageEmbedding_ = async (jpegFilePath: string) => {
    const session = await cachedCLIPImageSession();
    const t1 = Date.now();
    const rgbData = await getRGBData(jpegFilePath);
    const feeds = {
        input: new ort.Tensor("float32", rgbData, [1, 3, 224, 224]),
    };
    const t2 = Date.now();
    const results = await session.run(feeds);
    log.debug(
        () =>
            `ONNX/CLIP image embedding took ${Date.now() - t1} ms (prep: ${t2 - t1} ms, inference: ${Date.now() - t2} ms)`,
    );
    /* Need these model specific casts to type the result */
    const imageEmbedding = ensure(results.output).data as Float32Array;
    return normalizeEmbedding(imageEmbedding);
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
    const t1 = Date.now();
    const tokenizer = getTokenizer();
    const tokenizedText = Int32Array.from(tokenizer.encodeForCLIP(text));
    const feeds = {
        input: new ort.Tensor("int32", tokenizedText, [1, 77]),
    };
    const t2 = Date.now();
    const results = await session.run(feeds);
    log.debug(
        () =>
            `ONNX/CLIP text embedding took ${Date.now() - t1} ms (prep: ${t2 - t1} ms, inference: ${Date.now() - t2} ms)`,
    );
    const textEmbedding = ensure(results.output).data as Float32Array;
    return normalizeEmbedding(textEmbedding);
};

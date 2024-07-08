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

const getRGBData = async (jpegFilePath: string): Promise<Float32Array> => {
    const jpegData = await fs.readFile(jpegFilePath);
    const rawImageData = jpeg.decode(jpegData, {
        useTArray: true,
        formatAsRGBA: true,
    }); // TODO: manav: make sure this works on all images, not just jpeg
    const pixelData = rawImageData.data;

    const requiredWidth = 224;
    const requiredHeight = 224;
    const requiredSize = 3 * requiredWidth * requiredHeight;
    const mean: number[] = [0.48145466, 0.4578275, 0.40821073];
    const std: number[] = [0.26862954, 0.26130258, 0.27577711];

    const scale = Math.max(
        requiredWidth / rawImageData.width,
        requiredHeight / rawImageData.height,
    );
    const scaledWidth = Math.round(rawImageData.width * scale);
    const scaledHeight = Math.round(rawImageData.height * scale);
    const widthOffset = Math.max(0, scaledWidth - requiredWidth) / 2;
    const heightOffset = Math.max(0, scaledHeight - requiredHeight) / 2;

    const processedImage = new Float32Array(requiredSize);

    // Populate the Float32Array with normalized pixel values.
    let pi = 0;
    const cOffsetG = requiredHeight * requiredWidth; // ChannelOffsetGreen
    const cOffsetB = 2 * requiredHeight * requiredWidth; // ChannelOffsetBlue
    for (let h = 0 + heightOffset; h < scaledHeight - heightOffset; h++) {
        for (let w = 0 + widthOffset; w < scaledWidth - widthOffset; w++) {
            const { r, g, b } = pixelRGBBicubic(
                w / scale,
                h / scale,
                pixelData,
                rawImageData.width,
                rawImageData.height,
            );
            processedImage[pi] = (r / 255.0 - mean[0]!) / std[0]!;
            processedImage[pi + cOffsetG] = (g / 255.0 - mean[1]!) / std[1]!;
            processedImage[pi + cOffsetB] = (b / 255.0 - mean[2]!) / std[2]!;
            pi++;
        }
    }
    return processedImage;
};

// NOTE: exact duplicate of the function in web/apps/photos/src/services/face/image.ts
const pixelRGBBicubic = (
    fx: number,
    fy: number,
    imageData: Uint8Array,
    imageWidth: number,
    imageHeight: number,
) => {
    // Clamp to image boundaries.
    fx = clamp(fx, 0, imageWidth - 1);
    fy = clamp(fy, 0, imageHeight - 1);

    const x = Math.trunc(fx) - (fx >= 0.0 ? 0 : 1);
    const px = x - 1;
    const nx = x + 1;
    const ax = x + 2;
    const y = Math.trunc(fy) - (fy >= 0.0 ? 0 : 1);
    const py = y - 1;
    const ny = y + 1;
    const ay = y + 2;
    const dx = fx - x;
    const dy = fy - y;

    const cubic = (
        dx: number,
        ipp: number,
        icp: number,
        inp: number,
        iap: number,
    ) =>
        icp +
        0.5 *
            (dx * (-ipp + inp) +
                dx * dx * (2 * ipp - 5 * icp + 4 * inp - iap) +
                dx * dx * dx * (-ipp + 3 * icp - 3 * inp + iap));

    const icc = pixelRGBA(imageData, imageWidth, imageHeight, x, y);

    const ipp =
        px < 0 || py < 0
            ? icc
            : pixelRGBA(imageData, imageWidth, imageHeight, px, py);
    const icp =
        px < 0 ? icc : pixelRGBA(imageData, imageWidth, imageHeight, x, py);
    const inp =
        py < 0 || nx >= imageWidth
            ? icc
            : pixelRGBA(imageData, imageWidth, imageHeight, nx, py);
    const iap =
        ax >= imageWidth || py < 0
            ? icc
            : pixelRGBA(imageData, imageWidth, imageHeight, ax, py);

    const ip0 = cubic(dx, ipp.r, icp.r, inp.r, iap.r);
    const ip1 = cubic(dx, ipp.g, icp.g, inp.g, iap.g);
    const ip2 = cubic(dx, ipp.b, icp.b, inp.b, iap.b);
    // const ip3 = cubic(dx, ipp.a, icp.a, inp.a, iap.a);

    const ipc =
        px < 0 ? icc : pixelRGBA(imageData, imageWidth, imageHeight, px, y);
    const inc =
        nx >= imageWidth
            ? icc
            : pixelRGBA(imageData, imageWidth, imageHeight, nx, y);
    const iac =
        ax >= imageWidth
            ? icc
            : pixelRGBA(imageData, imageWidth, imageHeight, ax, y);

    const ic0 = cubic(dx, ipc.r, icc.r, inc.r, iac.r);
    const ic1 = cubic(dx, ipc.g, icc.g, inc.g, iac.g);
    const ic2 = cubic(dx, ipc.b, icc.b, inc.b, iac.b);
    // const ic3 = cubic(dx, ipc.a, icc.a, inc.a, iac.a);

    const ipn =
        px < 0 || ny >= imageHeight
            ? icc
            : pixelRGBA(imageData, imageWidth, imageHeight, px, ny);
    const icn =
        ny >= imageHeight
            ? icc
            : pixelRGBA(imageData, imageWidth, imageHeight, x, ny);
    const inn =
        nx >= imageWidth || ny >= imageHeight
            ? icc
            : pixelRGBA(imageData, imageWidth, imageHeight, nx, ny);
    const ian =
        ax >= imageWidth || ny >= imageHeight
            ? icc
            : pixelRGBA(imageData, imageWidth, imageHeight, ax, ny);

    const in0 = cubic(dx, ipn.r, icn.r, inn.r, ian.r);
    const in1 = cubic(dx, ipn.g, icn.g, inn.g, ian.g);
    const in2 = cubic(dx, ipn.b, icn.b, inn.b, ian.b);
    // const in3 = cubic(dx, ipn.a, icn.a, inn.a, ian.a);

    const ipa =
        px < 0 || ay >= imageHeight
            ? icc
            : pixelRGBA(imageData, imageWidth, imageHeight, px, ay);
    const ica =
        ay >= imageHeight
            ? icc
            : pixelRGBA(imageData, imageWidth, imageHeight, x, ay);
    const ina =
        nx >= imageWidth || ay >= imageHeight
            ? icc
            : pixelRGBA(imageData, imageWidth, imageHeight, nx, ay);
    const iaa =
        ax >= imageWidth || ay >= imageHeight
            ? icc
            : pixelRGBA(imageData, imageWidth, imageHeight, ax, ay);

    const ia0 = cubic(dx, ipa.r, ica.r, ina.r, iaa.r);
    const ia1 = cubic(dx, ipa.g, ica.g, ina.g, iaa.g);
    const ia2 = cubic(dx, ipa.b, ica.b, ina.b, iaa.b);
    // const ia3 = cubic(dx, ipa.a, ica.a, ina.a, iaa.a);

    const c0 = Math.trunc(clamp(cubic(dy, ip0, ic0, in0, ia0), 0, 255));
    const c1 = Math.trunc(clamp(cubic(dy, ip1, ic1, in1, ia1), 0, 255));
    const c2 = Math.trunc(clamp(cubic(dy, ip2, ic2, in2, ia2), 0, 255));
    // const c3 = cubic(dy, ip3, ic3, in3, ia3);

    return { r: c0, g: c1, b: c2 };
};

// NOTE: exact duplicate of the function in web/apps/photos/src/services/face/image.ts
const clamp = (value: number, min: number, max: number) =>
    Math.min(max, Math.max(min, value));

// NOTE: exact duplicate of the function in web/apps/photos/src/services/face/image.ts
const pixelRGBA = (
    imageData: Uint8Array,
    width: number,
    height: number,
    x: number,
    y: number,
) => {
    if (x < 0 || x >= width || y < 0 || y >= height) {
        return { r: 0, g: 0, b: 0, a: 0 };
    }
    const index = (y * width + x) * 4;
    return {
        r: ensure(imageData[index]),
        g: ensure(imageData[index + 1]),
        b: ensure(imageData[index + 2]),
        a: ensure(imageData[index + 3]),
    };
};

const normalizeEmbedding = (embedding: Float32Array) => {
    let normalization = 0;
    for (const v of embedding) normalization += v * v;

    const sqrtNormalization = Math.sqrt(normalization);
    for (let index = 0; index < embedding.length; index++)
        embedding[index] = ensure(embedding[index]) / sqrtNormalization;

    return embedding;
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

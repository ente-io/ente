// these utils only work in env where OffscreenCanvas is available

import { Matrix, inverse } from "ml-matrix";
import { BlobOptions, Dimensions } from "types/image";
import { FaceAlignment } from "types/machineLearning";
import { enlargeBox } from "utils/machineLearning";
import { Box } from "../../../thirdparty/face-api/classes";

export function normalizePixelBetween0And1(pixelValue: number) {
    return pixelValue / 255.0;
}

export function normalizePixelBetweenMinus1And1(pixelValue: number) {
    return pixelValue / 127.5 - 1.0;
}

export function unnormalizePixelFromBetweenMinus1And1(pixelValue: number) {
    return clamp(Math.round((pixelValue + 1.0) * 127.5), 0, 255);
}

export function readPixelColor(
    imageData: Uint8ClampedArray,
    width: number,
    height: number,
    x: number,
    y: number,
) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
        return { r: 0, g: 0, b: 0, a: 0 };
    }
    const index = (y * width + x) * 4;
    return {
        r: imageData[index],
        g: imageData[index + 1],
        b: imageData[index + 2],
        a: imageData[index + 3],
    };
}

export function clamp(value: number, min: number, max: number) {
    return Math.min(max, Math.max(min, value));
}

export function getPixelBicubic(
    fx: number,
    fy: number,
    imageData: Uint8ClampedArray,
    imageWidth: number,
    imageHeight: number,
) {
    // Clamp to image boundaries
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

    function cubic(
        dx: number,
        ipp: number,
        icp: number,
        inp: number,
        iap: number,
    ) {
        return (
            icp +
            0.5 *
                (dx * (-ipp + inp) +
                    dx * dx * (2 * ipp - 5 * icp + 4 * inp - iap) +
                    dx * dx * dx * (-ipp + 3 * icp - 3 * inp + iap))
        );
    }

    const icc = readPixelColor(imageData, imageWidth, imageHeight, x, y);

    const ipp =
        px < 0 || py < 0
            ? icc
            : readPixelColor(imageData, imageWidth, imageHeight, px, py);
    const icp =
        px < 0
            ? icc
            : readPixelColor(imageData, imageWidth, imageHeight, x, py);
    const inp =
        py < 0 || nx >= imageWidth
            ? icc
            : readPixelColor(imageData, imageWidth, imageHeight, nx, py);
    const iap =
        ax >= imageWidth || py < 0
            ? icc
            : readPixelColor(imageData, imageWidth, imageHeight, ax, py);

    const ip0 = cubic(dx, ipp.r, icp.r, inp.r, iap.r);
    const ip1 = cubic(dx, ipp.g, icp.g, inp.g, iap.g);
    const ip2 = cubic(dx, ipp.b, icp.b, inp.b, iap.b);
    // const ip3 = cubic(dx, ipp.a, icp.a, inp.a, iap.a);

    const ipc =
        px < 0
            ? icc
            : readPixelColor(imageData, imageWidth, imageHeight, px, y);
    const inc =
        nx >= imageWidth
            ? icc
            : readPixelColor(imageData, imageWidth, imageHeight, nx, y);
    const iac =
        ax >= imageWidth
            ? icc
            : readPixelColor(imageData, imageWidth, imageHeight, ax, y);

    const ic0 = cubic(dx, ipc.r, icc.r, inc.r, iac.r);
    const ic1 = cubic(dx, ipc.g, icc.g, inc.g, iac.g);
    const ic2 = cubic(dx, ipc.b, icc.b, inc.b, iac.b);
    // const ic3 = cubic(dx, ipc.a, icc.a, inc.a, iac.a);

    const ipn =
        px < 0 || ny >= imageHeight
            ? icc
            : readPixelColor(imageData, imageWidth, imageHeight, px, ny);
    const icn =
        ny >= imageHeight
            ? icc
            : readPixelColor(imageData, imageWidth, imageHeight, x, ny);
    const inn =
        nx >= imageWidth || ny >= imageHeight
            ? icc
            : readPixelColor(imageData, imageWidth, imageHeight, nx, ny);
    const ian =
        ax >= imageWidth || ny >= imageHeight
            ? icc
            : readPixelColor(imageData, imageWidth, imageHeight, ax, ny);

    const in0 = cubic(dx, ipn.r, icn.r, inn.r, ian.r);
    const in1 = cubic(dx, ipn.g, icn.g, inn.g, ian.g);
    const in2 = cubic(dx, ipn.b, icn.b, inn.b, ian.b);
    // const in3 = cubic(dx, ipn.a, icn.a, inn.a, ian.a);

    const ipa =
        px < 0 || ay >= imageHeight
            ? icc
            : readPixelColor(imageData, imageWidth, imageHeight, px, ay);
    const ica =
        ay >= imageHeight
            ? icc
            : readPixelColor(imageData, imageWidth, imageHeight, x, ay);
    const ina =
        nx >= imageWidth || ay >= imageHeight
            ? icc
            : readPixelColor(imageData, imageWidth, imageHeight, nx, ay);
    const iaa =
        ax >= imageWidth || ay >= imageHeight
            ? icc
            : readPixelColor(imageData, imageWidth, imageHeight, ax, ay);

    const ia0 = cubic(dx, ipa.r, ica.r, ina.r, iaa.r);
    const ia1 = cubic(dx, ipa.g, ica.g, ina.g, iaa.g);
    const ia2 = cubic(dx, ipa.b, ica.b, ina.b, iaa.b);
    // const ia3 = cubic(dx, ipa.a, ica.a, ina.a, iaa.a);

    const c0 = Math.trunc(clamp(cubic(dy, ip0, ic0, in0, ia0), 0, 255));
    const c1 = Math.trunc(clamp(cubic(dy, ip1, ic1, in1, ia1), 0, 255));
    const c2 = Math.trunc(clamp(cubic(dy, ip2, ic2, in2, ia2), 0, 255));
    // const c3 = cubic(dy, ip3, ic3, in3, ia3);

    return { r: c0, g: c1, b: c2 };
}

/// Returns the pixel value (RGB) at the given coordinates using bilinear interpolation.
export function getPixelBilinear(
    fx: number,
    fy: number,
    imageData: Uint8ClampedArray,
    imageWidth: number,
    imageHeight: number,
) {
    // Clamp to image boundaries
    fx = clamp(fx, 0, imageWidth - 1);
    fy = clamp(fy, 0, imageHeight - 1);

    // Get the surrounding coordinates and their weights
    const x0 = Math.floor(fx);
    const x1 = Math.ceil(fx);
    const y0 = Math.floor(fy);
    const y1 = Math.ceil(fy);
    const dx = fx - x0;
    const dy = fy - y0;
    const dx1 = 1.0 - dx;
    const dy1 = 1.0 - dy;

    // Get the original pixels
    const pixel1 = readPixelColor(imageData, imageWidth, imageHeight, x0, y0);
    const pixel2 = readPixelColor(imageData, imageWidth, imageHeight, x1, y0);
    const pixel3 = readPixelColor(imageData, imageWidth, imageHeight, x0, y1);
    const pixel4 = readPixelColor(imageData, imageWidth, imageHeight, x1, y1);

    function bilinear(val1: number, val2: number, val3: number, val4: number) {
        return Math.round(
            val1 * dx1 * dy1 +
                val2 * dx * dy1 +
                val3 * dx1 * dy +
                val4 * dx * dy,
        );
    }

    // Interpolate the pixel values
    const red = bilinear(pixel1.r, pixel2.r, pixel3.r, pixel4.r);
    const green = bilinear(pixel1.g, pixel2.g, pixel3.g, pixel4.g);
    const blue = bilinear(pixel1.b, pixel2.b, pixel3.b, pixel4.b);

    return { r: red, g: green, b: blue };
}

export function warpAffineFloat32List(
    imageBitmap: ImageBitmap,
    faceAlignment: FaceAlignment,
    faceSize: number,
    inputData: Float32Array,
    inputStartIndex: number,
): void {
    // Get the pixel data
    const offscreenCanvas = new OffscreenCanvas(
        imageBitmap.width,
        imageBitmap.height,
    );
    const ctx = offscreenCanvas.getContext("2d");
    ctx.drawImage(imageBitmap, 0, 0, imageBitmap.width, imageBitmap.height);
    const imageData = ctx.getImageData(
        0,
        0,
        imageBitmap.width,
        imageBitmap.height,
    );
    const pixelData = imageData.data;

    const transformationMatrix = faceAlignment.affineMatrix.map((row) =>
        row.map((val) => (val != 1.0 ? val * faceSize : 1.0)),
    ); // 3x3

    const A: Matrix = new Matrix([
        [transformationMatrix[0][0], transformationMatrix[0][1]],
        [transformationMatrix[1][0], transformationMatrix[1][1]],
    ]);
    const Ainverse = inverse(A);

    const b00 = transformationMatrix[0][2];
    const b10 = transformationMatrix[1][2];
    const a00Prime = Ainverse.get(0, 0);
    const a01Prime = Ainverse.get(0, 1);
    const a10Prime = Ainverse.get(1, 0);
    const a11Prime = Ainverse.get(1, 1);

    for (let yTrans = 0; yTrans < faceSize; ++yTrans) {
        for (let xTrans = 0; xTrans < faceSize; ++xTrans) {
            // Perform inverse affine transformation
            const xOrigin =
                a00Prime * (xTrans - b00) + a01Prime * (yTrans - b10);
            const yOrigin =
                a10Prime * (xTrans - b00) + a11Prime * (yTrans - b10);

            // Get the pixel from interpolation
            const pixel = getPixelBicubic(
                xOrigin,
                yOrigin,
                pixelData,
                imageBitmap.width,
                imageBitmap.height,
            );

            // Set the pixel in the input data
            const index = (yTrans * faceSize + xTrans) * 3;
            inputData[inputStartIndex + index] =
                normalizePixelBetweenMinus1And1(pixel.r);
            inputData[inputStartIndex + index + 1] =
                normalizePixelBetweenMinus1And1(pixel.g);
            inputData[inputStartIndex + index + 2] =
                normalizePixelBetweenMinus1And1(pixel.b);
        }
    }
}

export function createGrayscaleIntMatrixFromNormalized2List(
    imageList: Float32Array,
    faceNumber: number,
    width: number = 112,
    height: number = 112,
): number[][] {
    const startIndex = faceNumber * width * height * 3;
    return Array.from({ length: height }, (_, y) =>
        Array.from({ length: width }, (_, x) => {
            // 0.299 ∙ Red + 0.587 ∙ Green + 0.114 ∙ Blue
            const pixelIndex = startIndex + 3 * (y * width + x);
            return clamp(
                Math.round(
                    0.299 *
                        unnormalizePixelFromBetweenMinus1And1(
                            imageList[pixelIndex],
                        ) +
                        0.587 *
                            unnormalizePixelFromBetweenMinus1And1(
                                imageList[pixelIndex + 1],
                            ) +
                        0.114 *
                            unnormalizePixelFromBetweenMinus1And1(
                                imageList[pixelIndex + 2],
                            ),
                ),
                0,
                255,
            );
        }),
    );
}

export function resizeToSquare(img: ImageBitmap, size: number) {
    const scale = size / Math.max(img.height, img.width);
    const width = scale * img.width;
    const height = scale * img.height;
    const offscreen = new OffscreenCanvas(size, size);
    const ctx = offscreen.getContext("2d");
    ctx.imageSmoothingQuality = "high";
    ctx.drawImage(img, 0, 0, width, height);
    const resizedImage = offscreen.transferToImageBitmap();
    return { image: resizedImage, width, height };
}

export function transform(
    imageBitmap: ImageBitmap,
    affineMat: number[][],
    outputWidth: number,
    outputHeight: number,
) {
    const offscreen = new OffscreenCanvas(outputWidth, outputHeight);
    const context = offscreen.getContext("2d");
    context.imageSmoothingQuality = "high";

    context.transform(
        affineMat[0][0],
        affineMat[1][0],
        affineMat[0][1],
        affineMat[1][1],
        affineMat[0][2],
        affineMat[1][2],
    );

    context.drawImage(imageBitmap, 0, 0);
    return offscreen.transferToImageBitmap();
}

export function crop(imageBitmap: ImageBitmap, cropBox: Box, size: number) {
    const dimensions: Dimensions = {
        width: size,
        height: size,
    };

    return cropWithRotation(imageBitmap, cropBox, 0, dimensions, dimensions);
}

export function cropWithRotation(
    imageBitmap: ImageBitmap,
    cropBox: Box,
    rotation?: number,
    maxSize?: Dimensions,
    minSize?: Dimensions,
) {
    const box = cropBox.round();

    const outputSize = { width: box.width, height: box.height };
    if (maxSize) {
        const minScale = Math.min(
            maxSize.width / box.width,
            maxSize.height / box.height,
        );
        if (minScale < 1) {
            outputSize.width = Math.round(minScale * box.width);
            outputSize.height = Math.round(minScale * box.height);
        }
    }

    if (minSize) {
        const maxScale = Math.max(
            minSize.width / box.width,
            minSize.height / box.height,
        );
        if (maxScale > 1) {
            outputSize.width = Math.round(maxScale * box.width);
            outputSize.height = Math.round(maxScale * box.height);
        }
    }

    // log.info({ imageBitmap, box, outputSize });

    const offscreen = new OffscreenCanvas(outputSize.width, outputSize.height);
    const offscreenCtx = offscreen.getContext("2d");
    offscreenCtx.imageSmoothingQuality = "high";

    offscreenCtx.translate(outputSize.width / 2, outputSize.height / 2);
    rotation && offscreenCtx.rotate(rotation);

    const outputBox = new Box({
        x: -outputSize.width / 2,
        y: -outputSize.height / 2,
        width: outputSize.width,
        height: outputSize.height,
    });

    const enlargedBox = enlargeBox(box, 1.5);
    const enlargedOutputBox = enlargeBox(outputBox, 1.5);

    offscreenCtx.drawImage(
        imageBitmap,
        enlargedBox.x,
        enlargedBox.y,
        enlargedBox.width,
        enlargedBox.height,
        enlargedOutputBox.x,
        enlargedOutputBox.y,
        enlargedOutputBox.width,
        enlargedOutputBox.height,
    );

    return offscreen.transferToImageBitmap();
}

export function addPadding(image: ImageBitmap, padding: number) {
    const scale = 1 + padding * 2;
    const width = scale * image.width;
    const height = scale * image.height;
    const offscreen = new OffscreenCanvas(width, height);
    const ctx = offscreen.getContext("2d");
    ctx.imageSmoothingEnabled = false;
    ctx.drawImage(
        image,
        width / 2 - image.width / 2,
        height / 2 - image.height / 2,
        image.width,
        image.height,
    );

    return offscreen.transferToImageBitmap();
}

export async function imageBitmapToBlob(
    imageBitmap: ImageBitmap,
    options?: BlobOptions,
) {
    const offscreen = new OffscreenCanvas(
        imageBitmap.width,
        imageBitmap.height,
    );
    offscreen.getContext("2d").drawImage(imageBitmap, 0, 0);

    return offscreen.convertToBlob(options);
}

export async function imageBitmapFromBlob(blob: Blob) {
    return createImageBitmap(blob);
}

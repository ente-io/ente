import { blobCache } from "@/next/blob-cache";
import { ensure } from "@/utils/ensure";
import { type Box, type FaceAlignment, type FaceIndex } from "./face";
import { clamp } from "./image";

/**
 * Extract and locally save the face crops (the rectangle of the original image
 * that contain the detected face) for each of the faces detected in an image.
 *
 * @param imageBitmap The original image.
 *
 * @param faceIndex The {@link FaceIndex} containing information about the faces
 * detected in the given image.
 *
 * The face crops are saved in a local cache and can subsequently be retrieved
 * from the {@link BlobCache} named "face-crops".
 */
export const saveFaceCrops = async (
    imageBitmap: ImageBitmap,
    faceIndex: FaceIndex,
) => {
    const cache = await blobCache("face-crops");

    const faces = faceIndex.faceEmbedding.faces;
    const blobs = await generateFaceThumbnailsUsingCanvas(
        imageBitmap,
        faces.map(({ detection }) => detection.box),
    );
    for (let i = 0; i < faces.length; i++) {
        // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
        await cache.put(faces[i]!.faceID, blobs[i]!);
    }
    /*
    return Promise.all(
        faceIndex.faceEmbedding.faces.map(({ faceID, detection }) =>
            // extractFaceCrop2(imageBitmap, detection.box).then((b) =>
            // extractFaceCrop(
            //     imageBitmap,
            //     computeFaceAlignment(
            //         restoreToImageDimensions(detection, imageBitmap),
            //     ),
            // ).then((b) => cache.put(faceID, b)),

        ),
    );
    */
};

const generateFaceThumbnailsUsingCanvas = async (
    imageBitmap: ImageBitmap,
    faceBoxes: Box[],
) => {
    const img = imageBitmap;

    const futureFaceThumbnails: Promise<Blob>[] = [];
    for (const faceBox of faceBoxes) {
        // Note that the faceBox values are relative to the image size, so we need to convert them to absolute values first
        const xMinAbs = faceBox.x * img.width;
        const yMinAbs = faceBox.y * img.height;
        const widthAbs = faceBox.width * img.width;
        const heightAbs = faceBox.height * img.height;

        // Calculate the crop values by adding some padding around the face and making sure it's centered
        const regularPadding = 0.4;
        const minimumPadding = 0.1;
        const xCrop = xMinAbs - widthAbs * regularPadding;
        const xOvershoot = Math.abs(Math.min(0, xCrop)) / widthAbs;
        const widthCrop =
            widthAbs * (1 + 2 * regularPadding) -
            2 *
                Math.min(xOvershoot, regularPadding - minimumPadding) *
                widthAbs;
        const yCrop = yMinAbs - heightAbs * regularPadding;
        const yOvershoot = Math.abs(Math.min(0, yCrop)) / heightAbs;
        const heightCrop =
            heightAbs * (1 + 2 * regularPadding) -
            2 *
                Math.min(yOvershoot, regularPadding - minimumPadding) *
                heightAbs;

        // Prevent the face from going out of image bounds
        const xCropSafe = clamp(xCrop, 0, img.width);
        const yCropSafe = clamp(yCrop, 0, img.height);
        const widthCropSafe = clamp(widthCrop, 0, img.width - xCropSafe);
        const heightCropSafe = clamp(heightCrop, 0, img.height - yCropSafe);

        futureFaceThumbnails.push(
            _cropAndEncodeCanvas(
                img,
                xCropSafe,
                yCropSafe,
                widthCropSafe,
                heightCropSafe,
            ),
        );
    }
    return Promise.all(futureFaceThumbnails);
};

const _cropAndEncodeCanvas = async (
    imageBitmap: ImageBitmap,
    x: number,
    y: number,
    width: number,
    height: number,
) => {
    const offscreen = new OffscreenCanvas(width, height);
    const offscreenCtx = ensure(offscreen.getContext("2d"));
    offscreenCtx.imageSmoothingQuality = "high";

    offscreenCtx.drawImage(
        imageBitmap,
        x,
        y,
        width,
        height,
        0,
        0,
        width,
        height,
    );

    return offscreen.convertToBlob({ type: "image/jpeg", quality: 0.8 });
};

/**
 * Return the face crops corresponding to each of the given face detections.
 *
 * @param imageBitmap The original image.
 *
 * @param faceBox A box (a rectangle relative to the image size) marking the
 * bounds of face in the given image.
 *
 * @returns a JPEG blob.
 */
export const extractFaceCrop2 = (imageBitmap: ImageBitmap, faceBox: Box) => {
    const { width: imageWidth, height: imageHeight } = imageBitmap;

    // The faceBox is relative to the image size, and we need to convert
    // them to absolute values first.
    const faceX = faceBox.x * imageWidth;
    const faceY = faceBox.y * imageHeight;
    const faceWidth = faceBox.width * imageWidth;
    const faceHeight = faceBox.height * imageHeight;

    // Calculate the crop values by adding some padding around the face and
    // making sure it's centered.
    const regularPadding = 0.4;
    const minimumPadding = 0.1;
    const xCrop = faceX - faceWidth * regularPadding;
    const xOvershoot = Math.abs(Math.min(0, xCrop)) / faceWidth;
    const widthCrop =
        faceWidth * (1 + 2 * regularPadding) -
        2 * Math.min(xOvershoot, regularPadding - minimumPadding) * faceWidth;

    const yCrop = faceY - faceHeight * regularPadding;
    const yOvershoot = Math.abs(Math.min(0, yCrop)) / faceHeight;
    const heightCrop =
        faceHeight * (1 + 2 * regularPadding) -
        2 * Math.min(yOvershoot, regularPadding - minimumPadding) * faceHeight;

    // Prevent the crop from going out of image bounds.
    const x = clamp(xCrop, 0, imageWidth);
    const y = clamp(yCrop, 0, imageHeight);
    const width = clamp(widthCrop, 0, imageWidth - x);
    const height = clamp(heightCrop, 0, imageHeight - y);

    const canvas = new OffscreenCanvas(width, height);
    const ctx = ensure(canvas.getContext("2d"));
    ctx.imageSmoothingQuality = "high";

    ctx.drawImage(imageBitmap, x, y, width, height, 0, 0, width, height);

    return canvas.convertToBlob({ type: "image/jpeg", quality: 0.8 });
};

// export const saveFaceCrop = async (
//     imageBitmap: ImageBitmap,
//     faceID: string,
//     alignment: FaceAlignment,
// ) => {
//     const faceCrop = extractFaceCrop(imageBitmap, alignment);
//     const blob = await imageBitmapToBlob(faceCrop);
//     faceCrop.close();

//     const cache = await blobCache("face-crops");
//     await cache.put(faceID, blob);

//     return blob;
// };

// const imageBitmapToBlob = (imageBitmap: ImageBitmap) => {
//     const canvas = new OffscreenCanvas(imageBitmap.width, imageBitmap.height);
//     ensure(canvas.getContext("2d")).drawImage(imageBitmap, 0, 0);
//     return canvas.convertToBlob({ type: "image/jpeg", quality: 0.8 });
// };

const unnormalizeBox = (imageBitmap: ImageBitmap, alignment: FaceAlignment) => {
    const { width: imageWidth, height: imageHeight } = imageBitmap;

    const obb = alignment.boundingBox;
    // The faceBox is relative to the image size, and we need to convert
    // them to absolute values first.
    const faceX = obb.x * imageWidth;
    const faceY = obb.y * imageHeight;
    const faceWidth = obb.width * imageWidth;
    const faceHeight = obb.height * imageHeight;

    const bb = { x: faceX, y: faceY, width: faceWidth, height: faceHeight };
    return bb;
};

const extractFaceCrop = (
    imageBitmap: ImageBitmap,
    alignment: FaceAlignment,
) => {
    // TODO-ML: This algorithm is different from what is used by the mobile app.
    // Also, it needs to be something that can work fully using the embedding we
    // receive from remote - the `alignment.boundingBox` will not be available
    // to us in such cases.
    const paddedBox = roundBox(enlargeBox(alignment.boundingBox, 1.5));
    const outputSize = { width: paddedBox.width, height: paddedBox.height };

    const maxDimension = 256;
    const scale = Math.min(
        maxDimension / paddedBox.width,
        maxDimension / paddedBox.height,
    );

    if (scale < 1) {
        outputSize.width = Math.round(scale * paddedBox.width);
        outputSize.height = Math.round(scale * paddedBox.height);
    }

    const offscreen = new OffscreenCanvas(outputSize.width, outputSize.height);
    const offscreenCtx = ensure(offscreen.getContext("2d"));
    offscreenCtx.imageSmoothingQuality = "high";

    offscreenCtx.translate(outputSize.width / 2, outputSize.height / 2);

    const outputBox = {
        x: -outputSize.width / 2,
        y: -outputSize.height / 2,
        width: outputSize.width,
        height: outputSize.height,
    };

    const enlargedBox = enlargeBox(paddedBox, 1.5);
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

    return offscreen.convertToBlob({ type: "image/jpeg", quality: 0.8 });
};

/** Round all the components of the box. */
const roundBox = (box: Box): Box => ({
    x: Math.round(box.x),
    y: Math.round(box.y),
    width: Math.round(box.width),
    height: Math.round(box.height),
});

/** Increase the size of the given {@link box} by {@link factor}. */
const enlargeBox = (box: Box, factor: number): Box => {
    const center = { x: box.x + box.width / 2, y: box.y + box.height / 2 };
    const newWidth = factor * box.width;
    const newHeight = factor * box.height;

    return {
        x: center.x - newWidth / 2,
        y: center.y - newHeight / 2,
        width: newWidth,
        height: newHeight,
    };
};

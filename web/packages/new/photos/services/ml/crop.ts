import type { Box } from "@/new/photos/services/ml/types";
import { blobCache } from "@/next/blob-cache";
import { ensure } from "@/utils/ensure";
import type { FaceAlignment } from "./f-index";

export const saveFaceCrop = async (
    imageBitmap: ImageBitmap,
    faceID: string,
    alignment: FaceAlignment,
) => {
    const faceCrop = extractFaceCrop(imageBitmap, alignment);
    const blob = await imageBitmapToBlob(faceCrop);
    faceCrop.close();

    const cache = await blobCache("face-crops");
    await cache.put(faceID, blob);

    return blob;
};

const imageBitmapToBlob = (imageBitmap: ImageBitmap) => {
    const canvas = new OffscreenCanvas(imageBitmap.width, imageBitmap.height);
    ensure(canvas.getContext("2d")).drawImage(imageBitmap, 0, 0);
    return canvas.convertToBlob({ type: "image/jpeg", quality: 0.8 });
};

const extractFaceCrop = (
    imageBitmap: ImageBitmap,
    alignment: FaceAlignment,
): ImageBitmap => {
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

    return offscreen.transferToImageBitmap();
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

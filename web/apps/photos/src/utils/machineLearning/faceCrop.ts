import { openCache } from "@/next/cache";
import { BlobOptions } from "types/image";
import {
    FaceAlignment,
    FaceCrop,
    FaceCropConfig,
    StoredFaceCrop,
} from "types/machineLearning";
import { cropWithRotation, imageBitmapToBlob } from "utils/image";
import { enlargeBox } from ".";
import { Box } from "../../../thirdparty/face-api/classes";

export function getFaceCrop(
    imageBitmap: ImageBitmap,
    alignment: FaceAlignment,
    config: FaceCropConfig,
): FaceCrop {
    const box = getAlignedFaceBox(alignment);
    const scaleForPadding = 1 + config.padding * 2;
    const paddedBox = enlargeBox(box, scaleForPadding).round();
    const faceImageBitmap = cropWithRotation(imageBitmap, paddedBox, 0, {
        width: config.maxSize,
        height: config.maxSize,
    });

    return {
        image: faceImageBitmap,
        imageBox: paddedBox,
    };
}

function getAlignedFaceBox(alignment: FaceAlignment) {
    return new Box({
        x: alignment.center.x - alignment.size / 2,
        y: alignment.center.y - alignment.size / 2,
        width: alignment.size,
        height: alignment.size,
    }).round();
}

export async function storeFaceCrop(
    faceId: string,
    faceCrop: FaceCrop,
    blobOptions: BlobOptions,
): Promise<StoredFaceCrop> {
    const faceCropBlob = await imageBitmapToBlob(faceCrop.image, blobOptions);
    return storeFaceCropForBlob(faceId, faceCrop.imageBox, faceCropBlob);
}

async function storeFaceCropForBlob(
    faceId: string,
    imageBox: Box,
    faceCropBlob: Blob,
) {
    const faceCropUrl = `/${faceId}`;
    const faceCropResponse = new Response(faceCropBlob);
    const faceCropCache = await openCache("face-crops");
    await faceCropCache.put(faceCropUrl, faceCropResponse);
    return {
        imageUrl: faceCropUrl,
        imageBox: imageBox,
    };
}

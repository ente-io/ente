import { CacheStorageService } from "@ente/shared/storage/cacheStorage";
import { CACHES } from "@ente/shared/storage/cacheStorage/constants";
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
import { getAlignedFaceBox } from "./faceAlign";

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
    const faceCropCache = await CacheStorageService.open(CACHES.FACE_CROPS);
    await faceCropCache.put(faceCropUrl, faceCropResponse);
    return {
        imageUrl: faceCropUrl,
        imageBox: imageBox,
    };
}

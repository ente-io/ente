import { addLogLine } from "@ente/shared/logging";
import { CacheStorageService } from "@ente/shared/storage/cacheStorage";
import { CACHES } from "@ente/shared/storage/cacheStorage/constants";
import { getBlobFromCache } from "@ente/shared/storage/cacheStorage/helpers";
import { compose, Matrix, scale, translate } from "transformation-matrix";
import { BlobOptions, Dimensions } from "types/image";
import {
    AlignedFace,
    FaceAlignment,
    FaceCrop,
    FaceCropConfig,
    FaceDetection,
    MlFileData,
    StoredFaceCrop,
} from "types/machineLearning";
import { cropWithRotation, imageBitmapToBlob } from "utils/image";
import { enlargeBox } from ".";
import { Box } from "../../../thirdparty/face-api/classes";
import { getAlignedFaceBox } from "./faceAlign";
import { transformBox, transformPoints } from "./transform";

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

export async function storeFaceCropForBlob(
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

export async function storeFaceCrop(
    faceId: string,
    faceCrop: FaceCrop,
    blobOptions: BlobOptions,
): Promise<StoredFaceCrop> {
    const faceCropBlob = await imageBitmapToBlob(faceCrop.image, blobOptions);
    return storeFaceCropForBlob(faceId, faceCrop.imageBox, faceCropBlob);
}

export async function getFaceCropBlobFromStorage(
    storedFaceCrop: StoredFaceCrop,
): Promise<Blob> {
    return getBlobFromCache(CACHES.FACE_CROPS, storedFaceCrop.imageUrl);
}

export async function getFaceCropFromStorage(
    storedFaceCrop: StoredFaceCrop,
): Promise<FaceCrop> {
    const faceCropBlob = await getFaceCropBlobFromStorage(storedFaceCrop);
    const faceCropImage = await createImageBitmap(faceCropBlob);

    return {
        image: faceCropImage,
        imageBox: storedFaceCrop.imageBox,
    };
}

export async function removeOldFaceCrops(
    oldMLFileData: MlFileData,
    newMLFileData: MlFileData,
) {
    const newFaceCropUrls =
        newMLFileData?.faces
            ?.map((f) => f.crop?.imageUrl)
            ?.filter((fc) => fc !== null && fc !== undefined) || [];

    const oldFaceCropUrls =
        oldMLFileData?.faces
            ?.map((f) => f.crop?.imageUrl)
            ?.filter((fc) => fc !== null && fc !== undefined) || [];

    const unusedFaceCropUrls = oldFaceCropUrls.filter(
        (oldUrl) => !newFaceCropUrls.includes(oldUrl),
    );
    if (!unusedFaceCropUrls || unusedFaceCropUrls.length < 1) {
        return;
    }

    return removeFaceCropUrls(unusedFaceCropUrls);
}

export async function removeFaceCropUrls(faceCropUrls: Array<string>) {
    addLogLine("Removing face crop urls: ", JSON.stringify(faceCropUrls));
    const faceCropCache = await CacheStorageService.open(CACHES.FACE_CROPS);
    const urlRemovalPromises = faceCropUrls?.map((url) =>
        faceCropCache.delete(url),
    );
    return urlRemovalPromises && Promise.all(urlRemovalPromises);
}

export function extractFaceImageFromCrop(
    faceCrop: FaceCrop,
    box: Box,
    rotation: number,
    faceSize: number,
): ImageBitmap {
    const faceCropImage = faceCrop?.image;
    let imageBox = faceCrop?.imageBox;
    if (!faceCropImage || !imageBox) {
        throw Error("Face crop not present");
    }

    // TODO: Have better serialization to avoid creating new object manually when calling class methods
    imageBox = new Box(imageBox);
    const scale = faceCropImage.width / imageBox.width;
    const transformedBox = box
        .shift(-imageBox.x, -imageBox.y)
        .rescale(scale)
        .round();
    // addLogLine({ box, imageBox, faceCropImage, scale, scaledBox, scaledImageBox, shiftedBox });

    const faceSizeDimentions: Dimensions = {
        width: faceSize,
        height: faceSize,
    };
    const faceImage = cropWithRotation(
        faceCropImage,
        transformedBox,
        rotation,
        faceSizeDimentions,
        faceSizeDimentions,
    );

    return faceImage;
}

export async function ibExtractFaceImageFromCrop(
    faceCrop: FaceCrop,
    alignment: FaceAlignment,
    faceSize: number,
): Promise<ImageBitmap> {
    const box = getAlignedFaceBox(alignment);

    return extractFaceImageFromCrop(
        faceCrop,
        box,
        alignment.rotation,
        faceSize,
    );
}

export async function ibExtractFaceImagesFromCrops(
    faces: Array<AlignedFace>,
    faceSize: number,
): Promise<Array<ImageBitmap>> {
    const faceImagePromises = faces.map(async (alignedFace) => {
        const faceCrop = await getFaceCropFromStorage(alignedFace.crop);
        return ibExtractFaceImageFromCrop(
            faceCrop,
            alignedFace.alignment,
            faceSize,
        );
    });
    return Promise.all(faceImagePromises);
}

export function transformFace(faceDetection: FaceDetection, transform: Matrix) {
    return {
        ...faceDetection,

        box: transformBox(faceDetection.box, transform),
        landmarks: transformPoints(faceDetection.landmarks, transform),
    };
}

export function transformToFaceCropDims(
    faceCrop: FaceCrop,
    faceDetection: FaceDetection,
) {
    const imageBox = new Box(faceCrop.imageBox);

    const transform = compose(
        scale(faceCrop.image.width / imageBox.width),
        translate(-imageBox.x, -imageBox.y),
    );

    return transformFace(faceDetection, transform);
}

export function transformToImageDims(
    faceCrop: FaceCrop,
    faceDetection: FaceDetection,
) {
    const imageBox = new Box(faceCrop.imageBox);

    const transform = compose(
        translate(imageBox.x, imageBox.y),
        scale(imageBox.width / faceCrop.image.width),
    );

    return transformFace(faceDetection, transform);
}

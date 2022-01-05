import { compose, Matrix, scale, translate } from 'transformation-matrix';
import { BlobOptions, Dimensions } from 'types/image';
import {
    AlignedFace,
    FaceCropConfig,
    FaceCrop,
    StoredFaceCrop,
    DetectedFace,
    FACE_CROPS_CACHE_NAME,
    MlFileData,
} from 'types/machineLearning';
import { cropWithRotation, imageBitmapToBlob } from 'utils/image';
import { enlargeBox } from '.';
import { Box } from '../../../thirdparty/face-api/classes';
import { getAlignedFaceBox } from './faceAlign';
import { transformBox, transformPoints } from './transform';

export function getFaceCrop(
    imageBitmap: ImageBitmap,
    alignedFace: AlignedFace,
    config: FaceCropConfig
): FaceCrop {
    const box = getAlignedFaceBox(alignedFace);
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

export async function getStoredFaceCropForBlob(
    faceId: string,
    imageBox: Box,
    faceCropBlob: Blob
) {
    const faceCropUrl = `/${faceId}`;
    const faceCropResponse = new Response(faceCropBlob);
    const faceCropCache = await caches.open(FACE_CROPS_CACHE_NAME);
    await faceCropCache.put(faceCropUrl, faceCropResponse);
    return {
        imageUrl: faceCropUrl,
        imageBox: imageBox,
    };
}

export async function getStoredFaceCrop(
    faceId: string,
    faceCrop: FaceCrop,
    blobOptions: BlobOptions
): Promise<StoredFaceCrop> {
    const faceCropBlob = await imageBitmapToBlob(faceCrop.image, blobOptions);
    return getStoredFaceCropForBlob(faceId, faceCrop.imageBox, faceCropBlob);
}

export async function getFaceImageBlobFromStorage(
    storedFaceCrop: StoredFaceCrop
): Promise<Blob> {
    const faceCropCache = await caches.open(FACE_CROPS_CACHE_NAME);
    const faceCropResponse = await faceCropCache.match(storedFaceCrop.imageUrl);

    return faceCropResponse.blob();
}

export async function getFaceCropFromStorage(
    storedFaceCrop: StoredFaceCrop
): Promise<FaceCrop> {
    const faceCropBlob = await getFaceImageBlobFromStorage(storedFaceCrop);
    const faceCropImage = await createImageBitmap(faceCropBlob);

    return {
        image: faceCropImage,
        imageBox: storedFaceCrop.imageBox,
    };
}

export async function removeOldFaceCrops(
    oldMLFileData: MlFileData,
    newMLFileData: MlFileData
) {
    const newFaceCropUrls =
        newMLFileData?.faces
            ?.map((f) => f.faceCrop?.imageUrl)
            ?.filter((fc) => fc !== null && fc !== undefined) || [];

    const oldFaceCropUrls =
        oldMLFileData?.faces
            ?.map((f) => f.faceCrop?.imageUrl)
            ?.filter((fc) => fc !== null && fc !== undefined) || [];

    const unusedFaceCropUrls = oldFaceCropUrls.filter(
        (oldUrl) => !newFaceCropUrls.includes(oldUrl)
    );
    if (!unusedFaceCropUrls || unusedFaceCropUrls.length < 1) {
        return;
    }

    return removeFaceCropUrls(unusedFaceCropUrls);
}

export async function removeFaceCropUrls(faceCropUrls: Array<string>) {
    console.log('Removing face crop urls: ', faceCropUrls);
    const faceCropCache = await caches.open(FACE_CROPS_CACHE_NAME);
    const urlRemovalPromises = faceCropUrls?.map((url) =>
        faceCropCache.delete(url)
    );
    return urlRemovalPromises && Promise.all(urlRemovalPromises);
}

export function extractFaceImageFromCrop(
    faceCrop: FaceCrop,
    box: Box,
    rotation: number,
    faceSize: number
): ImageBitmap {
    const faceCropImage = faceCrop?.image;
    let imageBox = faceCrop?.imageBox;
    if (!faceCropImage || !imageBox) {
        throw Error('Face crop not present');
    }

    // TODO: Have better serialization to avoid creating new object manually when calling class methods
    imageBox = new Box(imageBox);
    const scale = faceCropImage.width / imageBox.width;
    const transformedBox = box
        .shift(-imageBox.x, -imageBox.y)
        .rescale(scale)
        .round();
    // console.log({ box, imageBox, faceCropImage, scale, scaledBox, scaledImageBox, shiftedBox });

    const faceSizeDimentions: Dimensions = {
        width: faceSize,
        height: faceSize,
    };
    const faceImage = cropWithRotation(
        faceCropImage,
        transformedBox,
        rotation,
        faceSizeDimentions,
        faceSizeDimentions
    );

    return faceImage;
}

export async function ibExtractFaceImageFromCrop(
    alignedFace: AlignedFace,
    faceSize: number,
    usingFaceCrop?: FaceCrop
): Promise<ImageBitmap> {
    const box = getAlignedFaceBox(alignedFace);
    const faceCrop =
        usingFaceCrop || (await getFaceCropFromStorage(alignedFace.faceCrop));

    return extractFaceImageFromCrop(
        { image: faceCrop.image, imageBox: faceCrop.imageBox },
        box,
        alignedFace.rotation,
        faceSize
    );
}

export async function ibExtractFaceImagesFromCrops(
    faces: AlignedFace[],
    faceSize: number
): Promise<Array<ImageBitmap>> {
    const faceImagePromises = faces.map((f) =>
        ibExtractFaceImageFromCrop(f, faceSize)
    );
    return Promise.all(faceImagePromises);
}

export function transformFace(face: DetectedFace, transform: Matrix) {
    return {
        ...face,

        box: transformBox(face.box, transform),
        landmarks: transformPoints(face.landmarks, transform),
    };
}

export function transformToFaceCropDims(
    faceCrop: FaceCrop,
    detectedFace: DetectedFace
) {
    const imageBox = new Box(faceCrop.imageBox);

    const transform = compose(
        scale(faceCrop.image.width / imageBox.width),
        translate(-imageBox.x, -imageBox.y)
    );

    return transformFace(detectedFace, transform);
}

export function transformToImageDims(
    faceCrop: FaceCrop,
    detectedFace: DetectedFace
) {
    const imageBox = new Box(faceCrop.imageBox);

    const transform = compose(
        translate(imageBox.x, imageBox.y),
        scale(imageBox.width / faceCrop.image.width)
    );

    return transformFace(detectedFace, transform);
}

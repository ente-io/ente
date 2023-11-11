import { NormalizedFace } from 'blazeface-back';
import * as tf from '@tensorflow/tfjs-core';
import {
    BLAZEFACE_FACE_SIZE,
    ML_SYNC_DOWNLOAD_TIMEOUT_MS,
} from 'constants/mlConfig';
import { euclidean } from 'hdbscan';
import PQueue from 'p-queue';
import DownloadManager from 'services/downloadManager';
import { getLocalFiles } from 'services/fileService';
import { EnteFile } from 'types/file';
import { Dimensions } from 'types/image';
import {
    RealWorldObject,
    AlignedFace,
    DetectedFace,
    DetectedObject,
    Face,
    FaceImageBlob,
    MlFileData,
    Person,
    Versioned,
} from 'types/machineLearning';
// import { mlFilesStore, mlPeopleStore } from 'utils/storage/mlStorage';
import { getRenderableImage } from 'utils/file';
import { imageBitmapToBlob } from 'utils/image';
import { cached } from '@ente/shared/storage/cacheStorage/helpers';
import mlIDbStorage from 'utils/storage/mlIDbStorage';
import { Box, Point } from '../../../thirdparty/face-api/classes';
import {
    getArcfaceAlignment,
    ibExtractFaceImage,
    ibExtractFaceImages,
} from './faceAlign';
import {
    getFaceCropBlobFromStorage,
    ibExtractFaceImagesFromCrops,
} from './faceCrop';
import { CACHES } from '@ente/shared/storage/cacheStorage/constants';
import { FILE_TYPE } from 'constants/file';
import { decodeLivePhoto } from 'services/livePhotoService';
import { addLogLine } from '@ente/shared/logging';
import { Remote } from 'comlink';
import { DedicatedCryptoWorker } from '@ente/shared/crypto/internal/crypto.worker';

export function f32Average(descriptors: Float32Array[]) {
    if (descriptors.length < 1) {
        throw Error('f32Average: input size 0');
    }

    if (descriptors.length === 1) {
        return descriptors[0];
    }

    const f32Size = descriptors[0].length;
    const avg = new Float32Array(f32Size);

    for (let index = 0; index < f32Size; index++) {
        avg[index] = descriptors[0][index];
        for (let desc = 1; desc < descriptors.length; desc++) {
            avg[index] = avg[index] + descriptors[desc][index];
        }
        avg[index] = avg[index] / descriptors.length;
    }

    return avg;
}

export function isTensor(tensor: any, dim: number) {
    return tensor instanceof tf.Tensor && tensor.shape.length === dim;
}

export function isTensor1D(tensor: any): tensor is tf.Tensor1D {
    return isTensor(tensor, 1);
}

export function isTensor2D(tensor: any): tensor is tf.Tensor2D {
    return isTensor(tensor, 2);
}

export function isTensor3D(tensor: any): tensor is tf.Tensor3D {
    return isTensor(tensor, 3);
}

export function isTensor4D(tensor: any): tensor is tf.Tensor4D {
    return isTensor(tensor, 4);
}

export function toTensor4D(
    image: tf.Tensor3D | tf.Tensor4D,
    dtype?: tf.DataType
) {
    return tf.tidy(() => {
        let reshapedImage: tf.Tensor4D;
        if (isTensor3D(image)) {
            reshapedImage = tf.expandDims(image, 0);
        } else if (isTensor4D(image)) {
            reshapedImage = image;
        } else {
            throw Error('toTensor4D only supports Tensor3D and Tensor4D input');
        }
        if (dtype) {
            reshapedImage = tf.cast(reshapedImage, dtype);
        }

        return reshapedImage;
    });
}

export function imageBitmapsToTensor4D(imageBitmaps: Array<ImageBitmap>) {
    return tf.tidy(() => {
        const tfImages = imageBitmaps.map((ib) => tf.browser.fromPixels(ib));
        return tf.stack(tfImages) as tf.Tensor4D;
    });
}

export function extractFaces(
    image: tf.Tensor3D | tf.Tensor4D,
    facebBoxes: Array<Box>,
    faceSize: number
) {
    return tf.tidy(() => {
        const reshapedImage = toTensor4D(image, 'float32');

        const boxes = facebBoxes.map((box) => {
            const normalized = box.rescale({
                width: 1 / reshapedImage.shape[2],
                height: 1 / reshapedImage.shape[1],
            });

            return [
                normalized.top,
                normalized.left,
                normalized.bottom,
                normalized.right,
            ];
        });

        // addLogLine('boxes: ', boxes[0]);

        const faceImagesTensor = tf.image.cropAndResize(
            reshapedImage,
            boxes,
            tf.fill([boxes.length], 0, 'int32'),
            [faceSize, faceSize]
        );

        return faceImagesTensor;
    });
}

export function newBox(x: number, y: number, width: number, height: number) {
    return new Box({ x, y, width, height });
}

export function newBoxFromPoints(
    left: number,
    top: number,
    right: number,
    bottom: number
) {
    return new Box({ left, top, right, bottom });
}

export function normFaceBox(face: NormalizedFace) {
    return newBoxFromPoints(
        face.topLeft[0],
        face.topLeft[1],
        face.bottomRight[0],
        face.bottomRight[1]
    );
}

export function getBoxCenterPt(topLeft: Point, bottomRight: Point): Point {
    return topLeft.add(bottomRight.sub(topLeft).div(new Point(2, 2)));
}

export function getBoxCenter(box: Box): Point {
    return getBoxCenterPt(box.topLeft, box.bottomRight);
}

export function enlargeBox(box: Box, factor: number = 1.5) {
    const center = getBoxCenter(box);
    const size = new Point(box.width, box.height);
    const newHalfSize = new Point((factor * size.x) / 2, (factor * size.y) / 2);

    return new Box({
        left: center.x - newHalfSize.x,
        top: center.y - newHalfSize.y,
        right: center.x + newHalfSize.x,
        bottom: center.y + newHalfSize.y,
    });
}

export function normalizeRadians(angle: number) {
    return angle - 2 * Math.PI * Math.floor((angle + Math.PI) / (2 * Math.PI));
}

export function computeRotation(point1: Point, point2: Point) {
    const radians =
        Math.PI / 2 - Math.atan2(-(point2.y - point1.y), point2.x - point1.x);
    return normalizeRadians(radians);
}

export function getAllFacesFromMap(allFacesMap: Map<number, Array<Face>>) {
    const allFaces = [...allFacesMap.values()].flat();

    return allFaces;
}

export function getAllObjectsFromMap(
    allObjectsMap: Map<number, Array<RealWorldObject>>
) {
    return [...allObjectsMap.values()].flat();
}

export async function getLocalFile(fileId: number) {
    const localFiles = await getLocalFiles();
    return localFiles.find((f) => f.id === fileId);
}

export async function getFaceImage(
    face: AlignedFace,
    token: string,
    faceSize: number = BLAZEFACE_FACE_SIZE,
    file?: EnteFile
): Promise<FaceImageBlob> {
    if (!file) {
        file = await getLocalFile(face.fileId);
    }

    const imageBitmap = await getOriginalImageBitmap(file, token);
    const faceImageBitmap = ibExtractFaceImage(
        imageBitmap,
        face.alignment,
        faceSize
    );
    const faceImage = imageBitmapToBlob(faceImageBitmap);
    faceImageBitmap.close();
    imageBitmap.close();

    return faceImage;
}

export async function extractFaceImages(
    faces: Array<AlignedFace>,
    faceSize: number,
    image?: ImageBitmap
) {
    if (faces.length === faces.filter((f) => f.crop).length) {
        return ibExtractFaceImagesFromCrops(faces, faceSize);
    } else if (image) {
        const faceAlignments = faces.map((f) => f.alignment);
        return ibExtractFaceImages(image, faceAlignments, faceSize);
    } else {
        throw Error(
            'Either face crops or image is required to extract face images'
        );
    }
}

export function leftFillNum(num: number, length: number, padding: number) {
    return num.toString().padStart(length, padding.toString());
}

// TODO: same face can not be only based on this id,
// this gives same id to faces whose arcface center lies in same box of 1% image grid
// maximum distance for same id will be around √2%
// will give same id in most of the cases, except for face centers lying near grid edges
// faces with same id should be treated as same face, and diffrent id should be tested further
// further test can rely on nearest face within certain threshold in same image
// can also explore spatial index similar to Geohash for indexing, but overkill
// for mostly single digit faces in one image
// also check if this needs to be globally unique or unique for a user
export function getFaceId(detectedFace: DetectedFace, imageDims: Dimensions) {
    const arcFaceAlignedFace = getArcfaceAlignment(detectedFace.detection);
    const imgDimPoint = new Point(imageDims.width, imageDims.height);
    const gridPt = arcFaceAlignedFace.center
        .mul(new Point(100, 100))
        .div(imgDimPoint)
        .floor()
        .bound(0, 99);
    const gridPaddedX = leftFillNum(gridPt.x, 2, 0);
    const gridPaddedY = leftFillNum(gridPt.y, 2, 0);

    return `${detectedFace.fileId}-${gridPaddedX}-${gridPaddedY}`;
}

export function getObjectId(
    detectedObject: DetectedObject,
    imageDims: Dimensions
) {
    const imgDimPoint = new Point(imageDims.width, imageDims.height);
    const objectCenterPoint = new Point(
        detectedObject.detection.bbox[2] / 2,
        detectedObject.detection.bbox[3] / 2
    );
    const gridPt = objectCenterPoint
        .mul(new Point(100, 100))
        .div(imgDimPoint)
        .floor()
        .bound(0, 99);
    const gridPaddedX = leftFillNum(gridPt.x, 2, 0);
    const gridPaddedY = leftFillNum(gridPt.y, 2, 0);

    return `${detectedObject.fileID}-${gridPaddedX}-${gridPaddedY}`;
}

export async function getTFImage(blob): Promise<tf.Tensor3D> {
    const imageBitmap = await createImageBitmap(blob);
    const tfImage = tf.browser.fromPixels(imageBitmap);
    imageBitmap.close();

    return tfImage;
}

export async function getImageBlobBitmap(blob: Blob): Promise<ImageBitmap> {
    return await createImageBitmap(blob);
}

// export async function getTFImageUsingJpegJS(blob: Blob): Promise<TFImageBitmap> {
//     const imageData = jpegjs.decode(await blob.arrayBuffer());
//     const tfImage = tf.browser.fromPixels(imageData);

//     return new TFImageBitmap(undefined, tfImage);
// }

async function getOriginalFile(
    file: EnteFile,
    token: string,
    enteWorker?: Remote<DedicatedCryptoWorker>,
    queue?: PQueue
) {
    let fileStream;
    if (queue) {
        fileStream = await queue.add(() =>
            DownloadManager.downloadFile(
                file,
                token,
                enteWorker,
                ML_SYNC_DOWNLOAD_TIMEOUT_MS
            )
        );
    } else {
        fileStream = await DownloadManager.downloadFile(
            file,
            token,
            enteWorker
        );
    }
    return new Response(fileStream).blob();
}

async function getOriginalConvertedFile(
    file: EnteFile,
    token: string,
    enteWorker?: Remote<DedicatedCryptoWorker>,
    queue?: PQueue
) {
    const fileBlob = await getOriginalFile(file, token, enteWorker, queue);
    if (file.metadata.fileType === FILE_TYPE.IMAGE) {
        return await getRenderableImage(file.metadata.title, fileBlob);
    } else {
        const livePhoto = await decodeLivePhoto(file, fileBlob);
        return await getRenderableImage(
            livePhoto.imageNameTitle,
            new Blob([livePhoto.image])
        );
    }
}

export async function getOriginalImageBitmap(
    file: EnteFile,
    token: string,
    enteWorker?: Remote<DedicatedCryptoWorker>,
    queue?: PQueue,
    useCache: boolean = false
) {
    let fileBlob;

    if (useCache) {
        fileBlob = await cached(CACHES.FILES, file.id.toString(), () => {
            return getOriginalConvertedFile(file, token, enteWorker, queue);
        });
    } else {
        fileBlob = await getOriginalConvertedFile(
            file,
            token,
            enteWorker,
            queue
        );
    }
    addLogLine('[MLService] Got file: ', file.id.toString());

    return getImageBlobBitmap(fileBlob);
}

export async function getThumbnailImageBitmap(
    file: EnteFile,
    token: string,
    enteWorker?: Remote<DedicatedCryptoWorker>
) {
    const fileUrl = await DownloadManager.getThumbnail(
        file,
        token,
        enteWorker,
        ML_SYNC_DOWNLOAD_TIMEOUT_MS
    );
    addLogLine('[MLService] Got thumbnail: ', file.id.toString());

    const thumbFile = await fetch(fileUrl);

    return getImageBlobBitmap(await thumbFile.blob());
}

export async function getLocalFileImageBitmap(
    enteFile: EnteFile,
    localFile: globalThis.File
) {
    let fileBlob = localFile as Blob;
    fileBlob = await getRenderableImage(enteFile.metadata.title, fileBlob);
    return getImageBlobBitmap(fileBlob);
}

export async function getPeopleList(file: EnteFile): Promise<Array<Person>> {
    let startTime = Date.now();
    const mlFileData: MlFileData = await mlIDbStorage.getFile(file.id);
    addLogLine(
        'getPeopleList:mlFilesStore:getItem',
        Date.now() - startTime,
        'ms'
    );
    if (!mlFileData?.faces || mlFileData.faces.length < 1) {
        return [];
    }

    const peopleIds = mlFileData.faces
        .filter((f) => f.personId !== null && f.personId !== undefined)
        .map((f) => f.personId);
    if (!peopleIds || peopleIds.length < 1) {
        return [];
    }
    // addLogLine("peopleIds: ", peopleIds);
    startTime = Date.now();
    const peoplePromises = peopleIds.map(
        (p) => mlIDbStorage.getPerson(p) as Promise<Person>
    );
    const peopleList = await Promise.all(peoplePromises);
    addLogLine(
        'getPeopleList:mlPeopleStore:getItems',
        Date.now() - startTime,
        'ms'
    );
    // addLogLine("peopleList: ", peopleList);

    return peopleList;
}

export async function getUnidentifiedFaces(
    file: EnteFile
): Promise<Array<Face>> {
    const mlFileData: MlFileData = await mlIDbStorage.getFile(file.id);

    return mlFileData?.faces?.filter(
        (f) => f.personId === null || f.personId === undefined
    );
}

export async function getFaceCropBlobs(
    faces: Array<Face>
): Promise<Array<FaceImageBlob>> {
    const faceCrops = faces
        .map((f) => f.crop)
        .filter((faceCrop) => faceCrop !== null && faceCrop !== undefined);

    return (
        faceCrops &&
        Promise.all(
            faceCrops.map((faceCrop) => getFaceCropBlobFromStorage(faceCrop))
        )
    );
}

export async function getAllPeople(limit: number = undefined) {
    let people: Array<Person> = await mlIDbStorage.getAllPeople();
    // await mlPeopleStore.iterate<Person, void>((person) => {
    //     people.push(person);
    // });
    people = people ?? [];
    return people
        .sort((p1, p2) => p2.files.length - p1.files.length)
        .slice(0, limit);
}

export function findFirstIfSorted<T>(
    elements: Array<T>,
    comparator: (a: T, b: T) => number
) {
    if (!elements || elements.length < 1) {
        return;
    }
    let first = elements[0];

    for (let i = 1; i < elements.length; i++) {
        const comp = comparator(elements[i], first);
        if (comp < 0) {
            first = elements[i];
        }
    }

    return first;
}

export function isDifferentOrOld(
    method: Versioned<string>,
    thanMethod: Versioned<string>
) {
    return (
        !method ||
        method.value !== thanMethod.value ||
        method.version < thanMethod.version
    );
}

function primitiveArrayEquals(a, b) {
    return (
        Array.isArray(a) &&
        Array.isArray(b) &&
        a.length === b.length &&
        a.every((val, index) => val === b[index])
    );
}

export function areFaceIdsSame(ofFaces: Array<Face>, toFaces: Array<Face>) {
    if (
        (ofFaces === null || ofFaces === undefined) &&
        (toFaces === null || toFaces === undefined)
    ) {
        return true;
    }
    return primitiveArrayEquals(
        ofFaces?.map((f) => f.id),
        toFaces?.map((f) => f.id)
    );
}

export function getNearestPointIndex(
    toPoint: Point,
    fromPoints: Array<Point>,
    maxDistance?: number
) {
    const dists = fromPoints.map((point, i) => ({
        index: i,
        point: point,
        distance: euclidean([point.x, point.y], [toPoint.x, toPoint.y]),
    }));
    const nearest = findFirstIfSorted(
        dists,
        (a, b) => Math.abs(a.distance) - Math.abs(b.distance)
    );

    // addLogLine('Nearest dist: ', nearest.distance, maxDistance);
    if (!maxDistance || nearest.distance <= maxDistance) {
        return nearest.index;
    }
}

export function logQueueStats(queue: PQueue, name: string) {
    queue.on('active', () =>
        addLogLine(
            `queuestats: ${name}: Active, Size: ${queue.size} Pending: ${queue.pending}`
        )
    );
    queue.on('idle', () => addLogLine(`queuestats: ${name}: Idle`));
    queue.on('error', (error) =>
        console.error(`queuestats: ${name}: Error, `, error)
    );
}

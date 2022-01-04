import * as tf from '@tensorflow/tfjs-core';
import DownloadManager from 'services/downloadManager';
import { File, getLocalFiles } from 'services/fileService';
import { Box, Point } from '../../../thirdparty/face-api/classes';
import {
    BLAZEFACE_FACE_SIZE,
    Face,
    FaceImageBlob,
    MlFileData,
    MLSyncConfig,
    Person,
    Versioned,
} from 'types/machineLearning';
import { ibExtractFaceImage } from './faceAlign';
// import { mlFilesStore, mlPeopleStore } from 'utils/storage/mlStorage';
import { convertForPreview, needsConversionForPreview } from 'utils/file';
import { cached } from 'utils/storage/cache';
import { imageBitmapToBlob } from 'utils/image';
import { NormalizedFace } from '@tensorflow-models/blazeface';
import PQueue from 'p-queue';
import mlIDbStorage from 'utils/storage/mlIDbStorage';

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

        // console.log('boxes: ', boxes[0]);

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

export async function getFaceImage(
    face: Face,
    token: string,
    faceSize: number = BLAZEFACE_FACE_SIZE,
    file?: File
): Promise<FaceImageBlob> {
    if (!file) {
        const localFiles = await getLocalFiles();
        file = localFiles.find((f) => f.id === face.fileId);
    }

    const imageBitmap = await getOriginalImageBitmap(file, token);
    const faceImageBitmap = ibExtractFaceImage(imageBitmap, face, faceSize);
    const faceImage = imageBitmapToBlob(faceImageBitmap);
    faceImageBitmap.close();
    imageBitmap.close();

    return faceImage;
}

export async function getTFImage(blob): Promise<tf.Tensor3D> {
    const imageBitmap = await createImageBitmap(blob);
    const tfImage = tf.browser.fromPixels(imageBitmap);
    imageBitmap.close();

    return tfImage;
}

export async function getImageBitmap(blob: Blob): Promise<ImageBitmap> {
    return await createImageBitmap(blob);
}

// export async function getTFImageUsingJpegJS(blob: Blob): Promise<TFImageBitmap> {
//     const imageData = jpegjs.decode(await blob.arrayBuffer());
//     const tfImage = tf.browser.fromPixels(imageData);

//     return new TFImageBitmap(undefined, tfImage);
// }

async function getOriginalImageFile(
    file: File,
    token: string,
    enteWorker?: any,
    queue?: PQueue
) {
    let fileStream;
    if (queue) {
        fileStream = await queue.add(() =>
            DownloadManager.downloadFile(file, token, enteWorker)
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
    file: File,
    token: string,
    enteWorker?: any,
    queue?: PQueue
) {
    let fileBlob = await getOriginalImageFile(file, token, enteWorker, queue);
    if (needsConversionForPreview(file)) {
        fileBlob = await convertForPreview(file, fileBlob, enteWorker);
    }

    return fileBlob;
}

export async function getOriginalImageBitmap(
    file: File,
    token: string,
    enteWorker?: any,
    queue?: PQueue,
    useCache: boolean = false
) {
    let fileBlob;

    if (useCache) {
        fileBlob = await cached('files', '/' + file.id.toString(), () => {
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
    console.log('[MLService] Got file: ', file.id.toString());

    return getImageBitmap(fileBlob);
}

export async function getThumbnailImageBitmap(file: File, token: string) {
    const fileUrl = await DownloadManager.getThumbnail(file, token);
    console.log('[MLService] Got thumbnail: ', file.id.toString(), fileUrl);

    const thumbFile = await fetch(fileUrl);

    return getImageBitmap(await thumbFile.blob());
}

export async function getLocalFileImageBitmap(localFile: globalThis.File) {
    // TODO: handle formats not supported by createImageBitmap, like heic
    return getImageBitmap(localFile);
}

export async function getPeopleList(file: File): Promise<Array<Person>> {
    console.time('getPeopleList:mlFilesStore:getItem');
    const mlFileData: MlFileData = await mlIDbStorage.getFile(file.id);
    console.timeEnd('getPeopleList:mlFilesStore:getItem');
    if (!mlFileData?.faces || mlFileData.faces.length < 1) {
        return [];
    }

    const peopleIds = mlFileData.faces
        .filter((f) => f.personId !== null && f.personId !== undefined)
        .map((f) => f.personId);
    if (!peopleIds || peopleIds.length < 1) {
        return [];
    }
    // console.log("peopleIds: ", peopleIds);
    console.time('getPeopleList:mlPeopleStore:getItems');
    const peoplePromises = peopleIds.map(
        (p) => mlIDbStorage.getPerson(p) as Promise<Person>
    );
    const peopleList = await Promise.all(peoplePromises);
    console.timeEnd('getPeopleList:mlPeopleStore:getItems');
    // console.log("peopleList: ", peopleList);

    return peopleList;
}

export async function getUnidentifiedFaces(
    file: File
): Promise<Array<FaceImageBlob>> {
    const mlFileData: MlFileData = await mlIDbStorage.getFile(file.id);

    const faceImages = mlFileData?.faces
        ?.filter((f) => f.personId === null || f.personId === undefined)
        .map((f) => f.faceCrop?.image)
        .filter((image) => image !== null && image !== undefined);

    return faceImages;
}

export async function getAllPeople() {
    const people: Array<Person> = await mlIDbStorage.getAllPeople();
    // await mlPeopleStore.iterate<Person, void>((person) => {
    //     people.push(person);
    // });

    return people.sort((p1, p2) => p2.files.length - p1.files.length);
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
        if (comp > 0) {
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

export function logQueueStats(queue: PQueue, name: string) {
    queue.on('active', () => {
        console.log(
            `queuestats: ${name}: Working on next item.  Size: ${queue.size}  Pending: ${queue.pending}`
        );
    });
}

export async function getMLSyncConfig() {
    return DEFAULT_ML_SYNC_CONFIG;
}

const DEFAULT_ML_SYNC_CONFIG: MLSyncConfig = {
    syncIntervalSec: 30,
    maxSyncIntervalSec: 32768,
    batchSize: 200,
    imageSource: 'Original',
    faceDetection: {
        method: 'BlazeFace',
        minFaceSize: 32,
    },
    faceCrop: {
        enabled: true,
        method: 'ArcFace',
        padding: 0.25,
        maxSize: 256,
        blobOptions: {
            type: 'image/jpeg',
            quality: 0.8,
        },
    },
    faceAlignment: {
        method: 'ArcFace',
    },
    faceEmbedding: {
        method: 'MobileFaceNet',
        faceSize: 112,
        generateTsne: true,
    },
    faceClustering: {
        method: 'Hdbscan',
        minClusterSize: 5,
        minInputSize: 50,
        // maxDistanceInsideCluster: 0.4,
        generateDebugInfo: true,
    },
    // tsne: {
    //     samples: 200,
    //     dim: 2,
    //     perplexity: 10.0,
    //     learningRate: 10.0,
    //     metric: 'euclidean',
    // },
    mlVersion: 2,
};

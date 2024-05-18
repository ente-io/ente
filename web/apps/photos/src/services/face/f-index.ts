import { openCache } from "@/next/blob-cache";
import log from "@/next/log";
import { workerBridge } from "@/next/worker/worker-bridge";
import { Matrix } from "ml-matrix";
import mlIDbStorage from "services/face/db";
import { detectFaces, getRelativeDetection } from "services/face/detect";
import { Box, Point, enlargeBox } from "services/face/geom";
import {
    DetectedFace,
    Face,
    FaceAlignment,
    FaceCrop,
    FaceDetection,
    FaceEmbedding,
    MLSyncFileContext,
    type MlFileData,
} from "services/face/types";
import { defaultMLVersion } from "services/machineLearning/machineLearningService";
import { getSimilarityTransformation } from "similarity-transformation";
import type { EnteFile } from "types/file";
import {
    createGrayscaleIntMatrixFromNormalized2List,
    cropWithRotation,
    fetchImageBitmap,
    fetchImageBitmapForContext,
    getFaceId,
    getLocalFile,
    imageBitmapToBlob,
    warpAffineFloat32List,
} from "./image";

/**
 * Index faces in the given file.
 *
 * This function is the entry point to the indexing pipeline. The file goes
 * through various stages:
 *
 * 1. Downloading the original if needed.
 * 2. Detect faces using ONNX/YOLO
 * 3. Align the face rectangles, compute blur.
 * 4. Compute embbeddings for the detected face (crops).
 *
 * Once all of it is done, it returns the face rectangles and embeddings to the
 * higher layer (which saves them to locally for offline use, and encrypts and
 * uploads them to the user's remote storage so that their other devices can
 * download them instead of needing to reindex).
 */
export const indexFaces = async (
    enteFile: EnteFile,
    localFile?: globalThis.File,
) => {
    log.debug(() => ({ a: "Indexing faces in file", enteFile }));
    const fileContext: MLSyncFileContext = { enteFile, localFile };

    const newMlFile = (fileContext.newMlFile = {
        fileId: enteFile.id,
        mlVersion: defaultMLVersion,
        errorCount: 0,
    } as MlFileData);

    try {
        await fetchImageBitmapForContext(fileContext);
        await syncFileAnalyzeFaces(fileContext);
        newMlFile.errorCount = 0;
    } finally {
        fileContext.imageBitmap && fileContext.imageBitmap.close();
    }

    return newMlFile;
};

export const syncFileAnalyzeFaces = async (fileContext: MLSyncFileContext) => {
    const { newMlFile } = fileContext;
    const startTime = Date.now();

    await syncFileFaceDetections(fileContext);

    if (newMlFile.faces && newMlFile.faces.length > 0) {
        await syncFileFaceCrops(fileContext);

        const alignedFacesData = await syncFileFaceAlignments(fileContext);

        await syncFileFaceEmbeddings(fileContext, alignedFacesData);

        await syncFileFaceMakeRelativeDetections(fileContext);
    }
    log.debug(
        () =>
            `Face detection for file ${fileContext.enteFile.id} took ${Math.round(Date.now() - startTime)} ms`,
    );
};

const syncFileFaceDetections = async (fileContext: MLSyncFileContext) => {
    const { newMlFile } = fileContext;
    fileContext.newDetection = true;
    const imageBitmap = await fetchImageBitmapForContext(fileContext);
    const faceDetections = await detectFaces(imageBitmap);
    // TODO: reenable faces filtering based on width
    const detectedFaces = faceDetections?.map((detection) => {
        return {
            fileId: fileContext.enteFile.id,
            detection,
        } as DetectedFace;
    });
    newMlFile.faces = detectedFaces?.map((detectedFace) => ({
        ...detectedFace,
        id: getFaceId(detectedFace, newMlFile.imageDimensions),
    }));
    // ?.filter((f) =>
    //     f.box.width > syncContext.config.faceDetection.minFaceSize
    // );
    log.info("[MLService] Detected Faces: ", newMlFile.faces?.length);
};

const syncFileFaceCrops = async (fileContext: MLSyncFileContext) => {
    const { newMlFile } = fileContext;
    const imageBitmap = await fetchImageBitmapForContext(fileContext);
    for (const face of newMlFile.faces) {
        await saveFaceCrop(imageBitmap, face);
    }
};

const syncFileFaceAlignments = async (
    fileContext: MLSyncFileContext,
): Promise<Float32Array> => {
    const { newMlFile } = fileContext;
    fileContext.newAlignment = true;
    const imageBitmap =
        fileContext.imageBitmap ||
        (await fetchImageBitmapForContext(fileContext));

    // Execute the face alignment calculations
    for (const face of newMlFile.faces) {
        face.alignment = faceAlignment(face.detection);
    }
    // Extract face images and convert to Float32Array
    const faceAlignments = newMlFile.faces.map((f) => f.alignment);
    const faceImages = await extractFaceImagesToFloat32(
        faceAlignments,
        mobileFaceNetFaceSize,
        imageBitmap,
    );
    const blurValues = detectBlur(faceImages, newMlFile.faces);
    newMlFile.faces.forEach((f, i) => (f.blurValue = blurValues[i]));

    imageBitmap.close();
    log.info("[MLService] alignedFaces: ", newMlFile.faces?.length);

    return faceImages;
};

// TODO-ML(MR): When is this used or is it as Blazeface leftover?
const ARCFACE_LANDMARKS = [
    [38.2946, 51.6963],
    [73.5318, 51.5014],
    [56.0252, 71.7366],
    [56.1396, 92.2848],
] as Array<[number, number]>;

const ARCFACE_LANDMARKS_FACE_SIZE = 112;

const ARC_FACE_5_LANDMARKS = [
    [38.2946, 51.6963],
    [73.5318, 51.5014],
    [56.0252, 71.7366],
    [41.5493, 92.3655],
    [70.7299, 92.2041],
] as Array<[number, number]>;

/**
 * Compute and return an {@link FaceAlignment} for the given face detection.
 *
 * @param faceDetection A geometry indicating a face detected in an image.
 */
export const faceAlignment = (faceDetection: FaceDetection): FaceAlignment => {
    const landmarkCount = faceDetection.landmarks.length;
    return getFaceAlignmentUsingSimilarityTransform(
        faceDetection,
        normalizeLandmarks(
            landmarkCount === 5 ? ARC_FACE_5_LANDMARKS : ARCFACE_LANDMARKS,
            ARCFACE_LANDMARKS_FACE_SIZE,
        ),
    );
};

function getFaceAlignmentUsingSimilarityTransform(
    faceDetection: FaceDetection,
    alignedLandmarks: Array<[number, number]>,
): FaceAlignment {
    const landmarksMat = new Matrix(
        faceDetection.landmarks
            .map((p) => [p.x, p.y])
            .slice(0, alignedLandmarks.length),
    ).transpose();
    const alignedLandmarksMat = new Matrix(alignedLandmarks).transpose();

    const simTransform = getSimilarityTransformation(
        landmarksMat,
        alignedLandmarksMat,
    );

    const RS = Matrix.mul(simTransform.rotation, simTransform.scale);
    const TR = simTransform.translation;

    const affineMatrix = [
        [RS.get(0, 0), RS.get(0, 1), TR.get(0, 0)],
        [RS.get(1, 0), RS.get(1, 1), TR.get(1, 0)],
        [0, 0, 1],
    ];

    const size = 1 / simTransform.scale;
    const meanTranslation = simTransform.toMean.sub(0.5).mul(size);
    const centerMat = simTransform.fromMean.sub(meanTranslation);
    const center = new Point(centerMat.get(0, 0), centerMat.get(1, 0));
    const rotation = -Math.atan2(
        simTransform.rotation.get(0, 1),
        simTransform.rotation.get(0, 0),
    );

    return {
        affineMatrix,
        center,
        size,
        rotation,
    };
}

function normalizeLandmarks(
    landmarks: Array<[number, number]>,
    faceSize: number,
): Array<[number, number]> {
    return landmarks.map((landmark) =>
        landmark.map((p) => p / faceSize),
    ) as Array<[number, number]>;
}

/**
 * Laplacian blur detection.
 */
export const detectBlur = (
    alignedFaces: Float32Array,
    faces: Face[],
): number[] => {
    const numFaces = Math.round(
        alignedFaces.length /
            (mobileFaceNetFaceSize * mobileFaceNetFaceSize * 3),
    );
    const blurValues: number[] = [];
    for (let i = 0; i < numFaces; i++) {
        const face = faces[i];
        const direction = faceDirection(face);
        const faceImage = createGrayscaleIntMatrixFromNormalized2List(
            alignedFaces,
            i,
        );
        const laplacian = applyLaplacian(faceImage, direction);
        blurValues.push(matrixVariance(laplacian));
    }
    return blurValues;
};

type FaceDirection = "left" | "right" | "straight";

const faceDirection = (face: Face): FaceDirection => {
    const landmarks = face.detection.landmarks;
    const leftEye = landmarks[0];
    const rightEye = landmarks[1];
    const nose = landmarks[2];
    const leftMouth = landmarks[3];
    const rightMouth = landmarks[4];

    const eyeDistanceX = Math.abs(rightEye.x - leftEye.x);
    const eyeDistanceY = Math.abs(rightEye.y - leftEye.y);
    const mouthDistanceY = Math.abs(rightMouth.y - leftMouth.y);

    const faceIsUpright =
        Math.max(leftEye.y, rightEye.y) + 0.5 * eyeDistanceY < nose.y &&
        nose.y + 0.5 * mouthDistanceY < Math.min(leftMouth.y, rightMouth.y);

    const noseStickingOutLeft =
        nose.x < Math.min(leftEye.x, rightEye.x) &&
        nose.x < Math.min(leftMouth.x, rightMouth.x);

    const noseStickingOutRight =
        nose.x > Math.max(leftEye.x, rightEye.x) &&
        nose.x > Math.max(leftMouth.x, rightMouth.x);

    const noseCloseToLeftEye =
        Math.abs(nose.x - leftEye.x) < 0.2 * eyeDistanceX;
    const noseCloseToRightEye =
        Math.abs(nose.x - rightEye.x) < 0.2 * eyeDistanceX;

    if (noseStickingOutLeft || (faceIsUpright && noseCloseToLeftEye)) {
        return "left";
    } else if (noseStickingOutRight || (faceIsUpright && noseCloseToRightEye)) {
        return "right";
    }

    return "straight";
};

/**
 * Return a new image by applying a Laplacian blur kernel to each pixel.
 */
const applyLaplacian = (
    image: number[][],
    direction: FaceDirection,
): number[][] => {
    const paddedImage: number[][] = padImage(image, direction);
    const numRows = paddedImage.length - 2;
    const numCols = paddedImage[0].length - 2;

    // Create an output image initialized to 0.
    const outputImage: number[][] = Array.from({ length: numRows }, () =>
        new Array(numCols).fill(0),
    );

    // Define the Laplacian kernel.
    const kernel: number[][] = [
        [0, 1, 0],
        [1, -4, 1],
        [0, 1, 0],
    ];

    // Apply the kernel to each pixel
    for (let i = 0; i < numRows; i++) {
        for (let j = 0; j < numCols; j++) {
            let sum = 0;
            for (let ki = 0; ki < 3; ki++) {
                for (let kj = 0; kj < 3; kj++) {
                    sum += paddedImage[i + ki][j + kj] * kernel[ki][kj];
                }
            }
            // Adjust the output value if necessary (e.g., clipping).
            outputImage[i][j] = sum;
        }
    }

    return outputImage;
};

const padImage = (image: number[][], direction: FaceDirection): number[][] => {
    const removeSideColumns = 56; /* must be even */

    const numRows = image.length;
    const numCols = image[0].length;
    const paddedNumCols = numCols + 2 - removeSideColumns;
    const paddedNumRows = numRows + 2;

    // Create a new matrix with extra padding.
    const paddedImage: number[][] = Array.from({ length: paddedNumRows }, () =>
        new Array(paddedNumCols).fill(0),
    );

    if (direction === "straight") {
        // Copy original image into the center of the padded image.
        for (let i = 0; i < numRows; i++) {
            for (let j = 0; j < paddedNumCols - 2; j++) {
                paddedImage[i + 1][j + 1] =
                    image[i][j + Math.round(removeSideColumns / 2)];
            }
        }
    } else if (direction === "left") {
        // If the face is facing left, we only take the right side of the face image.
        for (let i = 0; i < numRows; i++) {
            for (let j = 0; j < paddedNumCols - 2; j++) {
                paddedImage[i + 1][j + 1] = image[i][j + removeSideColumns];
            }
        }
    } else if (direction === "right") {
        // If the face is facing right, we only take the left side of the face image.
        for (let i = 0; i < numRows; i++) {
            for (let j = 0; j < paddedNumCols - 2; j++) {
                paddedImage[i + 1][j + 1] = image[i][j];
            }
        }
    }

    // Reflect padding
    // Top and bottom rows
    for (let j = 1; j <= paddedNumCols - 2; j++) {
        paddedImage[0][j] = paddedImage[2][j]; // Top row
        paddedImage[numRows + 1][j] = paddedImage[numRows - 1][j]; // Bottom row
    }
    // Left and right columns
    for (let i = 0; i < numRows + 2; i++) {
        paddedImage[i][0] = paddedImage[i][2]; // Left column
        paddedImage[i][paddedNumCols - 1] = paddedImage[i][paddedNumCols - 3]; // Right column
    }

    return paddedImage;
};

const matrixVariance = (matrix: number[][]): number => {
    const numRows = matrix.length;
    const numCols = matrix[0].length;
    const totalElements = numRows * numCols;

    // Calculate the mean.
    let mean: number = 0;
    matrix.forEach((row) => {
        row.forEach((value) => {
            mean += value;
        });
    });
    mean /= totalElements;

    // Calculate the variance.
    let variance: number = 0;
    matrix.forEach((row) => {
        row.forEach((value) => {
            const diff: number = value - mean;
            variance += diff * diff;
        });
    });
    variance /= totalElements;

    return variance;
};

const syncFileFaceEmbeddings = async (
    fileContext: MLSyncFileContext,
    alignedFacesInput: Float32Array,
) => {
    const { newMlFile } = fileContext;
    // TODO: when not storing face crops, image will be needed to extract faces
    // fileContext.imageBitmap ||
    //     (await this.getImageBitmap(fileContext));

    const embeddings = await faceEmbeddings(alignedFacesInput);
    newMlFile.faces.forEach((f, i) => (f.embedding = embeddings[i]));

    log.info("[MLService] facesWithEmbeddings: ", newMlFile.faces.length);
};

export const mobileFaceNetFaceSize = 112;

/**
 * Compute embeddings for the given {@link faceData}.
 *
 * The model used is MobileFaceNet, running in an ONNX runtime.
 */
export const faceEmbeddings = async (
    faceData: Float32Array,
): Promise<Array<FaceEmbedding>> => {
    const outputData = await workerBridge.faceEmbeddings(faceData);

    const embeddingSize = 192;
    const embeddings = new Array<FaceEmbedding>(
        outputData.length / embeddingSize,
    );
    for (let i = 0; i < embeddings.length; i++) {
        embeddings[i] = new Float32Array(
            outputData.slice(i * embeddingSize, (i + 1) * embeddingSize),
        );
    }
    return embeddings;
};

const syncFileFaceMakeRelativeDetections = async (
    fileContext: MLSyncFileContext,
) => {
    const { newMlFile } = fileContext;
    for (let i = 0; i < newMlFile.faces.length; i++) {
        const face = newMlFile.faces[i];
        if (face.detection.box.x + face.detection.box.width < 2) continue; // Skip if somehow already relative
        face.detection = getRelativeDetection(
            face.detection,
            newMlFile.imageDimensions,
        );
    }
};

export const saveFaceCrop = async (imageBitmap: ImageBitmap, face: Face) => {
    const faceCrop = getFaceCrop(imageBitmap, face.detection);

    const blob = await imageBitmapToBlob(faceCrop.image);

    const cache = await openCache("face-crops");
    await cache.put(face.id, blob);

    faceCrop.image.close();

    return blob;
};

export const getFaceCrop = (
    imageBitmap: ImageBitmap,
    faceDetection: FaceDetection,
): FaceCrop => {
    const alignment = faceAlignment(faceDetection);

    const padding = 0.25;
    const maxSize = 256;

    const alignmentBox = new Box({
        x: alignment.center.x - alignment.size / 2,
        y: alignment.center.y - alignment.size / 2,
        width: alignment.size,
        height: alignment.size,
    }).round();
    const scaleForPadding = 1 + padding * 2;
    const paddedBox = enlargeBox(alignmentBox, scaleForPadding).round();
    const faceImageBitmap = cropWithRotation(imageBitmap, paddedBox, 0, {
        width: maxSize,
        height: maxSize,
    });

    return {
        image: faceImageBitmap,
        imageBox: paddedBox,
    };
};

export const regenerateFaceCrop = async (faceID: string) => {
    const fileID = Number(faceID.split("-")[0]);
    const personFace = await mlIDbStorage.getFace(fileID, faceID);
    if (!personFace) {
        throw Error("Face not found");
    }

    const file = await getLocalFile(personFace.fileId);
    const imageBitmap = await fetchImageBitmap(file);
    return await saveFaceCrop(imageBitmap, personFace);
};

async function extractFaceImagesToFloat32(
    faceAlignments: Array<FaceAlignment>,
    faceSize: number,
    image: ImageBitmap,
): Promise<Float32Array> {
    const faceData = new Float32Array(
        faceAlignments.length * faceSize * faceSize * 3,
    );
    for (let i = 0; i < faceAlignments.length; i++) {
        const alignedFace = faceAlignments[i];
        const faceDataOffset = i * faceSize * faceSize * 3;
        warpAffineFloat32List(
            image,
            alignedFace,
            faceSize,
            faceData,
            faceDataOffset,
        );
    }
    return faceData;
}

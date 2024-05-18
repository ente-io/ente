import { FILE_TYPE } from "@/media/file-type";
import { openCache } from "@/next/blob-cache";
import log from "@/next/log";
import { workerBridge } from "@/next/worker/worker-bridge";
import { euclidean } from "hdbscan";
import { Matrix } from "ml-matrix";
import { Box, Dimensions, Point, enlargeBox } from "services/face/geom";
import {
    DetectedFace,
    Face,
    FaceAlignment,
    FaceCrop,
    FaceDetection,
    FaceEmbedding,
    type MlFileData,
} from "services/face/types";
import { defaultMLVersion } from "services/machineLearning/machineLearningService";
import { getSimilarityTransformation } from "similarity-transformation";
import type { EnteFile } from "types/file";
import {
    clamp,
    createGrayscaleIntMatrixFromNormalized2List,
    fetchImageBitmap,
    getLocalFileImageBitmap,
    pixelRGBBilinear,
    warpAffineFloat32List,
} from "./image";
import { transformFaceDetections } from "./transform-box";

/**
 * Index faces in the given file.
 *
 * This function is the entry point to the indexing pipeline. The file goes
 * through various stages:
 *
 * 1. Downloading the original if needed.
 * 2. Detect faces using ONNX/YOLO
 * 3. Align the face rectangles, compute blur.
 * 4. Compute embeddings for the detected face (crops).
 *
 * Once all of it is done, it returns the face rectangles and embeddings so that
 * they can be saved locally for offline use, and encrypts and uploads them to
 * the user's remote storage so that their other devices can download them
 * instead of needing to reindex.
 */
export const indexFaces = async (enteFile: EnteFile, localFile?: File) => {
    const startTime = Date.now();

    const imageBitmap = await fetchOrCreateImageBitmap(enteFile, localFile);
    let mlFile: MlFileData;
    try {
        mlFile = await indexFaces_(enteFile, imageBitmap);
    } finally {
        imageBitmap.close();
    }

    log.debug(() => {
        const ms = Math.round(Date.now() - startTime);
        const nf = mlFile.faces?.length ?? 0;
        return `Indexed ${nf} faces in file ${enteFile.id} (${ms} ms)`;
    });
    return mlFile;
};

interface MLSyncFileContext {
    enteFile: EnteFile;

    newMlFile?: MlFileData;

    imageBitmap?: ImageBitmap;
}

/**
 * Return a {@link ImageBitmap}, using {@link localFile} if present otherwise
 * downloading the source image corresponding to {@link enteFile} from remote.
 */
const fetchOrCreateImageBitmap = async (
    enteFile: EnteFile,
    localFile: File,
) => {
    const fileType = enteFile.metadata.fileType;
    if (localFile) {
        // TODO-ML(MR): Could also be image part of live photo?
        if (fileType !== FILE_TYPE.IMAGE)
            throw new Error("Local file of only image type is supported");

        return await getLocalFileImageBitmap(enteFile, localFile);
    } else if ([FILE_TYPE.IMAGE, FILE_TYPE.LIVE_PHOTO].includes(fileType)) {
        return await fetchImageBitmap(enteFile);
    } else {
        throw new Error(`Cannot index unsupported file type ${fileType}`);
    }
};

const indexFaces_ = async (enteFile: EnteFile, imageBitmap: ImageBitmap) => {
    const fileContext: MLSyncFileContext = { enteFile };

    const newMlFile = (fileContext.newMlFile = {
        fileId: enteFile.id,
        mlVersion: defaultMLVersion,
        errorCount: 0,
    } as MlFileData);

    fileContext.imageBitmap = imageBitmap;
    const { width, height } = imageBitmap;
    fileContext.newMlFile.imageDimensions = { width, height };

    const faceDetections = await detectFaces(imageBitmap);
    const detectedFaces = faceDetections?.map((detection) => {
        return {
            fileId: fileContext.enteFile.id,
            detection,
        } as DetectedFace;
    });
    newMlFile.faces = detectedFaces?.map((detectedFace) => ({
        ...detectedFace,
        id: makeFaceID(detectedFace, newMlFile.imageDimensions),
    }));
    // TODO-ML(MR): reenable faces filtering based on width
    // ?.filter((f) =>
    //     f.box.width > syncContext.config.faceDetection.minFaceSize
    // );

    if (newMlFile.faces && newMlFile.faces.length > 0) {
        await syncFileFaceCrops(fileContext);

        const alignedFacesData = await syncFileFaceAlignments(fileContext);

        await syncFileFaceEmbeddings(fileContext, alignedFacesData);

        await syncFileFaceMakeRelativeDetections(fileContext);
    }
    newMlFile.errorCount = 0;

    return newMlFile;
};

/**
 * Detect faces in the given {@link imageBitmap}.
 *
 * The model used is YOLO, running in an ONNX runtime.
 */
const detectFaces = async (
    imageBitmap: ImageBitmap,
): Promise<Array<FaceDetection>> => {
    const rect = ({ width, height }: { width: number; height: number }) =>
        new Box({ x: 0, y: 0, width, height });

    const { yoloInput, yoloSize } =
        convertToYOLOInputFloat32ChannelsFirst(imageBitmap);
    const yoloOutput = await workerBridge.detectFaces(yoloInput);
    const faces = faceDetectionsFromYOLOOutput(yoloOutput);
    const faceDetections = transformFaceDetections(
        faces,
        rect(yoloSize),
        rect(imageBitmap),
    );

    const maxFaceDistancePercent = Math.sqrt(2) / 100;
    const maxFaceDistance = imageBitmap.width * maxFaceDistancePercent;
    return removeDuplicateDetections(faceDetections, maxFaceDistance);
};

/**
 * Convert {@link imageBitmap} into the format that the YOLO face detection
 * model expects.
 */
const convertToYOLOInputFloat32ChannelsFirst = (imageBitmap: ImageBitmap) => {
    const requiredWidth = 640;
    const requiredHeight = 640;

    const width = imageBitmap.width;
    const height = imageBitmap.height;

    // Create an OffscreenCanvas and set its size.
    const offscreenCanvas = new OffscreenCanvas(width, height);
    const ctx = offscreenCanvas.getContext("2d");
    ctx.drawImage(imageBitmap, 0, 0, width, height);
    const imageData = ctx.getImageData(0, 0, width, height);
    const pixelData = imageData.data;

    // Maintain aspect ratio.
    const scale = Math.min(requiredWidth / width, requiredHeight / height);

    const scaledWidth = clamp(Math.round(width * scale), 0, requiredWidth);
    const scaledHeight = clamp(Math.round(height * scale), 0, requiredHeight);

    const yoloInput = new Float32Array(1 * 3 * requiredWidth * requiredHeight);
    const yoloSize = { width: scaledWidth, height: scaledHeight };

    // Populate the Float32Array with normalized pixel values.
    let pi = 0;
    const channelOffsetGreen = requiredHeight * requiredWidth;
    const channelOffsetBlue = 2 * requiredHeight * requiredWidth;
    for (let h = 0; h < requiredHeight; h++) {
        for (let w = 0; w < requiredWidth; w++) {
            const { r, g, b } =
                w >= scaledWidth || h >= scaledHeight
                    ? { r: 114, g: 114, b: 114 }
                    : pixelRGBBilinear(
                          w / scale,
                          h / scale,
                          pixelData,
                          width,
                          height,
                      );
            yoloInput[pi] = r / 255.0;
            yoloInput[pi + channelOffsetGreen] = g / 255.0;
            yoloInput[pi + channelOffsetBlue] = b / 255.0;
            pi++;
        }
    }

    return { yoloInput, yoloSize };
};

/**
 * Extract detected faces from the YOLO's output.
 *
 * Only detections that exceed a minimum score are returned.
 *
 * @param rows A Float32Array of shape [25200, 16], where each row
 * represents a bounding box.
 */
const faceDetectionsFromYOLOOutput = (rows: Float32Array): FaceDetection[] => {
    const faces: FaceDetection[] = [];
    // Iterate over each row.
    for (let i = 0; i < rows.length; i += 16) {
        const score = rows[i + 4];
        if (score < 0.7) continue;

        const xCenter = rows[i];
        const yCenter = rows[i + 1];
        const width = rows[i + 2];
        const height = rows[i + 3];
        const xMin = xCenter - width / 2.0; // topLeft
        const yMin = yCenter - height / 2.0; // topLeft

        const leftEyeX = rows[i + 5];
        const leftEyeY = rows[i + 6];
        const rightEyeX = rows[i + 7];
        const rightEyeY = rows[i + 8];
        const noseX = rows[i + 9];
        const noseY = rows[i + 10];
        const leftMouthX = rows[i + 11];
        const leftMouthY = rows[i + 12];
        const rightMouthX = rows[i + 13];
        const rightMouthY = rows[i + 14];

        const box = new Box({
            x: xMin,
            y: yMin,
            width: width,
            height: height,
        });
        const probability = score as number;
        const landmarks = [
            new Point(leftEyeX, leftEyeY),
            new Point(rightEyeX, rightEyeY),
            new Point(noseX, noseY),
            new Point(leftMouthX, leftMouthY),
            new Point(rightMouthX, rightMouthY),
        ];
        faces.push({ box, landmarks, probability });
    }
    return faces;
};

/**
 * Removes duplicate face detections from an array of detections.
 *
 * This function sorts the detections by their probability in descending order,
 * then iterates over them.
 *
 * For each detection, it calculates the Euclidean distance to all other
 * detections.
 *
 * If the distance is less than or equal to the specified threshold
 * (`withinDistance`), the other detection is considered a duplicate and is
 * removed.
 *
 * @param detections - An array of face detections to remove duplicates from.
 *
 * @param withinDistance - The maximum Euclidean distance between two detections
 * for them to be considered duplicates.
 *
 * @returns An array of face detections with duplicates removed.
 */
const removeDuplicateDetections = (
    detections: FaceDetection[],
    withinDistance: number,
) => {
    detections.sort((a, b) => b.probability - a.probability);
    const isSelected = new Map<number, boolean>();
    for (let i = 0; i < detections.length; i++) {
        if (!isSelected.get(i)) continue;

        isSelected.set(i, true);
        for (let j = i + 1; j < detections.length; j++) {
            if (!isSelected.get(j)) continue;

            const centeri = faceDetectionCenter(detections[i]);
            const centerj = faceDetectionCenter(detections[j]);
            const dist = euclidean(
                [centeri.x, centeri.y],
                [centerj.x, centerj.y],
            );
            if (dist <= withinDistance) isSelected.set(j, false);
        }
    }

    return detections.filter((_, i) => isSelected.get(i));
};

const faceDetectionCenter = (detection: FaceDetection) => {
    const center = new Point(0, 0);
    // TODO-ML: first 4 landmarks is applicable to blazeface only this needs to
    // consider eyes, nose and mouth landmarks to take center
    detection.landmarks?.slice(0, 4).forEach((p) => {
        center.x += p.x;
        center.y += p.y;
    });
    return new Point(center.x / 4, center.y / 4);
};

const syncFileFaceCrops = async (fileContext: MLSyncFileContext) => {
    const { newMlFile } = fileContext;
    const imageBitmap = fileContext.imageBitmap;
    for (const face of newMlFile.faces) {
        await saveFaceCrop(imageBitmap, face);
    }
};

const syncFileFaceAlignments = async (
    fileContext: MLSyncFileContext,
): Promise<Float32Array> => {
    const { newMlFile } = fileContext;
    const imageBitmap = fileContext.imageBitmap;

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
const faceAlignment = (faceDetection: FaceDetection): FaceAlignment => {
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

const makeFaceID = (detectedFace: DetectedFace, imageDims: Dimensions) => {
    const part = (v: number) => clamp(v, 0.0, 0.999999).toFixed(5).substring(2);
    const xMin = part(detectedFace.detection.box.x / imageDims.width);
    const yMin = part(detectedFace.detection.box.y / imageDims.height);
    const xMax = part(
        (detectedFace.detection.box.x + detectedFace.detection.box.width) /
            imageDims.width,
    );
    const yMax = part(
        (detectedFace.detection.box.y + detectedFace.detection.box.height) /
            imageDims.height,
    );
    return [detectedFace.fileId, xMin, yMin, xMax, yMax].join("_");
};

/**
 * Laplacian blur detection.
 */
const detectBlur = (alignedFaces: Float32Array, faces: Face[]): number[] => {
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
            mobileFaceNetFaceSize,
            mobileFaceNetFaceSize,
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

    const embeddings = await faceEmbeddings(alignedFacesInput);
    newMlFile.faces.forEach((f, i) => (f.embedding = embeddings[i]));

    log.info("[MLService] facesWithEmbeddings: ", newMlFile.faces.length);
};

const mobileFaceNetFaceSize = 112;

/**
 * Compute embeddings for the given {@link faceData}.
 *
 * The model used is MobileFaceNet, running in an ONNX runtime.
 */
const faceEmbeddings = async (
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

const getRelativeDetection = (
    faceDetection: FaceDetection,
    dimensions: Dimensions,
): FaceDetection => {
    const oldBox: Box = faceDetection.box;
    const box = new Box({
        x: oldBox.x / dimensions.width,
        y: oldBox.y / dimensions.height,
        width: oldBox.width / dimensions.width,
        height: oldBox.height / dimensions.height,
    });
    const oldLandmarks: Point[] = faceDetection.landmarks;
    const landmarks = oldLandmarks.map((l) => {
        return new Point(l.x / dimensions.width, l.y / dimensions.height);
    });
    const probability = faceDetection.probability;
    return { box, landmarks, probability };
};

export const saveFaceCrop = async (imageBitmap: ImageBitmap, face: Face) => {
    const faceCrop = getFaceCrop(imageBitmap, face.detection);

    const blob = await imageBitmapToBlob(faceCrop.image);

    const cache = await openCache("face-crops");
    await cache.put(face.id, blob);

    faceCrop.image.close();

    return blob;
};

const imageBitmapToBlob = (imageBitmap: ImageBitmap) => {
    const canvas = new OffscreenCanvas(imageBitmap.width, imageBitmap.height);
    canvas.getContext("2d").drawImage(imageBitmap, 0, 0);
    return canvas.convertToBlob({ type: "image/jpeg", quality: 0.8 });
};

const getFaceCrop = (
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

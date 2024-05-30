import { FILE_TYPE } from "@/media/file-type";
import { decodeLivePhoto } from "@/media/live-photo";
import log from "@/next/log";
import { workerBridge } from "@/next/worker/worker-bridge";
import { Matrix } from "ml-matrix";
import DownloadManager from "services/download";
import { defaultMLVersion } from "services/machineLearning/machineLearningService";
import { getSimilarityTransformation } from "similarity-transformation";
import {
    Matrix as TransformationMatrix,
    applyToPoint,
    compose,
    scale,
    translate,
} from "transformation-matrix";
import type { EnteFile } from "types/file";
import { getRenderableImage, logIdentifier } from "utils/file";
import { saveFaceCrop } from "./crop";
import {
    clamp,
    grayscaleIntMatrixFromNormalized2List,
    pixelRGBBilinear,
    warpAffineFloat32List,
} from "./image";
import type { Box, Dimensions } from "./types";
import type { Face, FaceDetection, MlFileData } from "./types-old";

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
 *
 * @param enteFile The {@link EnteFile} to index.
 *
 * @param file The contents of {@link enteFile} as a web {@link File}, if
 * available. These are used when they are provided, otherwise the file is
 * downloaded and decrypted from remote.
 */
export const indexFaces = async (
    enteFile: EnteFile,
    file: File | undefined,
) => {
    const startTime = Date.now();

    const imageBitmap = await fetchOrCreateImageBitmap(enteFile, file);
    let mlFile: MlFileData;
    try {
        mlFile = await indexFaces_(enteFile, imageBitmap);
    } finally {
        imageBitmap.close();
    }

    log.debug(() => {
        const nf = mlFile.faces?.length ?? 0;
        const ms = Date.now() - startTime;
        return `Indexed ${nf} faces in file ${logIdentifier(enteFile)} (${ms} ms)`;
    });
    return mlFile;
};

/**
 * Return a {@link ImageBitmap}, using {@link file} if present otherwise
 * downloading the source image corresponding to {@link enteFile} from remote.
 */
const fetchOrCreateImageBitmap = async (enteFile: EnteFile, file: File) => {
    const fileType = enteFile.metadata.fileType;
    if (file) {
        // TODO-ML(MR): Could also be image part of live photo?
        if (fileType !== FILE_TYPE.IMAGE)
            throw new Error("Local file of only image type is supported");

        return await getLocalFileImageBitmap(enteFile, file);
    } else if ([FILE_TYPE.IMAGE, FILE_TYPE.LIVE_PHOTO].includes(fileType)) {
        return await fetchImageBitmap(enteFile);
    } else {
        throw new Error(`Cannot index unsupported file type ${fileType}`);
    }
};

const fetchImageBitmap = async (enteFile: EnteFile) =>
    fetchRenderableBlob(enteFile).then(createImageBitmap);

const fetchRenderableBlob = async (enteFile: EnteFile) => {
    const fileStream = await DownloadManager.getFile(enteFile);
    const fileBlob = await new Response(fileStream).blob();
    if (enteFile.metadata.fileType === FILE_TYPE.IMAGE) {
        return getRenderableImage(enteFile.metadata.title, fileBlob);
    } else {
        const { imageFileName, imageData } = await decodeLivePhoto(
            enteFile.metadata.title,
            fileBlob,
        );
        return getRenderableImage(imageFileName, new Blob([imageData]));
    }
};

const getLocalFileImageBitmap = async (enteFile: EnteFile, localFile: File) =>
    createImageBitmap(
        await getRenderableImage(enteFile.metadata.title, localFile),
    );

const indexFaces_ = async (enteFile: EnteFile, imageBitmap: ImageBitmap) => {
    const fileID = enteFile.id;
    const { width, height } = imageBitmap;
    const imageDimensions = { width, height };
    const mlFile: MlFileData = {
        fileId: fileID,
        mlVersion: defaultMLVersion,
        imageDimensions,
        errorCount: 0,
    };

    const faceDetections = await detectFaces(imageBitmap);
    const detectedFaces = faceDetections.map((detection) => ({
        id: makeFaceID(fileID, detection, imageDimensions),
        fileId: fileID,
        detection,
    }));
    mlFile.faces = detectedFaces;

    if (detectedFaces.length > 0) {
        const alignments: FaceAlignment[] = [];

        for (const face of mlFile.faces) {
            const alignment = computeFaceAlignment(face.detection);
            alignments.push(alignment);

            // This step is not really part of the indexing pipeline, we just do
            // it here since we have already computed the face alignment.
            await saveFaceCrop(imageBitmap, face, alignment);
        }

        const alignedFacesData = convertToMobileFaceNetInput(
            imageBitmap,
            alignments,
        );

        const blurValues = detectBlur(alignedFacesData, mlFile.faces);
        mlFile.faces.forEach((f, i) => (f.blurValue = blurValues[i]));

        const embeddings = await computeEmbeddings(alignedFacesData);
        mlFile.faces.forEach((f, i) => (f.embedding = embeddings[i]));

        mlFile.faces.forEach((face) => {
            face.detection = relativeDetection(face.detection, imageDimensions);
        });
    }

    return mlFile;
};

/**
 * Detect faces in the given {@link imageBitmap}.
 *
 * The model used is YOLOv5Face, running in an ONNX runtime.
 */
const detectFaces = async (
    imageBitmap: ImageBitmap,
): Promise<FaceDetection[]> => {
    const rect = ({ width, height }) => ({ x: 0, y: 0, width, height });

    const { yoloInput, yoloSize } =
        convertToYOLOInputFloat32ChannelsFirst(imageBitmap);
    const yoloOutput = await workerBridge.detectFaces(yoloInput);
    const faces = filterExtractDetectionsFromYOLOOutput(yoloOutput);
    const faceDetections = transformFaceDetections(
        faces,
        rect(yoloSize),
        rect(imageBitmap),
    );

    return naiveNonMaxSuppression(faceDetections, 0.4);
};

/**
 * Convert {@link imageBitmap} into the format that the YOLO face detection
 * model expects.
 */
const convertToYOLOInputFloat32ChannelsFirst = (imageBitmap: ImageBitmap) => {
    const requiredWidth = 640;
    const requiredHeight = 640;

    const { width, height } = imageBitmap;

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
 * Extract detected faces from the YOLOv5Face's output.
 *
 * Only detections that exceed a minimum score are returned.
 *
 * @param rows A Float32Array of shape [25200, 16], where each row represents a
 * face detection.
 *
 * YOLO detects a fixed number of faces, 25200, always from the input it is
 * given. Each detection is a "row" of 16 bytes, containing the bounding box,
 * score, and landmarks of the detection.
 *
 * We prune out detections with a score lower than our threshold. However, we
 * will still be left with some overlapping detections of the same face: these
 * we will deduplicate in {@link removeDuplicateDetections}.
 */
const filterExtractDetectionsFromYOLOOutput = (
    rows: Float32Array,
): FaceDetection[] => {
    const faces: FaceDetection[] = [];
    // Iterate over each row.
    for (let i = 0; i < rows.length; i += 16) {
        const score = rows[i + 4];
        if (score < 0.7) continue;

        const xCenter = rows[i];
        const yCenter = rows[i + 1];
        const width = rows[i + 2];
        const height = rows[i + 3];
        const x = xCenter - width / 2.0; // topLeft
        const y = yCenter - height / 2.0; // topLeft

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

        const box = { x, y, width, height };
        const probability = score as number;
        const landmarks = [
            { x: leftEyeX, y: leftEyeY },
            { x: rightEyeX, y: rightEyeY },
            { x: noseX, y: noseY },
            { x: leftMouthX, y: leftMouthY },
            { x: rightMouthX, y: rightMouthY },
        ];
        faces.push({ box, landmarks, probability });
    }
    return faces;
};

/**
 * Transform the given {@link faceDetections} from their coordinate system in
 * which they were detected ({@link inBox}) back to the coordinate system of the
 * original image ({@link toBox}).
 */
const transformFaceDetections = (
    faceDetections: FaceDetection[],
    inBox: Box,
    toBox: Box,
): FaceDetection[] => {
    const transform = boxTransformationMatrix(inBox, toBox);
    return faceDetections.map((f) => ({
        box: transformBox(f.box, transform),
        landmarks: f.landmarks.map((p) => applyToPoint(transform, p)),
        probability: f.probability,
    }));
};

const boxTransformationMatrix = (
    inBox: Box,
    toBox: Box,
): TransformationMatrix =>
    compose(
        translate(toBox.x, toBox.y),
        scale(toBox.width / inBox.width, toBox.height / inBox.height),
    );

const transformBox = (box: Box, transform: TransformationMatrix): Box => {
    const topLeft = applyToPoint(transform, { x: box.x, y: box.y });
    const bottomRight = applyToPoint(transform, {
        x: box.x + box.width,
        y: box.y + box.height,
    });

    return {
        x: topLeft.x,
        y: topLeft.y,
        width: bottomRight.x - topLeft.x,
        height: bottomRight.y - topLeft.y,
    };
};

/**
 * Remove overlapping faces from an array of face detections through non-maximum
 * suppression algorithm.
 *
 * This function sorts the detections by their probability in descending order,
 * then iterates over them.
 *
 * For each detection, it calculates the Intersection over Union (IoU) with all
 * other detections.
 *
 * If the IoU is greater than or equal to the specified threshold
 * (`iouThreshold`), the other detection is considered overlapping and is
 * removed.
 *
 * @param detections - An array of face detections to remove overlapping faces
 * from.
 *
 * @param iouThreshold - The minimum IoU between two detections for them to be
 * considered overlapping.
 *
 * @returns An array of face detections with overlapping faces removed
 */
const naiveNonMaxSuppression = (
    detections: FaceDetection[],
    iouThreshold: number,
): FaceDetection[] => {
    // Sort the detections by score, the highest first.
    detections.sort((a, b) => b.probability - a.probability);

    // Loop through the detections and calculate the IOU.
    for (let i = 0; i < detections.length - 1; i++) {
        for (let j = i + 1; j < detections.length; j++) {
            const iou = intersectionOverUnion(detections[i], detections[j]);
            if (iou >= iouThreshold) {
                detections.splice(j, 1);
                j--;
            }
        }
    }

    return detections;
};

const intersectionOverUnion = (a: FaceDetection, b: FaceDetection): number => {
    const intersectionMinX = Math.max(a.box.x, b.box.x);
    const intersectionMinY = Math.max(a.box.y, b.box.y);
    const intersectionMaxX = Math.min(
        a.box.x + a.box.width,
        b.box.x + b.box.width,
    );
    const intersectionMaxY = Math.min(
        a.box.y + a.box.height,
        b.box.y + b.box.height,
    );

    const intersectionWidth = intersectionMaxX - intersectionMinX;
    const intersectionHeight = intersectionMaxY - intersectionMinY;

    if (intersectionWidth < 0 || intersectionHeight < 0) {
        return 0.0; // If boxes do not overlap, IoU is 0
    }

    const areaA = a.box.width * a.box.height;
    const areaB = b.box.width * b.box.height;

    const intersectionArea = intersectionWidth * intersectionHeight;
    const unionArea = areaA + areaB - intersectionArea;

    return intersectionArea / unionArea;
};

const makeFaceID = (
    fileID: number,
    { box }: FaceDetection,
    image: Dimensions,
) => {
    const part = (v: number) => clamp(v, 0.0, 0.999999).toFixed(5).substring(2);
    const xMin = part(box.x / image.width);
    const yMin = part(box.y / image.height);
    const xMax = part((box.x + box.width) / image.width);
    const yMax = part((box.y + box.height) / image.height);
    return [`${fileID}`, xMin, yMin, xMax, yMax].join("_");
};

export interface FaceAlignment {
    /**
     * An affine transformation matrix (rotation, translation, scaling) to align
     * the face extracted from the image.
     */
    affineMatrix: number[][];
    /**
     * The bounding box of the transformed box.
     *
     * The affine transformation shifts the original detection box a new,
     * transformed, box (possibily rotated). This property is the bounding box
     * of that transformed box. It is in the coordinate system of the original,
     * full, image on which the detection occurred.
     */
    boundingBox: Box;
}

/**
 * Compute and return an {@link FaceAlignment} for the given face detection.
 *
 * @param faceDetection A geometry indicating a face detected in an image.
 */
const computeFaceAlignment = (faceDetection: FaceDetection): FaceAlignment =>
    computeFaceAlignmentUsingSimilarityTransform(
        faceDetection,
        normalizeLandmarks(idealMobileFaceNetLandmarks, mobileFaceNetFaceSize),
    );

/**
 * The ideal location of the landmarks (eye etc) that the MobileFaceNet
 * embedding model expects.
 */
const idealMobileFaceNetLandmarks: [number, number][] = [
    [38.2946, 51.6963],
    [73.5318, 51.5014],
    [56.0252, 71.7366],
    [41.5493, 92.3655],
    [70.7299, 92.2041],
];

const normalizeLandmarks = (
    landmarks: [number, number][],
    faceSize: number,
): [number, number][] =>
    landmarks.map(([x, y]) => [x / faceSize, y / faceSize]);

const computeFaceAlignmentUsingSimilarityTransform = (
    faceDetection: FaceDetection,
    alignedLandmarks: [number, number][],
): FaceAlignment => {
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
    const center = { x: centerMat.get(0, 0), y: centerMat.get(1, 0) };

    const boundingBox = {
        x: center.x - size / 2,
        y: center.y - size / 2,
        width: size,
        height: size,
    };

    return { affineMatrix, boundingBox };
};

const convertToMobileFaceNetInput = (
    imageBitmap: ImageBitmap,
    faceAlignments: FaceAlignment[],
): Float32Array => {
    const faceSize = mobileFaceNetFaceSize;
    const faceData = new Float32Array(
        faceAlignments.length * faceSize * faceSize * 3,
    );
    for (let i = 0; i < faceAlignments.length; i++) {
        const { affineMatrix } = faceAlignments[i];
        const faceDataOffset = i * faceSize * faceSize * 3;
        warpAffineFloat32List(
            imageBitmap,
            affineMatrix,
            faceSize,
            faceData,
            faceDataOffset,
        );
    }
    return faceData;
};

/**
 * Laplacian blur detection.
 *
 * Return an array of detected blur values, one for each face in {@link faces}.
 * The face data is taken from the slice of {@link alignedFacesData}
 * corresponding to each face of {@link faces}.
 */
const detectBlur = (alignedFacesData: Float32Array, faces: Face[]): number[] =>
    faces.map((face, i) => {
        const faceImage = grayscaleIntMatrixFromNormalized2List(
            alignedFacesData,
            i,
            mobileFaceNetFaceSize,
            mobileFaceNetFaceSize,
        );
        return matrixVariance(applyLaplacian(faceImage, faceDirection(face)));
    });

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
    const paddedImage = padImage(image, direction);
    const numRows = paddedImage.length - 2;
    const numCols = paddedImage[0].length - 2;

    // Create an output image initialized to 0.
    const outputImage: number[][] = Array.from({ length: numRows }, () =>
        new Array(numCols).fill(0),
    );

    // Define the Laplacian kernel.
    const kernel = [
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
        // If the face is facing left, we only take the right side of the face
        // image.
        for (let i = 0; i < numRows; i++) {
            for (let j = 0; j < paddedNumCols - 2; j++) {
                paddedImage[i + 1][j + 1] = image[i][j + removeSideColumns];
            }
        }
    } else if (direction === "right") {
        // If the face is facing right, we only take the left side of the face
        // image.
        for (let i = 0; i < numRows; i++) {
            for (let j = 0; j < paddedNumCols - 2; j++) {
                paddedImage[i + 1][j + 1] = image[i][j];
            }
        }
    }

    // Reflect padding
    // - Top and bottom rows
    for (let j = 1; j <= paddedNumCols - 2; j++) {
        // Top row
        paddedImage[0][j] = paddedImage[2][j];
        // Bottom row
        paddedImage[numRows + 1][j] = paddedImage[numRows - 1][j];
    }
    // - Left and right columns
    for (let i = 0; i < numRows + 2; i++) {
        // Left column
        paddedImage[i][0] = paddedImage[i][2];
        // Right column
        paddedImage[i][paddedNumCols - 1] = paddedImage[i][paddedNumCols - 3];
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

const mobileFaceNetFaceSize = 112;
const mobileFaceNetEmbeddingSize = 192;

/**
 * Compute embeddings for the given {@link faceData}.
 *
 * The model used is MobileFaceNet, running in an ONNX runtime.
 */
const computeEmbeddings = async (
    faceData: Float32Array,
): Promise<Float32Array[]> => {
    const outputData = await workerBridge.computeFaceEmbeddings(faceData);

    const embeddingSize = mobileFaceNetEmbeddingSize;
    const embeddings = new Array<Float32Array>(
        outputData.length / embeddingSize,
    );
    for (let i = 0; i < embeddings.length; i++) {
        embeddings[i] = new Float32Array(
            outputData.slice(i * embeddingSize, (i + 1) * embeddingSize),
        );
    }
    return embeddings;
};

/**
 * Convert the coordinates to between 0-1, normalized by the image's dimensions.
 */
const relativeDetection = (
    faceDetection: FaceDetection,
    { width, height }: Dimensions,
): FaceDetection => {
    const oldBox: Box = faceDetection.box;
    const box = {
        x: oldBox.x / width,
        y: oldBox.y / height,
        width: oldBox.width / width,
        height: oldBox.height / height,
    };
    const landmarks = faceDetection.landmarks.map((l) => ({
        x: l.x / width,
        y: l.y / height,
    }));
    const probability = faceDetection.probability;
    return { box, landmarks, probability };
};

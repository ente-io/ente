import { workerBridge } from "@/next/worker/worker-bridge";
import { euclidean } from "hdbscan";
import {
    Matrix,
    applyToPoint,
    compose,
    scale,
    translate,
} from "transformation-matrix";
import { Dimensions } from "types/image";
import {
    FaceDetection,
    FaceDetectionMethod,
    FaceDetectionService,
    Versioned,
} from "types/machineLearning";
import {
    clamp,
    getPixelBilinear,
    normalizePixelBetween0And1,
} from "utils/image";
import { newBox } from "utils/machineLearning";
import { Box, Point } from "../../../thirdparty/face-api/classes";

class YoloFaceDetectionService implements FaceDetectionService {
    public method: Versioned<FaceDetectionMethod>;

    public constructor() {
        this.method = {
            value: "YoloFace",
            version: 1,
        };
    }

    public async detectFaces(
        imageBitmap: ImageBitmap,
    ): Promise<Array<FaceDetection>> {
        const maxFaceDistancePercent = Math.sqrt(2) / 100;
        const maxFaceDistance = imageBitmap.width * maxFaceDistancePercent;
        const preprocessResult =
            this.preprocessImageBitmapToFloat32ChannelsFirst(
                imageBitmap,
                640,
                640,
            );
        const data = preprocessResult.data;
        const resized = preprocessResult.newSize;
        const outputData = await workerBridge.detectFaces(data);
        const faces = this.getFacesFromYoloOutput(
            outputData as Float32Array,
            0.7,
        );
        const inBox = newBox(0, 0, resized.width, resized.height);
        const toBox = newBox(0, 0, imageBitmap.width, imageBitmap.height);
        const transform = computeTransformToBox(inBox, toBox);
        const faceDetections: Array<FaceDetection> = faces?.map((f) => {
            const box = transformBox(f.box, transform);
            const normLandmarks = f.landmarks;
            const landmarks = transformPoints(normLandmarks, transform);
            return {
                box,
                landmarks,
                probability: f.probability as number,
            } as FaceDetection;
        });
        return removeDuplicateDetections(faceDetections, maxFaceDistance);
    }

    private preprocessImageBitmapToFloat32ChannelsFirst(
        imageBitmap: ImageBitmap,
        requiredWidth: number,
        requiredHeight: number,
        maintainAspectRatio: boolean = true,
        normFunction: (
            pixelValue: number,
        ) => number = normalizePixelBetween0And1,
    ) {
        // Create an OffscreenCanvas and set its size
        const offscreenCanvas = new OffscreenCanvas(
            imageBitmap.width,
            imageBitmap.height,
        );
        const ctx = offscreenCanvas.getContext("2d");
        ctx.drawImage(imageBitmap, 0, 0, imageBitmap.width, imageBitmap.height);
        const imageData = ctx.getImageData(
            0,
            0,
            imageBitmap.width,
            imageBitmap.height,
        );
        const pixelData = imageData.data;

        let scaleW = requiredWidth / imageBitmap.width;
        let scaleH = requiredHeight / imageBitmap.height;
        if (maintainAspectRatio) {
            const scale = Math.min(
                requiredWidth / imageBitmap.width,
                requiredHeight / imageBitmap.height,
            );
            scaleW = scale;
            scaleH = scale;
        }
        const scaledWidth = clamp(
            Math.round(imageBitmap.width * scaleW),
            0,
            requiredWidth,
        );
        const scaledHeight = clamp(
            Math.round(imageBitmap.height * scaleH),
            0,
            requiredHeight,
        );

        const processedImage = new Float32Array(
            1 * 3 * requiredWidth * requiredHeight,
        );

        // Populate the Float32Array with normalized pixel values
        let pixelIndex = 0;
        const channelOffsetGreen = requiredHeight * requiredWidth;
        const channelOffsetBlue = 2 * requiredHeight * requiredWidth;
        for (let h = 0; h < requiredHeight; h++) {
            for (let w = 0; w < requiredWidth; w++) {
                let pixel: {
                    r: number;
                    g: number;
                    b: number;
                };
                if (w >= scaledWidth || h >= scaledHeight) {
                    pixel = { r: 114, g: 114, b: 114 };
                } else {
                    pixel = getPixelBilinear(
                        w / scaleW,
                        h / scaleH,
                        pixelData,
                        imageBitmap.width,
                        imageBitmap.height,
                    );
                }
                processedImage[pixelIndex] = normFunction(pixel.r);
                processedImage[pixelIndex + channelOffsetGreen] = normFunction(
                    pixel.g,
                );
                processedImage[pixelIndex + channelOffsetBlue] = normFunction(
                    pixel.b,
                );
                pixelIndex++;
            }
        }

        return {
            data: processedImage,
            originalSize: {
                width: imageBitmap.width,
                height: imageBitmap.height,
            },
            newSize: { width: scaledWidth, height: scaledHeight },
        };
    }

    // The rowOutput is a Float32Array of shape [25200, 16], where each row represents a bounding box.
    private getFacesFromYoloOutput(
        rowOutput: Float32Array,
        minScore: number,
    ): Array<FaceDetection> {
        const faces: Array<FaceDetection> = [];
        // iterate over each row
        for (let i = 0; i < rowOutput.length; i += 16) {
            const score = rowOutput[i + 4];
            if (score < minScore) {
                continue;
            }
            // The first 4 values represent the bounding box's coordinates (x1, y1, x2, y2)
            const xCenter = rowOutput[i];
            const yCenter = rowOutput[i + 1];
            const width = rowOutput[i + 2];
            const height = rowOutput[i + 3];
            const xMin = xCenter - width / 2.0; // topLeft
            const yMin = yCenter - height / 2.0; // topLeft

            const leftEyeX = rowOutput[i + 5];
            const leftEyeY = rowOutput[i + 6];
            const rightEyeX = rowOutput[i + 7];
            const rightEyeY = rowOutput[i + 8];
            const noseX = rowOutput[i + 9];
            const noseY = rowOutput[i + 10];
            const leftMouthX = rowOutput[i + 11];
            const leftMouthY = rowOutput[i + 12];
            const rightMouthX = rowOutput[i + 13];
            const rightMouthY = rowOutput[i + 14];

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
            const face: FaceDetection = {
                box,
                landmarks,
                probability,
                // detectionMethod: this.method,
            };
            faces.push(face);
        }
        return faces;
    }

    public getRelativeDetection(
        faceDetection: FaceDetection,
        dimensions: Dimensions,
    ): FaceDetection {
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
        return {
            box,
            landmarks,
            probability: faceDetection.probability,
        };
    }
}

export default new YoloFaceDetectionService();

/**
 * Removes duplicate face detections from an array of detections.
 *
 * This function sorts the detections by their probability in descending order, then iterates over them.
 * For each detection, it calculates the Euclidean distance to all other detections.
 * If the distance is less than or equal to the specified threshold (`withinDistance`), the other detection is considered a duplicate and is removed.
 *
 * @param detections - An array of face detections to remove duplicates from.
 * @param withinDistance - The maximum Euclidean distance between two detections for them to be considered duplicates.
 *
 * @returns An array of face detections with duplicates removed.
 */
function removeDuplicateDetections(
    detections: Array<FaceDetection>,
    withinDistance: number,
) {
    // console.time('removeDuplicates');
    detections.sort((a, b) => b.probability - a.probability);
    const isSelected = new Map<number, boolean>();
    for (let i = 0; i < detections.length; i++) {
        if (isSelected.get(i) === false) {
            continue;
        }
        isSelected.set(i, true);
        for (let j = i + 1; j < detections.length; j++) {
            if (isSelected.get(j) === false) {
                continue;
            }
            const centeri = getDetectionCenter(detections[i]);
            const centerj = getDetectionCenter(detections[j]);
            const dist = euclidean(
                [centeri.x, centeri.y],
                [centerj.x, centerj.y],
            );
            if (dist <= withinDistance) {
                isSelected.set(j, false);
            }
        }
    }

    const uniques: Array<FaceDetection> = [];
    for (let i = 0; i < detections.length; i++) {
        isSelected.get(i) && uniques.push(detections[i]);
    }
    // console.timeEnd('removeDuplicates');
    return uniques;
}

function getDetectionCenter(detection: FaceDetection) {
    const center = new Point(0, 0);
    // TODO: first 4 landmarks is applicable to blazeface only
    // this needs to consider eyes, nose and mouth landmarks to take center
    detection.landmarks?.slice(0, 4).forEach((p) => {
        center.x += p.x;
        center.y += p.y;
    });

    return center.div({ x: 4, y: 4 });
}

function computeTransformToBox(inBox: Box, toBox: Box): Matrix {
    return compose(
        translate(toBox.x, toBox.y),
        scale(toBox.width / inBox.width, toBox.height / inBox.height),
    );
}

function transformPoint(point: Point, transform: Matrix) {
    const txdPoint = applyToPoint(transform, point);
    return new Point(txdPoint.x, txdPoint.y);
}

function transformPoints(points: Point[], transform: Matrix) {
    return points?.map((p) => transformPoint(p, transform));
}

function transformBox(box: Box, transform: Matrix) {
    const topLeft = transformPoint(box.topLeft, transform);
    const bottomRight = transformPoint(box.bottomRight, transform);

    return newBoxFromPoints(topLeft.x, topLeft.y, bottomRight.x, bottomRight.y);
}

function newBoxFromPoints(
    left: number,
    top: number,
    right: number,
    bottom: number,
) {
    return new Box({ left, top, right, bottom });
}

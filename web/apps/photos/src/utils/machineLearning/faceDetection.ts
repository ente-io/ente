import { euclidean } from "hdbscan";
import { FaceDetection } from "types/machineLearning";
import { getNearestPointIndex, newBox } from ".";
import { Box, Point } from "../../../thirdparty/face-api/classes";
import {
    computeTransformToBox,
    transformBox,
    transformPoints,
} from "./transform";

export function transformPaddedToImage(
    detection: FaceDetection,
    faceImage: ImageBitmap,
    imageBox: Box,
    paddedBox: Box,
) {
    const inBox = newBox(0, 0, faceImage.width, faceImage.height);
    imageBox.x = paddedBox.x;
    imageBox.y = paddedBox.y;
    const transform = computeTransformToBox(inBox, imageBox);

    detection.box = transformBox(detection.box, transform);
    detection.landmarks = transformPoints(detection.landmarks, transform);
}

export function getDetectionCenter(detection: FaceDetection) {
    const center = new Point(0, 0);
    // TODO: first 4 landmarks is applicable to blazeface only
    // this needs to consider eyes, nose and mouth landmarks to take center
    detection.landmarks?.slice(0, 4).forEach((p) => {
        center.x += p.x;
        center.y += p.y;
    });

    return center.div({ x: 4, y: 4 });
}

export function getNearestDetection(
    toDetection: FaceDetection,
    fromDetections: Array<FaceDetection>,
    maxDistance?: number,
) {
    const toCenter = getDetectionCenter(toDetection);
    const centers = fromDetections.map((d) => getDetectionCenter(d));
    const nearestIndex = getNearestPointIndex(toCenter, centers, maxDistance);

    return nearestIndex >= 0 && fromDetections[nearestIndex];
}

// TODO: can also be done through tf.image.nonMaxSuppression
export function removeDuplicateDetections(
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

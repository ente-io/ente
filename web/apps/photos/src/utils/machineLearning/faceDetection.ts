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

/**
 * Finds the nearest face detection from a list of detections to a specified detection.
 *
 * This function calculates the center of each detection and then finds the detection whose center is nearest to the center of the specified detection.
 * If a maximum distance is specified, only detections within that distance are considered.
 *
 * @param toDetection - The face detection to find the nearest detection to.
 * @param fromDetections - An array of face detections to search in.
 * @param maxDistance - The maximum distance between the centers of the two detections for a detection to be considered. If not specified, all detections are considered.
 *
 * @returns The nearest face detection from the list, or `undefined` if no detection is within the maximum distance.
 */
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

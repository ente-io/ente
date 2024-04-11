import { euclidean } from "hdbscan";
import { FaceDetection } from "types/machineLearning";
import { Point } from "../../../thirdparty/face-api/classes";

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

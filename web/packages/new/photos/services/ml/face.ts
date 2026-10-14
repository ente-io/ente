import { assertionFailed } from "ente-base/assert";
import type { Person } from "./people";

export interface AnnotatedFaceID {
    faceID: string;
    personID: string;
    personName: string | undefined;
    isIgnored: boolean;
}

export const annotateFileFaces = (
    faces: Face[],
    personByFaceID: ReadonlyMap<string, Person>,
): AnnotatedFaceID[] => {
    const annotatedFaces = faces.flatMap(({ faceID, score }) => {
        const person = personByFaceID.get(faceID);
        if (!person) return [];
        return [
            {
                annotation: {
                    faceID,
                    personID: person.id,
                    personName: person.name,
                    isIgnored: person.type == "cgroup" && person.isHidden,
                },
                isAssigned: person.type == "cgroup",
                score,
            },
        ];
    });

    annotatedFaces.sort((a, b) => {
        if (a.annotation.isIgnored != b.annotation.isIgnored)
            return a.annotation.isIgnored ? 1 : -1;
        if (a.isAssigned != b.isAssigned) return a.isAssigned ? -1 : 1;
        return b.score - a.score;
    });
    return annotatedFaces.map(({ annotation }) => annotation);
};

export const faceIndexingVersion = 1;

export interface FaceIndex {
    width: number;
    height: number;
    faces: Face[];
}

export type RemoteFaceIndex = FaceIndex & {
    // Same versions must be cross-client compatible.
    // Older versions are ignored and reindexed.
    // Breaking formats require a new top-level subtype.
    version: number;
    client: string;
    flags: number;
};

export type LocalFaceIndex = FaceIndex & { fileID: number };

export interface Face {
    // Stable across equivalent reindexing and prefixed with `${fileID}_`.
    faceID: string;
    // Detection coordinates are normalized to [0, 1].
    detection: { box: Box; landmarks: Point[] };
    score: number;
    blur: number;
    embedding: number[];
}

interface Point {
    x: number;
    y: number;
}

export interface Box {
    x: number;
    y: number;
    width: number;
    height: number;
}

export const fileIDFromFaceID = (faceID: string) => {
    const fileID = parseInt(faceID.split("_")[0] ?? "");
    if (isNaN(fileID)) {
        assertionFailed(`Ignoring attempt to parse invalid faceID ${faceID}`);
        return undefined;
    }
    return fileID;
};

interface FaceDetection {
    box: Box;
    landmarks: Point[];
}

type FaceDirection = "left" | "right" | "straight";

export const faceDirection = ({ landmarks }: FaceDetection): FaceDirection => {
    const leftEye = landmarks[0]!;
    const rightEye = landmarks[1]!;
    const nose = landmarks[2]!;
    const leftMouth = landmarks[3]!;
    const rightMouth = landmarks[4]!;

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

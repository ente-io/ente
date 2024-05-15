import {
    BlurDetectionMethod,
    BlurDetectionService,
    Face,
    Versioned,
} from "services/ml/types";
import { createGrayscaleIntMatrixFromNormalized2List } from "utils/image";
import { mobileFaceNetFaceSize } from "./mobileFaceNetEmbeddingService";

class LaplacianBlurDetectionService implements BlurDetectionService {
    public method: Versioned<BlurDetectionMethod>;

    public constructor() {
        this.method = {
            value: "Laplacian",
            version: 1,
        };
    }

    public detectBlur(alignedFaces: Float32Array, faces: Face[]): number[] {
        const numFaces = Math.round(
            alignedFaces.length /
                (mobileFaceNetFaceSize * mobileFaceNetFaceSize * 3),
        );
        const blurValues: number[] = [];
        for (let i = 0; i < numFaces; i++) {
            const face = faces[i];
            const direction = getFaceDirection(face);
            const faceImage = createGrayscaleIntMatrixFromNormalized2List(
                alignedFaces,
                i,
            );
            const laplacian = this.applyLaplacian(faceImage, direction);
            const variance = this.calculateVariance(laplacian);
            blurValues.push(variance);
        }
        return blurValues;
    }

    private calculateVariance(matrix: number[][]): number {
        const numRows = matrix.length;
        const numCols = matrix[0].length;
        const totalElements = numRows * numCols;

        // Calculate the mean
        let mean: number = 0;
        matrix.forEach((row) => {
            row.forEach((value) => {
                mean += value;
            });
        });
        mean /= totalElements;

        // Calculate the variance
        let variance: number = 0;
        matrix.forEach((row) => {
            row.forEach((value) => {
                const diff: number = value - mean;
                variance += diff * diff;
            });
        });
        variance /= totalElements;

        return variance;
    }

    private padImage(
        image: number[][],
        removeSideColumns: number = 56,
        direction: FaceDirection = "straight",
    ): number[][] {
        // Exception is removeSideColumns is not even
        if (removeSideColumns % 2 != 0) {
            throw new Error("removeSideColumns must be even");
        }
        const numRows = image.length;
        const numCols = image[0].length;
        const paddedNumCols = numCols + 2 - removeSideColumns;
        const paddedNumRows = numRows + 2;

        // Create a new matrix with extra padding
        const paddedImage: number[][] = Array.from(
            { length: paddedNumRows },
            () => new Array(paddedNumCols).fill(0),
        );

        // Copy original image into the center of the padded image
        if (direction === "straight") {
            for (let i = 0; i < numRows; i++) {
                for (let j = 0; j < paddedNumCols - 2; j++) {
                    paddedImage[i + 1][j + 1] =
                        image[i][j + Math.round(removeSideColumns / 2)];
                }
            }
        } // If the face is facing left, we only take the right side of the face image
        else if (direction === "left") {
            for (let i = 0; i < numRows; i++) {
                for (let j = 0; j < paddedNumCols - 2; j++) {
                    paddedImage[i + 1][j + 1] = image[i][j + removeSideColumns];
                }
            }
        } // If the face is facing right, we only take the left side of the face image
        else if (direction === "right") {
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
            paddedImage[i][paddedNumCols - 1] =
                paddedImage[i][paddedNumCols - 3]; // Right column
        }

        return paddedImage;
    }

    private applyLaplacian(
        image: number[][],
        direction: FaceDirection = "straight",
    ): number[][] {
        const paddedImage: number[][] = this.padImage(
            image,
            undefined,
            direction,
        );
        const numRows = paddedImage.length - 2;
        const numCols = paddedImage[0].length - 2;

        // Create an output image initialized to 0
        const outputImage: number[][] = Array.from({ length: numRows }, () =>
            new Array(numCols).fill(0),
        );

        // Define the Laplacian kernel
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
                // Adjust the output value if necessary (e.g., clipping)
                outputImage[i][j] = sum;
            }
        }

        return outputImage;
    }
}

export default new LaplacianBlurDetectionService();

type FaceDirection = "left" | "right" | "straight";

const getFaceDirection = (face: Face): FaceDirection => {
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

    // if (faceIsUpright && (noseStickingOutLeft || noseCloseToLeftEye)) {
    if (noseStickingOutLeft || (faceIsUpright && noseCloseToLeftEye)) {
        return "left";
        // } else if (faceIsUpright && (noseStickingOutRight || noseCloseToRightEye)) {
    } else if (noseStickingOutRight || (faceIsUpright && noseCloseToRightEye)) {
        return "right";
    }

    return "straight";
};

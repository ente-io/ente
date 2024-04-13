import { MOBILEFACENET_FACE_SIZE } from "constants/mlConfig";
import {
    BlurDetectionMethod,
    BlurDetectionService,
    Versioned,
} from "types/machineLearning";
import { createGrayscaleIntMatrixFromNormalized2List } from "utils/image";

class LaplacianBlurDetectionService implements BlurDetectionService {
    public method: Versioned<BlurDetectionMethod>;

    public constructor() {
        this.method = {
            value: "Laplacian",
            version: 1,
        };
    }

    public detectBlur(alignedFaces: Float32Array): number[] {
        const numFaces = Math.round(
            alignedFaces.length /
                (MOBILEFACENET_FACE_SIZE * MOBILEFACENET_FACE_SIZE * 3),
        );
        const blurValues: number[] = [];
        for (let i = 0; i < numFaces; i++) {
            const faceImage = createGrayscaleIntMatrixFromNormalized2List(
                alignedFaces,
                i,
            );
            const laplacian = this.applyLaplacian(faceImage);
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

    private padImage(image: number[][]): number[][] {
        const numRows = image.length;
        const numCols = image[0].length;

        // Create a new matrix with extra padding
        const paddedImage: number[][] = Array.from(
            { length: numRows + 2 },
            () => new Array(numCols + 2).fill(0),
        );

        // Copy original image into the center of the padded image
        for (let i = 0; i < numRows; i++) {
            for (let j = 0; j < numCols; j++) {
                paddedImage[i + 1][j + 1] = image[i][j];
            }
        }

        // Reflect padding
        // Top and bottom rows
        for (let j = 1; j <= numCols; j++) {
            paddedImage[0][j] = paddedImage[2][j]; // Top row
            paddedImage[numRows + 1][j] = paddedImage[numRows - 1][j]; // Bottom row
        }
        // Left and right columns
        for (let i = 0; i < numRows + 2; i++) {
            paddedImage[i][0] = paddedImage[i][2]; // Left column
            paddedImage[i][numCols + 1] = paddedImage[i][numCols - 1]; // Right column
        }

        return paddedImage;
    }

    private applyLaplacian(image: number[][]): number[][] {
        const paddedImage: number[][] = this.padImage(image);
        const numRows = image.length;
        const numCols = image[0].length;

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

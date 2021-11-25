/**
 * @fileoverview Implementation of the algorithm of Shinji Umeyama for matching
 * two tuples of n-dimensional points through rotation, translation and
 * scaling. This implementation also adds the possibility to allow reflecting
 * one of the tuples to achieve a better matching.
 *
 * The central function is getSimilarityTransformation(...).
 *
 * This file depends on the ml-matrix library for computing matrix
 * manipulations, see https://github.com/mljs/matrix. Version used: 6.4.1
 *
 * umeyama_1991 refers to http://web.stanford.edu/class/cs273/refs/umeyama.pdf:
 * @article{umeyama_1991,
 *   title={Least-squares estimation of transformation parameters between two point patterns},
 *   author={Umeyama, Shinji},
 *   journal={IEEE Transactions on Pattern Analysis \& Machine Intelligence},
 *   number={4},
 *   pages={376--380},
 *   year={1991},
 *   publisher={IEEE}
 * }
 *
 * Variable names and the corresponding term in the paper's notation:
 * - fromPoints refers to {x_i} with i = 1, 2, ..., n
 * - toPoints refers to {y_i} with i = 1, 2, ..., n
 * - numPoints refers to n
 * - dimensions refers to m
 * - rotation refers to R
 * - scale refers to c
 * - translation refers to t
 * - fromMean and toMean refer to mu_x and mu_y respectively
 * - fromVariance and toVariance refer to sigma_x and sigma_y respectively
 * - mirrorIdentity refers to S
 * - svd refers to the SVD given by U, D and V
 */

/**
 * Transform a tuple of source points to match a tuple of target points
 * following equation 40, 41 and 42 of umeyama_1991.
 *
 * This function expects two mlMatrix.Matrix instances of the same shape
 * (m, n), where n is the number of points and m is the number of dimensions.
 * This is the shape used by umeyama_1991. m and n can take any positive value.
 *
 * The returned matrix contains the transformed points.
 *
 * @param {!mlMatrix.Matrix} fromPoints - the source points {x_1, ..., x_n}.
 * @param {!mlMatrix.Matrix} toPoints - the target points {y_1, ..., y_n}.
 * @param {boolean} allowReflection - If true, the source points may be
 *   reflected to achieve a better mean squared error.
 * @returns {mlMatrix.Matrix}
 */
import * as mlMatrix from 'ml-matrix';

export function getSimilarityTransformation(fromPoints,
    toPoints,
    allowReflection = false) {
    const dimensions = fromPoints.rows;
    const numPoints = fromPoints.columns;

    // 1. Compute the rotation.
    const covarianceMatrix = getSimilarityTransformationCovariance(
        fromPoints,
        toPoints);

    const {
        svd,
        mirrorIdentityForSolution
    } = getSimilarityTransformationSvdWithMirrorIdentities(
        covarianceMatrix,
        allowReflection);

    const rotation = svd.U
        .mmul(mlMatrix.Matrix.diag(mirrorIdentityForSolution))
        .mmul(svd.V.transpose());

    // 2. Compute the scale.
    // The variance will first be a 1-D array and then reduced to a scalar.
    const summator = (sum, elem) => {
        return sum + elem;
    };
    const fromVariance = fromPoints
        .variance('row', { unbiased: false })
        .reduce(summator);

    let trace = 0;
    for (let dimension = 0; dimension < dimensions; dimension++) {
        const mirrorEntry = mirrorIdentityForSolution[dimension];
        trace += svd.diagonal[dimension] * mirrorEntry;
    }
    const scale = trace / fromVariance;

    // 3. Compute the translation.
    const fromMean = mlMatrix.Matrix.columnVector(fromPoints.mean('row'));
    const toMean = mlMatrix.Matrix.columnVector(toPoints.mean('row'));
    const translation = mlMatrix.Matrix.sub(
        toMean,
        mlMatrix.Matrix.mul(rotation.mmul(fromMean), scale));

    // 4. Transform the points.
    // const transformedPoints = mlMatrix.Matrix.add(
    //     mlMatrix.Matrix.mul(rotation.mmul(fromPoints), scale),
    //     translation.repeat({ columns: numPoints }));

    return { rotation, scale, translation };
}

/**
* Compute the mean squared error of a given solution, following equation 1
* in umeyama_1991.
*
* This function expects two mlMatrix.Matrix instances of the same shape
* (m, n), where n is the number of points and m is the number of dimensions.
* This is the shape used by umeyama_1991.
*
* @param {!mlMatrix.Matrix} transformedPoints - the solution, for example
*   returned by getSimilarityTransformation(...).
* @param {!mlMatrix.Matrix} toPoints - the target points {y_1, ..., y_n}.
* @returns {number}
*/
function getSimilarityTransformationError(transformedPoints, toPoints) {
    const numPoints = transformedPoints.columns;
    const difference = mlMatrix.Matrix.sub(toPoints, transformedPoints);
    return Math.pow(difference.norm('frobenius'), 2) / numPoints;
}

/**
* Compute the minimum possible mean squared error for a given problem,
* following equation 33 in umeyama_1991.
*
* This function expects two mlMatrix.Matrix instances of the same shape
* (m, n), where n is the number of points and m is the number of dimensions.
* This is the shape used by umeyama_1991. m and n can take any positive value.
*
* @param {!mlMatrix.Matrix} fromPoints - the source points {x_1, ..., x_n}.
* @param {!mlMatrix.Matrix} toPoints - the target points {y_1, ..., y_n}.
* @param {boolean} allowReflection - If true, the source points may be
*   reflected to achieve a better mean squared error.
* @returns {number}
*/
function getSimilarityTransformationErrorBound(fromPoints,
    toPoints,
    allowReflection = false) {
    const dimensions = fromPoints.rows;

    // The variances will first be 1-D arrays and then reduced to a scalar.
    const summator = (sum, elem) => {
        return sum + elem;
    };
    const fromVariance = fromPoints
        .variance('row', { unbiased: false })
        .reduce(summator);
    const toVariance = toPoints
        .variance('row', { unbiased: false })
        .reduce(summator);
    const covarianceMatrix = getSimilarityTransformationCovariance(
        fromPoints,
        toPoints);

    const {
        svd,
        mirrorIdentityForErrorBound
    } = getSimilarityTransformationSvdWithMirrorIdentities(
        covarianceMatrix,
        allowReflection);

    let trace = 0;
    for (let dimension = 0; dimension < dimensions; dimension++) {
        const mirrorEntry = mirrorIdentityForErrorBound[dimension];
        trace += svd.diagonal[dimension] * mirrorEntry;
    }
    return toVariance - Math.pow(trace, 2) / fromVariance;
}

/**
* Computes the covariance matrix of the source points and the target points
* following equation 38 in umeyama_1991.
*
* This function expects two mlMatrix.Matrix instances of the same shape
* (m, n), where n is the number of points and m is the number of dimensions.
* This is the shape used by umeyama_1991. m and n can take any positive value.
*
* @param {!mlMatrix.Matrix} fromPoints - the source points {x_1, ..., x_n}.
* @param {!mlMatrix.Matrix} toPoints - the target points {y_1, ..., y_n}.
* @returns {mlMatrix.Matrix}
*/
function getSimilarityTransformationCovariance(fromPoints, toPoints) {
    const dimensions = fromPoints.rows;
    const numPoints = fromPoints.columns;
    const fromMean = mlMatrix.Matrix.columnVector(fromPoints.mean('row'));
    const toMean = mlMatrix.Matrix.columnVector(toPoints.mean('row'));

    const covariance = mlMatrix.Matrix.zeros(dimensions, dimensions);

    for (let pointIndex = 0; pointIndex < numPoints; pointIndex++) {
        const fromPoint = fromPoints.getColumnVector(pointIndex);
        const toPoint = toPoints.getColumnVector(pointIndex);
        const outer = mlMatrix.Matrix.sub(toPoint, toMean)
            .mmul(mlMatrix.Matrix.sub(fromPoint, fromMean).transpose());

        covariance.addM(mlMatrix.Matrix.div(outer, numPoints));
    }

    return covariance;
}

/**
* Computes the SVD of the covariance matrix and returns the mirror identities
* (called S in umeyama_1991), following equation 39 and 43 in umeyama_1991.
*
* See getSimilarityTransformationCovariance(...) for more details on how to
* compute the covariance matrix.
*
* @param {!mlMatrix.Matrix} covarianceMatrix - the matrix returned by
*   getSimilarityTransformationCovariance(...)
* @param {boolean} allowReflection - If true, the source points may be
*   reflected to achieve a better mean squared error.
* @returns {{
*   svd: mlMatrix.SVD,
*   mirrorIdentityForErrorBound: number[],
*   mirrorIdentityForSolution: number[]
* }}
*/
function getSimilarityTransformationSvdWithMirrorIdentities(covarianceMatrix,
    allowReflection) {
    // Compute the SVD.
    const dimensions = covarianceMatrix.rows;
    const svd = new mlMatrix.SVD(covarianceMatrix);

    // Compute the mirror identities based on the equations in umeyama_1991.
    let mirrorIdentityForErrorBound = Array(svd.diagonal.length).fill(1);
    let mirrorIdentityForSolution = Array(svd.diagonal.length).fill(1);
    if (!allowReflection) {
        // Compute equation 39 in umeyama_1991.
        if (mlMatrix.determinant(covarianceMatrix) < 0) {
            const lastIndex = mirrorIdentityForErrorBound.length - 1;
            mirrorIdentityForErrorBound[lastIndex] = -1;
        }

        // Check the rank condition mentioned directly after equation 43.
        mirrorIdentityForSolution = mirrorIdentityForErrorBound;
        if (svd.rank === dimensions - 1) {
            // Compute equation 43 in umeyama_1991.
            mirrorIdentityForSolution = Array(svd.diagonal.length).fill(1);
            if (mlMatrix.determinant(svd.U) * mlMatrix.determinant(svd.V) < 0) {
                const lastIndex = mirrorIdentityForSolution.length - 1;
                mirrorIdentityForSolution[lastIndex] = -1;
            }
        }
    }

    return {
        svd: svd,
        mirrorIdentityForErrorBound: mirrorIdentityForErrorBound,
        mirrorIdentityForSolution: mirrorIdentityForSolution
    }
}
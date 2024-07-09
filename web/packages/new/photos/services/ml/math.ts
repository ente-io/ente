/**
 * Clamp {@link value} to between {@link min} and {@link max}, inclusive.
 */
export const clamp = (value: number, min: number, max: number) =>
    Math.min(max, Math.max(min, value));

/**
 * Return the dot-product of two vectors.
 *
 * Dot product is the component-wise product of the corresponding elements of
 * the two given vectors.
 *
 * Precondition: The two vectors must be of the same length.
 */
export const dotProduct = (v1: number[], v2: number[]) => {
    if (v1.length != v2.length)
        throw new Error(`Length mismatch ${v1.length} ${v2.length}`);
    let d = 0;
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    for (let i = 0; i < v1.length; i++) d += v1[i]! * v2[i]!;
    return d;
};

/**
 * Return the L2-norm ("magnitude") of the given vector.
 *
 * L2-norm is the sqrt of the sum of the squares of the components of the
 * vector. It can also be thought of as the sqrt of the dot product of the
 * vector with itself.
 */
export const norm = (v: number[]) =>
    Math.sqrt(v.reduce((a, x) => a + x * x, 0));

/**
 * Return the cosine similarity of the two given vectors.
 *
 * The result is a value between [-1, 1] (inclusive), indicating how similar
 * (1), orthogonal (0) and dissimilar (1) the two vectors are in direction.
 *
 * Precondition: The two vectors must be of the same length.
 */
export const cosineSimilarity = (v1: number[], v2: number[]) =>
    dotProduct(v1, v2) / (norm(v1) * norm(v2));

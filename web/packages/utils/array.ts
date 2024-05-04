/**
 * Shuffle.
 *
 * Return a new array containing the shuffled elements of the given array.
 *
 * The algorithm used is not the most efficient, but is effectively a one-liner
 * whilst being reasonably efficient. To each element we assign a random key,
 * then we sort by this key. Since the key is random, the sorted array will have
 * the original elements in a random order.
 */
export const shuffle = <T>(xs: T[]) =>
    xs
        .map((x) => [Math.random(), x])
        .sort()
        .map(([, x]) => x);

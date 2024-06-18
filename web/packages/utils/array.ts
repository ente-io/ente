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
export const shuffled = <T>(xs: T[]) =>
    xs
        .map((x) => [Math.random(), x])
        .sort()
        .map(([, x]) => x) as T[];

/**
 * Return the first non-empty string from the given list of strings.
 *
 * This function is needed because the `a ?? b` idiom doesn't do what you'd
 * expect when a is "". Perhaps the behaviour is wrong, perhaps the expecation
 * is wrong; this function papers over the differences.
 *
 * If none of the strings are non-empty, or if there are no strings in the given
 * array, return undefined.
 */
export const firstNonEmpty = (ss: (string | undefined)[]) => {
    for (const s of ss) if (s && s.length > 0) return s;
    return undefined;
};

/**
 * Merge the given array of {@link Uint8Array}s in order into a single
 * {@link Uint8Array}.
 *
 * @param as An array of {@link Uint8Array}.
 */
export const mergeUint8Arrays = (as: Uint8Array[]) => {
    // A longer but better performing replacement of
    //
    //     new Uint8Array(as.reduce((acc, x) => acc.concat(...x), []))
    //

    const len = as.reduce((len, xs) => len + xs.length, 0);
    const result = new Uint8Array(len);
    as.reduce((n, xs) => (result.set(xs, n), n + xs.length), 0);
    return result;
};

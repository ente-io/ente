/**
 * Throw an exception if the given value {@link v} is false-y.
 *
 * This is a variant of {@link assertionFailed}, except it always throws, not
 * just in dev builds, if the given value is falsey.
 */
export const ensurePrecondition = (v: unknown): void => {
    if (!v) throw new Error("Precondition failed");
};

/**
 * Throw an exception if the given value is not a string.
 */
export const ensureString = (v: unknown): string => {
    if (typeof v != "string")
        throw new Error(`Expected a string, instead found ${String(v)}`);
    return v;
};

/**
 * Throw an exception if the given value is not a number or if it is NaN.
 */
export const ensureNumber = (v: unknown): number => {
    if (typeof v != "number" || Number.isNaN(v))
        throw new Error(`Expected a number, instead found ${String(v)}`);
    return v;
};

/**
 * Throw an exception if the given value is not an integral number.
 */
export const ensureInteger = (v: unknown): number => {
    if (typeof v != "number")
        throw new Error(`Expected a number, instead found ${String(v)}`);
    if (!Number.isInteger(v))
        throw new Error(`Expected an integer, instead found ${v}`);
    return v;
};

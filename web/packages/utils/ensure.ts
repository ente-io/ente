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

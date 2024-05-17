/**
 * Throw an exception if the given value is `null` or `undefined`.
 */
export const ensure = <T>(v: T | null | undefined): T => {
    if (v === null) throw new Error("Required value was null");
    if (v === undefined) throw new Error("Required value was undefined");
    return v;
};

/**
 * Throw an exception if the given value is not a string.
 */
export const ensureString = (v: unknown): string => {
    if (typeof v != "string")
        throw new Error(`Expected a string, instead found ${String(v)}`);
    return v;
};

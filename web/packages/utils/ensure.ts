/**
 * Throw an exception if the given value is undefined.
 */
export const ensure = <T>(v: T | undefined): T => {
    if (v === undefined) throw new Error("Required value was not found");
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

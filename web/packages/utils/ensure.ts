/**
 * Throw an exception if the given value is `null` or `undefined`.
 *
 * This is different from TypeScript's built in null assertion operator `!` in
 * that `ensure` involves a runtime check, and will throw if the given value is
 * null-ish. On the other hand the TypeScript null assertion is only an
 * indication to the type system and does not involve any runtime checks.
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

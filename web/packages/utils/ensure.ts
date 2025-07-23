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
 * Throw an exception if the given value is `null` or `undefined`.
 *
 * This is different from TypeScript's built in null assertion operator `!` in
 * that `ensure` involves a runtime check, and will throw if the given value is
 * null-ish. On the other hand the TypeScript null assertion is only an
 * indication to the type system and does not involve any runtime checks.
 *
 * However, still it is preferable to use the TypeScript build in null assertion
 * since the stack traces are more informative. The stack trace is not at the
 * point of the assertion, but later at the point of the use, so it is not
 * _directly_ pointing at the issue, but usually it is not hard to backtrace.
 *
 * Still, in rare cases we might want to, well, ensure that a undefined value
 * doesn't sneak into the machinery. So this.
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

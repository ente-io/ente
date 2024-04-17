/**
 * Throw an exception if the given value is undefined.
 */
export const ensure = <T>(v: T | undefined): T => {
    if (v === undefined) throw new Error("Required value was not found");
    return v;
};

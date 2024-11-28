/**
 * Convert `null` to `undefined`, passthrough everything else unchanged.
 */
export const nullToUndefined = <T>(v: T | null | undefined): T | undefined =>
    v === null ? undefined : v;

/**
 * Convert `null` and `undefined` to `0`, passthrough everything else unchanged.
 */
export const nullishToZero = (v: number | null | undefined) => v ?? 0;

/**
 * Convert `null` and `undefined` to `[]`, passthrough everything else unchanged.
 */
export const nullishToEmpty = <T>(v: T[] | null | undefined) => v ?? [];

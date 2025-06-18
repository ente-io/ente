/**
 * Convert `null` to `undefined`, passthrough everything else unchanged.
 */
export const nullToUndefined = <T>(v: T | null | undefined): T | undefined =>
    v === null ? undefined : v;

/**
 * Convert `null` and `undefined` to `false`, passthrough everything else unchanged.
 */
export const nullishToFalse = (v: boolean | null | undefined): boolean =>
    v ?? false;

/**
 * Convert `null` and `undefined` to `0`, passthrough everything else unchanged.
 */
export const nullishToZero = (v: number | null | undefined): number => v ?? 0;

/**
 * Convert `null` and `undefined` to "" (blank string), passthrough everything else unchanged.
 */
export const nullishToBlank = (v: string | null | undefined): string => v ?? "";

/**
 * Convert `null` and `undefined` to `[]`, passthrough everything else unchanged.
 */
export const nullishToEmpty = <T>(v: T[] | null | undefined): T[] => v ?? [];

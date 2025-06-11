/**
 * Convert `null` to `undefined`, passthrough everything else unchanged.
 */
export const nullToUndefined = <T>(v: T | null | undefined): T | undefined =>
    v === null ? undefined : v;

/**
 * Convert any falsey value (including blank strings) to `undefined`;
 * passthrough everything else unchanged.
 */
export const falseyToUndefined = <T>(v: T | null | undefined): T | undefined =>
    v || undefined;

/**
 * Convert `null` and `undefined` to `0`, passthrough everything else unchanged.
 */
export const nullishToZero = (v: number | null | undefined): number => v ?? 0;

/**
 * Convert `null` and `undefined` to `[]`, passthrough everything else unchanged.
 */
export const nullishToEmpty = <T>(v: T[] | null | undefined): T[] => v ?? [];

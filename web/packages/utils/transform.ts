/** Convert `null` to `undefined`, passthrough everything else unchanged. */
export const nullToUndefined = <T>(v: T | null | undefined): T | undefined =>
    v === null ? undefined : v;

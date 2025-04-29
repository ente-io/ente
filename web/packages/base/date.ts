/**
 * Convert an epoch microsecond value to a JavaScript date.
 *
 * [Note: Remote timestamps are epoch microseconds]
 *
 * This is a convenience API for dealing with optional epoch microseconds in
 * various data structures. Remote talks in terms of epoch microseconds, but
 * JavaScript dates are underlain by epoch milliseconds, and this does a
 * conversion, with a convenience of short circuiting undefined values.
 */
export const dateFromEpochMicroseconds = (
    epochMicroseconds: number | undefined,
) =>
    epochMicroseconds === undefined
        ? undefined
        : new Date(epochMicroseconds / 1000);

/**
 * Return `true` if both the given dates have the same day.
 */
export const isSameDay = (first: Date, second: Date) =>
    first.getFullYear() === second.getFullYear() &&
    first.getMonth() === second.getMonth() &&
    first.getDate() === second.getDate();

/**
 * A variant of Array.includes that allows us to use it as a type guard.
 *
 * It allows us to narrow the type of an arbitrary T to U if it is one of U[].
 *
 * TypeScript currently doesn't allow us to use the standard Array.includes as a
 * type guard for checking if an arbitrary string is one of the known set of
 * values. This issue and this workaround is mentioned here:
 * - https://github.com/microsoft/TypeScript/issues/48247
 * - https://github.com/microsoft/TypeScript/issues/26255#issuecomment-502899689
 */
export function includes<T, U extends T>(us: readonly U[], t: T): t is U {
    // @ts-expect-error @typescript-eslint/no-unsafe-argument
    return us.includes(t);
}

/**
 * A wrapper over parseInt that deals with its sheNaNigans.
 *
 * This function takes as an input a string nominally (though the implementation
 * is meant to work for arbitrary JavaScript values). It parses it into a base
 * 10 integer. If the result is NaN, it returns undefined, otherwise it returns
 * the parsed integer.
 *
 * From MDN:
 *
 * > To be sure that you are working with numbers, coerce the value to a number
 * > and use Number.isNaN() to test the result()
 * >
 * > https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/isNaN
 */
export const maybeParseInt = (s: string) => {
    const n = parseInt(s, 10);
    return Number.isNaN(n) ? undefined : n;
};

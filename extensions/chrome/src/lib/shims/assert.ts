/**
 * Minimal Node "assert" shim for the browser.
 *
 * fast-srp-hap uses `assert.strictEqual(..)` only.
 */
export const strictEqual = (actual: unknown, expected: unknown, message?: string): void => {
  if (actual !== expected) {
    throw new Error(message || `AssertionError: expected ${String(expected)}, got ${String(actual)}`);
  }
};

export default {
  strictEqual,
};


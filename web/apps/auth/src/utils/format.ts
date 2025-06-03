/**
 * Format a generated OTP code to improve readability by breaking it into chunks
 * of length 3.
 */
export const prettyFormatCode = (code: string) =>
    code.replace(/(.{3})/g, "$1 ").trim();

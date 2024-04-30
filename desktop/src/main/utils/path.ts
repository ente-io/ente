import path from "node:path";

/**
 * Convert a file system {@link filePath} that uses the local system specific
 * path separators into a path that uses POSIX file separators.
 */
export const posixPath = (filePath: string) =>
    filePath.split(path.sep).join(path.posix.sep);

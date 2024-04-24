import type { ElectronFile } from "./types/file";

/**
 * The two parts of a file name - the name itself, and an (optional) extension.
 *
 * The extension does not include the dot.
 */
type FileNameComponents = [name: string, extension: string | undefined];

/**
 * Split a filename into its components - the name itself, and the extension (if
 * any) - returning both. The dot is not included in either.
 *
 * For example, `foo-bar.png` will be split into ["foo-bar", "png"].
 *
 * See {@link fileNameFromComponents} for the inverse operation.
 */
export const nameAndExtension = (fileName: string): FileNameComponents => {
    const i = fileName.lastIndexOf(".");
    // No extension
    if (i == -1) return [fileName, undefined];
    // A hidden file without an extension, e.g. ".gitignore"
    if (i == 0) return [fileName, undefined];
    // Both components present, just omit the dot.
    return [fileName.slice(0, i), fileName.slice(i + 1)];
};

/**
 * Construct a file name from its components (name and extension).
 *
 * Inverse of {@link nameAndExtension}.
 */
export const fileNameFromComponents = (components: FileNameComponents) =>
    components.filter((x) => !!x).join(".");

/**
 * Return the file name portion from the given {@link path}.
 *
 * This tries to emulate the UNIX `basename` command. In particular, any
 * trailing slashes on the path are trimmed, so this function can be used to get
 * the name of the directory too.
 *
 * The path is assumed to use POSIX separators ("/").
 */
export const basename = (path: string) => {
    const pathComponents = path.split("/");
    for (let i = pathComponents.length - 1; i >= 0; i--)
        if (pathComponents[i] !== "") return pathComponents[i];
    return path;
};

/**
 * Return the directory portion from the given {@link path}.
 *
 * This tries to emulate the UNIX `dirname` command. In particular, any trailing
 * slashes on the path are trimmed, so this function can be used to get the path
 * leading up to a directory too.
 *
 * The path is assumed to use POSIX separators ("/").
 */
export const dirname = (path: string) => {
    const pathComponents = path.split("/");
    while (pathComponents.pop() == "") {
        /* no-op */
    }
    return pathComponents.join("/");
};

/**
 * Return a short description of the given {@link fileOrPath} suitable for
 * helping identify it in log messages.
 */
export const fopLabel = (fileOrPath: File | string) =>
    fileOrPath instanceof File ? `File(${fileOrPath.name})` : fileOrPath;

export function getFileNameSize(file: File | ElectronFile) {
    return `${file.name}_${convertBytesToHumanReadable(file.size)}`;
}

export function convertBytesToHumanReadable(
    bytes: number,
    precision = 2,
): string {
    if (bytes === 0 || isNaN(bytes)) {
        return "0 MB";
    }

    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    const sizes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    return (bytes / Math.pow(1024, i)).toFixed(precision) + " " + sizes[i];
}

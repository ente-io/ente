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
    if (i == -1) return [fileName, undefined];
    else return [fileName.slice(0, i), fileName.slice(i + 1)];
};

/**
 * Construct a file name from its components (name and extension).
 *
 * Inverse of {@link nameAndExtension}.
 */
export const fileNameFromComponents = (components: FileNameComponents) =>
    components.filter((x) => !!x).join(".");

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

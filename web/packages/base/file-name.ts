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
 * If the file name or path has an extension, return a lowercased version of it.
 *
 * This is handy when comparing the extension to a known set without worrying
 * about case sensitivity.
 *
 * See {@link nameAndExtension} for its more generic sibling.
 */
export const lowercaseExtension = (
    fileNameOrPath: string,
): string | undefined => {
    // We rely on the implementation of nameAndExtension using lastIndexOf to
    // allow us to also work on paths.
    const [, ext] = nameAndExtension(fileNameOrPath);
    return ext?.toLowerCase();
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
    for (let i = pathComponents.length - 1; i >= 0; i--) {
        const component = pathComponents[i];
        if (component && component.length > 0) return component;
    }
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
 * Return a new path by joining two path components using the POSIX path
 * separator ("/").
 *
 * This is usually a trivial `p1/p2`, however it also handles the case where p1
 * already ends with a trailing slash. This can happen even if p1 is obtained
 * from a place which guarantees that only directory paths will be returned,
 * because p1 can be the path to a root folder (e.g. "/" on Linux, or "C:/" on
 * Windows), and the trivial join would then result in double slashes.
 *
 * @param p1 A path component that is expected to be using POSIX path
 * separators.
 *
 * @param p2 A path component that is expected to be using POSIX path
 * separators.
 *
 * @returns A path by joining p1 and p2 with a POSIX path separator if needed.
 */
export const joinPath = (p1: string, p2: string) =>
    p1.endsWith("/") ? p1 + p2 : `${p1}/${p2}`;

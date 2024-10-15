/**
 * Download the asset at the given {@link url} to a file on the user's download
 * folder by appending a temporary <a> element to the DOM.
 *
 * @param url The URL that we want to download. See also
 * {@link downloadAndRevokeObjectURL} and {@link downloadString}.
 *
 * @param fileName The name of downloaded file.
 */
export const downloadURL = (url: string, fileName: string) => {
    const a = document.createElement("a");
    a.style.display = "none";
    a.href = url;
    a.download = fileName;
    document.body.appendChild(a);
    a.click();
    URL.revokeObjectURL(url);
    a.remove();
};

/**
 * A variant of {@link downloadURL} that also revokes the provided
 * {@link objectURL} after initiating the download.
 */
export const downloadAndRevokeObjectURL = (url: string, fileName: string) => {
    downloadURL(url, fileName);
    URL.revokeObjectURL(url);
};

/**
 * Save the given string {@link s} as a file in the user's download folder.
 *
 * @param s The string to save.
 *
 * @param fileName The name of the file that gets saved.
 */
export const downloadString = (s: string, fileName: string) => {
    const file = new Blob([s], { type: "text/plain" });
    const fileURL = URL.createObjectURL(file);
    downloadAndRevokeObjectURL(fileURL, fileName);
};

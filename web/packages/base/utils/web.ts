/**
 * Download the asset at the given {@link url} to a file on the user's download
 * folder by appending a temporary <a> element to the DOM.
 *
 * @param url The URL that we want to download. The URL is revoked after
 * initiating the download.
 *
 * @param fileName The name of downloaded file.
 *
 * See also {@link saveStringAsFile}.
 */
export const saveAsFileAndRevokeObjectURL = (url: string, fileName: string) => {
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
 * Save the given string {@link s} as a file in the user's download folder.
 *
 * @param s The string to save.
 *
 * @param fileName The name of the file that gets saved.
 */
export const saveStringAsFile = (s: string, fileName: string) => {
    const file = new Blob([s], { type: "text/plain" });
    const fileURL = URL.createObjectURL(file);
    saveAsFileAndRevokeObjectURL(fileURL, fileName);
};

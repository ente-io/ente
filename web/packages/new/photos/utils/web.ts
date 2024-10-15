/**
 * Open the given {@link url} in a new browser tab.
 *
 * @param url The URL to open.
 */
export const openURL = (url: string) => {
    const a = document.createElement("a");
    a.href = url;
    a.target = "_blank";
    a.rel = "noopener";
    a.click();
};

/**
 * Open the system configured email client, initiating a new email to the given
 * {@link email} address.
 */
export const initiateEmail = (email: string) => {
    const a = document.createElement("a");
    a.href = "mailto:" + email;
    a.rel = "noopener";
    a.click();
};

/**
 * Open the system configured email client, initiating a new email to the given
 * {@link email} address.
 */
export const initiateEmail = (email: string) => {
    const a = document.createElement("a");
    a.href = "mailto:" + email;
    a.rel = "noreferrer noopener";
    a.click();
};

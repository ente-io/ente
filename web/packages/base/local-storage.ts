import { nullToUndefined } from "ente-utils/transform";

/**
 * Clear local storage on logout.
 *
 * This function clears everything from local storage except the app's logs.
 */
export const clearLocalStorage = () => {
    const existingLogs = nullToUndefined(localStorage.getItem("logs"));
    localStorage.clear();
    if (existingLogs) {
        localStorage.setItem("logs", existingLogs);
    }
};

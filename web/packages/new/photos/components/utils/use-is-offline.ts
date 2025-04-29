import { useEffect, useState } from "react";

/**
 * A hook that returns true if the browser is currently offline.
 *
 * This hook returns the (negated) value of the navigator.onLine property, and
 * also monitors for changes.
 */
export const useIsOffline = () => {
    const [offline, setOffline] = useState(
        typeof window != "undefined" && !window.navigator.onLine,
    );

    useEffect(() => {
        const setUserOnline = () => setOffline(false);
        const setUserOffline = () => setOffline(true);

        window.addEventListener("online", setUserOnline);
        window.addEventListener("offline", setUserOffline);

        return () => {
            window.removeEventListener("online", setUserOnline);
            window.removeEventListener("offline", setUserOffline);
        };
    }, []);

    return offline;
};

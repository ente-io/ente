import { setupI18n } from "@/base/i18n";
import { disableDiskLogs } from "@/base/log";
import { logUnhandledErrorsAndRejections } from "@/base/log-web";
import { useEffect, useState } from "react";

/**
 * A hook that initializes the localization library that we use.
 *
 * This is only meant to be called from the top level `_app.tsx`, as this
 * initialization is intended to happen only once for the lifetime of the app.
 *
 * @returns a boolean which will be set to true when the localized strings have
 * been loaded.
 */
export const useSetupI18n = () => {
    const [isI18nReady, setIsI18nReady] = useState(false);

    useEffect(() => {
        void setupI18n().finally(() => setIsI18nReady(true));
    }, []);

    return isI18nReady;
};

interface SetupLoggingOptions {
    /** If true, then the logs will not be saved to local storage. */
    disableDiskLogs?: boolean;
}

/**
 * A hook that initializes the logging subsystem.
 *
 * This is only meant to be called from the top level `_app.tsx`, as this
 * initialization is intended to happen only once for the lifetime of the app.
 *
 * @param opts Optional {@link SetupLoggingOptions} to customize the setup.
 */
export const useSetupLogs = (opts?: SetupLoggingOptions) => {
    useEffect(() => {
        if (opts?.disableDiskLogs) disableDiskLogs();
        logUnhandledErrorsAndRejections(true);
        return () => logUnhandledErrorsAndRejections(false);
    }, []);
};

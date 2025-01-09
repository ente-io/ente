import { setupI18n } from "@/base/i18n";
import { useEffect, useState } from "react";

/**
 * A hook that initializes the localization library that we use.
 *
 * This is only meant to be called from the top level `_app.tsx`, as this
 * initialization is expected to only happen once for the lifetime of the page.
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

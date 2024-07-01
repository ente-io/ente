import { ensure } from "@/utils/ensure";
import type { DialogBoxAttributesV2 } from "@ente/shared/components/DialogBoxV2/types";
import { createContext, useContext } from "react";

/**
 * The type of the context for pages in the accounts app.
 *
 * -   The accounts app has no extra properties on top of the base context.
 *
 * -   It also doesn't need the logout function.
 */
interface AppContextT {
    /** Show or hide the app's navigation bar. */
    showNavBar: (show: boolean) => void;
    isMobile: boolean;
    setDialogBoxAttributesV2: (attrs: DialogBoxAttributesV2) => void;
}

/**
 * The React {@link Context} available to all pages.
 */
export const AppContext = createContext<AppContextT | undefined>(undefined);

/**
 * Utility hook to get the {@link AppContextT}, throwing an exception if it is
 * not defined.
 */
export const useAppContext = (): AppContextT => ensure(useContext(AppContext));

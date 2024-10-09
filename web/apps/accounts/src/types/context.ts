import type { MiniDialogAttributes } from "@/base/components/MiniDialog";
import { ensure } from "@/utils/ensure";
import { createContext, useContext } from "react";

/**
 * The type of the context for pages in the accounts app.
 */
interface AppContextT {
    /** Show or hide the app's navigation bar. */
    showNavBar: (show: boolean) => void;
    setDialogBoxAttributesV2: (attrs: MiniDialogAttributes) => void;
}

/**
 * The React {@link Context} available to all nodes in the React tree.
 */
export const AppContext = createContext<AppContextT | undefined>(undefined);

/**
 * Utility hook to get the {@link AppContextT}, throwing an exception if it is
 * not defined.
 */
export const useAppContext = (): AppContextT => ensure(useContext(AppContext));

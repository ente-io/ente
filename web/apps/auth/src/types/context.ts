import type { AccountsContextT } from "@/accounts/types/context";
import { THEME_COLOR } from "@/base/components/utils/theme";
import { createContext, useContext } from "react";

/**
 * Properties available via {@link AppContext} to the Auth app's React tree.
 */
type AppContextT = AccountsContextT & {
    themeColor: THEME_COLOR;
    setThemeColor: (themeColor: THEME_COLOR) => void;
};

/** The React {@link Context} available to all pages. */
export const AppContext = createContext<AppContextT | undefined>(undefined);

/** Utility hook to reduce amount of boilerplate in account related pages. */
export const useAppContext = () => useContext(AppContext)!;

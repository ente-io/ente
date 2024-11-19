import type { AccountsContextT } from "@/accounts/types/context";
import { createContext, useContext } from "react";

/**
 * The type of the context for pages in the accounts app.
 */
type AppContextT = Omit<AccountsContextT, "logout">;

/**
 * The React {@link Context} available to all nodes in the React tree.
 */
export const AppContext = createContext<AppContextT | undefined>(undefined);

/**
 * Utility hook to get the {@link AppContextT}, throwing an exception if it is
 * not defined.
 */
export const useAppContext = (): AppContextT => useContext(AppContext)!;

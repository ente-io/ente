import type { BaseContextT } from "@/base/context";
import { createContext, useContext } from "react";

/**
 * The type of the context for pages in the accounts app.
 */
type AppContextT = Omit<BaseContextT, "logout">;

/**
 * The React {@link Context} available to all nodes in the React tree.
 */
export const AppContext = createContext<AppContextT | undefined>(undefined);

/**
 * Utility hook to get the {@link AppContextT} expected to be available to all
 * React components in the Accounts app's React tree.
 */
export const useAppContext = (): AppContextT => useContext(AppContext)!;

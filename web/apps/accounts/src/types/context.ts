import type { BaseAppContextT } from "@/next/types/context";
import { ensure } from "@/utils/ensure";
import { createContext, useContext } from "react";

/**
 * The type of the context for pages in the accounts app.
 *
 * -   The accounts app has no extra properties on top of the base context.
 *
 * -   It also doesn't need the logout function.
 */
type AppContextT = Omit<BaseAppContextT, "logout">;

/**
 * The React {@link Context} available to all pages.
 */
export const AppContext = createContext<AppContextT | undefined>(undefined);

/**
 * Utility hook to get the {@link AppContextT}, throwing an exception if it is
 * not defined.
 */
export const useAppContext = (): AppContextT => ensure(useContext(AppContext));

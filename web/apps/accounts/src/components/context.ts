import type { BaseAppContextT } from "@/next/types/app";
import { ensure } from "@/utils/ensure";
import { createContext, useContext } from "react";

/** The accounts app has no extra properties on top of the base context. */
type AppContextT = BaseAppContextT;

/** The React {@link Context} available to all pages. */
export const AppContext = createContext<AppContextT | undefined>(undefined);

/**
 * Utility hook to get the {@link AppContextT}, throwing an exception if it is
 * not defined.
 */
export const useAppContext = (): AppContextT => ensure(useContext(AppContext));

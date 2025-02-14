import type { BaseContextT } from "@/base/context";
import { createContext, useContext } from "react";

/**
 * Properties available via {@link AppContext} to the Auth app's React tree.
 */
type AppContextT = BaseContextT;

/** The React {@link Context} available to all pages. */
export const AppContext = createContext<AppContextT | undefined>(undefined);

/** Utility hook to reduce amount of boilerplate in account related pages. */
export const useAppContext = () => useContext(AppContext)!;

import type { AccountsContextT } from "./context";

/**
 * The default type for pages exposed by this package.
 *
 * Some specific pages might extend this further (e.g. the two-factor/recover).
 */
export interface PageProps {
    /**
     * The common denominator AppContext.
     *
     * Within this package we do not have access to the context object declared
     * with the app's code, so we need to take the context as a parameter.
     */
    appContext: AccountsContextT;
}

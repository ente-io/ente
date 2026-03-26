import type { MiniDialogAttributes } from "ente-base/components/MiniDialog";
import { createContext, useContext } from "react";
import { genericErrorDialogAttributes } from "./components/utils/dialog";
import log from "./log";

/**
 * The type of the context expected to be present in the React tree for all apps
 * that use the base package.
 *
 * It is usually provided by the _app.tsx for the corresponding app.
 */
export interface BaseContextT {
    /**
     * Perform the (possibly app specific) logout sequence.
     */
    logout: () => void;
    /**
     * Show a "mini dialog" with the given attributes.
     *
     * Mini dialogs (see {@link AttributedMiniDialog}) are meant for simple
     * confirmation or notifications. Their appearance and functionality can be
     * customized by providing appropriate {@link MiniDialogAttributes}.
     */
    showMiniDialog: (attributes: MiniDialogAttributes) => void;
    /**
     * Log the given error and show a generic error {@link MiniDialog}.
     */
    onGenericError: (error: unknown) => void;
}

/**
 * The React {@link Context} of type {@link BaseContextT} available to all React
 * components that refer to the base package.
 */
export const BaseContext = createContext<BaseContextT | undefined>(undefined);

/**
 * Utility hook to get the required {@link BaseContextT} that is expected to be
 * available to all React components that refer to the base package.
 */
export const useBaseContext = (): BaseContextT => useContext(BaseContext)!;

/**
 * A helper function to create a {@link BaseContext} by deriving derivable
 * context values from the minimal subset.
 *
 * In simpler words, it automatically provides a definition of
 * {@link onGenericError} using the given {@link showMiniDialog} prop.
 */
export const deriveBaseContext = ({
    logout,
    showMiniDialog,
}: Omit<BaseContextT, "onGenericError">): BaseContextT => {
    const onGenericError = (e: unknown) => {
        log.error(e);
        // The generic error handler is sometimes called in the context of
        // actions that were initiated by a confirmation dialog action handler
        // themselves, then we need to let the current one close.
        //
        // See: [Note: Chained MiniDialogs]
        setTimeout(() => {
            showMiniDialog(genericErrorDialogAttributes());
        }, 0);
    };

    return { logout, showMiniDialog, onGenericError };
};

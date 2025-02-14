import type { MiniDialogAttributes } from "@/base/components/MiniDialog";
import { createContext, useContext } from "react";

/**
 * The type of the context expected to be present in the React tree for all apps
 * that use the base package.
 *
 * It is usually provided by the _app.tsx for the corresponding app.
 */
export interface BaseContextT {
    /**
     * Show a "mini dialog" with the given attributes.
     *
     * Mini dialogs (see {@link AttributedMiniDialog}) are meant for simple
     * confirmation or notications. Their appearance and functionality can be
     * customized by providing appropriate {@link MiniDialogAttributes}.
     */
    showMiniDialog: (attributes: MiniDialogAttributes) => void;
    /**
     * Perform the (possibly app specific) logout sequence.
     */
    logout: () => void;
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

import type { MiniDialogAttributes } from "@/base/components/MiniDialog";

/**
 * The type of the context expected to be present in the React tree for all apps
 * that use the base package.
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
     * confirmation or notications. Their appearance and functionality can be
     * customized by providing appropriate {@link MiniDialogAttributes}.
     */
    showMiniDialog: (attributes: MiniDialogAttributes) => void;
}

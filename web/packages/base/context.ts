import type { MiniDialogAttributes } from "@/base/components/MiniDialog";

/**
 * Properties expected to be present in the AppContext types for pages that
 * defer to the pages provided by the accounts package.
 */
export interface AccountsContextT {
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

import type { MiniDialogAttributes } from "@/base/components/MiniDialog";

/**
 * Properties expected to be present in the AppContext types for pages that
 * defer to the pages provided by the accounts package.
 */
export interface AccountsContextT {
    /** Perform the (possibly app specific) logout sequence. */
    logout: () => void;
    /** Show or hide the app's navigation bar. */
    showNavBar: (show: boolean) => void;
    setDialogBoxAttributesV2: (attrs: MiniDialogAttributes) => void;
}

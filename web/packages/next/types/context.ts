import type { DialogBoxAttributesV2 } from "@ente/shared/components/DialogBoxV2/types";

/**
 * Properties guaranteed to be present in the AppContext types for apps that are
 * listed in {@link AppName}.
 */
export interface BaseAppContextT {
    /** Perform the (possibly app specific) logout sequence. */
    logout: () => void;
    /** Show or hide the app's navigation bar. */
    showNavBar: (show: boolean) => void;
    isMobile: boolean;
    setDialogBoxAttributesV2: (attrs: DialogBoxAttributesV2) => void;
}

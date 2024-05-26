import { TwoFactorType } from "@ente/accounts/constants/twofactor";
import type { DialogBoxAttributesV2 } from "@ente/shared/components/DialogBoxV2/types";
import { APPS } from "./constants";

export interface PageProps {
    appContext: {
        showNavBar: (show: boolean) => void;
        isMobile: boolean;
        setDialogBoxAttributesV2: (attrs: DialogBoxAttributesV2) => void;
        logout: () => void;
    };
    appName: APPS;
    twoFactorType?: TwoFactorType;
}

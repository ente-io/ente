import { TwoFactorType } from "@ente/accounts/constants/twofactor";
import type { SetDialogBoxAttributesV2 } from "@ente/shared/components/DialogBoxV2/types";
import { APPS } from "./constants";

export interface PageProps {
    appContext: {
        showNavBar: (show: boolean) => void;
        isMobile: boolean;
        setDialogBoxAttributesV2: SetDialogBoxAttributesV2;
        logout: () => void;
    };
    appName: APPS;
    twoFactorType?: TwoFactorType;
}

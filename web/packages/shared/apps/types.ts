import { TwoFactorType } from "@ente/accounts/constants/twofactor";
import type { DialogBoxAttributesV2 } from "@ente/shared/components/DialogBoxV2/types";
import { APPS } from "./constants";
import type { AppName } from "@/next/types/app";

export interface PageProps {
    appContext: {
        showNavBar: (show: boolean) => void;
        isMobile: boolean;
        setDialogBoxAttributesV2: (attrs: DialogBoxAttributesV2) => void;
        logout: () => void;
    };
    appName: APPS;
    appName2?: AppName;
    twoFactorType?: TwoFactorType;
}

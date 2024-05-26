import type { BaseAppContextT } from "@/next/types/app";
import { TwoFactorType } from "@ente/accounts/constants/twofactor";
import { APPS } from "./constants";

export interface PageProps {
    appContext: BaseAppContextT;
    appName?: APPS;
    twoFactorType?: TwoFactorType;
}

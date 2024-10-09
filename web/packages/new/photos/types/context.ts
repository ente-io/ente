import type { AccountsContextT } from "@/accounts/types/context";
import { ensure } from "@/utils/ensure";
import type { SetDialogBoxAttributes } from "@ente/shared/components/DialogBox/types";
import type { DialogBoxAttributesV2 } from "@ente/shared/components/DialogBoxV2/types";
import { THEME_COLOR } from "@ente/shared/themes/constants";
import { createContext, useContext } from "react";
import type { SetNotificationAttributes } from "./notification";

/**
 * A subset of the AppContext type used by the photos app.
 *
 * [Note: Migrating components that need the app context]
 *
 * This only exists to make it easier to migrate code into the @/new package.
 * Once we move this code back (after TypeScript strict mode migration is done),
 * then the code that uses this can start directly using the actual app context
 * instead of needing to explicitly pass a prop of this type.
 * */
export interface NewAppContextPhotos {
    startLoading: () => void;
    finishLoading: () => void;
    setDialogBoxAttributesV2: (attrs: DialogBoxAttributesV2) => void;
    somethingWentWrong: () => void;
    onGenericError: (error: unknown) => void;
}

/**
 * The type of the React context available to all pages in the photos app.
 */
type AppContextT = AccountsContextT & {
    /**
     * Show the global activity indicator (a green bar at the top of the page).
     */
    startLoading: () => void;
    /**
     * Hide the global activity indicator.
     */
    finishLoading: () => void;
    somethingWentWrong: () => void;
    setDialogMessage: SetDialogBoxAttributes;
    setNotificationAttributes: SetNotificationAttributes;
    onGenericError: (error: unknown) => void;
    closeMessageDialog: () => void;
    mapEnabled: boolean;
    updateMapEnabled: (enabled: boolean) => Promise<void>;
    watchFolderView: boolean;
    setWatchFolderView: (isOpen: boolean) => void;
    watchFolderFiles: FileList;
    setWatchFolderFiles: (files: FileList) => void;
    themeColor: THEME_COLOR;
    setThemeColor: (themeColor: THEME_COLOR) => void;
    isCFProxyDisabled: boolean;
    setIsCFProxyDisabled: (disabled: boolean) => void;
};

/**
 * The React {@link Context} available to all nodes in the React tree.
 */
export const AppContext = createContext<AppContextT | undefined>(undefined);

/**
 * Utility hook to get the photos {@link AppContextT}, throwing an exception if
 * it is not defined.
 *
 * This context is provided at the top level _app component for the photos app,
 * and thus is available to all React components in the Photos app's React tree.
 */
export const useAppContext = (): AppContextT => ensure(useContext(AppContext));

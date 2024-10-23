import type { AccountsContextT } from "@/accounts/types/context";
import { ensure } from "@/utils/ensure";
import type { SetDialogBoxAttributes } from "@ente/shared/components/DialogBox/types";
import { THEME_COLOR } from "@ente/shared/themes/constants";
import { createContext, useContext } from "react";
import type { SetNotificationAttributes } from "./notification";

/**
 * The type of the React context available to all pages in the photos app.
 */
export type AppContextT = AccountsContextT & {
    /**
     * Show the global activity indicator (a green bar at the top of the page).
     */
    startLoading: () => void;
    /**
     * Hide the global activity indicator.
     */
    finishLoading: () => void;
    /**
     * Show a generic error dialog, and log the given error.
     */
    onGenericError: (error: unknown) => void;
    /**
     * Deprecated, use onGenericError instead.
     */
    somethingWentWrong: () => void;
    /**
     * Deprecated, use showMiniDialog instead.
     */
    setDialogMessage: SetDialogBoxAttributes;
    setNotificationAttributes: SetNotificationAttributes;
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

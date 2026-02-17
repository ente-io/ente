import type { Electron } from "./types/ipc";

/**
 * A wrapper over a non-null assertion of `globalThis.electron`.
 *
 * This is useful where we have previously verified that the code path in which
 * we're running only executes when we're in electron (usually by directly
 * checking that `globalThis.electron` is defined somewhere up the chain).
 *
 * Generally, this should not be required - the check and the use should be
 * colocated, or the unwrapped non-null value saved somewhere. But sometimes
 * doing so requires code refactoring, so as an escape hatch we provide this
 * convenience function.
 *
 * It will throw if `globalThis.electron` is undefined.
 *
 * @see `global-electron.d.ts`.
 */
export const ensureElectron = (): Electron => {
    const et = globalThis.electron;
    if (et) return et;
    throw new Error(
        "Attempting to assert globalThis.electron in a non-electron context",
    );
};

type MainWindowFocusListener = () => void;

const mainWindowFocusListeners = new Set<MainWindowFocusListener>();
let hasAttachedMainWindowFocusBridge = false;

const emitMainWindowFocus = () => {
    for (const listener of mainWindowFocusListeners) {
        listener();
    }
};

const attachMainWindowFocusBridgeIfNeeded = () => {
    if (hasAttachedMainWindowFocusBridge) return;
    const electron = globalThis.electron;
    if (!electron) return;
    electron.onMainWindowFocus(emitMainWindowFocus);
    hasAttachedMainWindowFocusBridge = true;
};

const detachMainWindowFocusBridgeIfNeeded = () => {
    if (
        !hasAttachedMainWindowFocusBridge ||
        mainWindowFocusListeners.size > 0
    ) {
        return;
    }

    const electron = globalThis.electron;
    if (electron) {
        electron.onMainWindowFocus(undefined);
    }
    hasAttachedMainWindowFocusBridge = false;
};

/**
 * Subscribe to main window focus events on Electron.
 *
 * This helper multiplexes listeners over Electron's single-callback API,
 * allowing multiple consumers to listen concurrently.
 */
export const subscribeMainWindowFocus = (
    listener: MainWindowFocusListener,
): (() => void) => {
    mainWindowFocusListeners.add(listener);
    attachMainWindowFocusBridgeIfNeeded();
    return () => {
        mainWindowFocusListeners.delete(listener);
        detachMainWindowFocusBridgeIfNeeded();
    };
};

import type { Electron } from "./types/ipc";

// type ElectronAPIsType =
// TODO (MR):
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const ElectronAPIs = (globalThis as unknown as any)[
    // eslint-disable-next-line @typescript-eslint/dot-notation, @typescript-eslint/no-unsafe-member-access
    "ElectronAPIs"
] as Electron;

// /**
//  * Extend the global object's (`globalThis`) interface to state that it can
//  * potentially hold a property called `electron`. It will be injected by our
//  * preload.js script when we're running in the context of our desktop app.
//  */
// declare global {
//     const electron: Electron | undefined;
// }

// export const globalElectron = globalThis.electron;

export default ElectronAPIs;

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

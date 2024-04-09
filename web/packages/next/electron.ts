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

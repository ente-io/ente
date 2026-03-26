import type { Electron } from "./types/ipc";

/**
 * Extend the global object's (`globalThis`) interface to state that it can
 * potentially hold a property called `electron`. It will be injected by our
 * preload.js script when we're running in the context of our desktop app.
 */
declare global {
    /**
     * Extra, desktop specific, APIs provided by our Node.js layer.
     *
     * This property will defined only when we're running inside our desktop
     * (Electron) app. It will expose a bunch of functions (see
     * {@link Electron}) that allow us to communicate with the Node.js layer of
     * our desktop app.
     */
    declare var electron: Electron | undefined;
}

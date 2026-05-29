type TauriGlobal = typeof globalThis & { isTauri?: unknown };

/**
 * Return true if we're running under Tauri.
 *
 * TThis is an inlined variant of `isTauri` from from `@tauri-apps/api/core`
 * so that we can detect Tauri runtime without importing the entire package.
 */
export const isTauriRuntime = () =>
    (globalThis as TauriGlobal).isTauri === true;

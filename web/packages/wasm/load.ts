type EnteWasmModule = typeof import("ente-wasm");

let wasmPromise: Promise<EnteWasmModule> | undefined;
let cryptoInitDone = false;

/**
 * Load `ente-wasm` once and return the shared module instance.
 *
 * The first call performs the dynamic import. Later calls reuse the same
 * promise, so all consumers share one loader path.
 */
export const loadEnteWasm = async (): Promise<EnteWasmModule> => {
    wasmPromise ??= import("ente-wasm");
    return wasmPromise;
};

/**
 * Ensure the WASM crypto backend has been initialised exactly once for the
 * current page runtime.
 */
export const ensureWasmCryptoInit = async () => {
    if (cryptoInitDone) return;
    const wasm = await loadEnteWasm();
    wasm.crypto_init();
    cryptoInitDone = true;
};

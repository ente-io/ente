/**
 * Lazy loader for the `ente-wasm` package.
 *
 * We keep this behind a dynamic import so that the WASM bundle is only loaded
 * when needed (when crypto operations are first invoked).
 *
 * This follows the same pattern as `apps/ensu/src/services/wasm.ts` but
 * without the Tauri adapter since Locker is web-only.
 */

type EnteWasmModule = typeof import("ente-wasm");

let _wasmPromise: Promise<EnteWasmModule> | undefined;
let _cryptoInitDone = false;

/**
 * Return the lazily loaded `ente-wasm` module.
 *
 * The module is loaded once on first call and the same promise is reused for
 * subsequent calls.
 */
export const enteWasm = async (): Promise<EnteWasmModule> => {
    if (!_wasmPromise) {
        const load = import("ente-wasm");
        _wasmPromise = load.catch((error: unknown) => {
            if (_wasmPromise === load) {
                _wasmPromise = undefined;
            }
            throw error;
        });
    }
    return _wasmPromise;
};

/**
 * Ensure the WASM crypto backend has been initialised.
 *
 * This is a no-op for the pure-Rust backend but keeps the API symmetric with
 * other implementations.
 */
export const ensureCryptoInit = async () => {
    if (_cryptoInitDone) return;
    const wasm = await enteWasm();
    wasm.crypto_init();
    _cryptoInitDone = true;
};

type EnteWasmModule = typeof import("ente-wasm");

let wasmPromise: Promise<EnteWasmModule> | undefined;
let cryptoReadyPromise: Promise<EnteWasmModule> | undefined;

/**
 * Load `ente-wasm` once and return the shared module instance.
 *
 * The first call performs the dynamic import. Later calls reuse the same
 * promise, so all consumers share one loader path.
 */
export const loadEnteWasm = (): Promise<EnteWasmModule> =>
    (wasmPromise ??= import("ente-wasm").catch((error: unknown) => {
        wasmPromise = undefined;
        throw error;
    }));

/**
 * Load `ente-wasm`, initialize the crypto backend, and return the ready
 * module.
 *
 * The first call runs `crypto_init()`. Later calls reuse the same promise.
 */
export const loadCryptoReadyEnteWasm = (): Promise<EnteWasmModule> =>
    (cryptoReadyPromise ??= loadEnteWasm()
        .then((wasm) => {
            wasm.crypto_init();
            return wasm;
        })
        .catch((error: unknown) => {
            cryptoReadyPromise = undefined;
            throw error;
        }));

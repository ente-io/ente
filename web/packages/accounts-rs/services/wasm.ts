type EnteWasmModule = typeof import("ente-wasm");

let wasmPromise: Promise<EnteWasmModule> | undefined;
let initDone = false;

export const enteWasm = async (): Promise<EnteWasmModule> => {
    if (!wasmPromise) {
        const load = import("ente-wasm");
        wasmPromise = load.catch((error: unknown) => {
            if (wasmPromise === load) {
                wasmPromise = undefined;
            }
            throw error;
        });
    }
    return wasmPromise;
};

export const ensureCryptoInit = async () => {
    if (initDone) return;
    const wasm = await enteWasm();
    wasm.crypto_init();
    initDone = true;
};

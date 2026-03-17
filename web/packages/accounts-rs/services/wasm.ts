type EnteWasmModule = typeof import("ente-wasm");

let wasmPromise: Promise<EnteWasmModule> | undefined;
let initDone = false;

export const enteWasm = async (): Promise<EnteWasmModule> => {
    wasmPromise ??= import("ente-wasm");
    return wasmPromise;
};

export const ensureCryptoInit = async () => {
    if (initDone) return;
    const wasm = await enteWasm();
    wasm.crypto_init();
    initDone = true;
};

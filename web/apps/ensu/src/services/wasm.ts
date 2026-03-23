/**
 * Lazy loader for the `ente-wasm` package or Tauri-native bindings.
 *
 * We keep this behind a dynamic import so that the WASM bundle is only loaded
 * when needed (login/crypto flows), while Tauri uses native Rust bindings.
 */

export type EnteWasmModule = typeof import("ente-wasm");

export interface EncryptedBox {
    encrypted_data: string;
    nonce: string;
}

export interface EncryptedBlob {
    encrypted_data: string;
    decryption_header: string;
}

export interface SrpCredentials {
    kek: string;
    login_key: string;
}

export interface DecryptedSecrets {
    master_key: string;
    secret_key: string;
    token: string;
}

export interface DecryptedKeys {
    master_key: string;
    secret_key: string;
}

export interface SrpSessionAdapter {
    public_a(): Promise<string>;
    compute_m1(srpB64: string): Promise<string>;
    verify_m2(srpM2B64: string): Promise<void>;
}

export interface EnteCryptoAdapter {
    crypto_init(): Promise<void>;
    crypto_generate_key(): Promise<string>;
    crypto_encrypt_box(dataB64: string, keyB64: string): Promise<EncryptedBox>;
    crypto_decrypt_box(
        encryptedDataB64: string,
        nonceB64: string,
        keyB64: string,
    ): Promise<string>;
    crypto_encrypt_blob(
        dataB64: string,
        keyB64: string,
    ): Promise<EncryptedBlob>;
    crypto_decrypt_blob(
        encryptedDataB64: string,
        headerB64: string,
        keyB64: string,
    ): Promise<string>;

    auth_derive_srp_credentials(
        password: string,
        srpAttributes: Record<string, unknown>,
    ): Promise<SrpCredentials>;
    auth_decrypt_secrets(
        kekB64: string,
        keyAttributes: Record<string, unknown>,
        encryptedTokenB64: string,
    ): Promise<DecryptedSecrets>;
    auth_decrypt_keys_only(
        kekB64: string,
        keyAttributes: Record<string, unknown>,
    ): Promise<DecryptedKeys>;

    SrpSession: new (
        srpUserID: string,
        srpSaltB64: string,
        loginKeyB64: string,
    ) => SrpSessionAdapter;
}

const isTauriRuntime = () =>
    typeof window !== "undefined" &&
    ("__TAURI__" in window || "__TAURI_IPC__" in window);

const createWasmAdapter = (wasm: EnteWasmModule): EnteCryptoAdapter => {
    class WasmSrpSession implements SrpSessionAdapter {
        private inner: InstanceType<typeof wasm.SrpSession>;

        constructor(
            srpUserID: string,
            srpSaltB64: string,
            loginKeyB64: string,
        ) {
            this.inner = new wasm.SrpSession(
                srpUserID,
                srpSaltB64,
                loginKeyB64,
            );
        }

        public_a() {
            return Promise.resolve(this.inner.public_a());
        }

        compute_m1(srpB64: string) {
            return Promise.resolve(this.inner.compute_m1(srpB64));
        }

        verify_m2(srpM2B64: string) {
            this.inner.verify_m2(srpM2B64);
            return Promise.resolve();
        }
    }

    return {
        crypto_init: () => {
            wasm.crypto_init();
            return Promise.resolve();
        },
        crypto_generate_key: () => Promise.resolve(wasm.crypto_generate_key()),
        crypto_encrypt_box: (dataB64, keyB64) =>
            Promise.resolve(wasm.crypto_encrypt_box(dataB64, keyB64)),
        crypto_decrypt_box: (encryptedDataB64, nonceB64, keyB64) =>
            Promise.resolve(
                wasm.crypto_decrypt_box(encryptedDataB64, nonceB64, keyB64),
            ),
        crypto_encrypt_blob: (dataB64, keyB64) =>
            Promise.resolve(wasm.crypto_encrypt_blob(dataB64, keyB64)),
        crypto_decrypt_blob: (encryptedDataB64, headerB64, keyB64) =>
            Promise.resolve(
                wasm.crypto_decrypt_blob(encryptedDataB64, headerB64, keyB64),
            ),

        auth_derive_srp_credentials: (password, srpAttributes) =>
            Promise.resolve(
                wasm.auth_derive_srp_credentials(password, srpAttributes),
            ),
        auth_decrypt_secrets: (kekB64, keyAttributes, encryptedTokenB64) =>
            Promise.resolve(
                wasm.auth_decrypt_secrets(
                    kekB64,
                    keyAttributes,
                    encryptedTokenB64,
                ),
            ),
        auth_decrypt_keys_only: (kekB64, keyAttributes) =>
            Promise.resolve(wasm.auth_decrypt_keys_only(kekB64, keyAttributes)),

        SrpSession: WasmSrpSession,
    };
};

const createTauriAdapter = async (): Promise<EnteCryptoAdapter> => {
    const { invoke } = (await import("@tauri-apps/api/tauri")) as {
        invoke: <T>(
            command: string,
            args?: Record<string, unknown>,
        ) => Promise<T>;
    };

    const toNativeError = (code: string, message: string) =>
        Object.assign(new Error(message), { code });

    const invokeOrThrow = async <T>(
        command: string,
        args?: Record<string, unknown>,
    ) => {
        try {
            return await invoke<T>(command, args);
        } catch (error) {
            if (
                typeof error === "object" &&
                error !== null &&
                "code" in error &&
                "message" in error
            ) {
                const code = String(
                    (error as { code?: string }).code ?? "native_error",
                );
                const message = String(
                    (error as { message?: string }).message ?? "Unknown error",
                );

                if (error instanceof Error) {
                    (error as Error & { code?: string }).code = code;
                    throw error;
                }

                throw toNativeError(code, message);
            }

            if (typeof error === "string") {
                try {
                    const parsed = JSON.parse(error) as {
                        code?: string;
                        message?: string;
                    };
                    if (parsed.code && parsed.message) {
                        throw toNativeError(parsed.code, parsed.message);
                    }
                } catch {
                    // ignore JSON parse failures
                }
                throw toNativeError("native_error", error);
            }

            if (error instanceof Error) {
                try {
                    const parsed = JSON.parse(error.message) as {
                        code?: string;
                        message?: string;
                    };
                    if (parsed.code && parsed.message) {
                        throw toNativeError(parsed.code, parsed.message);
                    }
                } catch {
                    // ignore JSON parse failures
                }
                throw toNativeError("native_error", error.message);
            }

            throw toNativeError("native_error", "Unknown error");
        }
    };

    class TauriSrpSession implements SrpSessionAdapter {
        private sessionIdPromise: Promise<string>;

        constructor(
            srpUserID: string,
            srpSaltB64: string,
            loginKeyB64: string,
        ) {
            this.sessionIdPromise = invokeOrThrow<string>("srp_session_new", {
                input: { srpUserId: srpUserID, srpSaltB64, loginKeyB64 },
            });
        }

        async public_a() {
            return invokeOrThrow<string>("srp_session_public_a", {
                input: { sessionId: await this.sessionIdPromise },
            });
        }

        async compute_m1(srpB64: string) {
            return invokeOrThrow<string>("srp_session_compute_m1", {
                input: { sessionId: await this.sessionIdPromise, srpB64 },
            });
        }

        async verify_m2(srpM2B64: string) {
            await invokeOrThrow("srp_session_verify_m2", {
                input: { sessionId: await this.sessionIdPromise, srpM2B64 },
            });
        }
    }

    return {
        crypto_init: async () => {
            await invokeOrThrow("crypto_init");
        },
        crypto_generate_key: () => invokeOrThrow<string>("crypto_generate_key"),
        crypto_encrypt_box: (dataB64, keyB64) =>
            invokeOrThrow<EncryptedBox>("crypto_encrypt_box", {
                input: { dataB64, keyB64 },
            }),
        crypto_decrypt_box: (encryptedDataB64, nonceB64, keyB64) =>
            invokeOrThrow<string>("crypto_decrypt_box", {
                input: { encryptedDataB64, nonceB64, keyB64 },
            }),
        crypto_encrypt_blob: (dataB64, keyB64) =>
            invokeOrThrow<EncryptedBlob>("crypto_encrypt_blob", {
                input: { dataB64, keyB64 },
            }),
        crypto_decrypt_blob: (encryptedDataB64, headerB64, keyB64) =>
            invokeOrThrow<string>("crypto_decrypt_blob", {
                input: { encryptedDataB64, headerB64, keyB64 },
            }),

        auth_derive_srp_credentials: (password, srpAttributes) =>
            invokeOrThrow<SrpCredentials>("auth_derive_srp_credentials", {
                input: { password, srpAttrs: srpAttributes },
            }),
        auth_decrypt_secrets: (kekB64, keyAttributes, encryptedTokenB64) =>
            invokeOrThrow<DecryptedSecrets>("auth_decrypt_secrets", {
                input: { kekB64, keyAttrs: keyAttributes, encryptedTokenB64 },
            }),
        auth_decrypt_keys_only: (kekB64, keyAttributes) =>
            invokeOrThrow<DecryptedKeys>("auth_decrypt_keys_only", {
                input: { kekB64, keyAttrs: keyAttributes },
            }),

        SrpSession: TauriSrpSession,
    };
};

let _wasmPromise: Promise<EnteCryptoAdapter> | undefined;
let _cryptoInitDone = false;

export const enteWasm = async (): Promise<EnteCryptoAdapter> => {
    _wasmPromise ??= (async () => {
        if (isTauriRuntime()) {
            return createTauriAdapter();
        }
        const wasm = await import("ente-wasm");
        return createWasmAdapter(wasm);
    })();

    return _wasmPromise;
};

export const ensureCryptoInit = async () => {
    if (_cryptoInitDone) return;
    const wasm = await enteWasm();
    // No-op for the pure Rust backend, but keeps the API symmetric.
    await wasm.crypto_init();
    _cryptoInitDone = true;
};

import { expect, test } from "vitest";
import {
    auth_generate_interactive_kek,
    auth_generate_sensitive_kek,
    auth_generate_srp_setup,
    auth_recovery_key_from_mnemonic_or_hex,
    auth_recovery_key_to_mnemonic,
    crypto_generate_key,
} from "../pkg/ente_wasm.js";

test("generates an interactive kek bundle", () => {
    const generated = auth_generate_interactive_kek(
        "correct horse battery staple",
    );

    expect(Buffer.from(generated.key, "base64")).toHaveLength(32);
    expect(Buffer.from(generated.salt, "base64")).toHaveLength(16);
    expect(generated.mem_limit).toBe(67_108_864);
    expect(generated.ops_limit).toBe(2);
});

test("generates a sensitive kek bundle", () => {
    const generated = auth_generate_sensitive_kek(
        "correct horse battery staple",
    );

    expect(Buffer.from(generated.key, "base64")).toHaveLength(32);
    expect(Buffer.from(generated.salt, "base64")).toHaveLength(16);
    expect(generated.mem_limit).toBeGreaterThan(0);
    expect(generated.ops_limit).toBeGreaterThan(0);
});

test("generates SRP setup attributes from a kek", () => {
    const kek = crypto_generate_key();
    const generated = auth_generate_srp_setup(kek, "test-user-id");

    expect(Buffer.from(generated.srp_salt, "base64")).toHaveLength(16);
    expect(Buffer.from(generated.login_sub_key, "base64")).toHaveLength(16);
    expect(
        Buffer.from(generated.srp_verifier, "base64").length,
    ).toBeGreaterThan(0);
});

test("round-trips recovery key mnemonic", () => {
    const recoveryKey = crypto_generate_key();
    const mnemonic = auth_recovery_key_to_mnemonic(recoveryKey);
    const decoded = auth_recovery_key_from_mnemonic_or_hex(mnemonic);

    expect(decoded).toBe(recoveryKey);
});

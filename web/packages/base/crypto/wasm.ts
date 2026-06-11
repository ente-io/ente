import * as wasm from "ente-wasm";

function fromB64(b64: string): Uint8Array {
    const binaryString = atob(b64);
    const bytes = new Uint8Array(binaryString.length);

    for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
    }

    return bytes;
}

function toB64(bytes: Uint8Array): string {
    let binaryString = "";

    for (let i = 0; i < bytes.length; i++) {
        binaryString += String.fromCharCode(bytes[i]!);
    }

    return btoa(binaryString);
}

export async function generateKeypairPQ(): Promise<{
    publicKey: string;
    privateKey: string;
}> {
    const keypair = wasm.crypto_generate_keypair_pq();

    return {
        publicKey: keypair.public_key,
        privateKey: keypair.secret_key,
    };
}

export function boxSealPQBytes(
    data: Uint8Array,
    publicKey: string,
): Uint8Array {
    const sealedDataB64 = wasm.crypto_box_seal_pq(toB64(data), publicKey);

    return fromB64(sealedDataB64);
}

export function boxSealOpenPQBytes(
    sealedData: string,
    publicKey: string,
    privateKey: string,
): Uint8Array {
    const dataB64 = wasm.crypto_box_seal_open_pq(
        sealedData,
        publicKey,
        privateKey,
    );

    return fromB64(dataB64);
}

import { DataStream } from '@ente/shared/upload/types';

export interface LocalFileAttributes<
    T extends string | Uint8Array | DataStream
> {
    encryptedData: T;
    decryptionHeader: string;
}

export interface EncryptionResult<T extends string | Uint8Array | DataStream> {
    file: LocalFileAttributes<T>;
    key: string;
}

export interface B64EncryptionResult {
    encryptedData: string;
    key: string;
    nonce: string;
}

import { decryptBoxBytes } from "ente-base/crypto";
import {
    authenticatedPublicAlbumsRequestHeaders,
    ensureOk,
    type PublicAlbumsCredentials,
} from "ente-base/http";
import { apiURL } from "ente-base/origins";
import {
    decryptRemoteFile,
    RemoteEnteFile,
    type EnteFile,
} from "ente-media/file";
import { z } from "zod";

/**
 * Credentials for accessing a public memory share.
 */
export interface PublicMemoryCredentials {
    accessToken: string;
}

/**
 * Request headers for authenticated public memory share requests.
 */
export const authenticatedPublicMemoryRequestHeaders = (
    credentials: PublicMemoryCredentials,
): ReturnType<typeof authenticatedPublicAlbumsRequestHeaders> =>
    authenticatedPublicAlbumsRequestHeaders(
        credentials as PublicAlbumsCredentials,
    );

/**
 * Information about a public memory share fetched from remote.
 */
export interface PublicMemoryShareInfo {
    id: number;
    type: string;
    metadataCipher: string;
    metadataNonce: string;
    encryptedKey: string;
    keyDecryptionNonce: string;
}

const PublicMemoryShareInfoResponse = z.object({
    memoryShare: z.object({
        id: z.number(),
        type: z.string().optional().default("share"),
        metadataCipher: z.string().optional().default(""),
        metadataNonce: z.string().optional().default(""),
        encryptedKey: z.string(),
        keyDecryptionNonce: z.string(),
    }),
});

/**
 * Fetch information about a public memory share from remote.
 *
 * @param accessToken The access token from the memory share URL.
 */
export const getPublicMemoryInfo = async (
    accessToken: string,
): Promise<PublicMemoryShareInfo> => {
    const res = await fetch(await apiURL("/public-memory/info"), {
        headers: authenticatedPublicAlbumsRequestHeaders({ accessToken }),
    });
    ensureOk(res);
    const { memoryShare } = PublicMemoryShareInfoResponse.parse(
        await res.json(),
    );
    return memoryShare;
};

/**
 * A file in a public memory share, with its key re-encrypted to the share key.
 */
const PublicMemoryShareFile = z.object({
    file: RemoteEnteFile,
    encryptedKey: z.string(),
    keyDecryptionNonce: z.string(),
});

const PublicMemoryShareFilesResponse = z.object({
    files: PublicMemoryShareFile.array(),
});

/**
 * Fetch the files in a public memory share, decrypt them using the provided
 * share key, and return them as {@link EnteFile}s.
 *
 * @param accessToken The access token from the memory share URL.
 * @param shareKey The base64 encoded per-share key (from the URL hash).
 */
export const getPublicMemoryFiles = async (
    accessToken: string,
    shareKey: string,
): Promise<EnteFile[]> => {
    const res = await fetch(await apiURL("/public-memory/files"), {
        headers: authenticatedPublicAlbumsRequestHeaders({ accessToken }),
    });
    ensureOk(res);
    const { files } = PublicMemoryShareFilesResponse.parse(await res.json());

    const enteFiles: EnteFile[] = [];
    for (const { file, encryptedKey, keyDecryptionNonce } of files) {
        // The file's key is re-encrypted to the per-share key.
        // Override the file's encryptedKey/nonce with the share-level values
        // so that decryptRemoteFile can decrypt using the shareKey.
        const remoteFile = { ...file, encryptedKey, keyDecryptionNonce };
        const decrypted = await decryptRemoteFile(remoteFile, shareKey);
        enteFiles.push(decrypted);
    }
    return enteFiles;
};

/**
 * Decrypt the memory share's metadata and extract the name.
 *
 * The metadata is a JSON object encrypted with the per-share key.
 * Currently contains: { "name": "..." }
 *
 * @param metadataCipher Base64 encrypted metadata JSON.
 * @param metadataNonce Base64 nonce for decryption.
 * @param shareKey Base64 encoded per-share key.
 * @returns The decrypted name string, or empty string if not present.
 */
export const decryptMemoryShareName = async (
    metadataCipher: string,
    metadataNonce: string,
    shareKey: string,
): Promise<string> => {
    const metadataBytes = await decryptBoxBytes(
        { encryptedData: metadataCipher, nonce: metadataNonce },
        shareKey,
    );
    const metadataJson = new TextDecoder().decode(metadataBytes);
    const metadata = JSON.parse(metadataJson) as { name?: string };
    return metadata.name ?? "";
};

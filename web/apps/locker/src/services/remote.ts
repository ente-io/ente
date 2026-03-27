/**
 * @file Service layer for fetching, decrypting, and caching Locker data.
 *
 * Follows the mobile app's encryption-at-rest pattern: all data stored in
 * the browser's storage (sessionStorage / in-memory) remains encrypted.
 * Decryption happens only in-memory at read time and decrypted values are
 * never persisted.
 *
 * Key hierarchy (mirrors mobile):
 *   masterKey → collectionKey → fileKey → file metadata (pubMagicMetadata)
 */

import { deriveInteractiveKey } from "ente-accounts-rs/services/crypto";
import {
    ensureLocalUser,
    ensureUserKeyPair,
    getPublicKey,
} from "ente-accounts-rs/services/user";
import {
    authenticatedRequestHeaders,
    ensureOk,
    publicRequestHeaders,
    retryEnsuringHTTPOk,
} from "ente-base/http";
import log from "ente-base/log";
import { apiURL, customAPIOrigin } from "ente-base/origins";
import { ensureAuthToken } from "ente-base/token";
import type {
    LockerCollection,
    LockerCollectionParticipant,
    LockerCollectionParticipantRole,
    LockerItem,
    LockerItemType,
} from "types";
import { z } from "zod";
import {
    b64ToBytes,
    boxSeal,
    boxSealOpen,
    createStreamDecryptor,
    createStreamEncryptor,
    decryptBox,
    decryptBoxBytes,
    decryptMetadataJSON,
    encryptBlob,
    encryptBox,
    encryptFileStreamWithKey,
    generateKey,
    md5Base64,
    stringToB64,
} from "./crypto";

// ---------------------------------------------------------------------------
// Zod schemas for API responses
// ---------------------------------------------------------------------------

const RemoteCollectionUser = z.object({
    id: z.number(),
    email: z.string().nullish(),
    role: z.string().nullish(),
});

const RemoteMagicMetadata = z.object({
    version: z.number(),
    count: z.number().optional(),
    data: z.string(),
    header: z.string(),
});

const RemoteCollection = z.object({
    id: z.number(),
    owner: RemoteCollectionUser,
    encryptedKey: z.string(),
    keyDecryptionNonce: z.string().nullish(),
    encryptedName: z.string().nullish(),
    nameDecryptionNonce: z.string().nullish(),
    name: z.string().nullish(),
    type: z.string(),
    sharees: z.array(RemoteCollectionUser).nullish(),
    publicURLs: z.array(z.unknown()).nullish(),
    updationTime: z.number(),
    isDeleted: z.boolean().nullish(),
    magicMetadata: RemoteMagicMetadata.nullish(),
    pubMagicMetadata: RemoteMagicMetadata.nullish(),
    sharedMagicMetadata: RemoteMagicMetadata.nullish(),
});

type RemoteCollection = z.infer<typeof RemoteCollection>;

const CollectionsResponse = z.object({
    collections: z.array(RemoteCollection),
});

const RemoteEncryptedMetadata = z.object({
    encryptedData: z.string(),
    decryptionHeader: z.string(),
});

const RemoteFileObjectAttributes = z.object({ decryptionHeader: z.string() });

const RemoteFile = z.object({
    id: z.number(),
    collectionID: z.number(),
    ownerID: z.number().optional(),
    encryptedKey: z.string(),
    keyDecryptionNonce: z.string(),
    file: RemoteFileObjectAttributes,
    thumbnail: RemoteFileObjectAttributes.optional(),
    metadata: RemoteEncryptedMetadata,
    magicMetadata: z
        .object({
            version: z.number(),
            count: z.number().optional(),
            data: z.string(),
            header: z.string(),
        })
        .nullish(),
    pubMagicMetadata: z
        .object({
            version: z.number(),
            count: z.number().optional(),
            data: z.string(),
            header: z.string(),
        })
        .nullish(),
    updationTime: z.number(),
    isDeleted: z.boolean(),
    info: z.object({ fileSize: z.number().optional() }).nullish(),
});

type RemoteFile = z.infer<typeof RemoteFile>;

const FileDiffResponse = z.object({
    diff: z.array(RemoteFile),
    hasMore: z.boolean(),
});

// ---------------------------------------------------------------------------
// In-memory cache of encrypted collection data (never persisted decrypted)
// ---------------------------------------------------------------------------

/**
 * An encrypted collection record stored in-memory. All sensitive fields remain
 * encrypted exactly as received from remote — we never persist decrypted keys
 * or names. Decryption is done on-the-fly when the UI requests the data.
 */
interface EncryptedCollectionRecord {
    /** Collection ID. */
    id: number;
    /** Owner info (plaintext — structural metadata only). */
    owner: LockerCollectionParticipant;
    /** Owner user ID (plaintext — structural metadata only). */
    ownerID: number;
    /** Participants excluding the owner. */
    sharees: LockerCollectionParticipant[];
    /** Encrypted collection key (base64). */
    encryptedKey: string;
    /** Nonce for key decryption (base64), null for shared collections. */
    keyDecryptionNonce: string | undefined;
    /** Encrypted collection name (base64). */
    encryptedName: string | undefined;
    /** Nonce for name decryption (base64). */
    nameDecryptionNonce: string | undefined;
    /** Unencrypted name (legacy, may be blank). */
    name: string | undefined;
    /** Collection type (structural metadata). */
    type: string;
    /** Whether the collection has sharees. */
    isShared: boolean;
    /** Whether this collection is deleted on remote (key still needed for trash restore). */
    isDeleted: boolean;
    /** Updation time (structural metadata). */
    updationTime: number;
}

/**
 * An encrypted file record stored in-memory. All sensitive payloads remain
 * encrypted until explicitly decrypted for display.
 */
interface EncryptedFileRecord {
    /** File ID (structural metadata). */
    id: number;
    /** Collection this file belongs to (structural metadata). */
    collectionID: number;
    /** Owner of the file, when provided by remote. */
    ownerID?: number;
    /** Encrypted file key (base64). */
    encryptedKey: string;
    /** Nonce for file key decryption (base64). */
    keyDecryptionNonce: string;
    /** Decryption header for the actual file content blob on S3. */
    fileDecryptionHeader: string;
    /** Whether the file has a downloadable backing object. */
    hasObject: boolean;
    /** File size in bytes, when provided by the API. */
    fileSize?: number;
    /** Encrypted file metadata. */
    metadata: { encryptedData: string; decryptionHeader: string };
    /** Encrypted private magic metadata, if present. */
    magicMetadata?: { version: number; data: string; header: string };
    /** Encrypted public magic metadata, if present. */
    pubMagicMetadata?: { version: number; data: string; header: string };
    /** Updation time (structural metadata). */
    updationTime: number;
}

/** In-memory cache: collectionID → EncryptedCollectionRecord */
let encryptedCollections = new Map<number, EncryptedCollectionRecord>();

/** In-memory cache: fileID → (collectionID → EncryptedFileRecord) */
let encryptedFiles = new Map<number, Map<number, EncryptedFileRecord>>();

const setEncryptedFileRecord = (
    target: Map<number, Map<number, EncryptedFileRecord>>,
    record: EncryptedFileRecord,
) => {
    const existing =
        target.get(record.id) ?? new Map<number, EncryptedFileRecord>();
    existing.set(record.collectionID, record);
    target.set(record.id, existing);
};

const getEncryptedFileRecord = (
    fileID: number,
    collectionID?: number,
): EncryptedFileRecord | undefined => {
    const records = encryptedFiles.get(fileID);
    if (!records) {
        return undefined;
    }
    if (collectionID !== undefined) {
        return records.get(collectionID);
    }
    return records.values().next().value;
};

const getAllEncryptedFileRecords = (): EncryptedFileRecord[] =>
    [...encryptedFiles.values()].flatMap((records) => [...records.values()]);

const getCollectionIDsForFile = (fileID: number): number[] => {
    const records = encryptedFiles.get(fileID);
    return records ? [...records.keys()] : [];
};

const describeCryptoError = (e: unknown): string => {
    if (typeof e === "object" && e && "code" in e) {
        const code = typeof e.code === "string" ? e.code : "unknown";
        const message =
            "message" in e && typeof e.message === "string"
                ? e.message
                : "unknown";
        return `code=${code}, msg=${message}`;
    }
    if (e instanceof Error) {
        return e.message;
    }
    return String(e);
};

const RemoteShareesResponse = z.object({
    sharees: z.array(RemoteCollectionUser),
});

const RemoteFileShareLink = z.object({
    linkID: z.union([z.string(), z.number().transform(String)]),
    url: z.string(),
    ownerID: z.number(),
    fileID: z.number(),
    isDisabled: z.boolean().optional(),
    validTill: z.number().nullish(),
    deviceLimit: z.number().nullish(),
    passwordEnabled: z.boolean(),
    nonce: z.string().nullish(),
    memLimit: z.number().nullish(),
    opsLimit: z.number().nullish(),
    enableDownload: z.boolean(),
    createdAt: z.number(),
    encryptedFileKey: z.string().nullish(),
    encryptedFileKeyNonce: z.string().nullish(),
    kdfNonce: z.string().nullish(),
    kdfMemLimit: z.number().nullish(),
    kdfOpsLimit: z.number().nullish(),
    encryptedShareKey: z.string().nullish(),
});

export interface LockerFileShareLink {
    linkID: string;
    url: string;
    fileID?: number;
    validTill?: number | null;
    enableDownload?: boolean;
    passwordEnabled?: boolean;
}

export interface LockerFileShareLinkSummary {
    linkID: string;
    fileID: number;
    validTill?: number | null;
    enableDownload: boolean;
    passwordEnabled: boolean;
}

interface DecryptAllDataResult {
    collections: LockerCollection[];
    failedCollectionIDs: number[];
    totalCollectionCount: number;
}

const utf8Decoder = new TextDecoder();

const toLockerCollectionParticipant = (
    user: z.infer<typeof RemoteCollectionUser>,
): LockerCollectionParticipant => ({
    id: user.id,
    email: user.email ?? undefined,
    role: user.role
        ? (user.role.toUpperCase() as LockerCollectionParticipantRole)
        : undefined,
});

const updateCollectionShareesInCache = (
    collectionID: number,
    sharees: LockerCollectionParticipant[],
) => {
    const record = encryptedCollections.get(collectionID);
    if (!record) {
        return;
    }

    encryptedCollections.set(collectionID, {
        ...record,
        sharees,
        isShared: sharees.length > 0,
    });
};

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Fetch all Locker collections and their info items from remote, decrypt
 * them using the user's master key, and return them ready for display.
 *
 * Encrypted data is cached in-memory (never written to persistent storage
 * in decrypted form). Only structural metadata (IDs, timestamps) is
 * stored unencrypted — matching the mobile app's SQLite pattern.
 */
export const fetchLockerData = async (
    masterKey: string,
): Promise<LockerCollection[]> => {
    const previousCollections = encryptedCollections;
    const previousFiles = encryptedFiles;

    // Step 1: Fetch all encrypted collections from remote
    await fetchEncryptedCollections();

    // Step 2: For each collection, fetch encrypted file diffs
    await fetchAllEncryptedFiles();

    // Step 3: Decrypt everything in-memory and return
    const decrypted = await decryptAllData(masterKey);
    if (
        decrypted.totalCollectionCount > 0 &&
        decrypted.collections.length === 0
    ) {
        encryptedCollections = previousCollections;
        encryptedFiles = previousFiles;
        throw new Error(
            `Failed to decrypt all ${decrypted.totalCollectionCount} locker collections`,
        );
    }

    if (decrypted.failedCollectionIDs.length > 0) {
        log.warn(
            `Decrypted ${decrypted.collections.length}/${decrypted.totalCollectionCount} locker collections`,
        );
    }

    return decrypted.collections;
};

/**
 * Clear all cached data (call on logout).
 */
export const clearLockerCache = () => {
    encryptedCollections = new Map();
    encryptedFiles = new Map();
};

// ---------------------------------------------------------------------------
// Step 1: Fetch encrypted collections
// ---------------------------------------------------------------------------

const fetchEncryptedCollections = async () => {
    const res = await fetch(await apiURL("/collections/v2", { sinceTime: 0 }), {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    const { collections } = CollectionsResponse.parse(await res.json());

    const nextCollections = new Map<number, EncryptedCollectionRecord>();

    for (const c of collections) {
        nextCollections.set(c.id, {
            id: c.id,
            owner: { ...toLockerCollectionParticipant(c.owner), role: "OWNER" },
            ownerID: c.owner.id,
            sharees: (c.sharees ?? []).map(toLockerCollectionParticipant),
            encryptedKey: c.encryptedKey,
            keyDecryptionNonce: c.keyDecryptionNonce ?? undefined,
            encryptedName: c.encryptedName ?? undefined,
            nameDecryptionNonce: c.nameDecryptionNonce ?? undefined,
            name: c.name ?? undefined,
            type: c.type,
            isShared: (c.sharees?.length ?? 0) > 0,
            isDeleted: !!c.isDeleted,
            updationTime: c.updationTime,
        });
    }

    encryptedCollections = nextCollections;
};

// ---------------------------------------------------------------------------
// Step 2: Fetch encrypted files for all collections
// ---------------------------------------------------------------------------

const fetchAllEncryptedFiles = async () => {
    const activeCollections = [...encryptedCollections.values()].filter(
        (collection) => !collection.isDeleted,
    );
    const fileResults = await Promise.all(
        activeCollections.map((c) => fetchEncryptedFilesForCollection(c.id)),
    );

    const nextFiles = new Map<number, Map<number, EncryptedFileRecord>>();
    for (const records of fileResults) {
        for (const record of records) {
            setEncryptedFileRecord(nextFiles, record);
        }
    }

    encryptedFiles = nextFiles;
};

const fetchEncryptedFilesForCollection = async (
    collectionID: number,
): Promise<EncryptedFileRecord[]> => {
    let sinceTime = 0;
    let hasMore = true;
    const records: EncryptedFileRecord[] = [];

    while (hasMore) {
        const res = await fetch(
            await apiURL("/collections/v2/diff", { collectionID, sinceTime }),
            { headers: await authenticatedRequestHeaders() },
        );
        ensureOk(res);
        const parsed = FileDiffResponse.parse(await res.json());

        for (const f of parsed.diff) {
            sinceTime = Math.max(sinceTime, f.updationTime);

            if (f.isDeleted) {
                continue;
            }

            records.push({
                id: f.id,
                collectionID: f.collectionID,
                ownerID: f.ownerID ?? undefined,
                encryptedKey: f.encryptedKey,
                keyDecryptionNonce: f.keyDecryptionNonce,
                fileDecryptionHeader: f.file.decryptionHeader,
                hasObject: f.file.decryptionHeader.length > 0,
                fileSize: f.info?.fileSize,
                metadata: {
                    encryptedData: f.metadata.encryptedData,
                    decryptionHeader: f.metadata.decryptionHeader,
                },
                magicMetadata: f.magicMetadata
                    ? {
                          version: f.magicMetadata.version,
                          data: f.magicMetadata.data,
                          header: f.magicMetadata.header,
                      }
                    : undefined,
                pubMagicMetadata: f.pubMagicMetadata
                    ? {
                          version: f.pubMagicMetadata.version,
                          data: f.pubMagicMetadata.data,
                          header: f.pubMagicMetadata.header,
                      }
                    : undefined,
                updationTime: f.updationTime,
            });
        }

        hasMore = parsed.hasMore;
    }

    return records;
};

// ---------------------------------------------------------------------------
// Step 3: Decrypt everything in-memory
// ---------------------------------------------------------------------------

/**
 * Decrypt a collection key. Owned collections use masterKey + nonce (box),
 * shared collections use the user's keypair (sealed box).
 */
const decryptCollectionKey = async (
    record: EncryptedCollectionRecord,
    masterKey: string,
): Promise<string> => {
    const currentUserID = ensureLocalUser().id;
    if (record.ownerID === currentUserID) {
        // Owned collection: key encrypted with masterKey + nonce
        return decryptBox(
            {
                encryptedData: record.encryptedKey,
                nonce: record.keyDecryptionNonce!,
            },
            masterKey,
        );
    } else {
        // Shared collection: key encrypted with user's public key (sealed)
        return boxSealOpen(record.encryptedKey, await ensureUserKeyPair());
    }
};

/**
 * Decrypt a collection name from its encrypted fields.
 */
const decryptCollectionName = async (
    record: EncryptedCollectionRecord,
    collectionKey: string,
): Promise<string> => {
    // Legacy collections might have unencrypted name
    if (record.name) return record.name;

    if (record.encryptedName && record.nameDecryptionNonce) {
        try {
            const nameBytes = await decryptBoxBytes(
                {
                    encryptedData: record.encryptedName,
                    nonce: record.nameDecryptionNonce,
                },
                collectionKey,
            );
            return new TextDecoder().decode(nameBytes);
        } catch (e) {
            log.error(`Failed to decrypt collection name for ${record.id}`, e);
        }
    }
    return "Untitled";
};

const decodeUTF8B64 = (b64: string) => utf8Decoder.decode(b64ToBytes(b64));

const decryptFileKeyForRecord = async (
    record: EncryptedFileRecord,
    masterKey: string,
): Promise<string> => {
    const collectionRecord = encryptedCollections.get(record.collectionID);
    if (!collectionRecord) {
        throw new Error(`Collection ${record.collectionID} not found in cache`);
    }

    const collectionKey = await decryptCollectionKey(
        collectionRecord,
        masterKey,
    );
    return decryptBox(
        {
            encryptedData: record.encryptedKey,
            nonce: record.keyDecryptionNonce,
        },
        collectionKey,
    );
};

const generateBase62Secret = (length: number) => {
    const charset =
        "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    const randomValues = crypto.getRandomValues(new Uint8Array(length));
    return Array.from(
        randomValues,
        (value) => charset[value % charset.length]!,
    ).join("");
};

const prepareFileLinkSecretPayload = async (fileKey: string) => {
    const secret = generateBase62Secret(12);
    const secretB64 = stringToB64(secret);
    const derivedKey = await deriveInteractiveKey(secret);
    const encryptedFileKey = await encryptBox(fileKey, derivedKey.key);
    const keyPair = await ensureUserKeyPair();
    const encryptedShareKey = await boxSeal(
        stringToB64(secretB64),
        keyPair.publicKey,
    );

    return {
        secret,
        metadata: {
            encryptedFileKey: encryptedFileKey.encryptedData,
            encryptedFileKeyNonce: encryptedFileKey.nonce,
            kdfNonce: derivedKey.salt,
            kdfMemLimit: derivedKey.memLimit,
            kdfOpsLimit: derivedKey.opsLimit,
            encryptedShareKey,
        },
    };
};

const resolveFileLinkSecret = async (
    link: z.infer<typeof RemoteFileShareLink>,
    generatedSecret: string,
) => {
    if (!link.encryptedShareKey) {
        return generatedSecret;
    }

    const decryptedSecretB64 = decodeUTF8B64(
        await boxSealOpen(link.encryptedShareKey, await ensureUserKeyPair()),
    );
    return decodeUTF8B64(decryptedSecretB64);
};

const infoItemTitle = (
    infoType: LockerItemType,
    infoData: Record<string, unknown>,
) => {
    const namedTitle =
        (infoData.title as string | undefined)?.trim() ||
        (infoData.name as string | undefined)?.trim();
    if (namedTitle) {
        return namedTitle;
    }

    switch (infoType) {
        case "note":
            return "Note";
        case "physicalRecord":
            return "Location";
        case "accountCredential":
            return "Secret";
        case "emergencyContact":
            return "Emergency Contact";
        case "file":
            return "File";
    }
};

const toEpochMicroseconds = (timestamp: unknown) => {
    if (typeof timestamp !== "number") {
        return undefined;
    }

    // Locker mobile stores metadata timestamps in epoch milliseconds while
    // server structural timestamps use epoch microseconds.
    return timestamp < 100_000_000_000_000 ? timestamp * 1000 : timestamp;
};

/**
 * Decrypt a file and return a LockerItem.
 *
 * If the file has pubMagicMetadata.info with a recognised type, we return a
 * structured info item. Otherwise we return a generic "file" item with the
 * display name extracted from basic metadata.
 */
const decryptFileToLockerItem = async (
    record: EncryptedFileRecord,
    collectionKey: string,
    collectionOwnerID: number,
): Promise<LockerItem | undefined> => {
    try {
        // Decrypt file key using collection key
        const fileKey = await decryptBox(
            {
                encryptedData: record.encryptedKey,
                nonce: record.keyDecryptionNonce,
            },
            collectionKey,
        );

        // Decrypt basic metadata (title / filename lives here)
        const metadata = (await decryptMetadataJSON(
            record.metadata,
            fileKey,
        )) as Record<string, unknown> | undefined;

        // Try to decrypt pubMagicMetadata for info items
        let pubMM: Record<string, unknown> | undefined;
        if (record.pubMagicMetadata) {
            try {
                pubMM = (await decryptMetadataJSON(
                    {
                        encryptedData: record.pubMagicMetadata.data,
                        decryptionHeader: record.pubMagicMetadata.header,
                    },
                    fileKey,
                )) as Record<string, unknown> | undefined;
            } catch {
                // pubMM decryption may fail for some files — that's fine
            }
        }

        // Check for structured info item
        const info = pubMM?.info as
            | { type?: string; data?: Record<string, unknown> }
            | undefined;

        const validInfoTypes = new Set<string>([
            "note",
            "accountCredential",
            "physicalRecord",
            "emergencyContact",
        ]);

        if (info?.type && info.data && validInfoTypes.has(info.type)) {
            return {
                id: record.id,
                type: info.type as LockerItemType,
                data: info.data as unknown as LockerItem["data"],
                collectionID: record.collectionID,
                collectionIDs: [record.collectionID],
                ownerID: record.ownerID ?? collectionOwnerID,
                createdAt: toEpochMicroseconds(metadata?.creationTime),
                updatedAt: record.updationTime,
            };
        }

        // Fall back to generic file item
        const editedName =
            typeof pubMM?.editedName === "string"
                ? pubMM.editedName
                : undefined;
        const metadataTitle =
            typeof metadata?.title === "string" ? metadata.title : undefined;
        const displayName = editedName ?? metadataTitle ?? "File";

        return {
            id: record.id,
            type: "file",
            data: {
                name: displayName,
                fileSize: record.fileSize,
                hasObject: record.hasObject,
            },
            collectionID: record.collectionID,
            collectionIDs: [record.collectionID],
            ownerID: record.ownerID ?? collectionOwnerID,
            createdAt: toEpochMicroseconds(metadata?.creationTime),
            updatedAt: record.updationTime,
        };
    } catch (e: unknown) {
        const detail = describeCryptoError(e);
        log.error(`Failed to decrypt file ${record.id}: ${detail}`);
        return undefined;
    }
};

/**
 * Decrypt all cached encrypted data and assemble into LockerCollections.
 * This is the only place where decryption happens — results are never
 * persisted back to storage.
 */
const decryptAllData = async (
    masterKey: string,
): Promise<DecryptAllDataResult> => {
    const activeCollectionRecords = [...encryptedCollections.values()].filter(
        (collection) => !collection.isDeleted,
    );
    const result: LockerCollection[] = [];
    const failedCollectionIDs: number[] = [];
    const totalCollectionCount = activeCollectionRecords.length;

    // Group files by collection
    const filesByCollection = new Map<number, EncryptedFileRecord[]>();
    for (const file of getAllEncryptedFileRecords()) {
        const existing = filesByCollection.get(file.collectionID) ?? [];
        existing.push(file);
        filesByCollection.set(file.collectionID, existing);
    }

    // Decrypt each collection and its files
    for (const collectionRecord of activeCollectionRecords) {
        try {
            const collectionKey = await decryptCollectionKey(
                collectionRecord,
                masterKey,
            );
            const name = await decryptCollectionName(
                collectionRecord,
                collectionKey,
            );

            const files = filesByCollection.get(collectionRecord.id) ?? [];
            const itemPromises = files.map((f) =>
                decryptFileToLockerItem(
                    f,
                    collectionKey,
                    collectionRecord.ownerID,
                ),
            );
            const decryptedItems = await Promise.all(itemPromises);
            const items = decryptedItems.filter(
                (item): item is LockerItem => item !== undefined,
            );

            result.push({
                id: collectionRecord.id,
                name,
                owner: collectionRecord.owner,
                sharees: collectionRecord.sharees,
                items,
                type: collectionRecord.type,
                isShared: collectionRecord.isShared,
            });
        } catch (e: unknown) {
            failedCollectionIDs.push(collectionRecord.id);
            log.error(
                `Failed to decrypt collection ${collectionRecord.id}: ${describeCryptoError(e)}`,
            );
        }
    }

    if (failedCollectionIDs.length > 0) {
        const failedCollectionIDSet = new Set(failedCollectionIDs);
        encryptedCollections = new Map(
            [...encryptedCollections.entries()].filter(
                ([collectionID]) => !failedCollectionIDSet.has(collectionID),
            ),
        );
        encryptedFiles = new Map(
            [...encryptedFiles.entries()]
                .map(
                    ([fileID, records]): [
                        number,
                        Map<number, EncryptedFileRecord>,
                    ] => [
                        fileID,
                        new Map(
                            [...records.entries()].filter(
                                ([collectionID]) =>
                                    !failedCollectionIDSet.has(collectionID),
                            ),
                        ),
                    ],
                )
                .filter(([, records]) => records.size > 0),
        );
    }

    // Sort collections alphabetically by name
    result.sort((a, b) => a.name.localeCompare(b.name));

    return { collections: result, failedCollectionIDs, totalCollectionCount };
};

// ---------------------------------------------------------------------------
// Trash support
// ---------------------------------------------------------------------------

const RemoteTrashItem = z.object({
    file: RemoteFile,
    isDeleted: z.boolean(),
    isRestored: z.boolean(),
    updatedAt: z.number(),
    deleteBy: z.number(),
});

const TrashDiffResponse = z.object({
    diff: z.array(RemoteTrashItem),
    hasMore: z.boolean(),
});

interface LockerTrashData {
    items: LockerItem[];
    lastUpdatedAt: number;
}

/**
 * Fetch trashed Locker items from remote, decrypt them, and return them
 * ready for display. Must be called after {@link fetchLockerData} so that
 * the encrypted collection cache is populated (needed for key decryption).
 */
export const fetchLockerTrash = async (
    masterKey: string,
): Promise<LockerTrashData> => {
    const trashItems: LockerItem[] = [];
    let sinceTime = 0;
    let hasMore = true;

    while (hasMore) {
        const res = await fetch(await apiURL("/trash/v2/diff", { sinceTime }), {
            headers: await authenticatedRequestHeaders(),
        });
        ensureOk(res);
        const parsed = TrashDiffResponse.parse(await res.json());

        for (const entry of parsed.diff) {
            sinceTime = Math.max(sinceTime, entry.updatedAt);

            // Skip items that have been permanently deleted or restored
            if (entry.isDeleted || entry.isRestored) continue;

            const f = entry.file;

            // We need the collection key to decrypt the file. The collection
            // may have been deleted by the time trash is fetched, but its
            // record should still be in our cache from the collections fetch.
            const collectionRecord = encryptedCollections.get(f.collectionID);
            if (!collectionRecord) {
                log.warn(
                    `Skipping trash file ${f.id}: collection ${f.collectionID} not in cache`,
                );
                continue;
            }

            // Build an EncryptedFileRecord from the trash entry's file
            const fileRecord: EncryptedFileRecord = {
                id: f.id,
                collectionID: f.collectionID,
                ownerID: f.ownerID ?? undefined,
                encryptedKey: f.encryptedKey,
                keyDecryptionNonce: f.keyDecryptionNonce,
                fileDecryptionHeader: f.file.decryptionHeader,
                hasObject: f.file.decryptionHeader.length > 0,
                fileSize: f.info?.fileSize,
                metadata: {
                    encryptedData: f.metadata.encryptedData,
                    decryptionHeader: f.metadata.decryptionHeader,
                },
                magicMetadata: f.magicMetadata
                    ? {
                          version: f.magicMetadata.version,
                          data: f.magicMetadata.data,
                          header: f.magicMetadata.header,
                      }
                    : undefined,
                pubMagicMetadata: f.pubMagicMetadata
                    ? {
                          version: f.pubMagicMetadata.version,
                          data: f.pubMagicMetadata.data,
                          header: f.pubMagicMetadata.header,
                      }
                    : undefined,
                updationTime: f.updationTime,
            };
            // Keep trash records in cache so restore can locate key material.
            setEncryptedFileRecord(encryptedFiles, fileRecord);

            try {
                const collectionKey = await decryptCollectionKey(
                    collectionRecord,
                    masterKey,
                );
                const item = await decryptFileToLockerItem(
                    fileRecord,
                    collectionKey,
                    collectionRecord.ownerID,
                );
                if (item) {
                    trashItems.push({ ...item, deleteBy: entry.deleteBy });
                }
            } catch (e) {
                log.error(`Failed to decrypt trash file ${f.id}`, e);
            }
        }

        hasMore = parsed.hasMore;
    }

    // Sort by most recently trashed first
    trashItems.sort((a, b) => (b.updatedAt ?? 0) - (a.updatedAt ?? 0));
    return { items: trashItems, lastUpdatedAt: sinceTime };
};

// ---------------------------------------------------------------------------
// File download (read-only — decrypt and save to user's device)
// ---------------------------------------------------------------------------

/**
 * Download a Locker file: fetch the encrypted blob from remote, decrypt it
 * in-memory using the file's key, and trigger a browser download.
 *
 * @param fileID The file's unique ID.
 * @param fileName The display name for the downloaded file.
 * @param masterKey The user's decrypted master key.
 */
export const downloadLockerFile = async (
    fileID: number,
    fileName: string,
    masterKey: string,
    onProgress?: (progress: { loaded: number; total?: number }) => void,
): Promise<void> => {
    const fileRecord = getEncryptedFileRecord(fileID);
    if (!fileRecord) throw new Error(`File ${fileID} not found in cache`);

    const collectionRecord = encryptedCollections.get(fileRecord.collectionID);
    if (!collectionRecord)
        throw new Error(
            `Collection ${fileRecord.collectionID} not found in cache`,
        );

    // Decrypt collection key → file key
    const collectionKey = await decryptCollectionKey(
        collectionRecord,
        masterKey,
    );
    const fileKey = await decryptBox(
        {
            encryptedData: fileRecord.encryptedKey,
            nonce: fileRecord.keyDecryptionNonce,
        },
        collectionKey,
    );

    // Fetch encrypted file blob from remote
    const customOrigin = await customAPIOrigin();
    let res: Response;
    if (customOrigin) {
        const token = await ensureAuthToken();
        const url = await apiURL(`/files/download/${fileID}`, { token });
        res = await fetch(url);
    } else {
        res = await fetch(`https://files.ente.io/?fileID=${fileID}`, {
            headers: await authenticatedRequestHeaders(),
        });
    }
    ensureOk(res);
    const body = res.body;
    if (!body) {
        throw new Error("Download response body is empty");
    }

    const reader = body.getReader();
    const contentLength =
        parseInt(res.headers.get("Content-Length") ?? "", 10) || 0;
    let downloadedBytes = 0;

    onProgress?.({
        loaded: 0,
        total: contentLength > 0 ? contentLength : undefined,
    });

    const streamDecryptor = await createStreamDecryptor(
        fileRecord.fileDecryptionHeader,
        fileKey,
    );

    let leftoverBytes = new Uint8Array();

    const decryptedStream = new ReadableStream<Uint8Array>({
        pull: async (controller) => {
            let didEnqueue = false;
            try {
                do {
                    const { done, value } = await reader.read();

                    let data: Uint8Array;
                    if (done) {
                        data = leftoverBytes;
                    } else {
                        downloadedBytes += value.length;
                        onProgress?.({
                            loaded: downloadedBytes,
                            total:
                                contentLength > 0 ? contentLength : undefined,
                        });
                        data = new Uint8Array(
                            leftoverBytes.length + value.length,
                        );
                        data.set(leftoverBytes, 0);
                        data.set(value, leftoverBytes.length);
                    }

                    while (data.length >= streamDecryptor.decryptionChunkSize) {
                        const decryptedChunk =
                            await streamDecryptor.decryptChunk(
                                data.slice(
                                    0,
                                    streamDecryptor.decryptionChunkSize,
                                ),
                            );
                        controller.enqueue(decryptedChunk);
                        didEnqueue = true;
                        data = data.slice(streamDecryptor.decryptionChunkSize);
                    }

                    if (done) {
                        if (data.length) {
                            const decryptedChunk =
                                await streamDecryptor.decryptChunk(data);
                            controller.enqueue(decryptedChunk);
                        }
                        if (!streamDecryptor.isFinalized()) {
                            throw new Error(
                                "Download stream truncated before final chunk",
                            );
                        }
                        onProgress?.({
                            loaded:
                                contentLength > 0
                                    ? contentLength
                                    : downloadedBytes,
                            total:
                                contentLength > 0 ? contentLength : undefined,
                        });
                        streamDecryptor.free();
                        controller.close();
                        didEnqueue = true;
                    } else {
                        leftoverBytes = new Uint8Array(data);
                    }
                } while (!didEnqueue);
            } catch (error) {
                streamDecryptor.free();
                controller.error(error);
            }
        },
        cancel: () => {
            streamDecryptor.free();
            void reader.cancel();
        },
    });

    const decryptedData = await new Response(decryptedStream).blob();

    // Trigger browser download
    const url = URL.createObjectURL(decryptedData);
    const a = document.createElement("a");
    a.style.display = "none";
    a.href = url;
    a.download = fileName;
    document.body.appendChild(a);
    a.click();
    setTimeout(() => URL.revokeObjectURL(url), 0);
    a.remove();
};

/**
 * Fetch Locker file share links for the current user.
 *
 * The backend endpoint is user-wide rather than per-file, so the client
 * filters to the latest non-disabled record per file.
 */
export const fetchLockerFileShareLinks = (): Promise<
    Map<number, LockerFileShareLinkSummary>
> => {
    // TODO: Re-enable this after GET /files/share-url is deployed on the API.
    return Promise.resolve(new Map<number, LockerFileShareLinkSummary>());
};

/**
 * Get or create a public share link for a Locker file.
 */
export const getOrCreateLockerFileShareLink = async (
    fileID: number,
    masterKey: string,
): Promise<LockerFileShareLink> => {
    const fileRecord = getEncryptedFileRecord(fileID);
    if (!fileRecord) {
        throw new Error(`File ${fileID} not found in cache`);
    }

    const fileKey = await decryptFileKeyForRecord(fileRecord, masterKey);
    const payload = await prepareFileLinkSecretPayload(fileKey);

    const res = await fetch(await apiURL("/files/share-url"), {
        method: "POST",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ fileID, app: "locker", ...payload.metadata }),
    });
    ensureOk(res);

    const link = RemoteFileShareLink.parse(await res.json());
    const secret = await resolveFileLinkSecret(link, payload.secret);

    return {
        linkID: link.linkID,
        url: `${link.url}#${secret}`,
        fileID: link.fileID,
        validTill: link.validTill,
        enableDownload: link.enableDownload,
        passwordEnabled: link.passwordEnabled,
    };
};

/**
 * Delete a public share link for a Locker file.
 */
export const deleteLockerFileShareLink = async (
    fileID: number,
    linkID?: string,
): Promise<void> => {
    const candidateIDs = [linkID, String(fileID)].filter(
        (candidate, index, values): candidate is string =>
            !!candidate && values.indexOf(candidate) === index,
    );

    let lastError: Error | undefined;
    for (const candidateID of candidateIDs) {
        const res = await fetch(
            await apiURL(`/files/share-url/${candidateID}`),
            { method: "DELETE", headers: await authenticatedRequestHeaders() },
        );
        if (res.ok) {
            return;
        }
        lastError = new Error(
            `Failed to delete link ${candidateID}: ${res.status} ${res.statusText}`,
        );
        if (candidateID !== String(fileID)) {
            continue;
        }
    }

    throw lastError ?? new Error("Failed to delete file share link");
};

// ---------------------------------------------------------------------------
// Create info item (note, credential, physical record, emergency contact)
// ---------------------------------------------------------------------------

/**
 * Create a new info item in the specified collection.
 *
 * This uses the `/files/meta` endpoint for metadata-only files (no file
 * content blob, no thumbnail). The info data is stored in pubMagicMetadata.
 *
 * @param collectionID The collection to create the item in.
 * @param infoType The item type (e.g. "note", "accountCredential").
 * @param infoData The item's structured data (matching the type's schema).
 * @param masterKey The user's master key.
 */
export const createInfoItem = async (
    collectionIDs: number[],
    infoType: LockerItemType,
    infoData: Record<string, unknown>,
    masterKey: string,
): Promise<void> => {
    const [collectionID, ...additionalCollectionIDs] = collectionIDs;
    if (collectionID === undefined) {
        throw new Error("No collection selected");
    }
    const collectionRecord = encryptedCollections.get(collectionID);
    if (!collectionRecord)
        throw new Error(`Collection ${collectionID} not in cache`);

    // Decrypt collection key
    const collectionKey = await decryptCollectionKey(
        collectionRecord,
        masterKey,
    );

    // Generate a random file key
    const fileKey = await generateKey();

    // Encrypt file key with collection key (SecretBox)
    const encryptedFileKey = await encryptBox(fileKey, collectionKey);

    // Build metadata (basic file metadata — title, creation time, file type)
    const now = Date.now(); // Epoch milliseconds, matching mobile Locker
    const title = infoItemTitle(infoType, infoData);
    const metadata = {
        title,
        creationTime: now,
        modificationTime: now,
        fileType: 4, // FileType.info
    };
    const metadataJSON = JSON.stringify(metadata);
    const encryptedMetadata = await encryptBlob(
        stringToB64(metadataJSON),
        fileKey,
    );

    // Build pubMagicMetadata with info field
    const pubMagicMetadata = {
        info: { type: infoType, data: infoData },
        noThumb: true,
    };
    const pubMMJSON = JSON.stringify(pubMagicMetadata);
    const encryptedPubMM = await encryptBlob(stringToB64(pubMMJSON), fileKey);

    // POST /files/meta
    const res = await fetch(await apiURL("/files/meta"), {
        method: "POST",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            collectionID,
            encryptedKey: encryptedFileKey.encryptedData,
            keyDecryptionNonce: encryptedFileKey.nonce,
            metadata: {
                encryptedData: encryptedMetadata.encryptedData,
                decryptionHeader: encryptedMetadata.decryptionHeader,
            },
            pubMagicMetadata: {
                version: 1,
                count: Object.keys(pubMagicMetadata).length,
                data: encryptedPubMM.encryptedData,
                header: encryptedPubMM.decryptionHeader,
            },
        }),
    });
    ensureOk(res);

    const created = (await res.json()) as { id: number };
    if (additionalCollectionIDs.length > 0) {
        await addFileToCollections(
            created.id,
            fileKey,
            additionalCollectionIDs,
            masterKey,
        );
    }
};

// ---------------------------------------------------------------------------
// Update info item (edit existing item's pubMagicMetadata)
// ---------------------------------------------------------------------------

/**
 * Update an existing info item's data by replacing its pubMagicMetadata.
 *
 * @param fileID The file/item ID to update.
 * @param infoType The item type.
 * @param infoData The new structured data.
 * @param masterKey The user's master key.
 */
export const updateInfoItem = async (
    fileID: number,
    infoType: LockerItemType,
    infoData: Record<string, unknown>,
    masterKey: string,
): Promise<void> => {
    const fileRecord = getEncryptedFileRecord(fileID);
    if (!fileRecord) throw new Error(`File ${fileID} not in cache`);

    const collectionRecord = encryptedCollections.get(fileRecord.collectionID);
    if (!collectionRecord)
        throw new Error(`Collection ${fileRecord.collectionID} not in cache`);

    // Decrypt collection key → file key
    const collectionKey = await decryptCollectionKey(
        collectionRecord,
        masterKey,
    );
    const fileKey = await decryptBox(
        {
            encryptedData: fileRecord.encryptedKey,
            nonce: fileRecord.keyDecryptionNonce,
        },
        collectionKey,
    );

    const existingPubMagicMetadata = fileRecord.pubMagicMetadata
        ? ((await decryptMetadataJSON(
              {
                  encryptedData: fileRecord.pubMagicMetadata.data,
                  decryptionHeader: fileRecord.pubMagicMetadata.header,
              },
              fileKey,
          )) as Record<string, unknown>)
        : {};

    // Build updated pubMagicMetadata by merging into the existing public
    // metadata, mirroring mobile's MetadataUpdaterService behavior.
    const title = infoItemTitle(infoType, infoData);
    const pubMagicMetadata = {
        ...existingPubMagicMetadata,
        info: { type: infoType, data: infoData },
        noThumb: true,
        editedName: title,
        editedTime: Date.now(),
    };
    const pubMMJSON = JSON.stringify(pubMagicMetadata);
    const encryptedPubMM = await encryptBlob(stringToB64(pubMMJSON), fileKey);

    const version = fileRecord.pubMagicMetadata?.version ?? 1;

    // PUT /files/public-magic-metadata
    const res = await fetch(await apiURL("/files/public-magic-metadata"), {
        method: "PUT",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            metadataList: [
                {
                    id: fileID,
                    magicMetadata: {
                        version,
                        count: Object.keys(pubMagicMetadata).length,
                        data: encryptedPubMM.encryptedData,
                        header: encryptedPubMM.decryptionHeader,
                    },
                },
            ],
        }),
    });
    ensureOk(res);

    const records = encryptedFiles.get(fileID);
    if (records) {
        encryptedFiles.set(
            fileID,
            new Map(
                [...records.entries()].map(([recordCollectionID, record]) => [
                    recordCollectionID,
                    {
                        ...record,
                        pubMagicMetadata: {
                            version: version + 1,
                            data: encryptedPubMM.encryptedData,
                            header: encryptedPubMM.decryptionHeader,
                        },
                    },
                ]),
            ),
        );
    }
};

export const updateFileItem = async (
    fileID: number,
    title: string,
    masterKey: string,
): Promise<void> => {
    const fileRecord = getEncryptedFileRecord(fileID);
    if (!fileRecord) throw new Error(`File ${fileID} not in cache`);

    const collectionRecord = encryptedCollections.get(fileRecord.collectionID);
    if (!collectionRecord)
        throw new Error(`Collection ${fileRecord.collectionID} not in cache`);

    const collectionKey = await decryptCollectionKey(
        collectionRecord,
        masterKey,
    );
    const fileKey = await decryptBox(
        {
            encryptedData: fileRecord.encryptedKey,
            nonce: fileRecord.keyDecryptionNonce,
        },
        collectionKey,
    );

    const existingPubMagicMetadata = fileRecord.pubMagicMetadata
        ? ((await decryptMetadataJSON(
              {
                  encryptedData: fileRecord.pubMagicMetadata.data,
                  decryptionHeader: fileRecord.pubMagicMetadata.header,
              },
              fileKey,
          )) as Record<string, unknown>)
        : {};

    const pubMagicMetadata = {
        ...existingPubMagicMetadata,
        noThumb: true,
        editedName: title.trim(),
        editedTime: Date.now(),
    };
    const pubMMJSON = JSON.stringify(pubMagicMetadata);
    const encryptedPubMM = await encryptBlob(stringToB64(pubMMJSON), fileKey);
    const version = fileRecord.pubMagicMetadata?.version ?? 1;

    const res = await fetch(await apiURL("/files/public-magic-metadata"), {
        method: "PUT",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            metadataList: [
                {
                    id: fileID,
                    magicMetadata: {
                        version,
                        count: Object.keys(pubMagicMetadata).length,
                        data: encryptedPubMM.encryptedData,
                        header: encryptedPubMM.decryptionHeader,
                    },
                },
            ],
        }),
    });
    ensureOk(res);

    const records = encryptedFiles.get(fileID);
    if (records) {
        encryptedFiles.set(
            fileID,
            new Map(
                [...records.entries()].map(([recordCollectionID, record]) => [
                    recordCollectionID,
                    {
                        ...record,
                        pubMagicMetadata: {
                            version: version + 1,
                            data: encryptedPubMM.encryptedData,
                            header: encryptedPubMM.decryptionHeader,
                        },
                    },
                ]),
            ),
        );
    }
};

export const updateItemCollections = async (
    fileID: number,
    collectionIDs: number[],
    masterKey: string,
): Promise<void> => {
    const currentCollectionIDs = getCollectionIDsForFile(fileID);
    const nextCollectionIDs = Array.from(
        new Set(
            collectionIDs.length > 0
                ? collectionIDs
                : [(await ensureUncategorizedCollection(masterKey)).id],
        ),
    );
    const currentCollectionIDSet = new Set(currentCollectionIDs);
    const nextCollectionIDSet = new Set(nextCollectionIDs);
    const collectionIDsToAdd = nextCollectionIDs.filter(
        (collectionID) => !currentCollectionIDSet.has(collectionID),
    );
    const collectionIDsToRemove = currentCollectionIDs.filter(
        (collectionID) => !nextCollectionIDSet.has(collectionID),
    );
    const uncategorizedCollection =
        await ensureUncategorizedCollection(masterKey);
    const pendingAddedCollectionIDs = [...collectionIDsToAdd];

    for (const collectionID of collectionIDsToRemove) {
        const targetCollectionID =
            pendingAddedCollectionIDs.shift() ??
            nextCollectionIDs.find(
                (candidateCollectionID) =>
                    candidateCollectionID !== collectionID,
            ) ??
            uncategorizedCollection.id;

        if (targetCollectionID === collectionID) {
            continue;
        }

        const fileKey = await decryptFileKeyForCollection(
            fileID,
            collectionID,
            masterKey,
        );
        const targetCollectionRecord =
            encryptedCollections.get(targetCollectionID);
        if (!targetCollectionRecord) {
            throw new Error(`Collection ${targetCollectionID} not in cache`);
        }
        const targetCollectionKey = await decryptCollectionKey(
            targetCollectionRecord,
            masterKey,
        );
        const encryptedFileKey = await encryptBox(fileKey, targetCollectionKey);

        await moveFilesBetweenCollections(collectionID, targetCollectionID, [
            {
                id: fileID,
                encryptedKey: encryptedFileKey.encryptedData,
                keyDecryptionNonce: encryptedFileKey.nonce,
            },
        ]);
    }

    if (pendingAddedCollectionIDs.length > 0) {
        const sourceCollectionID =
            nextCollectionIDs.find((collectionID) =>
                currentCollectionIDSet.has(collectionID),
            ) ?? currentCollectionIDs[0];
        if (!sourceCollectionID) {
            throw new Error(`File ${fileID} has no source collection`);
        }
        const fileKey = await decryptFileKeyForCollection(
            fileID,
            sourceCollectionID,
            masterKey,
        );
        await addFileToCollections(
            fileID,
            fileKey,
            pendingAddedCollectionIDs,
            masterKey,
        );
    }
};

// ---------------------------------------------------------------------------
// Trash operations
// ---------------------------------------------------------------------------

/**
 * Move files to trash.
 *
 * @param fileIDs The file IDs to trash.
 * @param collectionID The collection the files belong to.
 */
export const trashFiles = async (
    fileIDs: number[],
    collectionID: number,
): Promise<void> => {
    const res = await fetch(await apiURL("/files/trash"), {
        method: "POST",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            items: fileIDs.map((fileID) => ({ fileID, collectionID })),
        }),
    });
    ensureOk(res);
};

/**
 * Permanently delete files from trash.
 *
 * @param fileIDs The file IDs to permanently delete.
 */
export const permanentlyDeleteFromTrash = async (
    fileIDs: number[],
): Promise<void> => {
    const res = await fetch(await apiURL("/trash/delete"), {
        method: "POST",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ fileIDs }),
    });
    ensureOk(res);
};

/**
 * Empty the entire trash.
 */
export const emptyTrash = async (lastUpdatedAt: number): Promise<void> => {
    const res = await fetch(await apiURL("/trash/empty"), {
        method: "POST",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ lastUpdatedAt }),
    });
    ensureOk(res);
};

const addFileToCollections = async (
    fileID: number,
    fileKey: string,
    targetCollectionIDs: number[],
    masterKey: string,
): Promise<void> => {
    for (const targetCollectionID of targetCollectionIDs) {
        const collectionRecord = encryptedCollections.get(targetCollectionID);
        if (!collectionRecord) {
            throw new Error(`Collection ${targetCollectionID} not in cache`);
        }

        const collectionKey = await decryptCollectionKey(
            collectionRecord,
            masterKey,
        );
        const encryptedFileKey = await encryptBox(fileKey, collectionKey);

        const res = await fetch(await apiURL("/collections/add-files"), {
            method: "POST",
            headers: {
                ...(await authenticatedRequestHeaders()),
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                collectionID: targetCollectionID,
                files: [
                    {
                        id: fileID,
                        encryptedKey: encryptedFileKey.encryptedData,
                        keyDecryptionNonce: encryptedFileKey.nonce,
                    },
                ],
            }),
        });
        ensureOk(res);
    }
};

const decryptFileKeyForCollection = async (
    fileID: number,
    collectionID: number,
    masterKey: string,
): Promise<string> => {
    const fileRecord = getEncryptedFileRecord(fileID, collectionID);
    if (!fileRecord) {
        throw new Error(
            `File ${fileID} not in cache for collection ${collectionID}`,
        );
    }

    const collectionRecord = encryptedCollections.get(collectionID);
    if (!collectionRecord) {
        throw new Error(`Collection ${collectionID} not in cache`);
    }

    const collectionKey = await decryptCollectionKey(
        collectionRecord,
        masterKey,
    );
    return await decryptBox(
        {
            encryptedData: fileRecord.encryptedKey,
            nonce: fileRecord.keyDecryptionNonce,
        },
        collectionKey,
    );
};

const removeFilesFromCollection = async (
    collectionID: number,
    fileIDs: number[],
): Promise<void> => {
    if (fileIDs.length === 0) {
        return;
    }

    const res = await fetch(await apiURL("/collections/v3/remove-files"), {
        method: "POST",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ collectionID, fileIDs }),
    });
    ensureOk(res);
};

const moveFilesBetweenCollections = async (
    fromCollectionID: number,
    toCollectionID: number,
    files: { id: number; encryptedKey: string; keyDecryptionNonce: string }[],
): Promise<void> => {
    if (files.length === 0) {
        return;
    }

    const res = await fetch(await apiURL("/collections/move-files"), {
        method: "POST",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ fromCollectionID, toCollectionID, files }),
    });
    ensureOk(res);
};

/**
 * Restore files from trash to a collection.
 *
 * @param items The files to restore with their source collection IDs.
 * @param targetCollectionID The target collection.
 * @param masterKey The user's master key.
 */
export const restoreFromTrash = async (
    items: Pick<LockerItem, "id" | "collectionID">[],
    targetCollectionID: number,
    masterKey: string,
): Promise<void> => {
    const collectionRecord = encryptedCollections.get(targetCollectionID);
    if (!collectionRecord)
        throw new Error(`Collection ${targetCollectionID} not in cache`);

    const collectionKey = await decryptCollectionKey(
        collectionRecord,
        masterKey,
    );

    const buildRestorePayload = async (
        candidateItems: Pick<LockerItem, "id" | "collectionID">[],
    ) => {
        const files: {
            id: number;
            encryptedKey: string;
            keyDecryptionNonce: string;
        }[] = [];
        const skippedFileIDs: number[] = [];

        for (const item of candidateItems) {
            const fileRecord = getEncryptedFileRecord(
                item.id,
                item.collectionID,
            );
            if (!fileRecord) {
                skippedFileIDs.push(item.id);
                continue;
            }

            // Decrypt file key using original collection key
            const origCollectionRecord = encryptedCollections.get(
                fileRecord.collectionID,
            );
            if (!origCollectionRecord) {
                skippedFileIDs.push(item.id);
                continue;
            }

            const origCollectionKey = await decryptCollectionKey(
                origCollectionRecord,
                masterKey,
            );
            const fileKey = await decryptBox(
                {
                    encryptedData: fileRecord.encryptedKey,
                    nonce: fileRecord.keyDecryptionNonce,
                },
                origCollectionKey,
            );

            // Re-encrypt file key with target collection key
            const encryptedFileKey = await encryptBox(fileKey, collectionKey);
            files.push({
                id: item.id,
                encryptedKey: encryptedFileKey.encryptedData,
                keyDecryptionNonce: encryptedFileKey.nonce,
            });
        }

        return { files, skippedFileIDs };
    };

    let { files, skippedFileIDs } = await buildRestorePayload(items);
    if (files.length === 0 && skippedFileIDs.length > 0) {
        // Recover from stale cache by refetching trash metadata once.
        await fetchLockerTrash(masterKey);
        ({ files, skippedFileIDs } = await buildRestorePayload(items));
    }

    if (skippedFileIDs.length > 0) {
        log.warn(
            `Skipping ${skippedFileIDs.length} trash files during restore due to missing cache records`,
            skippedFileIDs,
        );
    }
    if (files.length === 0) {
        throw new Error(
            "Unable to restore files: missing encrypted metadata in local cache. Please refresh and try again.",
        );
    }

    const res = await fetch(await apiURL("/collections/restore-files"), {
        method: "POST",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ collectionID: targetCollectionID, files }),
    });
    ensureOk(res);
};

// ---------------------------------------------------------------------------
// Collection management
// ---------------------------------------------------------------------------

/**
 * Create a new collection.
 *
 * @param name The collection name.
 * @param masterKey The user's master key.
 * @returns The new collection's ID.
 */
export const createCollection = async (
    name: string,
    masterKey: string,
    type = "folder",
): Promise<number> => {
    // Generate collection key
    const collectionKey = await generateKey();

    // Encrypt collection key with master key (SecretBox)
    const encryptedKey = await encryptBox(collectionKey, masterKey);

    // Encrypt collection name with collection key (SecretBox)
    const nameB64 = stringToB64(name);
    const encryptedName = await encryptBox(nameB64, collectionKey);

    const res = await fetch(await apiURL("/collections"), {
        method: "POST",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            encryptedKey: encryptedKey.encryptedData,
            keyDecryptionNonce: encryptedKey.nonce,
            encryptedName: encryptedName.encryptedData,
            nameDecryptionNonce: encryptedName.nonce,
            type,
        }),
    });
    ensureOk(res);
    const data = (await res.json()) as { collection: { id: number } };
    return data.collection.id;
};

const ensureUncategorizedCollection = async (masterKey: string) => {
    let uncategorizedCollection = [...encryptedCollections.values()].find(
        (candidate) => candidate.type === "uncategorized",
    );
    if (uncategorizedCollection) {
        return uncategorizedCollection;
    }

    await createCollection("Uncategorized", masterKey, "uncategorized");
    await fetchLockerData(masterKey);

    uncategorizedCollection = [...encryptedCollections.values()].find(
        (candidate) => candidate.type === "uncategorized",
    );
    if (!uncategorizedCollection) {
        throw new Error("Failed to create Uncategorized collection");
    }

    return uncategorizedCollection;
};

/**
 * Rename a collection.
 *
 * @param collectionID The collection to rename.
 * @param newName The new name.
 * @param masterKey The user's master key.
 */
export const renameCollection = async (
    collectionID: number,
    newName: string,
    masterKey: string,
): Promise<void> => {
    const collectionRecord = encryptedCollections.get(collectionID);
    if (!collectionRecord)
        throw new Error(`Collection ${collectionID} not in cache`);

    const collectionKey = await decryptCollectionKey(
        collectionRecord,
        masterKey,
    );

    // Encrypt new name with collection key
    const nameB64 = stringToB64(newName);
    const encryptedName = await encryptBox(nameB64, collectionKey);

    const res = await fetch(await apiURL("/collections/rename"), {
        method: "POST",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            collectionID,
            encryptedName: encryptedName.encryptedData,
            nameDecryptionNonce: encryptedName.nonce,
        }),
    });
    ensureOk(res);
};

/**
 * Delete a collection (moves to trash).
 *
 * @param collectionID The collection to delete.
 */
export const deleteCollection = async (
    collectionID: number,
    opts?: { keepFiles?: boolean },
): Promise<void> => {
    const keepFiles = opts?.keepFiles ?? false;
    const res = await fetch(
        await apiURL(`/collections/v3/${collectionID}`, {
            collectionID,
            keepFiles,
        }),
        { method: "DELETE", headers: await authenticatedRequestHeaders() },
    );
    ensureOk(res);
};

export const deleteCollectionKeepingFiles = async (
    collection: LockerCollection,
    masterKey: string,
): Promise<void> => {
    const collectionID = collection.id;
    const currentUserID = ensureLocalUser().id;
    let uncategorizedCollection: EncryptedCollectionRecord | undefined;

    const fileIDsToRemove: number[] = [];
    const filesToMoveByTargetCollectionID = new Map<
        number,
        { id: number; encryptedKey: string; keyDecryptionNonce: string }[]
    >();

    for (const item of collection.items) {
        const isCurrentUserOwned =
            (item.ownerID ?? currentUserID) === currentUserID;
        if (!isCurrentUserOwned) {
            fileIDsToRemove.push(item.id);
            continue;
        }

        const otherOwnedCollectionIDs = getCollectionIDsForFile(item.id).filter(
            (itemCollectionID) => {
                if (itemCollectionID === collectionID) {
                    return false;
                }

                const targetCollection =
                    encryptedCollections.get(itemCollectionID);
                return (
                    !!targetCollection &&
                    targetCollection.ownerID === currentUserID &&
                    targetCollection.type !== "uncategorized"
                );
            },
        );

        if (otherOwnedCollectionIDs.length === 0 && !uncategorizedCollection) {
            uncategorizedCollection =
                await ensureUncategorizedCollection(masterKey);
        }

        const targetCollectionID =
            otherOwnedCollectionIDs[0] ?? uncategorizedCollection?.id;
        if (!targetCollectionID) {
            throw new Error("Failed to resolve target collection");
        }
        const fileKey = await decryptFileKeyForCollection(
            item.id,
            collectionID,
            masterKey,
        );
        const targetCollectionRecord =
            encryptedCollections.get(targetCollectionID);
        if (!targetCollectionRecord) {
            throw new Error(`Collection ${targetCollectionID} not in cache`);
        }
        const targetCollectionKey = await decryptCollectionKey(
            targetCollectionRecord,
            masterKey,
        );
        const encryptedFileKey = await encryptBox(fileKey, targetCollectionKey);
        const filesToMove =
            filesToMoveByTargetCollectionID.get(targetCollectionID) ?? [];
        filesToMove.push({
            id: item.id,
            encryptedKey: encryptedFileKey.encryptedData,
            keyDecryptionNonce: encryptedFileKey.nonce,
        });
        filesToMoveByTargetCollectionID.set(targetCollectionID, filesToMove);
    }

    for (const [targetCollectionID, files] of filesToMoveByTargetCollectionID) {
        await moveFilesBetweenCollections(
            collectionID,
            targetCollectionID,
            files,
        );
    }

    await removeFilesFromCollection(collectionID, fileIDsToRemove);
    await deleteCollection(collectionID, { keepFiles: true });
};

/**
 * Fetch the current list of participants for a shared collection.
 */
export const fetchCollectionSharees = async (
    collectionID: number,
): Promise<LockerCollectionParticipant[]> => {
    const res = await fetch(
        await apiURL("/collections/sharees", { collectionID }),
        { headers: await authenticatedRequestHeaders() },
    );
    ensureOk(res);
    const { sharees } = RemoteShareesResponse.parse(await res.json());
    const parsedSharees = sharees.map(toLockerCollectionParticipant);
    updateCollectionShareesInCache(collectionID, parsedSharees);
    return parsedSharees;
};

/**
 * Share a collection with another Ente user as a viewer.
 */
export const shareCollection = async (
    collectionID: number,
    email: string,
    masterKey: string,
): Promise<LockerCollectionParticipant[]> => {
    const collectionRecord = encryptedCollections.get(collectionID);
    if (!collectionRecord)
        throw new Error(`Collection ${collectionID} not in cache`);

    const collectionKey = await decryptCollectionKey(
        collectionRecord,
        masterKey,
    );
    const publicKey = await getPublicKey(email);
    const encryptedKey = await boxSeal(collectionKey, publicKey);

    const res = await fetch(await apiURL("/collections/share"), {
        method: "POST",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            collectionID,
            email,
            role: "VIEWER",
            encryptedKey,
        }),
    });
    ensureOk(res);

    const { sharees } = RemoteShareesResponse.parse(await res.json());
    const parsedSharees = sharees.map(toLockerCollectionParticipant);
    updateCollectionShareesInCache(collectionID, parsedSharees);
    return parsedSharees;
};

/**
 * Remove a participant from a shared collection.
 */
export const unshareCollection = async (
    collectionID: number,
    email: string,
): Promise<LockerCollectionParticipant[]> => {
    const res = await fetch(await apiURL("/collections/unshare"), {
        method: "POST",
        headers: {
            ...(await authenticatedRequestHeaders()),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ collectionID, email }),
    });
    ensureOk(res);

    const { sharees } = RemoteShareesResponse.parse(await res.json());
    const parsedSharees = sharees.map(toLockerCollectionParticipant);
    updateCollectionShareesInCache(collectionID, parsedSharees);
    return parsedSharees;
};

// ---------------------------------------------------------------------------
// File upload
// ---------------------------------------------------------------------------

/**
 * A small black JPEG used as a placeholder thumbnail for non-image files.
 *
 * The server requires every file to have a thumbnail. For Locker files we
 * don't need a real one, so we encrypt this tiny placeholder and set the
 * `noThumb` flag in pubMagicMetadata.
 *
 * Generated via PIL: `Image.new('RGB', (1,1), (0,0,0)).save(buf, 'JPEG')`.
 */
const BLACK_THUMBNAIL_B64 =
    "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////" +
    "2wBDAf//////////////////////////////////////////////////////////////////////////////////////wAARCAABAAEDASIAAhEBAxEB" +
    "/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAk" +
    "M2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKz" +
    "tLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgEC" +
    "BAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpj" +
    "ZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6" +
    "/9oADAMBAAIRAxEAPwCOiiigD//Z";

const STREAM_ENCRYPTION_CHUNK_SIZE = 4 * 1024 * 1024;
const MULTIPART_CHUNKS_PER_PART = 5;

const MultipartUploadURLs = z.object({
    objectKey: z.string(),
    partURLs: z.array(z.string()),
    completeURL: z.string(),
});

interface MultipartCompletedPart {
    partNumber: number;
    eTag: string;
}

export type LockerUploadProgress =
    | { phase: "preparing" }
    | { phase: "uploading"; loaded: number; total: number }
    | { phase: "finalizing" };

/**
 * Request a presigned upload URL from the server.
 *
 * @param contentLength Size of the encrypted data in bytes.
 * @param contentMd5 MD5 hash of the encrypted data as base64.
 * @returns The S3 object key and presigned upload URL.
 */
const fetchUploadURL = async (
    contentLength: number,
    contentMd5: string,
): Promise<{ objectKey: string; url: string }> => {
    const headers = new Headers(await authenticatedRequestHeaders());
    headers.set("Content-Type", "application/json");
    const res = await fetch(
        await apiURL("/files/upload-url", { ts: Date.now() }),
        {
            method: "POST",
            headers,
            body: JSON.stringify({ contentLength, contentMD5: contentMd5 }),
        },
    );
    ensureOk(res);
    return (await res.json()) as { objectKey: string; url: string };
};

const fetchMultipartUploadURLs = async ({
    contentLength,
    partLength,
    partMd5s,
}: {
    contentLength: number;
    partLength: number;
    partMd5s: string[];
}): Promise<z.infer<typeof MultipartUploadURLs>> => {
    const headers = new Headers(await authenticatedRequestHeaders());
    headers.set("Content-Type", "application/json");
    const res = await fetch(
        await apiURL("/files/multipart-upload-url", { ts: Date.now() }),
        {
            method: "POST",
            headers,
            body: JSON.stringify({ contentLength, partLength, partMd5s }),
        },
    );
    ensureOk(res);
    return MultipartUploadURLs.parse(await res.json());
};

/**
 * Upload encrypted data to S3 using a presigned URL.
 *
 * @param url The presigned S3 URL.
 * @param data Encrypted data as bytes.
 * @param contentMd5 MD5 of the data as base64 (for Content-MD5 header).
 */
const putFileToS3 = async (
    url: string,
    data: Uint8Array,
    contentMd5: string,
    onProgress?: (progress: { loaded: number; total?: number }) => void,
): Promise<void> => {
    const res = await new Promise<{
        ok: boolean;
        status: number;
        statusText: string;
    }>((resolve, reject) => {
        const request = new XMLHttpRequest();
        request.open("PUT", url);
        request.setRequestHeader("Content-Type", "application/octet-stream");
        request.setRequestHeader("Content-MD5", contentMd5);
        request.upload.onprogress = (event) => {
            onProgress?.({
                loaded: event.loaded,
                total: event.lengthComputable ? event.total : data.length,
            });
        };
        request.onload = () =>
            resolve({
                ok: request.status >= 200 && request.status < 300,
                status: request.status,
                statusText: request.statusText,
            });
        request.onerror = () => reject(new Error("S3 upload failed"));
        request.send(data);
    });
    if (!res.ok) {
        throw new Error(`S3 upload failed: ${res.status} ${res.statusText}`);
    }
};

const uploadSingleObject = async (
    data: Uint8Array,
    contentMd5: string,
    onProgress?: (progress: { loaded: number; total?: number }) => void,
): Promise<string> => {
    const maxAttempts = 3;

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
            const uploadURL = await fetchUploadURL(data.length, contentMd5);
            await putFileToS3(uploadURL.url, data, contentMd5, onProgress);
            return uploadURL.objectKey;
        } catch (error) {
            if (attempt === maxAttempts) {
                throw error;
            }
        }
    }

    throw new Error("Unreachable upload retry state");
};

const putFilePartToS3 = async (
    url: string,
    data: Uint8Array,
    contentMd5: string,
    onProgress?: (progress: { loaded: number; total?: number }) => void,
): Promise<string> => {
    const maxAttempts = 3;

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
            const eTag = await new Promise<string | null>((resolve, reject) => {
                const request = new XMLHttpRequest();
                request.open("PUT", url);
                for (const [headerName, headerValue] of Object.entries({
                    ...publicRequestHeaders(),
                    "Content-MD5": contentMd5,
                })) {
                    request.setRequestHeader(headerName, headerValue);
                }
                request.upload.onprogress = (event) => {
                    onProgress?.({
                        loaded: event.loaded,
                        total: event.lengthComputable
                            ? event.total
                            : data.length,
                    });
                };
                request.onload = () => {
                    if (request.status < 200 || request.status >= 300) {
                        reject(
                            new Error(
                                `S3 multipart upload failed: ${request.status} ${request.statusText}`,
                            ),
                        );
                        return;
                    }
                    resolve(request.getResponseHeader("etag"));
                };
                request.onerror = () =>
                    reject(new Error("S3 multipart upload failed"));
                request.send(data);
            });
            if (!eTag) {
                throw new Error("Missing ETag from multipart upload response");
            }
            return eTag;
        } catch (error) {
            if (attempt === maxAttempts) {
                throw error;
            }
        }
    }

    throw new Error("Unreachable multipart upload retry state");
};

const completeMultipartUpload = async (
    completionURL: string,
    completedParts: MultipartCompletedPart[],
) => {
    const body = [
        "<CompleteMultipartUpload>",
        ...completedParts.map(
            (part) =>
                `<Part><PartNumber>${part.partNumber}</PartNumber><ETag>${part.eTag}</ETag></Part>`,
        ),
        "</CompleteMultipartUpload>",
    ].join("\n");

    await retryEnsuringHTTPOk(() =>
        fetch(completionURL, {
            method: "POST",
            headers: { ...publicRequestHeaders(), "Content-Type": "text/xml" },
            body,
        }),
    );
};

const mergeUint8Arrays = (chunks: Uint8Array[]): Uint8Array => {
    const totalLength = chunks.reduce((sum, chunk) => sum + chunk.length, 0);
    const merged = new Uint8Array(totalLength);
    let offset = 0;
    for (const chunk of chunks) {
        merged.set(chunk, offset);
        offset += chunk.length;
    }
    return merged;
};

const createAggregateUploadProgressReporter = (
    total: number,
    onProgress?: (progress: LockerUploadProgress) => void,
) => {
    let uploadedBytes = 0;

    return {
        reportPartProgress: (loaded: number) => {
            onProgress?.({
                phase: "uploading",
                loaded: Math.min(total, uploadedBytes + loaded),
                total,
            });
        },
        completePart: (partLength: number) => {
            uploadedBytes += partLength;
            onProgress?.({
                phase: "uploading",
                loaded: Math.min(total, uploadedBytes),
                total,
            });
        },
    };
};

/**
 * Upload a file to Locker with E2E encryption.
 *
 * The full flow:
 * 1. Read file → base64
 * 2. Generate stream key, encrypt file content (4 MB chunks) via Rust/WASM
 * 3. Encrypt placeholder thumbnail with the same file key
 * 4. Get presigned URLs for file and thumbnail
 * 5. PUT encrypted data to S3
 * 6. Encrypt file key with collection key
 * 7. Encrypt metadata and pubMagicMetadata
 * 8. POST /files to register the file
 *
 * @param file The browser File object to upload.
 * @param collectionID Target collection.
 * @param masterKey The user's master key (base64).
 * @returns The created file's ID.
 */
export const uploadLockerFile = async (
    file: File,
    collectionIDs: number[],
    masterKey: string,
    onProgress?: (progress: LockerUploadProgress) => void,
): Promise<number> => {
    const [collectionID, ...additionalCollectionIDs] = collectionIDs;
    if (collectionID === undefined) {
        throw new Error("No collection selected");
    }
    onProgress?.({ phase: "preparing" });

    const plaintextChunkCount = Math.max(
        1,
        Math.ceil(file.size / STREAM_ENCRYPTION_CHUNK_SIZE),
    );

    const streamEncryptor = await createStreamEncryptor();
    const fileKey = streamEncryptor.key;
    const encryptedFileHeader = streamEncryptor.decryptionHeader;

    let encryptedFileObjectKey: string;
    let encryptedFileSize = 0;

    try {
        if (plaintextChunkCount >= MULTIPART_CHUNKS_PER_PART) {
            const parts: Uint8Array[] = [];
            const partMd5s: string[] = [];
            let pendingEncryptedChunks: Uint8Array[] = [];

            for (
                let chunkIndex = 0;
                chunkIndex < plaintextChunkCount;
                chunkIndex++
            ) {
                const chunkStart = chunkIndex * STREAM_ENCRYPTION_CHUNK_SIZE;
                const chunkEnd = Math.min(
                    file.size,
                    chunkStart + STREAM_ENCRYPTION_CHUNK_SIZE,
                );
                const plaintextChunk = new Uint8Array(
                    await file.slice(chunkStart, chunkEnd).arrayBuffer(),
                );
                const isFinalChunk = chunkIndex === plaintextChunkCount - 1;
                const encryptedChunk = await streamEncryptor.encryptChunk(
                    plaintextChunk,
                    isFinalChunk,
                );
                pendingEncryptedChunks.push(encryptedChunk);

                if (
                    pendingEncryptedChunks.length ===
                        MULTIPART_CHUNKS_PER_PART ||
                    isFinalChunk
                ) {
                    const partData = mergeUint8Arrays(pendingEncryptedChunks);
                    parts.push(partData);
                    partMd5s.push(await md5Base64(partData));
                    encryptedFileSize += partData.length;
                    pendingEncryptedChunks = [];
                }
            }

            const firstPartLength = parts[0]?.length ?? 0;
            if (!firstPartLength) {
                throw new Error("Multipart upload produced no parts");
            }

            const multipartUpload = await fetchMultipartUploadURLs({
                contentLength: encryptedFileSize,
                partLength: firstPartLength,
                partMd5s,
            });
            const completedParts: MultipartCompletedPart[] = [];
            const progressReporter = createAggregateUploadProgressReporter(
                encryptedFileSize,
                onProgress,
            );

            for (const [index, partData] of parts.entries()) {
                const partUploadURL = multipartUpload.partURLs[index];
                const partMd5 = partMd5s[index];
                if (!partUploadURL || !partMd5) {
                    throw new Error("Missing multipart upload URL");
                }
                const eTag = await putFilePartToS3(
                    partUploadURL,
                    partData,
                    partMd5,
                    ({ loaded }) => progressReporter.reportPartProgress(loaded),
                );
                completedParts.push({ partNumber: index + 1, eTag });
                progressReporter.completePart(partData.length);
                parts[index] = new Uint8Array(0);
            }

            await completeMultipartUpload(
                multipartUpload.completeURL,
                completedParts,
            );
            encryptedFileObjectKey = multipartUpload.objectKey;
        } else {
            const encryptedChunks: Uint8Array[] = [];

            for (
                let chunkIndex = 0;
                chunkIndex < plaintextChunkCount;
                chunkIndex++
            ) {
                const chunkStart = chunkIndex * STREAM_ENCRYPTION_CHUNK_SIZE;
                const chunkEnd = Math.min(
                    file.size,
                    chunkStart + STREAM_ENCRYPTION_CHUNK_SIZE,
                );
                const plaintextChunk = new Uint8Array(
                    await file.slice(chunkStart, chunkEnd).arrayBuffer(),
                );
                const isFinalChunk = chunkIndex === plaintextChunkCount - 1;
                encryptedChunks.push(
                    await streamEncryptor.encryptChunk(
                        plaintextChunk,
                        isFinalChunk,
                    ),
                );
            }

            const encryptedFileBytes = mergeUint8Arrays(encryptedChunks);
            encryptedFileSize = encryptedFileBytes.length;
            const encryptedFileMd5 = await md5Base64(encryptedFileBytes);
            encryptedFileObjectKey = await uploadSingleObject(
                encryptedFileBytes,
                encryptedFileMd5,
                ({ loaded, total }) =>
                    onProgress?.({
                        phase: "uploading",
                        loaded,
                        total: total ?? encryptedFileBytes.length,
                    }),
            );
        }
    } finally {
        streamEncryptor.free();
    }

    onProgress?.({
        phase: "uploading",
        loaded: encryptedFileSize,
        total: encryptedFileSize,
    });
    onProgress?.({ phase: "finalizing" });

    // 3. Encrypt the black placeholder thumbnail with the file key
    const encryptedThumb = await encryptFileStreamWithKey(
        BLACK_THUMBNAIL_B64,
        fileKey,
    );

    // 4. Get the encrypted bytes for computing content length
    const encryptedThumbBytes = b64ToBytes(encryptedThumb.encryptedData);

    // 5. Fetch presigned upload URLs
    const thumbObjectKey = await uploadSingleObject(
        encryptedThumbBytes,
        encryptedThumb.md5Hash,
    );

    // 7. Look up collection key
    const collectionRecord = encryptedCollections.get(collectionID);
    if (!collectionRecord)
        throw new Error(`Collection ${collectionID} not in cache`);
    const collectionKey = await decryptCollectionKey(
        collectionRecord,
        masterKey,
    );

    // 8. Encrypt file key with collection key (SecretBox)
    const encryptedKey = await encryptBox(fileKey, collectionKey);

    // 9. Build and encrypt metadata
    const now = Date.now();
    // The browser exposes only lastModified, so preserve that instead of
    // replacing file times with upload time.
    const sourceModificationTime =
        file.lastModified > 0 ? file.lastModified : now;
    const metadata = {
        title: file.name,
        creationTime: sourceModificationTime,
        modificationTime: sourceModificationTime,
        fileType: 3, // FileType.other
    };
    const metadataJSON = JSON.stringify(metadata);
    const encryptedMetadata = await encryptBlob(
        stringToB64(metadataJSON),
        fileKey,
    );

    // 10. Build and encrypt pubMagicMetadata (noThumb flag)
    const pubMagicMetadata = { noThumb: true };
    const pubMagicJSON = JSON.stringify(pubMagicMetadata);
    const encryptedPubMagic = await encryptBlob(
        stringToB64(pubMagicJSON),
        fileKey,
    );

    // 11. POST /files to register the uploaded file
    const postHeaders = new Headers(await authenticatedRequestHeaders());
    postHeaders.set("Content-Type", "application/json");
    const res = await fetch(await apiURL("/files"), {
        method: "POST",
        headers: postHeaders,
        body: JSON.stringify({
            collectionID,
            encryptedKey: encryptedKey.encryptedData,
            keyDecryptionNonce: encryptedKey.nonce,
            file: {
                objectKey: encryptedFileObjectKey,
                decryptionHeader: encryptedFileHeader,
                size: encryptedFileSize,
            },
            thumbnail: {
                objectKey: thumbObjectKey,
                decryptionHeader: encryptedThumb.decryptionHeader,
                size: encryptedThumbBytes.length,
            },
            metadata: {
                encryptedData: encryptedMetadata.encryptedData,
                decryptionHeader: encryptedMetadata.decryptionHeader,
            },
            pubMagicMetadata: {
                version: 1,
                count: 1,
                data: encryptedPubMagic.encryptedData,
                header: encryptedPubMagic.decryptionHeader,
            },
        }),
    });
    ensureOk(res);
    const created = (await res.json()) as { id: number };
    if (additionalCollectionIDs.length > 0) {
        await addFileToCollections(
            created.id,
            fileKey,
            additionalCollectionIDs,
            masterKey,
        );
    }
    return created.id;
};

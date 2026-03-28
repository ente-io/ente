import {
    ensureLocalUser,
    ensureUserKeyPair,
} from "ente-accounts-rs/services/user";
import { authenticatedRequestHeaders, ensureOk } from "ente-base/http";
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
    boxSealOpen,
    createStreamDecryptor,
    decryptBox,
    decryptBoxBytes,
    decryptMetadataJSON,
} from "./crypto";
import {
    type EncryptedCollectionRecord,
    type EncryptedFileRecord,
    type LockerEncryptedCache,
    createEmptyLockerCache,
    getEncryptedFileRecord,
    getLockerCacheSnapshot,
    mergeEncryptedFileRecordsIntoCache,
    replaceLockerCache,
    setEncryptedFileRecord,
} from "./remote-cache";

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

interface DecryptAllDataResult {
    collections: LockerCollection[];
    failedCollectionIDs: number[];
    totalCollectionCount: number;
}

export interface LockerTrashData {
    items: LockerItem[];
    lastUpdatedAt: number;
}

const collectionNameDecoder = new TextDecoder();
const DOWNLOAD_URL_REVOKE_DELAY_MS = 30_000;

const toLockerCollectionParticipant = (
    user: z.infer<typeof RemoteCollectionUser>,
): LockerCollectionParticipant => ({
    id: user.id,
    email: user.email ?? undefined,
    role: user.role
        ? (user.role.toUpperCase() as LockerCollectionParticipantRole)
        : undefined,
});

const describeCryptoError = (error: unknown): string => {
    if (typeof error === "object" && error && "code" in error) {
        const code = typeof error.code === "string" ? error.code : "unknown";
        const message =
            "message" in error && typeof error.message === "string"
                ? error.message
                : "unknown";
        return `code=${code}, msg=${message}`;
    }
    if (error instanceof Error) {
        return error.message;
    }
    return String(error);
};

const toEpochMicroseconds = (timestamp: unknown) => {
    if (typeof timestamp !== "number") {
        return undefined;
    }

    // Locker mobile stores metadata timestamps in epoch milliseconds while
    // server structural timestamps use epoch microseconds.
    return timestamp < 100_000_000_000_000 ? timestamp * 1000 : timestamp;
};

const buildEncryptedFileRecord = (file: RemoteFile): EncryptedFileRecord => ({
    id: file.id,
    collectionID: file.collectionID,
    ownerID: file.ownerID ?? undefined,
    encryptedKey: file.encryptedKey,
    keyDecryptionNonce: file.keyDecryptionNonce,
    fileDecryptionHeader: file.file.decryptionHeader,
    hasObject: file.file.decryptionHeader.length > 0,
    fileSize: file.info?.fileSize,
    metadata: {
        encryptedData: file.metadata.encryptedData,
        decryptionHeader: file.metadata.decryptionHeader,
    },
    magicMetadata: file.magicMetadata
        ? {
              version: file.magicMetadata.version,
              data: file.magicMetadata.data,
              header: file.magicMetadata.header,
          }
        : undefined,
    pubMagicMetadata: file.pubMagicMetadata
        ? {
              version: file.pubMagicMetadata.version,
              data: file.pubMagicMetadata.data,
              header: file.pubMagicMetadata.header,
          }
        : undefined,
    updationTime: file.updationTime,
});

const fetchEncryptedCollections = async () => {
    const response = await fetch(
        await apiURL("/collections/v2", { sinceTime: 0 }),
        { headers: await authenticatedRequestHeaders() },
    );
    ensureOk(response);
    const { collections } = CollectionsResponse.parse(await response.json());

    const nextCollections = new Map<number, EncryptedCollectionRecord>();
    for (const collection of collections) {
        nextCollections.set(collection.id, {
            id: collection.id,
            owner: {
                ...toLockerCollectionParticipant(collection.owner),
                role: "OWNER",
            },
            ownerID: collection.owner.id,
            sharees: (collection.sharees ?? []).map(
                toLockerCollectionParticipant,
            ),
            encryptedKey: collection.encryptedKey,
            keyDecryptionNonce: collection.keyDecryptionNonce ?? undefined,
            encryptedName: collection.encryptedName ?? undefined,
            nameDecryptionNonce: collection.nameDecryptionNonce ?? undefined,
            name: collection.name ?? undefined,
            type: collection.type,
            isShared: (collection.sharees?.length ?? 0) > 0,
            isDeleted: !!collection.isDeleted,
            updationTime: collection.updationTime,
        });
    }

    return nextCollections;
};

const fetchEncryptedFilesForCollection = async (
    collectionID: number,
): Promise<EncryptedFileRecord[]> => {
    let sinceTime = 0;
    let hasMore = true;
    const records: EncryptedFileRecord[] = [];

    while (hasMore) {
        const response = await fetch(
            await apiURL("/collections/v2/diff", { collectionID, sinceTime }),
            { headers: await authenticatedRequestHeaders() },
        );
        ensureOk(response);
        const parsed = FileDiffResponse.parse(await response.json());

        for (const file of parsed.diff) {
            sinceTime = Math.max(sinceTime, file.updationTime);
            if (!file.isDeleted) {
                records.push(buildEncryptedFileRecord(file));
            }
        }

        hasMore = parsed.hasMore;
    }

    return records;
};

const fetchAllEncryptedFiles = async (
    collections: Map<number, EncryptedCollectionRecord>,
) => {
    const activeCollections = [...collections.values()].filter(
        (collection) => !collection.isDeleted,
    );
    const fileResults = await Promise.all(
        activeCollections.map((collection) =>
            fetchEncryptedFilesForCollection(collection.id),
        ),
    );

    const nextFiles = createEmptyLockerCache().files;
    for (const records of fileResults) {
        for (const record of records) {
            setEncryptedFileRecord(nextFiles, record);
        }
    }

    return nextFiles;
};

export const decryptCollectionKey = async (
    record: EncryptedCollectionRecord,
    masterKey: string,
): Promise<string> => {
    const currentUserID = ensureLocalUser().id;
    if (record.ownerID === currentUserID) {
        return decryptBox(
            {
                encryptedData: record.encryptedKey,
                nonce: record.keyDecryptionNonce!,
            },
            masterKey,
        );
    }

    return boxSealOpen(record.encryptedKey, await ensureUserKeyPair());
};

const decryptCollectionName = async (
    record: EncryptedCollectionRecord,
    collectionKey: string,
): Promise<string> => {
    if (record.name) {
        return record.name;
    }

    if (record.encryptedName && record.nameDecryptionNonce) {
        try {
            const nameBytes = await decryptBoxBytes(
                {
                    encryptedData: record.encryptedName,
                    nonce: record.nameDecryptionNonce,
                },
                collectionKey,
            );
            return collectionNameDecoder.decode(nameBytes);
        } catch (error) {
            log.error(
                `Failed to decrypt collection name for ${record.id}`,
                error,
            );
        }
    }

    return "Untitled";
};

const decryptFileKeyForRecordFromCollections = async (
    record: EncryptedFileRecord,
    masterKey: string,
    collections: Map<number, EncryptedCollectionRecord>,
): Promise<string> => {
    const collectionRecord = collections.get(record.collectionID);
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

export const decryptFileKeyForRecord = async (
    record: EncryptedFileRecord,
    masterKey: string,
): Promise<string> => {
    const cacheSnapshot = getLockerCacheSnapshot();
    return decryptFileKeyForRecordFromCollections(
        record,
        masterKey,
        cacheSnapshot.collections,
    );
};

const decryptFileToLockerItem = async (
    record: EncryptedFileRecord,
    collectionKey: string,
    collectionOwnerID: number,
): Promise<LockerItem | undefined> => {
    try {
        const fileKey = await decryptBox(
            {
                encryptedData: record.encryptedKey,
                nonce: record.keyDecryptionNonce,
            },
            collectionKey,
        );

        const metadata = (await decryptMetadataJSON(
            record.metadata,
            fileKey,
        )) as Record<string, unknown> | undefined;

        let pubMagicMetadata: Record<string, unknown> | undefined;
        if (record.pubMagicMetadata) {
            try {
                pubMagicMetadata = (await decryptMetadataJSON(
                    {
                        encryptedData: record.pubMagicMetadata.data,
                        decryptionHeader: record.pubMagicMetadata.header,
                    },
                    fileKey,
                )) as Record<string, unknown> | undefined;
            } catch {
                // Public metadata can be missing or unreadable for some older
                // files. We still want to surface the file row if basic
                // metadata decrypts successfully.
            }
        }

        const info = pubMagicMetadata?.info as
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

        const editedName =
            typeof pubMagicMetadata?.editedName === "string"
                ? pubMagicMetadata.editedName
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
    } catch (error) {
        log.error(
            `Failed to decrypt file ${record.id}: ${describeCryptoError(error)}`,
        );
        return undefined;
    }
};

const decryptAllData = async (
    masterKey: string,
    cache: LockerEncryptedCache,
): Promise<DecryptAllDataResult> => {
    const activeCollectionRecords = [...cache.collections.values()].filter(
        (collection) => !collection.isDeleted,
    );
    const result: LockerCollection[] = [];
    const failedCollectionIDs: number[] = [];
    const totalCollectionCount = activeCollectionRecords.length;

    const filesByCollection = new Map<number, EncryptedFileRecord[]>();
    const collectionIDsByFileID = new Map<number, number[]>();
    for (const records of cache.files.values()) {
        const sharedCollectionIDs = [...records.keys()];
        for (const file of records.values()) {
            const existing = filesByCollection.get(file.collectionID) ?? [];
            existing.push(file);
            filesByCollection.set(file.collectionID, existing);
            collectionIDsByFileID.set(file.id, sharedCollectionIDs);
        }
    }

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
            const decryptedItems = await Promise.all(
                files.map((file) =>
                    decryptFileToLockerItem(
                        file,
                        collectionKey,
                        collectionRecord.ownerID,
                    ),
                ),
            );
            const items = decryptedItems
                .filter((item): item is LockerItem => item !== undefined)
                .map((item) => ({
                    ...item,
                    collectionIDs:
                        collectionIDsByFileID.get(item.id) ??
                        item.collectionIDs,
                }));

            result.push({
                id: collectionRecord.id,
                name,
                owner: collectionRecord.owner,
                sharees: collectionRecord.sharees,
                items,
                type: collectionRecord.type,
                isShared: collectionRecord.isShared,
            });
        } catch (error) {
            failedCollectionIDs.push(collectionRecord.id);
            log.error(
                `Failed to decrypt collection ${collectionRecord.id}: ${describeCryptoError(
                    error,
                )}`,
            );
        }
    }

    result.sort((a, b) => a.name.localeCompare(b.name));
    return { collections: result, failedCollectionIDs, totalCollectionCount };
};

const withoutFailedCollections = (
    cache: LockerEncryptedCache,
    failedCollectionIDs: number[],
): LockerEncryptedCache => {
    if (failedCollectionIDs.length === 0) {
        return cache;
    }

    const failedCollectionIDSet = new Set(failedCollectionIDs);
    return {
        collections: new Map(
            [...cache.collections.entries()].filter(
                ([collectionID]) => !failedCollectionIDSet.has(collectionID),
            ),
        ),
        files: new Map(
            [...cache.files.entries()]
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
        ),
    };
};

export const fetchLockerData = async (
    masterKey: string,
): Promise<LockerCollection[]> => {
    const stagedCollections = await fetchEncryptedCollections();
    const stagedFiles = await fetchAllEncryptedFiles(stagedCollections);
    const stagedCache: LockerEncryptedCache = {
        collections: stagedCollections,
        files: stagedFiles,
    };

    const decrypted = await decryptAllData(masterKey, stagedCache);
    if (
        decrypted.totalCollectionCount > 0 &&
        decrypted.collections.length === 0
    ) {
        throw new Error(
            `Failed to decrypt all ${decrypted.totalCollectionCount} locker collections`,
        );
    }

    replaceLockerCache(
        withoutFailedCollections(stagedCache, decrypted.failedCollectionIDs),
    );

    if (decrypted.failedCollectionIDs.length > 0) {
        log.warn(
            `Decrypted ${decrypted.collections.length}/${decrypted.totalCollectionCount} locker collections`,
        );
    }

    return decrypted.collections;
};

export const fetchLockerTrash = async (
    masterKey: string,
): Promise<LockerTrashData> => {
    const cacheSnapshot = getLockerCacheSnapshot();
    const trashItems: LockerItem[] = [];
    const stagedTrashFileRecords: EncryptedFileRecord[] = [];
    let sinceTime = 0;
    let hasMore = true;

    while (hasMore) {
        const response = await fetch(
            await apiURL("/trash/v2/diff", { sinceTime }),
            { headers: await authenticatedRequestHeaders() },
        );
        ensureOk(response);
        const parsed = TrashDiffResponse.parse(await response.json());

        for (const entry of parsed.diff) {
            sinceTime = Math.max(sinceTime, entry.updatedAt);
            if (entry.isDeleted || entry.isRestored) {
                continue;
            }

            const collectionRecord = cacheSnapshot.collections.get(
                entry.file.collectionID,
            );
            if (!collectionRecord) {
                log.warn(
                    `Skipping trash file ${entry.file.id}: collection ${entry.file.collectionID} not in cache`,
                );
                continue;
            }

            const fileRecord = buildEncryptedFileRecord(entry.file);
            stagedTrashFileRecords.push(fileRecord);

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
            } catch (error) {
                log.error(
                    `Failed to decrypt trash file ${entry.file.id}`,
                    error,
                );
            }
        }

        hasMore = parsed.hasMore;
    }

    mergeEncryptedFileRecordsIntoCache(stagedTrashFileRecords);
    trashItems.sort((a, b) => (b.updatedAt ?? 0) - (a.updatedAt ?? 0));
    return { items: trashItems, lastUpdatedAt: sinceTime };
};

export const downloadLockerFile = async (
    fileID: number,
    fileName: string,
    masterKey: string,
    onProgress?: (progress: { loaded: number; total?: number }) => void,
): Promise<void> => {
    const fileRecord = getEncryptedFileRecord(fileID);
    if (!fileRecord) {
        throw new Error(`File ${fileID} not found in cache`);
    }

    const cacheSnapshot = getLockerCacheSnapshot();
    const collectionRecord = cacheSnapshot.collections.get(
        fileRecord.collectionID,
    );
    if (!collectionRecord) {
        throw new Error(
            `Collection ${fileRecord.collectionID} not found in cache`,
        );
    }

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

    const customOrigin = await customAPIOrigin();
    let response: Response;
    if (customOrigin) {
        const token = await ensureAuthToken();
        const url = await apiURL(`/files/download/${fileID}`, { token });
        response = await fetch(url);
    } else {
        response = await fetch(`https://files.ente.io/?fileID=${fileID}`, {
            headers: await authenticatedRequestHeaders(),
        });
    }
    ensureOk(response);

    const body = response.body;
    if (!body) {
        throw new Error("Download response body is empty");
    }

    const reader = body.getReader();
    const contentLength =
        parseInt(response.headers.get("Content-Length") ?? "", 10) || 0;
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
                        if (data.length > 0) {
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
    const url = URL.createObjectURL(decryptedData);
    const anchor = document.createElement("a");
    anchor.style.display = "none";
    anchor.href = url;
    anchor.download = fileName;
    document.body.appendChild(anchor);
    anchor.click();
    setTimeout(() => URL.revokeObjectURL(url), DOWNLOAD_URL_REVOKE_DELAY_MS);
    anchor.remove();
};

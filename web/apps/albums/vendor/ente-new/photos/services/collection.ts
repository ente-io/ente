import { ensureLocalUser, ensureSavedKeyAttributes } from "./auth-state";
import { boxSealOpen, decryptBox, encryptBox } from "ente-base/crypto";
import { authenticatedRequestHeaders, ensureOk } from "ente-base/http";
import { apiURL } from "ente-base/origins";
import { ensureMasterKeyFromSession } from "ente-base/session";
import {
    decryptRemoteCollection,
    RemoteCollection,
    type Collection,
} from "ente-media/collection";
import type { EnteFile } from "ente-media/file";
import { z } from "zod";

const requestBatchSize = 1000;

interface CollectionFileItem {
    id: number;
    encryptedKey: string;
    keyDecryptionNonce: string;
}

const CollectionResponse = z.object({ collection: RemoteCollection });

const batched = async <T>(
    items: T[],
    op: (batchItems: T[]) => Promise<void>,
): Promise<void> => {
    for (let i = 0; i < items.length; i += requestBatchSize) {
        await op(items.slice(i, i + requestBatchSize));
    }
};

const ensureUserKeyPair = async () => {
    const { encryptedSecretKey, secretKeyDecryptionNonce, publicKey } =
        ensureSavedKeyAttributes();
    const privateKey = await decryptBox(
        { encryptedData: encryptedSecretKey, nonce: secretKeyDecryptionNonce },
        await ensureMasterKeyFromSession(),
    );
    return { publicKey, privateKey };
};

const decryptCollectionKey = async (
    collection: z.infer<typeof RemoteCollection>,
): Promise<string> => {
    const { owner, encryptedKey, keyDecryptionNonce } = collection;
    if (owner.id === ensureLocalUser().id) {
        return decryptBox(
            { encryptedData: encryptedKey, nonce: keyDecryptionNonce! },
            await ensureMasterKeyFromSession(),
        );
    }

    return boxSealOpen(encryptedKey, await ensureUserKeyPair());
};

const decryptRemoteKeyAndCollection = async (
    collection: z.infer<typeof RemoteCollection>,
) => decryptRemoteCollection(collection, await decryptCollectionKey(collection));

/**
 * Fetch a collection from remote by its ID and decrypt it for local use.
 */
export const getCollectionByID = async (
    collectionID: number,
): Promise<Collection> => {
    const res = await fetch(await apiURL(`/collections/${collectionID}`), {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    const { collection } = CollectionResponse.parse(await res.json());
    return decryptRemoteKeyAndCollection(collection);
};

const encryptWithCollectionKey = async (
    collection: Collection,
    files: EnteFile[],
): Promise<CollectionFileItem[]> =>
    Promise.all(
        files.map(async (file) => {
            const box = await encryptBox(file.key, collection.key);
            return {
                id: file.id,
                encryptedKey: box.encryptedData,
                keyDecryptionNonce: box.nonce,
            };
        }),
    );

/**
 * Add existing files to a collection on remote.
 */
export const addToCollection = async (
    collection: Collection,
    files: EnteFile[],
): Promise<void> =>
    batched(files, async (batchFiles) => {
        const encryptedFileKeys = await encryptWithCollectionKey(
            collection,
            batchFiles,
        );
        ensureOk(
            await fetch(await apiURL("/collections/add-files"), {
                method: "POST",
                headers: await authenticatedRequestHeaders(),
                body: JSON.stringify({
                    collectionID: collection.id,
                    files: encryptedFileKeys,
                }),
            }),
        );
    });

import {
    decryptBoxB64,
    encryptBoxB64,
    generateNewBlobOrStreamKey,
} from "@/base/crypto";
import { nullToUndefined } from "@/utils/transform";
import { z } from "zod";
import { gunzip } from "../gzip";
import { applyCGroupDiff } from "../ml/db";
import type { CGroup } from "../ml/people";
import {
    savedLatestUpdatedAt,
    savedLocationTags,
    savedRemoteUserEntityKey,
    saveLatestUpdatedAt,
    saveLocationTags,
    saveRemoteUserEntityKey,
} from "./db";
import {
    getUserEntityKey,
    postUserEntityKey,
    RemoteUserEntityKey,
    type UserEntityChange,
    userEntityDiff,
} from "./remote";

/**
 * User entities are predefined lists of otherwise arbitrary data that the user
 * can store for their account.
 *
 * e.g. location tags, cluster groups.
 */
export type EntityType =
    /**
     * A location tag.
     *
     * The entity data is base64(encrypt(json))
     */
    | "location"
    /**
     * A cluster group.
     *
     * The entity data is base64(encrypt(gzip(json)))
     */
    | "cgroup";

/**
 * Update our local location tags with changes from remote.
 *
 * This function fetches all the location tag user entities from remote and
 * updates our local database. It uses local state to remember the latest entry
 * the last time it did a pull, so each subsequent pull is a lightweight diff.
 *
 * @param masterKey The user's master key. This is used to encrypt and decrypt
 * the location tags specific entity key.
 */
export const pullLocationTags = async (masterKey: Uint8Array) => {
    const decoder = new TextDecoder();
    const parse = (id: string, data: Uint8Array): LocationTag => ({
        id,
        ...RemoteLocationTag.parse(JSON.parse(decoder.decode(data))),
    });

    const processBatch = async (entities: UserEntityChange[]) => {
        const existingTagsByID = new Map(
            (await savedLocationTags()).map((t) => [t.id, t]),
        );
        entities.forEach(({ id, data }) =>
            data
                ? existingTagsByID.set(id, parse(id, data))
                : existingTagsByID.delete(id),
        );
        return saveLocationTags([...existingTagsByID.values()]);
    };

    return pullUserEntities("location", masterKey, processBatch);
};

/** Zod schema for the tag that we get from or put to remote. */
const RemoteLocationTag = z.object({
    name: z.string(),
    radius: z.number(),
    centerPoint: z.object({
        latitude: z.number(),
        longitude: z.number(),
    }),
});

export type RemoteLocationTag = z.infer<typeof RemoteLocationTag>;

/** Zod schema for the tag that we persist locally. */
export const LocalLocationTag = RemoteLocationTag.extend({
    id: z.string(),
});

export type LocationTag = z.infer<typeof LocalLocationTag>;

/**
 * Update our local cgroups with changes from remote.
 *
 * This fetches all the user entities corresponding to the "cgroup" entity type
 * from remote that have been created, updated or deleted since the last time we
 * checked.
 *
 * This diff is then applied to the data we have persisted locally.
 *
 * @param masterKey The user's master key. This is used to encrypt and decrypt
 * the cgroup specific entity key.
 */
export const pullCGroups = (masterKey: Uint8Array) => {
    // See: [Note: strict mode migration]
    //
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const parse = async (id: string, data: Uint8Array): Promise<CGroup> => ({
        id,
        name: undefined,
        avatarFaceID: undefined,
        ...RemoteCGroup.parse(JSON.parse(await gunzip(data))),
    });

    const processBatch = async (entities: UserEntityChange[]) =>
        await applyCGroupDiff(
            await Promise.all(
                entities.map(async ({ id, data }) =>
                    data ? await parse(id, data) : id,
                ),
            ),
        );

    return pullUserEntities("cgroup", masterKey, processBatch);
};

const RemoteFaceCluster = z.object({
    id: z.string(),
    faces: z.string().array(),
});

const RemoteCGroup = z.object({
    name: z.string().nullish().transform(nullToUndefined),
    assigned: z.array(RemoteFaceCluster),
    // The remote cgroup also has a "rejected" property, but that is not
    // currently used by any of the clients.
    isHidden: z.boolean(),
    avatarFaceID: z.string().nullish().transform(nullToUndefined),
});

export type RemoteCGroup = z.infer<typeof RemoteCGroup>;

/**
 * Sync of the given {@link type} entities that we have locally with remote.
 *
 * This fetches all the user entities of {@link type} from remote that have been
 * created, updated or deleted since the last time we checked.
 *
 * For each diff response, the {@link processBatch} is invoked to give a chance
 * to caller to apply the updates to the data we have persisted locally.
 *
 * The user's {@link masterKey} is used to decrypt (or encrypt, when generating
 * a new one) the entity key.
 */
const pullUserEntities = async (
    type: EntityType,
    masterKey: Uint8Array,
    processBatch: (entities: UserEntityChange[]) => Promise<void>,
) => {
    const entityKeyB64 = await getOrCreateEntityKeyB64(type, masterKey);

    let sinceTime = (await savedLatestUpdatedAt(type)) ?? 0;
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition, no-constant-condition
    while (true) {
        const entities = await userEntityDiff(type, sinceTime, entityKeyB64);
        if (entities.length == 0) break;

        await processBatch(entities);

        sinceTime = entities.reduce(
            (max, entity) => Math.max(max, entity.updatedAt),
            sinceTime,
        );
        await saveLatestUpdatedAt(type, sinceTime);
    }
};

/**
 * Return the entity key that can be used to decrypt the encrypted contents of
 * user entities of the given {@link type}.
 *
 * 1.  See if we have the encrypted entity key present locally. If so, return
 *     the entity key by decrypting it using with the user's master key.
 *
 * 2.  Otherwise fetch the encrypted entity key for that type from remote. If we
 *     get one, obtain the entity key by decrypt the encrypted one using the
 *     user's master key, save it locally for future use, and return it.
 *
 * 3.  Otherwise generate a new entity key, encrypt it using the user's master
 *     key, putting the encrypted one to remote and also saving it locally, and
 *     return it.
 *
 * See also, [Note: User entity keys].
 */
const getOrCreateEntityKeyB64 = async (
    type: EntityType,
    masterKey: Uint8Array,
) => {
    // See if we already have it locally.
    const saved = await savedRemoteUserEntityKey(type);
    if (saved) return decryptEntityKey(saved, masterKey);

    // See if remote already has it.
    const existing = await getUserEntityKey(type);
    if (existing) {
        // Only save it if we can decrypt it to avoid corrupting our local state
        // in unforeseen circumstances.
        const result = await decryptEntityKey(existing, masterKey);
        await saveRemoteUserEntityKey(type, existing);
        return result;
    }

    // Nada. Create a new one, put it to remote, save it locally, and return.

    // As a sanity check, genarate the key but immediately encrypt it as if it
    // were fetched from remote and then try to decrypt it before doing anything
    // with it.
    const generated = await generateNewEncryptedEntityKey(masterKey);
    const result = decryptEntityKey(generated, masterKey);
    await postUserEntityKey(type, generated);
    await saveRemoteUserEntityKey(type, generated);
    return result;
};

const generateNewEncryptedEntityKey = async (masterKey: Uint8Array) => {
    const { encryptedData, nonce } = await encryptBoxB64(
        await generateNewBlobOrStreamKey(),
        masterKey,
    );
    // Remote calls it the header, but it really is the nonce.
    return { encryptedKey: encryptedData, header: nonce };
};

/**
 * Decrypt an encrypted entity key using the user's master key.
 */
const decryptEntityKey = async (
    remote: RemoteUserEntityKey,
    masterKey: Uint8Array,
) =>
    decryptBoxB64(
        {
            encryptedData: remote.encryptedKey,
            // Remote calls it the header, but it really is the nonce.
            nonce: remote.header,
        },
        masterKey,
    );

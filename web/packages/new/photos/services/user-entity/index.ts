import {
    decryptBox,
    encryptBlob,
    encryptBox,
    generateBlobOrStreamKey,
} from "ente-base/crypto";
import { nullishToEmpty, nullToUndefined } from "ente-utils/transform";
import { z } from "zod/v4";
import { gunzip, gzip } from "../../utils/gzip";
import type { CGroupUserEntityData } from "../ml/people";
import {
    savedEntities,
    savedLatestUpdatedAt,
    savedRemoteUserEntityKey,
    saveEntities,
    saveLatestUpdatedAt,
    saveRemoteUserEntityKey,
    type LocalUserEntity,
} from "./db";
import {
    getUserEntityKey,
    postUserEntity,
    postUserEntityKey,
    putUserEntity,
    RemoteUserEntityKey,
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
 * Zod schema for the fields of interest in the location tag that we get from
 * remote.
 */
const RemoteLocationTagData = z.looseObject({
    name: z.string(),
    radius: z.number(),
    centerPoint: z.object({ latitude: z.number(), longitude: z.number() }),
});

/**
 * A view of the location tag data suitable for use by the rest of the app.
 */
export type LocationTag = z.infer<typeof RemoteLocationTagData>;

/**
 * Return the list of locally available location tags.
 */
export const savedLocationTags = (): Promise<LocationTag[]> =>
    savedEntities("location").then((es) =>
        es.map((e) => RemoteLocationTagData.parse(e.data)),
    );

const RemoteFaceCluster = z.looseObject({
    id: z.string(),
    faces: z.string().array(),
});

/**
 * Zod schema for the fields of interest in the cgroup that we get from remote.
 *
 * See also: {@link CGroupUserEntityData}.
 *
 * See: [Note: Use looseObject for metadata Zod schemas].
 */
const RemoteCGroupData = z.looseObject({
    name: z.string().nullish().transform(nullToUndefined),
    assigned: z.array(RemoteFaceCluster).nullish().transform(nullishToEmpty),
    rejectedFaceIDs: z.array(z.string()).nullish().transform(nullishToEmpty),
    isHidden: z.boolean(),
    avatarFaceID: z.string().nullish().transform(nullToUndefined),
});

/**
 * A "cgroup" user entity.
 */
export type CGroup = Omit<LocalUserEntity, "data"> & {
    // CGroupUserEntityData is meant to be a (documented) equivalent of
    // `z.infer<typeof RemoteCGroup>`.
    data: CGroupUserEntityData;
};

/**
 * Return the list of locally available cgroup user entities.
 */
export const savedCGroups = (): Promise<CGroup[]> =>
    savedEntities("cgroup").then((es) =>
        es.map((e) => ({ ...e, data: RemoteCGroupData.parse(e.data) })),
    );

/**
 * Update our local entities of the given {@link type} by pulling the latest
 * changes from remote.
 *
 * This fetches all the user entities corresponding to the given user entity
 * type from remote that have been created, updated or deleted since the last
 * time we checked.
 *
 * This diff is then applied to the data we have persisted locally.
 *
 * It uses local state to remember the latest entry the last time it did a pull,
 * so each subsequent pull is a lightweight diff.
 *
 * @param masterKey The user's masterKey (as a base64 string), which is is used
 * to encrypt and decrypt the entity key.
 */
export const pullUserEntities = async (type: EntityType, masterKey: string) => {
    const entityKey = await getOrCreateEntityKey(type, masterKey);

    let sinceTime = (await savedLatestUpdatedAt(type)) ?? 0;
    while (true) {
        const diff = await userEntityDiff(type, sinceTime, entityKey);
        if (diff.length == 0) break;

        const entityByID = new Map(
            (await savedEntities(type)).map((e) => [e.id, e]),
        );

        for (const { id, data, updatedAt } of diff) {
            if (data) {
                const s = isGzipped(type)
                    ? await gunzip(data)
                    : new TextDecoder().decode(data);
                entityByID.set(id, { id, data: JSON.parse(s), updatedAt });
            } else {
                entityByID.delete(id);
            }
            sinceTime = Math.max(sinceTime, updatedAt);
        }

        await saveEntities(type, [...entityByID.values()]);
        await saveLatestUpdatedAt(type, sinceTime);
    }
};

const isGzipped = (type: EntityType) => type == "cgroup";

/**
 * Create a new user entity of the given {@link type}.
 *
 * @param data Arbitrary data associated with the entity. The format of the data
 * is specific to each entity type, but the provided data should be JSON
 * serializable (Typescript does not have a native JSON type, so we need to
 * specify this as an `unknown`).
 *
 * @param masterKey The user's masterKey, which is is used to encrypt and
 * decrypt the entity key.
 *
 * @returns The ID of the newly created entity.
 */
export const addUserEntity = async (
    type: EntityType,
    data: unknown,
    masterKey: string,
) =>
    await postUserEntity(
        type,
        await encryptedUserEntityData(type, data, masterKey),
    );

const encryptedUserEntityData = async (
    type: EntityType,
    data: unknown,
    masterKey: string,
) => {
    const entityKey = await getOrCreateEntityKey(type, masterKey);

    const json = JSON.stringify(data);
    const bytes = isGzipped(type)
        ? await gzip(json)
        : new TextEncoder().encode(json);
    return encryptBlob(bytes, entityKey);
};

/**
 * Update the given user entities (both on remote and locally), creating them if
 * they don't exist.
 *
 * @param masterKey The user's masterKey (as a base64 string), which is is used
 * to encrypt and decrypt the entity key.
 */
export const updateOrCreateUserEntities = async (
    type: EntityType,
    entities: LocalUserEntity[],
    masterKey: string,
) =>
    await Promise.all(
        entities.map(({ id, data }) =>
            encryptedUserEntityData(type, data, masterKey).then(
                (encryptedBlob) => putUserEntity(id, type, encryptedBlob),
            ),
        ),
    );

/**
 * Return the entity key (base64 string) that can be used to decrypt the
 * encrypted contents of user entities of the given {@link type}.
 *
 * 1. See if we have the encrypted entity key present locally. If so, return the
 *    entity key by decrypting it using with the user's master key.
 *
 * 2. Otherwise fetch the encrypted entity key for that type from remote. If we
 *    get one, obtain the entity key by decrypt the encrypted one using the
 *    user's master key, save it locally for future use, and return it.
 *
 * 3. Otherwise generate a new entity key, encrypt it using the user's master
 *    key, putting the encrypted one to remote and also saving it locally, and
 *    return it.
 *
 * See also, [Note: User entity keys].
 */
const getOrCreateEntityKey = async (type: EntityType, masterKey: string) => {
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

    // As a sanity check, generate the key but immediately encrypt it as if it
    // were fetched from remote and then try to decrypt it before doing anything
    // with it.
    const generated = await generateEncryptedEntityKey(masterKey);
    const result = decryptEntityKey(generated, masterKey);
    await postUserEntityKey(type, generated);
    await saveRemoteUserEntityKey(type, generated);
    return result;
};

const generateEncryptedEntityKey = async (masterKey: string) => {
    const { encryptedData, nonce } = await encryptBox(
        await generateBlobOrStreamKey(),
        masterKey,
    );
    // Remote calls it the header, but it really is the nonce.
    return { encryptedKey: encryptedData, header: nonce };
};

/**
 * Decrypt an encrypted entity key (as a base64 string) using the provided
 * user's {@link masterKey}.
 */
const decryptEntityKey = async (
    remote: RemoteUserEntityKey,
    masterKey: string,
) =>
    decryptBox(
        {
            encryptedData: remote.encryptedKey,
            // Remote calls it the header, but it really is the nonce.
            nonce: remote.header,
        },
        masterKey,
    );

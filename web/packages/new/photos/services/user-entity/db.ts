import { getKV, getKVN, setKV } from "@/base/kv";
import { LocalLocationTag, type EntityType, type LocationTag } from ".";
import { RemoteUserEntityKey } from "./remote";

export const saveLocationTags = (tags: LocationTag[]) =>
    setKV("locationTags", JSON.stringify(tags));

/**
 * Return all the location tags that are present locally.
 *
 * Use {@link pullLocationTags} to synchronize this list with remote.
 */
export const savedLocationTags = async () =>
    LocalLocationTag.array().parse(
        JSON.parse((await getKV("locationTags")) ?? "[]"),
    );

const entityKeyKey = (type: EntityType) => `entityKey/${type}`;

/**
 * Return the locally persisted {@link RemoteUserEntityKey}, if any,
 * corresponding the given {@link type}.
 */
export const savedRemoteUserEntityKey = (
    type: EntityType,
): Promise<RemoteUserEntityKey | undefined> =>
    getKV(entityKeyKey(type)).then((s) =>
        s ? RemoteUserEntityKey.parse(JSON.parse(s)) : undefined,
    );

/**
 * Setter for {@link entityKey}.
 */
export const saveRemoteUserEntityKey = (
    type: EntityType,
    entityKey: RemoteUserEntityKey,
) => setKV(entityKeyKey(type), JSON.stringify(entityKey));

const latestUpdatedAtKey = (type: EntityType) => `latestUpdatedAt/${type}`;

/**
 * Return the locally persisted value for the latest `updatedAt` time for the
 * given entity {@link type}.
 *
 * This is used to checkpoint diffs, so that we can resume fetching from the
 * last time we did a fetch.
 */
export const savedLatestUpdatedAt = (type: EntityType) =>
    getKVN(latestUpdatedAtKey(type));

/**
 * Setter for {@link savedLatestUpdatedAt}.
 */
export const saveLatestUpdatedAt = (type: EntityType, value: number) =>
    setKV(latestUpdatedAtKey(type), value);

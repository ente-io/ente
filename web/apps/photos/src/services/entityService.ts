import log from "@/base/log";
import { apiURL } from "@/base/origins";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import HTTPService from "@ente/shared/network/HTTPService";
import localForage from "@ente/shared/storage/localForage";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import { getActualKey } from "@ente/shared/user";
import {
    EncryptedEntity,
    EncryptedEntityKey,
    Entity,
    EntityKey,
    EntitySyncDiffResponse,
    EntityType,
} from "types/entity";
import { getLatestVersionEntities } from "utils/entity";

/**
 * The maximum number of items to fetch in a single diff
 *
 * [Note: Limit of returned items in /diff requests]
 *
 * The various GET /diff API methods, which tell the client what all has changed
 * since a timestamp (provided by the client) take a limit parameter.
 *
 * These diff API calls return all items whose updated at is greater
 * (non-inclusive) than the timestamp we provide. So there is no mechanism for
 * pagination of items which have the same exact updated at.
 *
 * Conceptually, it may happen that there are more items than the limit we've
 * provided, but there are practical safeguards.
 *
 * For file diff, the limit is advisory, and remote may return less, equal or
 * more items than the provided limit. The scenario where it returns more is
 * when more files than the limit have the same updated at. Theoretically it
 * would make the diff response unbounded, however in practice file
 * modifications themselves are all batched. Even if the user were to select all
 * the files in their library and updates them all in one go in the UI, their
 * client app is required to use batched API calls to make those updates, and
 * each of those batches would get distinct updated at.
 */
const DIFF_LIMIT = 500;

const ENTITY_TABLES: Record<EntityType, string> = {
    [EntityType.LOCATION_TAG]: "location_tags",
};

const ENTITY_KEY_TABLES: Record<EntityType, string> = {
    [EntityType.LOCATION_TAG]: "location_tags_key",
};

const ENTITY_SYNC_TIME_TABLES: Record<EntityType, string> = {
    [EntityType.LOCATION_TAG]: "location_tags_time",
};

const getLocalEntity = async <T>(type: EntityType) => {
    const entities: Array<Entity<T>> =
        (await localForage.getItem<Entity<T>[]>(ENTITY_TABLES[type])) || [];
    return entities;
};

const getEntityLastSyncTime = async (type: EntityType) => {
    return (
        (await localForage.getItem<number>(ENTITY_SYNC_TIME_TABLES[type])) ?? 0
    );
};

const getCachedEntityKey = async (type: EntityType) => {
    const entityKey: EntityKey =
        (await localForage.getItem<EntityKey>(ENTITY_KEY_TABLES[type])) || null;
    return entityKey;
};

const getEntityKey = async (type: EntityType) => {
    try {
        const entityKey = await getCachedEntityKey(type);
        if (entityKey) {
            return entityKey;
        }
        const token = getToken();
        if (!token) {
            return;
        }
        const resp = await HTTPService.get(
            await apiURL("/user-entity/key"),
            {
                type,
            },
            {
                "X-Auth-Token": token,
            },
        );
        const encryptedEntityKey: EncryptedEntityKey = resp.data;
        const worker = await ComlinkCryptoWorker.getInstance();
        const masterKey = await getActualKey();
        const { encryptedKey, header, ...rest } = encryptedEntityKey;
        const decryptedData = await worker.decryptB64(
            encryptedKey,
            header,
            masterKey,
        );
        const decryptedEntityKey: EntityKey = { data: decryptedData, ...rest };
        localForage.setItem(ENTITY_KEY_TABLES[type], decryptedEntityKey);
        return decryptedEntityKey;
    } catch (e) {
        log.error("Get entity key failed", e);
        throw e;
    }
};

export const getLatestEntities = async <T>(type: EntityType) => {
    try {
        await syncEntity<T>(type);
        return await getLocalEntity<T>(type);
    } catch (e) {
        log.error("Sync entities failed", e);
        throw e;
    }
};

export const syncEntities = async () => {
    try {
        await syncEntity(EntityType.LOCATION_TAG);
    } catch (e) {
        log.error("Sync entities failed", e);
        throw e;
    }
};

const syncEntity = async <T>(type: EntityType): Promise<Entity<T>> => {
    try {
        let entities = await getLocalEntity(type);
        log.info(
            `Syncing ${type} entities localEntitiesCount: ${entities.length}`,
        );
        let syncTime = await getEntityLastSyncTime(type);
        log.info(`Syncing ${type} entities syncTime: ${syncTime}`);
        let response: EntitySyncDiffResponse;
        do {
            response = await getEntityDiff(type, syncTime);
            if (!response.diff?.length) {
                return;
            }

            const entityKey = await getEntityKey(type);
            const newDecryptedEntities: Array<Entity<T>> = await Promise.all(
                response.diff.map(async (entity: EncryptedEntity) => {
                    if (entity.isDeleted) {
                        // This entry is deleted, so we don't need to decrypt it, just return it as is
                        // as unknown as EntityData is a hack to get around the type system
                        return entity as unknown as Entity<T>;
                    }
                    const { encryptedData, header, ...rest } = entity;
                    const worker = await ComlinkCryptoWorker.getInstance();
                    const decryptedData = await worker.decryptMetadata(
                        encryptedData,
                        header,
                        entityKey.data,
                    );
                    return {
                        ...rest,
                        data: decryptedData,
                    };
                }),
            );

            entities = getLatestVersionEntities([
                ...entities,
                ...newDecryptedEntities,
            ]);

            const nonDeletedEntities = entities.filter(
                (entity) => !entity.isDeleted,
            );

            if (response.diff.length) {
                syncTime = response.diff.slice(-1)[0].updatedAt;
            }
            await localForage.setItem(ENTITY_TABLES[type], nonDeletedEntities);
            await localForage.setItem(ENTITY_SYNC_TIME_TABLES[type], syncTime);
            log.info(
                `Syncing ${type} entities syncedEntitiesCount: ${nonDeletedEntities.length}`,
            );
        } while (response.diff.length === DIFF_LIMIT);
    } catch (e) {
        log.error("Sync entity failed", e);
    }
};

const getEntityDiff = async (
    type: EntityType,
    time: number,
): Promise<EntitySyncDiffResponse> => {
    try {
        const token = getToken();
        if (!token) {
            return;
        }
        const resp = await HTTPService.get(
            await apiURL("/user-entity/entity/diff"),
            {
                sinceTime: time,
                type,
                limit: DIFF_LIMIT,
            },
            {
                "X-Auth-Token": token,
            },
        );

        return resp.data;
    } catch (e) {
        log.error("Get entity diff failed", e);
        throw e;
    }
};

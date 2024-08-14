import { decryptAssociatedB64Data } from "@/base/crypto/ente";
import { authenticatedRequestHeaders, ensureOk } from "@/base/http";
import { getKVN, setKV } from "@/base/kv";
import { apiURL } from "@/base/origins";
import { nullToUndefined } from "@/utils/transform";
import { z } from "zod";
import type { Person } from "./ml/cluster-new";
import { applyPersonDiff } from "./ml/db";

/**
 * User entities are predefined lists of otherwise arbitrary data that the user
 * can store for their account.
 *
 * e.g. location tags, people in their photos.
 */
export type EntityType =
    | "person"
    /**
     * The latest iteration of the Person entity format, where the data is
     * gzipped before encryption.
     */
    | "person_v2";

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
 * pagination of items which have the exact same updated at.
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
const defaultDiffLimit = 500;

/**
 * A generic user entity.
 *
 * This is an intermediate step, usually what we really want is a version
 * of this with the {@link data} parsed to the specific type of JSON object
 * expected to be associated with this entity type.
 */
interface UserEntity {
    /**
     * A UUID or nanoid for the entity.
     */
    id: string;
    /**
     * Arbitrary data associated with the entity. The format of this data is
     * specific to each entity type.
     *
     * This will not be present for entities that have been deleted on remote.
     */
    data: Uint8Array | undefined;
    /**
     * Epoch microseconds denoting when this entity was created or last updated.
     */
    updatedAt: number;
}

const RemoteUserEntity = z.object({
    id: z.string(),
    /** Base64 string containing the encrypted contents of the entity. */
    encryptedData: z.string(),
    /** Base64 string containing the decryption header. */
    header: z.string(),
    isDeleted: z.boolean(),
    updatedAt: z.number(),
});

/**
 * Fetch the next batch of user entities of the given type that have been
 * created or updated since the given time.
 *
 * @param type The type of the entities to fetch.
 *
 * @param sinceTime Epoch milliseconds. This is used to ask remote to provide us
 * only entities whose {@link updatedAt} is more than the given value. Set this
 * to zero to start from the beginning.
 *
 * @param entityKeyB64 The base64 encoded key to use for decrypting the
 * encrypted contents of the user entity.
 *
 * [Note: Diff response will have at most one entry for an id]
 *
 * Unlike git diffs which track all changes, the diffs we get from remote are
 * guaranteed to contain only one entry (upsert or delete) for particular Ente
 * object. This holds true irrespective of the diff limit.
 *
 * For example, in the user entity diff response, it is guaranteed that there
 * will only be at max one entry for a particular entity id. The entry will have
 * no data to indicate that the corresponding entity was deleted. Otherwise,
 * when the data is present, it is taken as the creation of a new entity or the
 * updation of an existing one.
 *
 * This behaviour comes from how remote stores the underlying, e.g., entities. A
 * diff returns just entities whose updation times greater than the provided
 * since time (limited to the given diff limit). So there will be at most one
 * row for a particular entity id. And if that entity has been deleted, then the
 * row will be a tombstone so data will be not be present.
 */
export const userEntityDiff = async (
    type: EntityType,
    sinceTime: number,
    entityKeyB64: string,
): Promise<UserEntity[]> => {
    const decrypt = (encryptedDataB64: string, decryptionHeaderB64: string) =>
        decryptAssociatedB64Data({
            encryptedDataB64,
            decryptionHeaderB64,
            keyB64: entityKeyB64,
        });

    const params = new URLSearchParams({
        type,
        sinceTime: sinceTime.toString(),
        limit: defaultDiffLimit.toString(),
    });
    const url = await apiURL(`/user-entity/entity/diff`);
    const res = await fetch(`${url}?${params.toString()}`, {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    const entities = z
        .object({ diff: z.array(RemoteUserEntity) })
        .parse(await res.json()).diff;
    return Promise.all(
        entities.map(
            async ({ id, encryptedData, header, isDeleted, updatedAt }) => ({
                id,
                data: isDeleted
                    ? undefined
                    : await decrypt(encryptedData, header),
                updatedAt,
            }),
        ),
    );
};

/**
 * Sync the {@link Person} entities that we have locally with remote.
 *
 * This fetches all the user entities corresponding to the "person_v2" entity
 * type from remote that have been created, updated or deleted since the last
 * time we checked.
 *
 * This diff is then applied to the data we have persisted locally.
 */
export const syncPersons = async (entityKeyB64: string) => {
    const type: EntityType = "person";

    const parse = ({ id, data }: UserEntity): Person => {
        const rp = RemotePerson.parse(
            JSON.parse(new TextDecoder().decode(data)),
        );
        return {
            id,
            name: rp.name,
            clusterIDs: rp.assigned.map(({ id }) => id),
            isHidden: rp.isHidden,
            avatarFaceID: rp.avatarFaceID,
            displayFaceID: undefined,
        };
    };

    let sinceTime = (await latestUpdatedAt(type)) ?? 0;
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition, no-constant-condition
    while (true) {
        const entities = await userEntityDiff(type, sinceTime, entityKeyB64);
        if (entities.length == 0) break;

        await applyPersonDiff(entities.map((e) => (e.data ? parse(e) : e.id)));

        sinceTime = entities.reduce(
            (max, e) => Math.max(max, e.updatedAt),
            sinceTime,
        );
        await setLatestUpdatedAt(type, sinceTime);
    }
};

/** Zod schema for the {@link RemotePerson} type. */
const RemotePerson = z.object({
    name: z.string().nullish().transform(nullToUndefined),
    assigned: z.array(
        z.object({
            // TODO-Cluster temporary modify
            id: z.number().transform((n) => n.toString()), // TODO z.string person_v2
            faces: z.string().array(),
        }),
    ),
    isHidden: z.boolean(),
    avatarFaceID: z.string().nullish().transform(nullToUndefined),
});

/**
 * A "person_v2" entity as synced via remote.
 */
type RemotePerson = z.infer<typeof RemotePerson>;

const latestUpdatedAtKey = (type: EntityType) => `latestUpdatedAt/${type}`;

/**
 * Return the locally persisted value for the latest `updatedAt` time for the
 * given entity type.
 *
 * This is used to checkpoint diffs, so that we can resume fetching from the
 * last time we did a fetch.
 */
const latestUpdatedAt = (type: EntityType) => getKVN(latestUpdatedAtKey(type));

/**
 * Setter for {@link latestUpdatedAt}.
 */
const setLatestUpdatedAt = (type: EntityType, value: number) =>
    setKV(latestUpdatedAtKey(type), value);

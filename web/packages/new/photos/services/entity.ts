import { authenticatedRequestHeaders, ensureOk } from "@/base/http";
import { apiURL } from "@/base/origins";

/**
 * Entities are predefined lists of otherwise arbitrary data that the user can
 * store for their account.
 *
 * e.g. location tags, people in their photos.
 */
export type EntityType =
    /**
     * A new version of the Person entity where the data is gzipped before
     * encryption.
     */
    "person_v2";

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
 * Fetch all entities of the given type that have been created or updated since
 * the given time.
 *
 * For each batch of fetched entities, call a provided function that can ingest
 * them. This function is also provided the latest timestamp from amongst all of
 * the entities fetched so far, which the caller can persist if needed to resume
 * future diffs fetches from the current checkpoint.
 *
 * @param type The type of the entities to fetch.
 *
 * @param sinceTime Epoch milliseconds. This is used to ask remote to provide us
 * only entities whose {@link updatedAt} is more than the given value. Set this
 * to zero to start from the beginning.
 */
export const entityDiff = async (
    type: EntityType,
    sinceTime: number,
    onFetch: (entities: unknown[], latestUpdatedAt: number) => Promise<void>,
) => {
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
};

import { SUB_TYPE, type Collection } from "@/media/collection";
import { ItemVisibility } from "@/media/file-metadata";
import type { User } from "@ente/shared/user/types";

export const ARCHIVE_SECTION = -1;
export const TRASH_SECTION = -2;
export const DUMMY_UNCATEGORIZED_COLLECTION = -3;
export const HIDDEN_ITEMS_SECTION = -4;
export const ALL_SECTION = 0;

/**
 * Return true if this is a default hidden collection.
 *
 * See also: [Note: Multiple "default" hidden collections].
 */
export const isDefaultHiddenCollection = (collection: Collection) =>
    // TODO: Need to audit the types
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    collection.magicMetadata?.data.subType === SUB_TYPE.DEFAULT_HIDDEN;

/**
 * Extract the IDs of all the "default" hidden collections.
 *
 * [Note: Multiple "default" hidden collections].
 *
 * Normally, there is only expected to be one such collection. But to provide
 * clients laxity in synchronization, we don't enforce this and instead allow
 * for multiple such default hidden collections to exist.
 */
export const findDefaultHiddenCollectionIDs = (collections: Collection[]) =>
    new Set<number>(
        collections
            .filter(isDefaultHiddenCollection)
            .map((collection) => collection.id),
    );

export const isIncomingShare = (collection: Collection, user: User) =>
    collection.owner.id !== user.id;

export const isHiddenCollection = (collection: Collection) =>
    // TODO: Need to audit the types
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    collection.magicMetadata?.data.visibility === ItemVisibility.hidden;

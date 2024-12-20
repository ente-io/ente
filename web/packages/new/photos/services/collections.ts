import { type Collection } from "@/media/collection";
import localForage from "@ente/shared/storage/localForage";
import { isHiddenCollection } from "./collection";

const COLLECTION_TABLE = "collections";

export const getLocalCollections = async (
    type: "normal" | "hidden" = "normal",
): Promise<Collection[]> => {
    const collections = await getAllLocalCollections();
    return type == "normal"
        ? collections.filter((c) => !isHiddenCollection(c))
        : collections.filter((c) => isHiddenCollection(c));
};

export const getAllLocalCollections = async (): Promise<Collection[]> => {
    const collections: Collection[] =
        (await localForage.getItem(COLLECTION_TABLE)) ?? [];
    return collections;
};

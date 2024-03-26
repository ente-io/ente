import Store, { Schema } from "electron-store";
import type { KeysStoreType } from "../types/main";

const keysStoreSchema: Schema<KeysStoreType> = {
    AnonymizeUserID: {
        type: "object",
        properties: {
            id: {
                type: "string",
            },
        },
    },
};

export const keysStore = new Store({
    name: "keys",
    schema: keysStoreSchema,
});

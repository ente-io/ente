import Store, { Schema } from "electron-store";
import type { SafeStorageStoreType } from "../types/main";

const safeStorageSchema: Schema<SafeStorageStoreType> = {
    encryptionKey: {
        type: "string",
    },
};

export const safeStorageStore = new Store({
    name: "safeStorage",
    schema: safeStorageSchema,
});

import { deleteDB, openDB, type DBSchema } from "idb";
import log from "./log";

/**
 * Key value store schema.
 *
 * The use IndexedDB to store arbitrary key-value pairs. The functional
 * motivation is to allow these to also be accessed from web workers (local
 * storage is limited to the main thread).
 *
 * The "kv" database consists of one object store, "kv". Each entry is a string.
 * The key is also a string.
 */
interface KVDBSchema extends DBSchema {
    kv: {
        key: string;
        value: string;
    };
}

/**
 * A lazily-created, cached promise for KV DB.
 *
 * [Note: Caching IDB instances in separate execution contexts]
 *
 * We open the database once (on access), and thereafter save and reuse this
 * promise each time something wants to connect to it.
 *
 * This promise can subsequently get cleared if we need to relinquish our
 * connection (e.g. if another client wants to open the face DB with a newer
 * version of the schema).
 *
 * It can also get cleared on logout. In all such cases, it'll automatically get
 * recreated on next access.
 *
 * Note that this is module specific state, so each execution context (main
 * thread, web worker) that calls the functions in this module will its own
 * promise to the database. To ensure that all connections get torn down
 * correctly, we need to perform the following logout sequence:
 *
 * 1.  Terminate all the workers which might have one of the instances in
 *     memory. This closes their connections.
 *
 * 2.  Delete the database on the main thread.
 */
let _kvDB: ReturnType<typeof openKVDB> | undefined;

const openKVDB = async () => {
    const db = await openDB<KVDBSchema>("kv", 1, {
        upgrade(db) {
            db.createObjectStore("kv");
        },
        blocking() {
            log.info(
                "Another client is attempting to open a new version of KV DB",
            );
            db.close();
            _kvDB = undefined;
        },
        blocked() {
            log.warn(
                "Waiting for an existing client to close their connection so that we can update the KV DB version",
            );
        },
        terminated() {
            log.warn("Our connection to KV DB was unexpectedly terminated");
            _kvDB = undefined;
        },
    });

    return db;
};

/**
 * @returns a lazily created, cached connection to the KV DB.
 */
const kvDB = () => (_kvDB ??= openKVDB());

/**
 * Clear all key values stored in the KV db.
 *
 * This is meant to be called during logout in the main thread.
 */
export const clearKVDB = async () => {
    try {
        if (_kvDB) (await _kvDB).close();
    } catch (e) {
        log.warn("Ignoring error when trying to close KV DB", e);
    }
    _kvDB = undefined;

    return deleteDB("kv", {
        blocked() {
            log.warn(
                "Waiting for an existing client to close their connection so that we can delete the KV DB",
            );
        },
    });
};

/**
 * Return the value stored corresponding to {@link key}, or `undefined` if there
 * is no such entry.
 */
export const getKV = async (key: string) => {
    const db = await kvDB();
    return await db.get("kv", key);
};

/**
 * Save the given {@link value} corresponding to {@link key}, overwriting any
 * existing value.
 */
export const setKV = async (key: string, value: string) => {
    const db = await kvDB();
    await db.put("kv", value, key);
};

/**
 * Remove the entry corresponding to {@link key} (if any).
 */
export const removeKV = async (key: string) => {
    const db = await kvDB();
    await db.delete("kv", key);
};

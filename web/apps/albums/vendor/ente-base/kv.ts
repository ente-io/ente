import { deleteDB, openDB, type DBSchema } from "idb";
import log from "./log";

/**
 * Key value store schema.
 *
 * [Note: KV DB]
 *
 * The use IndexedDB to store arbitrary key-value pairs. The functional
 * motivation is to allow these to also be accessed from web workers (local
 * storage is limited to the main thread).
 *
 * The "kv" database consists of one object store, "kv". Keys are strings.
 * Values can be arbitrary JSON objects.
 *
 * [Note: Avoiding IndexedDB flakiness by avoiding indexes]
 *
 * Sporadically, rarely, but definitely, we ran into issues with IndexedDB
 * losing data. e.g. saves from the ML web worker would complete successfully,
 * but the saves would not reflect on the main thread, and that data would just
 * get lost when the app would refresh.
 *
 * I'm not sure where the problem lay - in our own code, in the library that we
 * are using (idb), within IndexedDB itself, or in Electron/Chrome's
 * implementation of it (these cases all came up in the context of the ML code
 * that only ran in our desktop app).
 *
 * A piece of advice I randomly ran across on the internet was to keep it very
 * simple, and avoid all indexes. I also recalled that we did not see such
 * issues with our older (but now unmaintained) library, localforage, which also
 * doesn't use any indexes, and just has a flat single-store schema.
 *
 * So this may be superstition, but for now the approach I'm taking is to use
 * IndexedDB as a key value store only.
 */
interface KVDBSchema extends DBSchema {
    kv: {
        key: string;
        /**
         * Typescript doesn't have a native JSON type, so this needs to be
         * unknown
         */
        value: unknown;
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
 * 1. Terminate all the workers which might have one of the instances in memory.
 *    This closes their connections.
 *
 * 2. Delete the database on the main thread.
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
 * Return the string value stored corresponding to {@link key}, or `undefined`
 * if there is no such entry.
 *
 * Typescript doesn't have a native JSON type, so the return value is type as an
 * `unknown`. For primitive types, you can avoid casting by using the
 * {@link getKVS} (string), {@link getKVN} (number) or {@link getKVB} (boolean)
 * methods that do an additional runtime check of the type.
 */
export const getKV = async (key: string) => {
    const db = await kvDB();
    return db.get("kv", key);
};

const _getKV = async <T extends string | number | boolean>(
    key: string,
    type: string,
): Promise<T | undefined> => {
    const db = await kvDB();
    const v = await db.get("kv", key);
    if (v === undefined) return undefined;
    if (typeof v != type)
        throw new Error(
            // This is just an error message, it is fine if stringification
            // produces nothing useful always, it might too in some cases.
            //
            // eslint-disable-next-line @typescript-eslint/no-base-to-string
            `Expected the value corresponding to key ${key} to be a ${type}, but instead got ${String(v)}`,
        );
    return v as T;
};

/** String variant of {@link getKV}. */
export const getKVS = async (key: string) => _getKV<string>(key, "string");

/** Numeric variant of {@link getKV}. */
export const getKVN = async (key: string) => _getKV<number>(key, "number");

/** Boolean variant of {@link getKV} */
export const getKVB = async (key: string) => _getKV<boolean>(key, "boolean");

/**
 * Save the given {@link value} corresponding to {@link key}, overwriting any
 * existing value.
 *
 * @param value Any arbitrary JSON object. Typescript doesn't have a native JSON
 * type, so this is typed as a unknown
 */
export const setKV = async (key: string, value: unknown) => {
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

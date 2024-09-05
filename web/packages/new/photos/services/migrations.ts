import { isDesktop } from "@/base/app";
import { getKVN, removeKV, setKV } from "@/base/kv";
import log from "@/base/log";
import localForage from "@ente/shared/storage/localForage";
import { deleteDB } from "idb";

/**
 * App specific migrations.
 *
 * The app stores data in multiple places: local storage, IndexedDB, OPFS, and
 * not all of these support DB migrations. And even when they do, those are
 * rather heavy weight and complicated (e.g. IndexedDB).
 *
 * Further, there are various app level migrations, e.g. resetting the diff
 * fetch times, that don't correspond to DB migrations, these are just changes
 * we need to make to our locally persisted values and not the schemas
 * themselves.
 *
 * Thus we introduce the concept of app level migrations. This is some code
 * which runs early in the page load, and runs arbitrary blocks of code until it
 * reaches the last migration number.
 *
 * We can put all sorts of changes here: cleanup of legacy keys, re-triggers for
 * various fetches etc.
 *
 * This code usually runs fairly early on page load, but if you need specific
 * guarantees or have dependencies in the order of operations (beyond what is
 * captured by the sequential flow here), then this might not be appropriate.
 */
export const runMigrations = async () => {
    const m = (await getKVN("migrationLevel")) ?? 0;
    const latest = 1;
    if (m < latest) {
        log.info(`Running migrations ${m} => ${latest}`);
        if (m < 1 && isDesktop) await m0();
        await setKV("migrationLevel", latest);
    }
};

// Some of these (indicated by "Prunable") can be no-oped in the future when
// almost all clients would've migrated over.

// Last used: Aug 2024. Prunable.
const m0 = () =>
    Promise.allSettled([
        // Delete the legacy face DB v1.
        deleteDB("mldata"),

        // Delete the legacy CLIP (mostly) related keys from LocalForage.
        localForage.removeItem("embeddings"),
        localForage.removeItem("embedding_sync_time"),
        localForage.removeItem("embeddings_v2"),
        localForage.removeItem("file_embeddings"),
        localForage.removeItem("onnx-clip-embedding_sync_time"),
        localForage.removeItem("file-ml-clip-face-embedding_sync_time"),

        // Delete keys for the legacy diff based sync.
        removeKV("embeddingSyncTime:onnx-clip"),
        removeKV("embeddingSyncTime:file-ml-clip-face"),

        // Delete the legacy face DB v2.
        deleteDB("face"),
    ]);

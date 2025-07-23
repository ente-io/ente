import { isDesktop } from "ente-base/app";
import { getKVN, removeKV, setKV } from "ente-base/kv";
import log from "ente-base/log";
import { localForage } from "ente-gallery/services/files-db";
import { deleteDB } from "idb";
import { retryIndexingFailuresIfNeeded } from "./ml";

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
    const isNewInstall = m == 0;
    const latest = 5;
    if (m < latest) {
        log.info(`Running migrations ${m} => ${latest}`);
        if (m < 1 && isDesktop) await m1();
        if (m < 2) await m2();
        if (m < 3) await m3();
        if (m < 4) m4();
        if (m < 5) m5(isNewInstall);
        await setKV("migrationLevel", latest);
    }
};

// Some of these (indicated by "Prunable") can be no-oped in the future when
// almost all clients would've migrated over, and there wouldn't be any critical
// impact if the few remaining outliers never ran that specific migration.

// Added: Aug 2024 (v1.7.3). Prunable.
const m1 = () =>
    Promise.all([
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
    ]).then(() => {
        // Delete legacy ML keys.
        localStorage.removeItem("faceIndexingEnabled");
    });

// Added: Sep 2024 (v1.7.5-beta). Prunable.
const m2 = () =>
    // Older versions of the user-entities code kept the diff related state
    // in a different place. These entries are not needed anymore (the tags
    // themselves will get resynced).
    Promise.all([
        localForage.removeItem("location_tags"),
        localForage.removeItem("location_tags_key"),
        localForage.removeItem("location_tags_time"),

        // Remove data from an intermediate format that stored user-entities
        // piecewise instead of as generic, verbatim, entities.
        removeKV("locationTags"),
        removeKV("entityKey/locationTags"),
        removeKV("latestUpdatedAt/locationTags"),
    ]);

// Added: Sep 2024 (v1.7.5-beta). Prunable.
const m3 = () =>
    Promise.all([
        // Delete the legacy face DB v1.
        //
        // This was already removed in m1, but that was behind an isDesktop
        // check, but later I found out that old web versions also created this
        // DB (although empty).
        deleteDB("mldata"),

        // Remove data from an intermediate format that stored user-entities in
        // their parsed form instead of as generic, verbatim, entities.
        removeKV("locationTags"),
        removeKV("entityKey/location"),
        removeKV("latestUpdatedAt/location"),
    ]);

// Added: Nov 2024 (v1.7.7-beta). Prunable.
const m4 = () => {
    // Delete old local storage keys that have been subsumed elsewhere.
    localStorage.removeItem("mapEnabled");
    localStorage.removeItem("userDetails");
    localStorage.removeItem("subscription");
    localStorage.removeItem("familyData");
};

// Added: Feb 2025 (v1.7.10). Prunable.
const m5 = (isNewInstall: boolean) => {
    // MUI now persists the color scheme (also in local storage). This was
    // anyway never released, was only ever an internal user flag.
    localStorage.removeItem("theme");
    if (!isNewInstall) {
        // Let the indexer have another go at the files, the new vips conversion
        // logic added since 1.7.9 might be able to convert more outliers.
        retryIndexingFailuresIfNeeded();
    }
};

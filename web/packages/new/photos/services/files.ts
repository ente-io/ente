import { type EnteFile } from "@/new/photos/types/file";
import log from "@/next/log";
import { Events, eventBus } from "@ente/shared/events";
import localForage from "@ente/shared/storage/localForage";

const FILES_TABLE = "files";
const HIDDEN_FILES_TABLE = "hidden-files";

/**
 * Return all files that we know about locally, both "normal" and "hidden".
 */
export const getAllLocalFiles = async () =>
    (await getLocalFiles("normal")).concat(await getLocalFiles("hidden"));

/**
 * Return all files that we know about locally. By default it returns only
 * "normal" (i.e. non-"hidden") files, but it can be passed the {@link type}
 * "hidden" to get it to instead return hidden files that we know about locally.
 */
export const getLocalFiles = async (type: "normal" | "hidden" = "normal") => {
    const tableName = type === "normal" ? FILES_TABLE : HIDDEN_FILES_TABLE;
    const files: EnteFile[] =
        (await localForage.getItem<EnteFile[]>(tableName)) ?? [];
    return files;
};

export const setLocalFiles = async (
    type: "normal" | "hidden",
    files: EnteFile[],
) => {
    const tableName = type === "normal" ? FILES_TABLE : HIDDEN_FILES_TABLE;
    await localForage.setItem(tableName, files);
    try {
        eventBus.emit(Events.LOCAL_FILES_UPDATED);
    } catch (e) {
        log.error("Failed to save files", e);
    }
};

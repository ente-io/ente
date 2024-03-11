import { watchStore } from "../stores/watch.store";
import { WatchStoreType } from "../types";

export function getWatchMappings() {
    const mappings = watchStore.get("mappings") ?? [];
    return mappings;
}

export function setWatchMappings(watchMappings: WatchStoreType["mappings"]) {
    watchStore.set("mappings", watchMappings);
}

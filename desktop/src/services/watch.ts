import { WatchStoreType } from '../types';
import { watchStore } from '../stores/watch.store';

export function getWatchMappings() {
    const mappings = watchStore.get('mappings') ?? [];
    return mappings;
}

export function setWatchMappings(watchMappings: WatchStoreType['mappings']) {
    watchStore.set('mappings', watchMappings);
}

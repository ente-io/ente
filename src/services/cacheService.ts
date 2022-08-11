import electronService from './electron/common';
import electronCacheService from './electron/cache';
import { logError } from 'utils/sentry';

const THUMB_CACHE = 'thumbs';

export function getCacheProvider() {
    if (electronService.checkIsBundledApp()) {
        return electronCacheService;
    } else {
        return caches;
    }
}

export async function openThumbnailCache() {
    try {
        return await getCacheProvider().open(THUMB_CACHE);
    } catch (e) {
        logError(e, 'openThumbnailCache failed');
        // log and ignore
    }
}

export async function deleteThumbnailCache() {
    try {
        return await getCacheProvider().delete(THUMB_CACHE);
    } catch (e) {
        logError(e, 'deleteThumbnailCache failed');
        // dont throw
    }
}

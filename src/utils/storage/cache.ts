import { CACHES } from 'constants/cache';
import { CacheStorageService } from 'services/cache/cacheStorageService';

export async function deleteThumbnailCache() {
    await CacheStorageService.delete(CACHES.THUMBS);
}

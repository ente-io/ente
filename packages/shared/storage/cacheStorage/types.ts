export interface LimitedCacheStorage {
    open: (
        cacheName: string,
        cacheLimitInBytes?: number
    ) => Promise<LimitedCache>;
    delete: (cacheName: string) => Promise<boolean>;
}

export interface LimitedCache {
    match: (
        key: string,
        options?: { sizeInBytes?: number }
    ) => Promise<Response>;
    put: (key: string, data: Response) => Promise<void>;
    delete: (key: string) => Promise<boolean>;
}

export interface LimitedCacheStorage {
    open: (cacheName: string) => Promise<LimitedCache>;
    delete: (cacheName: string) => Promise<boolean>;
}

export interface LimitedCache {
    match: (key: string) => Promise<Response>;
    put: (key: string, data: Response) => Promise<void>;
    delete: (key: string) => Promise<boolean>;
}

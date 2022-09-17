export interface LimitedCacheStorage {
    open: (cacheName: string) => Promise<LimitedCache>;
    delete: (cacheName: string) => Promise<boolean>;
}

export interface LimitedCache {
    match: (key: string) => Promise<Response>;
    put: (key: string, data: Response) => Promise<void>;
    delete: (key: string) => Promise<boolean>;
}

export interface ProxiedLimitedCacheStorage {
    open: (cacheName: string) => Promise<ProxiedWorkerLimitedCache>;
    delete: (cacheName: string) => Promise<boolean>;
}
export interface ProxiedWorkerLimitedCache {
    match: (key: string) => Promise<ArrayBuffer>;
    put: (key: string, data: ArrayBuffer) => Promise<void>;
    delete: (key: string) => Promise<boolean>;
}

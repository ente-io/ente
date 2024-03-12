export interface LimitedCache {
    match: (
        key: string,
        options?: { sizeInBytes?: number },
    ) => Promise<Response>;
    put: (key: string, data: Response) => Promise<void>;
    delete: (key: string) => Promise<boolean>;
}

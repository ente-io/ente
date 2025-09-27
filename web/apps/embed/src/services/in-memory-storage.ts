/**
 * @file In-memory storage adapter for embed app
 *
 * This provides an in-memory storage implementation that mirrors the localForage
 * interface used by public-albums-fdb. It ensures complete isolation between
 * different iframe embeds by avoiding any persistent storage.
 */

/**
 * In-memory storage adapter that mimics the localForage interface.
 * Uses Maps to store data in memory, providing isolation between embeds.
 */
export class InMemoryStorage {
    private storage = new Map<string, unknown>();

    async getItem<T>(key: string): Promise<T | null> {
        const value = this.storage.get(key);
        return value !== undefined ? (value as T) : null;
    }

    async setItem<T>(key: string, value: T): Promise<T> {
        this.storage.set(key, value);
        return value;
    }

    async removeItem(key: string): Promise<void> {
        this.storage.delete(key);
    }

    async clear(): Promise<void> {
        this.storage.clear();
    }

    async ready(): Promise<void> {
        // Always ready since it's in-memory
        return Promise.resolve();
    }

    async keys(): Promise<string[]> {
        return Array.from(this.storage.keys());
    }

    async length(): Promise<number> {
        return this.storage.size;
    }

    async key(index: number): Promise<string | null> {
        const keys = await this.keys();
        return keys[index] || null;
    }

    // Config method to match localForage interface (no-op for in-memory)
    config(_options: Record<string, unknown>): void {
        // No configuration needed for in-memory storage
    }
}

// Create a singleton instance to be used as the storage backend
export const inMemoryStorage = new InMemoryStorage();
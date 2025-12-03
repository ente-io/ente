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

    getItem(key: string): unknown {
        const value = this.storage.get(key);
        return value !== undefined ? value : null;
    }

    setItem<T>(key: string, value: T): T {
        this.storage.set(key, value);
        return value;
    }

    removeItem(key: string): void {
        this.storage.delete(key);
    }

    clear(): void {
        this.storage.clear();
    }

    ready(): void {
        // Always ready since it's in-memory
    }

    keys(): string[] {
        return Array.from(this.storage.keys());
    }

    length(): number {
        return this.storage.size;
    }

    key(index: number): string | null {
        const keys = this.keys();
        return keys[index] || null;
    }

    // Config method to match localForage interface (no-op for in-memory)
    config(): void {
        // No configuration needed for in-memory storage
    }
}

// Create a singleton instance to be used as the storage backend
export const inMemoryStorage = new InMemoryStorage();

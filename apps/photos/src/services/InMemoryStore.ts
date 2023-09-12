export enum MS_KEYS {
    OPT_OUT_OF_CRASH_REPORTS = 'optOutOfCrashReports',
}

type StoreType = Map<Partial<MS_KEYS>, any>;

class InMemoryStore {
    private store: StoreType = new Map();

    get(key: MS_KEYS) {
        return this.store.get(key);
    }

    set(key: MS_KEYS, value: any) {
        this.store.set(key, value);
    }

    has(key: MS_KEYS) {
        return this.store.has(key);
    }
    clear() {
        this.store.clear();
    }
}

export default new InMemoryStore();

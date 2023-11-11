export enum MS_KEYS {
    OPT_OUT_OF_CRASH_REPORTS = 'optOutOfCrashReports',
    SRP_CONFIGURE_IN_PROGRESS = 'srpConfigureInProgress',
    REDIRECT_URL = 'redirectUrl',
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

    delete(key: MS_KEYS) {
        this.store.delete(key);
    }

    has(key: MS_KEYS) {
        return this.store.has(key);
    }
    clear() {
        this.store.clear();
    }
}

export default new InMemoryStore();

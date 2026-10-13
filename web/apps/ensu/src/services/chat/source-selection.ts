/** Device-local choices for one chat. Stable IDs survive pack updates. */
export interface ChatSourceSelection {
    packIds: string[];
    noteCollectionIds: string[];
}

type SourceKind = keyof ChatSourceSelection;
type SelectionStorage = Pick<Storage, "getItem" | "setItem" | "removeItem">;
const storagePrefix = "ensu.desktop.chatSources.";

const stringIds = (value: unknown): string[] | undefined =>
    Array.isArray(value) && value.every((id) => typeof id === "string")
        ? [...new Set(value)]
        : undefined;

/** Keeps draft identities stable across an asynchronous download or folder add. */
export class ChatSourceSelectionStore {
    private selections = new Map<string, ChatSourceSelection>();
    private destinations = new Map<string, string>();
    private deleted = new Set<string>();

    constructor(
        private storage?: SelectionStorage,
        private onError: (error: unknown) => void = () => undefined,
    ) {}

    private destination(id: string): string {
        return this.destinations.get(id) ?? id;
    }

    get(id: string): ChatSourceSelection | undefined {
        id = this.destination(id);
        if (this.deleted.has(id)) return;
        const cached = this.selections.get(id);
        if (cached) return cached;
        try {
            const raw = this.storage?.getItem(storagePrefix + id);
            if (!raw) return;
            const parsed = JSON.parse(
                raw,
            ) as Partial<ChatSourceSelection> | null;
            const packIds = stringIds(parsed?.packIds);
            const noteCollectionIds = stringIds(parsed?.noteCollectionIds);
            if (!packIds || !noteCollectionIds) return;
            const selection = { packIds, noteCollectionIds };
            this.selections.set(id, selection);
            return selection;
        } catch (error) {
            this.onError(error);
            return;
        }
    }

    private save(id: string, selection: ChatSourceSelection) {
        this.selections.set(id, selection);
        if (id.startsWith("draft:")) return;
        try {
            this.storage?.setItem(
                storagePrefix + id,
                JSON.stringify(selection),
            );
        } catch (error) {
            this.onError(error);
        }
    }

    initialize(id: string, defaults: ChatSourceSelection) {
        id = this.destination(id);
        if (this.deleted.has(id) || this.get(id)) return;
        this.save(id, {
            packIds: [...defaults.packIds],
            noteCollectionIds: [...defaults.noteCollectionIds],
        });
    }

    setEnabled(
        id: string,
        kind: SourceKind,
        sourceId: string,
        enabled: boolean,
    ) {
        id = this.destination(id);
        const current = this.get(id);
        if (!current) return;
        const ids = new Set(current[kind]);
        if (enabled) ids.add(sourceId);
        else ids.delete(sourceId);
        this.save(id, { ...current, [kind]: [...ids] });
    }

    transferDraft(draftId: string, sessionId: string) {
        const selection = this.get(draftId);
        if (!selection) return;
        this.save(sessionId, selection);
        this.destinations.set(draftId, sessionId);
        this.selections.delete(draftId);
    }

    remove(id: string) {
        id = this.destination(id);
        this.deleted.add(id);
        this.selections.delete(id);
        try {
            this.storage?.removeItem(storagePrefix + id);
        } catch (error) {
            this.onError(error);
        }
    }
}

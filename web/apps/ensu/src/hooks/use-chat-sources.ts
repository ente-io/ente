import {
    ChatSourceSelectionStore,
    type ChatSourceSelection,
} from "@/services/chat/source-selection";
import log from "ente-base/log";
import { useCallback, useEffect, useRef, useState } from "react";

export const useChatSources = (
    sessionId: string | undefined,
    defaults: ChatSourceSelection,
    inventoryReady: boolean,
) => {
    const [draftId, setDraftId] = useState("draft:initial");
    const [revision, setRevision] = useState(0);
    const storeRef = useRef<ChatSourceSelectionStore | null>(null);
    if (!storeRef.current) {
        storeRef.current = new ChatSourceSelectionStore(
            typeof window === "undefined" ? undefined : window.localStorage,
            (error) => log.warn("Failed to persist chat sources", error),
        );
    }
    const store = storeRef.current;
    const targetId = sessionId ?? draftId;
    const selection = store.get(targetId);
    useEffect(() => {
        if (!inventoryReady || store.get(targetId)) return;
        store.initialize(targetId, defaults);
        setRevision((value) => value + 1);
    }, [defaults, inventoryReady, revision, store, targetId]);

    const setEnabled = useCallback(
        (
            target: string,
            kind: keyof ChatSourceSelection,
            sourceId: string,
            enabled: boolean,
        ) => {
            store.setEnabled(target, kind, sourceId, enabled);
            setRevision((value) => value + 1);
        },
        [store],
    );
    const transferDraft = useCallback(
        (session: string) => {
            store.transferDraft(draftId, session);
            setRevision((value) => value + 1);
        },
        [draftId, store],
    );
    const resetDraft = useCallback(() => {
        setDraftId(`draft:${crypto.randomUUID()}`);
    }, []);
    const removeSelection = useCallback(
        (session: string) => {
            store.remove(session);
            setRevision((value) => value + 1);
        },
        [store],
    );
    return {
        selection,
        targetId,
        setEnabled,
        transferDraft,
        resetDraft,
        removeSelection,
    };
};

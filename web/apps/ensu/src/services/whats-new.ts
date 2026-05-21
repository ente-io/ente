import { isTauriAppRuntime } from "services/secure-storage";
import {
    whatsNewEntries,
    whatsNewVersion,
    type WhatsNewEntry,
} from "services/whats-new-content";

const storageKey = "ensu.whatsNew.seenVersion";

export interface PendingDesktopWhatsNew {
    readonly version: number;
    readonly entries: readonly WhatsNewEntry[];
}

export const getPendingDesktopWhatsNew = ():
    | PendingDesktopWhatsNew
    | undefined => {
    if (!isTauriAppRuntime()) return undefined;

    const seenVersion = readSeenVersion();
    if (seenVersion >= whatsNewVersion) return undefined;

    if (whatsNewEntries.length === 0) {
        markDesktopWhatsNewSeen();
        return undefined;
    }

    return { version: whatsNewVersion, entries: whatsNewEntries };
};

export const markDesktopWhatsNewSeen = () => {
    if (!isTauriAppRuntime()) return;

    try {
        window.localStorage.setItem(storageKey, String(whatsNewVersion));
    } catch {
        // localStorage can be unavailable in constrained webviews. In that
        // case, avoid blocking app startup or showing the dialog repeatedly.
    }
};

const readSeenVersion = () => {
    try {
        const rawValue = window.localStorage.getItem(storageKey);
        if (rawValue === null) return 0;

        const parsed = Number(rawValue);
        if (Number.isInteger(parsed) && parsed > 0) return parsed;
    } catch {
        return whatsNewVersion;
    }

    markDesktopWhatsNewSeen();
    return whatsNewVersion;
};

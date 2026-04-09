import { useCallback, useEffect, useMemo, useSyncExternalStore } from "react";
import {
    clientPackageName,
    desktopAppVersion,
    isDesktop,
} from "ente-base/app";
import log from "ente-base/log";
import { apiOrigin } from "ente-base/origins";
import { savedAuthToken } from "ente-base/token";
import {
    contacts_open_ctx,
    type ContactsCtxHandle,
} from "ente-wasm";
import {
    saveContactDisplayRecords,
    saveContactsSinceTime,
    saveWrappedRootContactKey,
    savedContactDisplayRecords,
    savedContactsSinceTime,
    savedWrappedRootContactKey,
} from "./db";
import {
    knownEmailOrUndefined,
    normalizeEmail,
    resolveContactDisplayFromSnapshot,
} from "./resolver";
import type {
    ContactDisplayRecord,
    ContactLookup,
    ContactsDisplaySnapshot,
    ResolvedContactAvatar,
    ResolvedContactDisplay,
    WrappedRootContactKey,
} from "./types";

const CONTACT_DIFF_LIMIT = 500;
const AVATAR_FAILURE_TTL_MS = 60_000;
const READY_RETRY_COOLDOWN_MS = 5_000;
const CONTACTS_CACHE_SCHEMA_VERSION = 2;

type RemoteContactRecord = {
    id: string;
    contactUserId: number | bigint;
    email?: string | null;
    name?: string | null;
    profilePictureAttachmentID?: string | null;
    profilePictureAttachmentId?: string | null;
    isDeleted: boolean;
    updatedAt: number | bigint;
};

type ContactsReadyInput = {
    userID: number;
    masterKeyB64: string;
};

type ContactsState = {
    snapshot: ContactsDisplaySnapshot;
    listeners: Set<() => void>;
    currentSessionKey: string | undefined;
    currentAuthToken: string | undefined;
    ctx: ContactsCtxHandle | undefined;
    readyPromise: Promise<void> | undefined;
    contactsByID: Map<string, ContactDisplayRecord>;
    contactIDByUserID: Map<number, string>;
    contactIDByEmail: Map<string, string>;
    avatarURLByContactID: Map<string, string>;
    avatarLoadsByContactID: Map<string, Promise<void>>;
    avatarFailureUntilByContactID: Map<string, number>;
    avatarListenersByContactID: Map<string, Set<() => void>>;
    lastReadyInput: ContactsReadyInput | undefined;
    retryTimer: ReturnType<typeof setTimeout> | undefined;
};

const emptySnapshot = (): ContactsDisplaySnapshot => ({
    isHydrated: false,
    recordsByUserID: new Map(),
    recordsByEmail: new Map(),
    avatarURLsByContactID: new Map(),
});

const state: ContactsState = {
    snapshot: emptySnapshot(),
    listeners: new Set(),
    currentSessionKey: undefined,
    currentAuthToken: undefined,
    ctx: undefined,
    readyPromise: undefined,
    contactsByID: new Map(),
    contactIDByUserID: new Map(),
    contactIDByEmail: new Map(),
    avatarURLByContactID: new Map(),
    avatarLoadsByContactID: new Map(),
    avatarFailureUntilByContactID: new Map(),
    avatarListenersByContactID: new Map(),
    lastReadyInput: undefined,
    retryTimer: undefined,
};

const buildSessionKey = (baseURL: string, userID: number) =>
    `${encodeURIComponent(baseURL)}:${userID}:v${CONTACTS_CACHE_SCHEMA_VERSION}`;

const emitAvatarURL = (contactID: string) => {
    const listeners = state.avatarListenersByContactID.get(contactID);
    if (!listeners) {
        return;
    }
    for (const listener of listeners) {
        listener();
    }
};

const cleanupAvatarURL = (contactID: string, shouldEmit = false) => {
    const current = state.avatarURLByContactID.get(contactID);
    if (current) {
        URL.revokeObjectURL(current);
        state.avatarURLByContactID.delete(contactID);
        if (shouldEmit) {
            emitAvatarURL(contactID);
        }
    }
    state.avatarLoadsByContactID.delete(contactID);
    state.avatarFailureUntilByContactID.delete(contactID);
};

const clearInMemoryState = () => {
    for (const avatarURL of state.avatarURLByContactID.values()) {
        URL.revokeObjectURL(avatarURL);
    }
    state.ctx = undefined;
    state.currentAuthToken = undefined;
    state.readyPromise = undefined;
    state.contactsByID = new Map();
    state.contactIDByUserID = new Map();
    state.contactIDByEmail = new Map();
    state.avatarURLByContactID = new Map();
    state.avatarLoadsByContactID = new Map();
    state.avatarFailureUntilByContactID = new Map();
    if (state.retryTimer) {
        clearTimeout(state.retryTimer);
        state.retryTimer = undefined;
    }
};

const emitSnapshot = (isHydrated = true) => {
    state.snapshot = {
        isHydrated,
        recordsByUserID: new Map(
            [...state.contactIDByUserID.entries()]
                .map(([userID, contactID]) => [
                    userID,
                    state.contactsByID.get(contactID),
                ])
                .filter(
                    (entry): entry is [number, ContactDisplayRecord] =>
                        entry[1] !== undefined,
                ),
        ),
        recordsByEmail: new Map(
            [...state.contactIDByEmail.entries()]
                .map(([email, contactID]) => [
                    email,
                    state.contactsByID.get(contactID),
                ])
                .filter(
                    (entry): entry is [string, ContactDisplayRecord] =>
                        entry[1] !== undefined,
                ),
        ),
        avatarURLsByContactID: new Map(state.avatarURLByContactID),
    };

    for (const listener of state.listeners) {
        listener();
    }
};

const removeContact = (contactID: string) => {
    const previous = state.contactsByID.get(contactID);
    if (!previous) return;

    state.contactsByID.delete(contactID);
    state.contactIDByUserID.delete(previous.contactUserId);
    const normalizedEmail = normalizeEmail(previous.resolvedEmail);
    if (normalizedEmail) {
        state.contactIDByEmail.delete(normalizedEmail);
    }
    cleanupAvatarURL(contactID, true);
};

const upsertContact = (record: ContactDisplayRecord) => {
    const previous = state.contactsByID.get(record.contactId);
    if (previous) {
        if (previous.contactUserId !== record.contactUserId) {
            state.contactIDByUserID.delete(previous.contactUserId);
        }
        const previousEmail = normalizeEmail(previous.resolvedEmail);
        const nextEmail = normalizeEmail(record.resolvedEmail);
        if (previousEmail && previousEmail !== nextEmail) {
            state.contactIDByEmail.delete(previousEmail);
        }
        if (
            previous.profilePictureAttachmentID !==
            record.profilePictureAttachmentID
        ) {
            cleanupAvatarURL(record.contactId, true);
        }
    }

    state.contactsByID.set(record.contactId, record);
    state.contactIDByUserID.set(record.contactUserId, record.contactId);

    const normalizedEmail = normalizeEmail(record.resolvedEmail);
    if (normalizedEmail) {
        state.contactIDByEmail.set(normalizedEmail, record.contactId);
    }
};

const contactDisplayRecordFromRemote = (
    record: RemoteContactRecord,
): ContactDisplayRecord => ({
    contactId: record.id,
    contactUserId: Number(record.contactUserId),
    resolvedEmail: knownEmailOrUndefined(record.email),
    displayName: knownEmailOrUndefined(record.name),
    profilePictureAttachmentID:
        knownEmailOrUndefined(
            record.profilePictureAttachmentID ??
                record.profilePictureAttachmentId,
        ),
    updatedAt: Number(record.updatedAt),
});

export const resolveContactDisplay = (
    lookup: ContactLookup,
): ResolvedContactDisplay =>
    resolveContactDisplayFromSnapshot(state.snapshot, lookup);

export const resolveKnownEmail = (lookup: ContactLookup) =>
    resolveContactDisplay(lookup).actualEmail;

export const contactsDisplaySubscribe = (onChange: () => void) => {
    state.listeners.add(onChange);
    return () => {
        state.listeners.delete(onChange);
    };
};

const subscribeAvatarURL = (contactID: string, onChange: () => void) => {
    const listeners =
        state.avatarListenersByContactID.get(contactID) ?? new Set<() => void>();
    listeners.add(onChange);
    state.avatarListenersByContactID.set(contactID, listeners);
    return () => {
        listeners.delete(onChange);
        if (listeners.size === 0) {
            state.avatarListenersByContactID.delete(contactID);
        }
    };
};

const avatarURLSnapshot = (contactID: string | undefined) =>
    contactID ? state.avatarURLByContactID.get(contactID) : undefined;

export const contactsDisplaySnapshot = () => state.snapshot;

const useContactsSnapshot = () =>
    useSyncExternalStore(
        contactsDisplaySubscribe,
        contactsDisplaySnapshot,
        contactsDisplaySnapshot,
    );

const loadLocalSessionState = async (sessionKey: string) => {
    clearInMemoryState();
    state.currentSessionKey = sessionKey;

    const savedRecords = await savedContactDisplayRecords(sessionKey);
    for (const record of savedRecords) {
        upsertContact(record);
    }

    emitSnapshot(true);
};

const syncContacts = async ({
    sessionKey,
    baseURL,
    authToken,
    userID,
    masterKeyB64,
}: ContactsReadyInput & {
    sessionKey: string;
    baseURL: string;
    authToken: string;
}) => {
    if (!state.ctx) {
        state.ctx = await contacts_open_ctx({
            baseUrl: baseURL,
            authToken,
            userId: userID,
            masterKeyB64,
            cachedRootKey: await savedWrappedRootContactKey(sessionKey),
            userAgent: globalThis.navigator?.userAgent,
            clientPackage: clientPackageName,
            clientVersion: isDesktop ? desktopAppVersion : undefined,
        });
        const wrappedRootKey =
            state.ctx.current_wrapped_root_key() as WrappedRootContactKey;
        await saveWrappedRootContactKey(sessionKey, wrappedRootKey);
    } else if (state.currentAuthToken !== authToken) {
        state.ctx.update_auth_token(authToken);
    }

    if (!state.ctx || state.currentSessionKey !== sessionKey) {
        return;
    }

    const ctx = state.ctx;
    state.currentAuthToken = authToken;

    let sinceTime = (await savedContactsSinceTime(sessionKey)) ?? 0;
    let didChange = false;

    while (true) {
        const diff = (await ctx.get_diff(
            BigInt(sinceTime),
            CONTACT_DIFF_LIMIT,
        )) as RemoteContactRecord[];
        if (state.currentSessionKey !== sessionKey) {
            return;
        }
        if (diff.length === 0) {
            break;
        }

        didChange = true;
        for (const record of diff) {
            if (record.isDeleted) {
                removeContact(record.id);
            } else {
                upsertContact(contactDisplayRecordFromRemote(record));
            }
            sinceTime = Math.max(sinceTime, Number(record.updatedAt));
        }
    }

    if (didChange) {
        if (state.currentSessionKey !== sessionKey) {
            return;
        }
        await saveContactDisplayRecords(
            sessionKey,
            [...state.contactsByID.values()],
        );
        await saveContactsSinceTime(sessionKey, sinceTime);
        emitSnapshot(true);
    }
};

export const ensureContactsReady = async ({
    userID,
    masterKeyB64,
}: ContactsReadyInput) => {
    state.lastReadyInput = { userID, masterKeyB64 };
    const authToken = await savedAuthToken();
    if (!authToken) {
        return;
    }

    const baseURL = await apiOrigin();
    const sessionKey = buildSessionKey(baseURL, userID);

    if (state.currentSessionKey !== sessionKey) {
        await loadLocalSessionState(sessionKey);
    }

    if (state.readyPromise) {
        return state.readyPromise;
    }

    state.readyPromise = syncContacts({
        sessionKey,
        baseURL,
        authToken,
        userID,
        masterKeyB64,
    })
        .then(() => {
            if (state.retryTimer) {
                clearTimeout(state.retryTimer);
                state.retryTimer = undefined;
            }
        })
        .catch((error) => {
            if (state.retryTimer) {
                clearTimeout(state.retryTimer);
            }
            const retryInput = state.lastReadyInput;
            state.retryTimer = setTimeout(() => {
                state.retryTimer = undefined;
                if (retryInput) {
                    void ensureContactsReady(retryInput).catch(() => undefined);
                }
            }, READY_RETRY_COOLDOWN_MS);
            throw error;
        })
        .finally(() => {
            state.readyPromise = undefined;
        });

    return state.readyPromise;
};

const inferImageMimeType = (bytes: Uint8Array) => {
    if (
        bytes.length >= 12 &&
        bytes[0] === 0x52 &&
        bytes[1] === 0x49 &&
        bytes[2] === 0x46 &&
        bytes[3] === 0x46 &&
        bytes[8] === 0x57 &&
        bytes[9] === 0x45 &&
        bytes[10] === 0x42 &&
        bytes[11] === 0x50
    ) {
        return "image/webp";
    }
    if (
        bytes.length >= 8 &&
        bytes[0] === 0x89 &&
        bytes[1] === 0x50 &&
        bytes[2] === 0x4e &&
        bytes[3] === 0x47 &&
        bytes[4] === 0x0d &&
        bytes[5] === 0x0a &&
        bytes[6] === 0x1a &&
        bytes[7] === 0x0a
    ) {
        return "image/png";
    }
    if (bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
        return "image/jpeg";
    }
    if (
        bytes.length >= 6 &&
        bytes[0] === 0x47 &&
        bytes[1] === 0x49 &&
        bytes[2] === 0x46 &&
        bytes[3] === 0x38
    ) {
        return "image/gif";
    }
    return "application/octet-stream";
};

const ensureProfilePictureLoaded = async (contactID: string) => {
    const contact = state.contactsByID.get(contactID);
    if (!contact?.profilePictureAttachmentID || !state.ctx) {
        return;
    }

    if (state.avatarURLByContactID.has(contactID)) {
        return;
    }

    const failureUntil = state.avatarFailureUntilByContactID.get(contactID);
    if (failureUntil && failureUntil > Date.now()) {
        return;
    }

    const existingLoad = state.avatarLoadsByContactID.get(contactID);
    if (existingLoad) {
        await existingLoad;
        return;
    }

    const load = state.ctx
        .get_profile_picture(contactID)
        .then((bytes: Uint8Array) => {
            const blob = new Blob([bytes], {
                type: inferImageMimeType(bytes),
            });
            const url = URL.createObjectURL(blob);
            cleanupAvatarURL(contactID);
            state.avatarURLByContactID.set(contactID, url);
            state.avatarFailureUntilByContactID.delete(contactID);
            emitAvatarURL(contactID);
        })
        .catch((error: unknown) => {
            state.avatarFailureUntilByContactID.set(
                contactID,
                Date.now() + AVATAR_FAILURE_TTL_MS,
            );
            log.info(
                `[contacts] Failed to load contact profile picture for ${contactID}`,
                error,
            );
        })
        .finally(() => {
            state.avatarLoadsByContactID.delete(contactID);
        });

    state.avatarLoadsByContactID.set(contactID, load);
    await load;
};

export const __testing = {
    preloadResolvedContactAvatar: async (lookup: ContactLookup) => {
        const display = resolveContactDisplay(lookup);
        if (!display.contactId || !display.profilePictureAttachmentID) {
            return;
        }
        await ensureProfilePictureLoaded(display.contactId);
    },
};

export const useResolvedContactDisplay = (lookup: ContactLookup) => {
    const snapshot = useContactsSnapshot();
    return useMemo(
        () => resolveContactDisplayFromSnapshot(snapshot, lookup),
        [lookup.email, lookup.userID, snapshot],
    );
};

export const useResolvedContactAvatar = (
    lookup: ContactLookup,
): ResolvedContactAvatar => {
    const snapshot = useContactsSnapshot();
    const display = useMemo(
        () => resolveContactDisplayFromSnapshot(snapshot, lookup),
        [lookup.email, lookup.userID, snapshot],
    );
    const avatarURL = useSyncExternalStore(
        useCallback(
            (onChange: () => void) =>
                display.contactId
                    ? subscribeAvatarURL(display.contactId, onChange)
                    : () => undefined,
            [display.contactId],
        ),
        () => avatarURLSnapshot(display.contactId),
        () => avatarURLSnapshot(display.contactId),
    );

    useEffect(() => {
        if (!display.contactId || !display.profilePictureAttachmentID) {
            return;
        }
        void ensureProfilePictureLoaded(display.contactId);
    }, [display.contactId, display.profilePictureAttachmentID]);

    return {
        ...display,
        avatarURL,
    };
};

import { beforeEach, describe, expect, test, vi } from "vitest";
import { resolveContactDisplayFromSnapshot } from "./resolver";
import type { ContactsDisplaySnapshot } from "./types";

const makeSnapshot = (): ContactsDisplaySnapshot => ({
    isHydrated: true,
    recordsByUserID: new Map([
        [
            101,
            {
                contactId: "c_1",
                contactUserId: 101,
                resolvedEmail: "set@test.test",
                displayName: "Set",
                profilePictureAttachmentID: "a_1",
                updatedAt: 1,
            },
        ],
    ]),
    recordsByEmail: new Map([
        [
            "set@test.test",
            {
                contactId: "c_1",
                contactUserId: 101,
                resolvedEmail: "set@test.test",
                displayName: "Set",
                profilePictureAttachmentID: "a_1",
                updatedAt: 1,
            },
        ],
    ]),
    avatarURLsByContactID: new Map(),
});

describe("resolveContactDisplayFromSnapshot", () => {
    test("prefers contact name by user id", () => {
        const resolved = resolveContactDisplayFromSnapshot(makeSnapshot(), {
            userID: 101,
            email: "set@test.test",
        });

        expect(resolved.primaryLabel).toBe("Set");
        expect(resolved.actualEmail).toBe("set@test.test");
        expect(resolved.source).toBe("contact");
    });

    test("falls back to email when no contact exists", () => {
        const resolved = resolveContactDisplayFromSnapshot(makeSnapshot(), {
            email: "other@test.test",
        });

        expect(resolved.primaryLabel).toBe("other@test.test");
        expect(resolved.actualEmail).toBe("other@test.test");
        expect(resolved.source).toBe("fallback");
    });

    test("returns an empty label when no user or email exists", () => {
        const resolved = resolveContactDisplayFromSnapshot(makeSnapshot(), {});

        expect(resolved.primaryLabel).toBe("");
        expect(resolved.initial).toBe("?");
        expect(resolved.source).toBe("fallback");
    });
});

beforeEach(() => {
    vi.resetModules();
    vi.clearAllMocks();
    vi.useRealTimers();
});

interface SetupOptions {
    diff?: object[];
    getProfilePictureError?: Error;
    getProfilePictureBytes?: Uint8Array;
}

const setupContactsModule = async (options: SetupOptions = {}) => {
    const kv = new Map<string, unknown>();
    const setKV = vi.fn((key: string, value: unknown) => {
        kv.set(key, JSON.parse(JSON.stringify(value)));
    });
    const getKV = vi.fn((key: string) => kv.get(key));
    const getKVN = vi.fn((key: string) => {
        const value = kv.get(key);
        return typeof value === "number" ? value : undefined;
    });

    const savedAuthToken = vi.fn(() => "auth-token-secret");
    const apiOrigin = vi.fn(() => "https://api.example");
    const info = vi.fn();
    const warn = vi.fn();
    const error = vi.fn();
    const update_auth_token = vi.fn();
    const current_wrapped_root_key = vi.fn(() => ({
        encryptedKey: "wrapped-root-key",
        header: "wrapped-header",
    }));

    const diff = options.diff ?? [
        {
            id: "ct_1",
            contactUserId: 101,
            email: "set@test.test",
            name: "Set",
            profilePictureAttachmentID: "ua_1",
            isDeleted: false,
            updatedAt: 1,
        },
    ];

    const get_diff = vi
        .fn()
        .mockResolvedValueOnce(diff)
        .mockResolvedValueOnce([]);
    const get_profile_picture = vi.fn(() => {
        if (options.getProfilePictureBytes) {
            return Promise.resolve(options.getProfilePictureBytes);
        }
        return Promise.reject(
            options.getProfilePictureError ?? new Error("boom"),
        );
    });

    vi.doMock("ente-base/kv", () => ({ getKV, getKVN, setKV }));
    vi.doMock("ente-base/token", () => ({ savedAuthToken }));
    vi.doMock("ente-base/origins", () => ({ apiOrigin }));
    vi.doMock("ente-base/log", () => ({ default: { info, warn, error } }));
    vi.doMock("ente-base/app", () => ({
        appName: "photos",
        clientPackageName: "io.ente.photos.web",
        desktopAppVersion: undefined,
        isDesktop: false,
    }));
    vi.doMock("ente-wasm", () => ({
        contacts_open_ctx: vi.fn(() => ({
            update_auth_token,
            current_wrapped_root_key,
            get_diff,
            get_profile_picture,
        })),
    }));

    const contacts = await import("./index");

    return { contacts, setKV, get_diff, get_profile_picture, info };
};

describe("ensureContactsReady", () => {
    test("does not persist auth token or master key in contacts kv", async () => {
        const { contacts, setKV } = await setupContactsModule();

        await contacts.ensureContactsReady({
            userID: 101,
            masterKeyB64: "MASTER_KEY_SHOULD_NOT_PERSIST",
        });

        const persisted = setKV.mock.calls
            .map(([key, value]) => `${String(key)}:${JSON.stringify(value)}`)
            .join("\n");

        expect(persisted).toContain("contacts/");
        expect(persisted).toContain("wrapped-root-key");
        expect(persisted).toContain("Set");
        expect(persisted).not.toContain("MASTER_KEY_SHOULD_NOT_PERSIST");
        expect(persisted).not.toContain("auth-token-secret");

        const resolved = contacts.resolveContactDisplay({ userID: 101 });
        expect(resolved.profilePictureAttachmentID).toBe("ua_1");
    });
});

describe("profile picture loading", () => {
    test("negative-caches failed profile picture fetches and logs at info", async () => {
        const { contacts, get_profile_picture, info } =
            await setupContactsModule({
                getProfilePictureError: new Error("network failure"),
            });

        await contacts.ensureContactsReady({
            userID: 101,
            masterKeyB64: "ignored",
        });

        await contacts.__testing.preloadResolvedContactAvatar({
            userID: 101,
            email: "set@test.test",
        });
        await contacts.__testing.preloadResolvedContactAvatar({
            userID: 101,
            email: "set@test.test",
        });

        expect(get_profile_picture).toHaveBeenCalledTimes(1);
        expect(info).toHaveBeenCalledTimes(1);
        expect(info.mock.calls[0]?.[0]).toContain(
            "Failed to load contact profile picture for ct_1",
        );
    });

    test("uses the inferred image mime type for avatar blobs", async () => {
        const createObjectURL = vi.fn((blob: Blob) => {
            void blob;
            return "blob:contact";
        });
        vi.stubGlobal("URL", { createObjectURL, revokeObjectURL: vi.fn() });
        const pngBytes = Uint8Array.from([
            0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00,
            0x0d,
        ]);
        const { contacts } = await setupContactsModule({
            getProfilePictureBytes: pngBytes,
        });

        await contacts.ensureContactsReady({
            userID: 101,
            masterKeyB64: "ignored",
        });
        await contacts.__testing.preloadResolvedContactAvatar({ userID: 101 });

        const blobArg = createObjectURL.mock.calls[0]?.[0];
        expect(blobArg?.type).toBe("image/png");
    });
});

describe("retry after warm-up failure", () => {
    test("retries with the last ready input after a transient failure", async () => {
        vi.useFakeTimers();
        const { contacts, get_diff } = await setupContactsModule();
        get_diff.mockReset();
        get_diff
            .mockRejectedValueOnce(new Error("transient"))
            .mockResolvedValueOnce([
                {
                    id: "ct_1",
                    contactUserId: 101,
                    email: "set@test.test",
                    name: "Set",
                    profilePictureAttachmentID: "ua_1",
                    isDeleted: false,
                    updatedAt: 1,
                },
            ])
            .mockResolvedValueOnce([]);

        await expect(
            contacts.ensureContactsReady({
                userID: 101,
                masterKeyB64: "ignored",
            }),
        ).rejects.toThrow("transient");
        await vi.advanceTimersByTimeAsync(5_001);

        expect(get_diff).toHaveBeenCalledTimes(3);
    });
});

// @vitest-environment happy-dom
import { CollectionSubType, type Collection } from "ente-media/collection";
import { act } from "react";
import { createRoot, type Root } from "react-dom/client";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import { usePublicLinkManagement } from "../src/components/share/usePublicLinkManagement";
import { useResolvedPublicLinkURL } from "../src/components/share/useResolvedPublicLinkURL";

const mocks = vi.hoisted(() => ({
    update: vi.fn(),
    remove: vi.fn(),
    removeURL: vi.fn(),
    layout: vi.fn(),
    restricted: vi.fn(),
    appendKey: vi.fn(),
    settings: { customDomain: undefined as string | undefined },
}));
vi.mock("ente-new/photos/services/collection", () => ({
    updatePublicURL: mocks.update,
    deleteCollection: mocks.remove,
    deleteShareURL: mocks.removeURL,
    updateCollectionLayout: mocks.layout,
}));
vi.mock("ente-base/http", () => ({ isMuseumHTTPError: mocks.restricted }));
vi.mock("ente-base/crypto", () => ({
    decryptBoxBytes: vi.fn(),
    decryptMetadataJSON: vi.fn(),
    encryptMetadataJSON: vi.fn(),
}));
vi.mock("ente-base/log", () => ({ default: { error: vi.fn() } }));
vi.mock("i18next", () => ({ t: (key: string) => key }));
vi.mock("ente-gallery/services/share", () => ({
    appendCollectionKeyToShareURL: mocks.appendKey,
}));
vi.mock("ente-new/photos/components/utils/use-snapshot", () => ({
    useSettingsSnapshot: () => mocks.settings,
}));

const collection = (id = 1): Collection => ({
    id,
    name: `Link ${id}`,
    type: "album",
    owner: { id: 1 },
    key: `key-${id}`,
    sharees: [],
    updationTime: id,
    magicMetadata: {
        version: 1,
        count: 1,
        data: { subType: CollectionSubType.quicklink },
    },
    publicURLs: [
        {
            url: `https://albums.ente.com/?t=${id}`,
            validTill: 0,
            deviceLimit: 0,
            enableDownload: true,
            enableCollect: false,
            enableComment: false,
            enableJoin: false,
            passwordEnabled: false,
        },
    ],
});
const deferred = <T,>() => {
    let resolve!: (value: T) => void;
    const promise = new Promise<T>((r) => {
        resolve = r;
    });
    return { promise, resolve };
};

const flush = async (callback: () => void | Promise<void>) => {
    await act(async () => {
        await callback();
    });
};

let root: Root;
let host: HTMLDivElement;
beforeEach(() => {
    vi.resetAllMocks();
    mocks.settings.customDomain = undefined;
    mocks.restricted.mockResolvedValue(false);
    mocks.update.mockResolvedValue(collection().publicURLs[0]);
    mocks.appendKey.mockImplementation((url: string, key: string) =>
        Promise.resolve(`${url}#${key}`),
    );
    Object.assign(globalThis, { IS_REACT_ACT_ENVIRONMENT: true });
    host = document.createElement("div");
    document.body.append(host);
    root = createRoot(host);
});
afterEach(async () => {
    await flush(() => root.unmount());
    host.remove();
});

const startManagement = async (item = collection()) => {
    const props = {
        collection: item,
        setPublicURL: vi.fn(),
        setBlockingLoad: vi.fn(),
        onRemotePull: vi.fn().mockResolvedValue(undefined),
        onRemove: vi.fn(),
        onLinkRemoved: vi.fn(),
    };
    let result!: ReturnType<typeof usePublicLinkManagement>;
    const Subject = ({ value }: { value: typeof props }) => {
        result = usePublicLinkManagement(value);
        return null;
    };
    const render = async (value = props) => {
        await flush(() =>
            root.render(<Subject key={value.collection.id} value={value} />),
        );
    };
    await render();
    return { props, render, current: () => result };
};

describe("shared public link management", () => {
    test("uses the returned settings and prevents duplicate or competing mutations", async () => {
        const pending =
            deferred<ReturnType<typeof collection>["publicURLs"][number]>();
        mocks.update.mockReturnValue(pending.promise);
        const subject = await startManagement();
        let save!: Promise<boolean>;
        await flush(() => {
            save = subject.current().onUpdate({ enableDownload: false });
        });
        expect(subject.current().isSaving).toBe(true);
        expect(await subject.current().onUpdateLayout("trip")).toBe(false);
        expect(await subject.current().onRemoveLink()).toBe(false);
        expect(mocks.layout).not.toHaveBeenCalled();
        expect(mocks.remove).not.toHaveBeenCalled();
        const result = {
            ...collection().publicURLs[0]!,
            enableDownload: false,
        };
        await flush(async () => {
            pending.resolve(result);
            expect(await save).toBe(true);
        });
        expect(mocks.update).toHaveBeenCalledExactlyOnceWith(1, {
            enableDownload: false,
        });
        expect(subject.props.setPublicURL).toHaveBeenCalledExactlyOnceWith(
            result,
        );
        expect(subject.props.onRemotePull).toHaveBeenCalledExactlyOnceWith({
            silent: true,
        });
        expect(subject.current().isSaving).toBe(false);
        expect(subject.props.setBlockingLoad.mock.calls).toEqual([
            [true],
            [false],
        ]);
    });

    test.each([false, true])(
        "retains the saved values on an error (restricted=%s)",
        async (restricted) => {
            mocks.update.mockRejectedValue(new Error("failed"));
            mocks.restricted.mockResolvedValue(restricted);
            const subject = await startManagement();
            await flush(async () => {
                expect(
                    await subject.current().onUpdate({ enableCollect: true }),
                ).toBe(false);
            });
            expect(subject.props.setPublicURL).not.toHaveBeenCalled();
            expect(subject.current().errorMessage).toBe(
                restricted
                    ? "link_edit_disabled_for_free_accounts"
                    : "generic_error",
            );
            expect(subject.current().isSaving).toBe(false);
        },
    );

    test("a response for a previous selection cannot update the current settings", async () => {
        const pending = deferred<Collection["publicURLs"][number]>();
        mocks.update.mockReturnValue(pending.promise);
        const subject = await startManagement();
        let save!: Promise<boolean>;
        await flush(() => {
            save = subject.current().onUpdate({ deviceLimit: 5 });
        });
        const next = {
            ...subject.props,
            collection: collection(2),
            setPublicURL: vi.fn(),
        };
        await subject.render(next);
        await flush(async () => {
            pending.resolve(collection().publicURLs[0]!);
            await save;
        });
        expect(subject.props.setPublicURL).not.toHaveBeenCalled();
        expect(next.setPublicURL).not.toHaveBeenCalled();
        expect(subject.current().isSaving).toBe(false);
        expect(subject.current().errorMessage).toBe("");
    });

    test.each(["quick", "album", "shared-quick"])(
        "removes a %s link using the appropriate service",
        async (kind) => {
            const item = collection();
            if (kind === "album") item.magicMetadata = undefined;
            if (kind === "shared-quick") item.sharees = [{ id: 2 }];
            const subject = await startManagement(item);
            await flush(async () => {
                expect(await subject.current().onRemoveLink()).toBe(true);
            });
            if (kind === "quick") {
                expect(mocks.remove).toHaveBeenCalledExactlyOnceWith(1, {
                    keepFiles: true,
                });
                expect(mocks.removeURL).not.toHaveBeenCalled();
            } else {
                expect(mocks.removeURL).toHaveBeenCalledExactlyOnceWith(1);
                expect(mocks.remove).not.toHaveBeenCalled();
            }
            expect(subject.props.onLinkRemoved).toHaveBeenCalledExactlyOnceWith(
                1,
            );
            expect(subject.props.onRemove).toHaveBeenCalledExactlyOnceWith(
                kind === "quick",
            );
        },
    );

    test("failed removal keeps the link and does not trigger navigation", async () => {
        mocks.remove.mockRejectedValue(new Error("offline"));
        const subject = await startManagement();
        await flush(async () => {
            expect(await subject.current().onRemoveLink()).toBe(false);
        });
        expect(subject.props.onLinkRemoved).not.toHaveBeenCalled();
        expect(subject.props.onRemove).not.toHaveBeenCalled();
        expect(subject.props.setPublicURL).not.toHaveBeenCalled();
    });

    test("a refresh failure does not undo a successful save", async () => {
        const subject = await startManagement();
        subject.props.onRemotePull.mockRejectedValue(new Error("offline"));
        await flush(async () => {
            expect(await subject.current().onUpdateLayout("trip")).toBe(true);
        });
        expect(mocks.layout).toHaveBeenCalledExactlyOnceWith(
            subject.props.collection,
            "trip",
        );
        expect(subject.current().errorMessage).toBe("");
    });
});

describe("resolved public link URLs", () => {
    test("keeps the client-side key and uses custom domains only for managed links", async () => {
        mocks.settings.customDomain = "photos.example.com";
        let resolved: string | undefined;
        const Subject = ({ canManage }: { canManage: boolean }) => {
            const item = collection();
            resolved = useResolvedPublicLinkURL(
                item,
                item.publicURLs[0],
                canManage,
            );
            return null;
        };
        await flush(() => root.render(<Subject canManage />));
        expect(resolved).toBe("https://photos.example.com/?t=1#key-1");
        await flush(() => root.render(<Subject canManage={false} />));
        expect(resolved).toBe("https://albums.ente.com/?t=1#key-1");
    });

    test("ignores a slow URL resolution for a previous selection", async () => {
        const first = deferred<string>();
        const second = deferred<string>();
        mocks.appendKey
            .mockReturnValueOnce(first.promise)
            .mockReturnValueOnce(second.promise);
        let resolved: string | undefined;
        const Subject = ({ id }: { id: number }) => {
            const item = collection(id);
            resolved = useResolvedPublicLinkURL(item, item.publicURLs[0], true);
            return null;
        };
        await flush(() => root.render(<Subject id={1} />));
        await flush(() => root.render(<Subject id={2} />));
        await flush(() => {
            second.resolve("https://albums.ente.com/?t=2#key-2");
        });
        await flush(() => {
            first.resolve("https://albums.ente.com/?t=1#key-1");
        });
        expect(resolved).toBe("https://albums.ente.com/?t=2#key-2");
    });
});

import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { expect, test, vi } from "vitest";
import { useCreateItemDialogState } from "../src/components/create-item/use-create-item-dialog-state";
import type { LockerItemType } from "../src/types";

vi.mock("ente-accounts/services/accounts-db", () => ({
    savedLocalUser: () => ({ id: 1 }),
}));
vi.mock("@/types", async () => import("../src/types"));
vi.mock("ente-base/log", () => ({ default: { error: vi.fn() } }));
vi.mock("i18next", () => ({ t: (key: string) => key }));
vi.mock("@/services/locker-errors", () => ({
    formatLockerMutationError: vi.fn(),
    lockerUpgradeCTAType: vi.fn(),
}));
vi.mock("../src/components/create-item/use-upload-queue", () => ({
    useUploadQueue: () => ({
        uploading: false,
        completedFileKeys: new Set(),
        failedFileKeys: new Set(),
        uploadingFileKeys: new Set(),
        uploadProgressByFileKey: {},
        uploadCapByFileKey: {},
        resetUploadState: vi.fn(),
        upload: vi.fn(),
    }),
}));

const formState = (type: LockerItemType, data: Record<string, string>) => {
    const onSave = vi.fn<() => Promise<void>>().mockResolvedValue(undefined);
    const onClose = vi.fn();
    let state!: ReturnType<typeof useCreateItemDialogState>;
    function Probe() {
        state = useCreateItemDialogState({
            open: true,
            collections: [
                {
                    id: 2,
                    name: "Test",
                    owner: { id: 1 },
                    sharees: [],
                    items: [],
                    type: "folder",
                    isShared: false,
                },
            ],
            editItem: {
                id: 1,
                type,
                data,
                collectionID: 2,
                collectionIDs: [2],
            },
            onSave,
            onClose,
        });
        return null;
    }
    renderToStaticMarkup(createElement(Probe));
    return { state, onSave, onClose };
};

const infoFields = [
    ["note", ["title", "content"], ["content"]],
    ["accountCredential", ["name", "username", "password", "notes"], ["name"]],
    ["physicalRecord", ["name", "location", "notes"], ["name"]],
    [
        "emergencyContact",
        ["name", "contactDetails", "notes"],
        ["name", "contactDetails"],
    ],
] as const;

for (const [type, fields, requiredFields] of infoFields) {
    test.each(["  entered text  ", " \t\u00a0 "])(
        `${type} reopens and submits exact text: %j`,
        async (value) => {
            const data = Object.fromEntries(
                fields.map((field) => [
                    field,
                    (requiredFields as readonly string[]).includes(field)
                        ? "  entered text  "
                        : value,
                ]),
            );
            const { state, onSave, onClose } = formState(type, data);
            expect(state.formData).toEqual(data);
            expect(state.canSave).toBe(true);
            await state.handleSave();
            expect(onSave).toHaveBeenCalledWith(type, data, [2]);
            expect(onClose).toHaveBeenCalledOnce();
        },
    );

    for (const field of requiredFields) {
        test.each(["", "   ", "\t\n", " \u00a0\u2003 ", undefined])(
            `${type} rejects an empty, whitespace-only or missing ${field}: %j`,
            async (value) => {
                const data = Object.fromEntries(
                    fields
                        .filter((key) => value !== undefined || key !== field)
                        .map((key) => [
                            key,
                            key === field ? (value ?? "") : "value",
                        ]),
                );
                const { state, onSave, onClose } = formState(type, data);
                expect.soft(state.canSave).toBe(false);
                await state.handleSave();
                expect(onSave).not.toHaveBeenCalled();
                expect(onClose).not.toHaveBeenCalled();
            },
        );
    }
}

test("a note with whitespace-only content and an empty title cannot save", async () => {
    const data = { title: "", content: "   " };
    const { state, onSave, onClose } = formState("note", data);
    expect(state.canSave).toBe(false);
    await state.handleSave();
    expect(onSave).not.toHaveBeenCalled();
    expect(onClose).not.toHaveBeenCalled();
});

test("file rename validation and trimming remain unchanged", async () => {
    const blank = formState("file", { name: "   " });
    expect(blank.state.canSave).toBe(false);
    await blank.state.handleSave();
    expect(blank.onSave).not.toHaveBeenCalled();

    const padded = formState("file", { name: "  notes.txt  " });
    expect(padded.state.formData).toEqual({ name: "  notes.txt  " });
    expect(padded.state.canSave).toBe(true);
    await padded.state.handleSave();
    expect(padded.onSave).toHaveBeenCalledWith(
        "file",
        { name: "notes.txt" },
        [2],
    );
});

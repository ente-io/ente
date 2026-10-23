// @vitest-environment jsdom

import { ThemeProvider } from "@mui/material";
import { SingleInputDialog } from "ente-base/components/SingleInputDialog";
import type { SingleInputFormProps } from "ente-base/components/SingleInputForm";
import { photosTheme } from "ente-base/components/utils/theme";
import { act, useState } from "react";
import { createRoot, type Root } from "react-dom/client";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";

vi.mock("i18next", () => ({ t: (key: string) => key }));
vi.mock("ente-base/log", () => ({ default: { error: vi.fn() } }));

let root: Root;
let container: HTMLDivElement;

beforeEach(() => {
    Object.assign(globalThis, { IS_REACT_ACT_ENVIRONMENT: true });
    container = document.createElement("div");
    document.body.append(container);
    root = createRoot(container);
});

const flushUpdates = async (update: () => void) => {
    await act(async () => {
        update();
        await Promise.resolve();
    });
};

afterEach(async () => {
    await flushUpdates(() => root.unmount());
    container.remove();
});

const prepare = async (onSubmit: SingleInputFormProps["onSubmit"]) => {
    const onClose = vi.fn();
    const Dialog = () => {
        const [open, setOpen] = useState(true);
        return (
            <ThemeProvider theme={photosTheme}>
                <SingleInputDialog
                    open={open}
                    title="Apply code"
                    label="Referral code"
                    initialValue="FRIEND"
                    submitButtonTitle="Apply"
                    onClose={() => {
                        onClose();
                        setOpen(false);
                    }}
                    onSubmit={onSubmit}
                />
            </ThemeProvider>
        );
    };
    await flushUpdates(() => root.render(<Dialog />));
    const form = document.querySelector("form")!;
    const input = form.querySelector("input")!;
    const button = form.querySelector<HTMLButtonElement>(
        'button[type="submit"]',
    )!;
    const submit = () =>
        flushUpdates(() => {
            form.dispatchEvent(
                new Event("submit", { bubbles: true, cancelable: true }),
            );
        });
    return { submit, onClose, input, button };
};

const expectVisibleError = (input: HTMLInputElement, message: string) => {
    const helperID = input.getAttribute("aria-describedby")!;
    const helper = document.getElementById(helperID)!;
    expect(helper.textContent).toBe(message);
    expect(input.getAttribute("aria-invalid")).toBe("true");
    expect(helper.closest('[role="dialog"]')).not.toBeNull();
    expect(getComputedStyle(helper).visibility).toBe("visible");
    expect(helper.closest('[aria-hidden="true"]')).toBeNull();
};

describe("single input dialog submission", () => {
    test("closes after a successful submission", async () => {
        const onSubmit = vi.fn();
        const { submit, onClose } = await prepare(onSubmit);
        await submit();
        expect(onSubmit).toHaveBeenCalledWith("FRIEND", expect.any(Function));
        expect(onClose).toHaveBeenCalledOnce();
    });

    test("prevents duplicate submissions during the close animation", async () => {
        const onSubmit = vi.fn();
        const { submit, onClose } = await prepare(onSubmit);
        await submit();
        expect(onClose).toHaveBeenCalledOnce();

        const dialog = document.querySelector('[role="dialog"]')!;
        const button = dialog.querySelector<HTMLButtonElement>(
            'button[type="submit"]',
        )!;
        expect(button.disabled).toBe(true);
        expect(dialog.querySelector("input")!.disabled).toBe(true);
        await flushUpdates(() => button.click());
        expect(onSubmit).toHaveBeenCalledOnce();
        expect(onClose).toHaveBeenCalledOnce();
    });

    test("keeps referral validation errors visible after submission finishes", async () => {
        const { submit, onClose, input, button } = await prepare(
            (_value, setFieldError) => setFieldError("Invalid code"),
        );
        await submit();
        expect(button.disabled).toBe(false);
        expect(onClose).not.toHaveBeenCalled();
        expectVisibleError(input, "Invalid code");
    });

    test("keeps asynchronous server errors visible after submission finishes", async () => {
        let finishRequest!: () => void;
        const request = new Promise<void>((resolve) => {
            finishRequest = resolve;
        });
        const { submit, onClose, input, button } = await prepare(
            async (_value, setFieldError) => {
                await request;
                setFieldError("Code unavailable");
            },
        );
        await submit();
        expect(button.disabled).toBe(true);
        expect(onClose).not.toHaveBeenCalled();
        await flushUpdates(finishRequest);
        expect(button.disabled).toBe(false);
        expect(onClose).not.toHaveBeenCalled();
        expectVisibleError(input, "Code unavailable");
    });

    test("shows a generic error for thrown failures without closing", async () => {
        const { submit, onClose, input, button } = await prepare(() => {
            throw new Error("Request failed");
        });
        await submit();
        expect(button.disabled).toBe(false);
        expect(onClose).not.toHaveBeenCalled();
        expectVisibleError(input, "generic_error");
    });
});

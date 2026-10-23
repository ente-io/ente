import { ThemeProvider } from "@mui/material";
import { SingleInputDialog } from "ente-base/components/SingleInputDialog";
import type { SingleInputFormProps } from "ente-base/components/SingleInputForm";
import { photosTheme } from "ente-base/components/utils/theme";
import type { PropsWithChildren } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { beforeEach, describe, expect, test, vi } from "vitest";

// Exercise the dialog's submission contract independently of browser form events.
const captured = vi.hoisted(() => ({
    props: undefined as SingleInputFormProps | undefined,
}));
vi.mock("@mui/material", async (importOriginal) => ({
    ...(await importOriginal<typeof import("@mui/material")>()),
    Dialog: ({ children }: PropsWithChildren) => <div>{children}</div>,
}));
vi.mock("ente-base/components/SingleInputForm", () => ({
    SingleInputForm: (props: SingleInputFormProps) => {
        captured.props = props;
        return null;
    },
}));

const prepare = (onSubmit: SingleInputFormProps["onSubmit"]) => {
    const onClose = vi.fn();
    renderToStaticMarkup(
        <ThemeProvider theme={photosTheme}>
            <SingleInputDialog
                open
                title="Apply code"
                label="Referral code"
                submitButtonTitle="Apply"
                onClose={onClose}
                onSubmit={onSubmit}
            />
        </ThemeProvider>,
    );
    const submit = captured.props?.onSubmit;
    if (!submit) throw new Error("The dialog did not render its form");
    return { submit, onClose };
};

beforeEach(() => {
    captured.props = undefined;
});

describe("single input dialog submission", () => {
    test("closes after a successful submission", async () => {
        const onSubmit = vi.fn();
        const { submit, onClose } = prepare(onSubmit);
        await submit("FRIEND", vi.fn());
        expect(onSubmit).toHaveBeenCalledWith("FRIEND", expect.any(Function));
        expect(onClose).toHaveBeenCalledOnce();
    });

    test("keeps referral validation errors visible", async () => {
        const { submit, onClose } = prepare((_value, setFieldError) => {
            setFieldError("Invalid code");
        });
        const setFieldError = vi.fn();
        await submit("bad-code", setFieldError);
        expect(setFieldError).toHaveBeenCalledWith("Invalid code");
        expect(onClose).not.toHaveBeenCalled();
    });

    test("keeps asynchronous server errors visible", async () => {
        const { submit, onClose } = prepare(async (_value, setFieldError) => {
            await Promise.resolve();
            setFieldError("Code unavailable");
        });
        const setFieldError = vi.fn();
        await submit("TAKEN", setFieldError);
        expect(setFieldError).toHaveBeenCalledWith("Code unavailable");
        expect(onClose).not.toHaveBeenCalled();
    });

    test("leaves thrown failures to the form without closing", async () => {
        const { submit, onClose } = prepare(() => {
            throw new Error("Request failed");
        });
        await expect(submit("FRIEND", vi.fn())).rejects.toThrow(
            "Request failed",
        );
        expect(onClose).not.toHaveBeenCalled();
    });
});

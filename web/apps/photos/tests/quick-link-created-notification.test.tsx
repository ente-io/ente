// @vitest-environment happy-dom

import { Copy01Icon, Tick02Icon } from "@hugeicons/core-free-icons";
import { HugeiconsIcon, type IconSvgElement } from "@hugeicons/react";
import { ThemeProvider } from "@mui/material";
import { photosTheme } from "ente-base/components/utils/theme";
import i18next from "i18next";
import { act } from "react";
import { createRoot } from "react-dom/client";
import { renderToStaticMarkup } from "react-dom/server";
import { expect, test, vi } from "vitest";
import { QuickLinkCreatedNotification } from "../src/components/QuickLinkCreatedNotification";

const iconContents = (icon: IconSvgElement) => {
    const element = document.createElement("div");
    element.innerHTML = renderToStaticMarkup(
        <HugeiconsIcon icon={icon} size={22} strokeWidth={1.8} />,
    );
    return element.querySelector("svg")!.innerHTML;
};

test("copying a quick link replaces the copy icon with a tick", async () => {
    await i18next.init({
        lng: "en",
        resources: {
            en: {
                translation: {
                    link_created: "Link created",
                    copy_link: "Copy link",
                    close: "Close",
                },
            },
        },
    });
    vi.stubGlobal("IS_REACT_ACT_ENVIRONMENT", true);
    const container = document.createElement("div");
    document.body.append(container);
    const root = createRoot(container);
    const onCopy = vi.fn();
    const onClose = vi.fn();

    try {
        await act(() => {
            root.render(
                <ThemeProvider theme={photosTheme}>
                    <QuickLinkCreatedNotification
                        open
                        onCopy={onCopy}
                        onClose={onClose}
                    />
                </ThemeProvider>,
            );
            return Promise.resolve();
        });
        const copyButton = container.querySelector<HTMLButtonElement>(
            'button[aria-label="Copy link"]',
        );
        expect(copyButton).not.toBeNull();
        expect(copyButton!.querySelector("svg")!.innerHTML).toBe(
            iconContents(Copy01Icon),
        );
        expect(onCopy).not.toHaveBeenCalled();

        await act(() => {
            copyButton!.click();
            return Promise.resolve();
        });

        expect(onCopy).toHaveBeenCalledOnce();
        expect(copyButton!.querySelector("svg")!.innerHTML).toBe(
            iconContents(Tick02Icon),
        );
    } finally {
        await act(() => {
            root.unmount();
            return Promise.resolve();
        });
        container.remove();
        vi.unstubAllGlobals();
    }
});

import { Copy01Icon, ReloadIcon, Tick02Icon } from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import { ThemeProvider } from "@mui/material";
import {
    Notification,
    type NotificationAttributes,
} from "ente-base/components/Notification";
import { photosTheme } from "ente-base/components/utils/theme";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, test, vi } from "vitest";

const renderNotification = (attributes: Partial<NotificationAttributes>) =>
    renderToStaticMarkup(
        <ThemeProvider theme={photosTheme}>
            <Notification
                open
                onClose={vi.fn()}
                attributes={{
                    color: "secondary",
                    title: "Done",
                    ...attributes,
                }}
            />
        </ThemeProvider>,
    );

describe("notification icons", () => {
    test("renders imported icon data at the shared sizes", () => {
        const markup = renderNotification({
            startIcon: Tick02Icon,
            endIcon: ReloadIcon,
            endIconLabel: "Retry",
            showCloseButtonWithEndIcon: true,
        });
        const icons = markup.match(/<svg\b[^>]*>/g) ?? [];
        expect(icons).toHaveLength(3);
        expect(icons[0]).toContain('width="24"');
        expect(icons[1]).toContain('width="22"');
        expect(icons[2]).toContain('width="22"');
        for (const icon of icons) expect(icon).toContain('stroke-width="1.8"');
        expect(markup).toContain('aria-label="Retry"');
    });

    test("supports a smaller copy icon without changing the close icon", () => {
        const markup = renderNotification({
            startIcon: null,
            endIcon: Copy01Icon,
            endIconSize: 18,
            showCloseButtonWithEndIcon: true,
        });
        const icons = markup.match(/<svg\b[^>]*>/g) ?? [];
        expect(icons).toHaveLength(2);
        expect(icons[0]).toContain('width="18"');
        expect(icons[1]).toContain('width="22"');
    });

    test("resolves the copied icon color through the theme", () => {
        const markup = renderNotification({
            startIcon: null,
            endIcon: Tick02Icon,
            endIconColor: "success.main",
        });
        expect(markup).toContain("color:var(--mui-palette-success-main)");
        expect(markup.match(/<svg\b[^>]*>/g)?.[0]).toContain('width="22"');
    });

    test("preserves custom icon elements and their sizing", () => {
        const markup = renderNotification({
            startIcon: null,
            endIcon: (
                <span data-testid="custom-copy">
                    <HugeiconsIcon
                        icon={Copy01Icon}
                        size={18}
                        strokeWidth={2}
                    />
                </span>
            ),
        });
        expect(markup).toContain('data-testid="custom-copy"');
        const icons = markup.match(/<svg\b[^>]*>/g) ?? [];
        expect(icons).toHaveLength(1);
        expect(icons[0]).toContain('width="18"');
        expect(icons[0]).toContain('stroke-width="2"');
    });

    test("keeps the default leading icon and allows explicitly omitting it", () => {
        const defaultMarkup = renderNotification({});
        const noLeadingIconMarkup = renderNotification({ startIcon: null });
        expect(defaultMarkup.match(/<svg\b/g)).toHaveLength(2);
        expect(noLeadingIconMarkup.match(/<svg\b/g)).toHaveLength(1);
    });
});

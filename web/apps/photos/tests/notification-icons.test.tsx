import { Copy01Icon, ReloadIcon, Tick02Icon } from "@hugeicons/core-free-icons";
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
        });
        const icons = markup.match(/<svg\b[^>]*>/g) ?? [];
        expect(icons).toHaveLength(3);
        expect(icons[0]).toContain('width="24"');
        expect(icons[1]).toContain('width="22"');
        expect(icons[2]).toContain('width="22"');
        for (const icon of icons) expect(icon).toContain('stroke-width="1.8"');
        expect(markup).toContain('aria-label="Retry"');
    });

    test("uses the same default size and color for copy and copied icons", () => {
        for (const endIcon of [Copy01Icon, Tick02Icon]) {
            const markup = renderNotification({
                color: "inherit",
                startIcon: null,
                endIcon,
            });
            const icons = markup.match(/<svg\b[^>]*>/g) ?? [];
            expect(icons).toHaveLength(2);
            for (const icon of icons) expect(icon).toContain('width="22"');
            expect(markup).not.toContain(
                "color:var(--mui-palette-success-main)",
            );
        }
    });

    test("keeps the default leading icon and allows explicitly omitting it", () => {
        const defaultMarkup = renderNotification({});
        const noLeadingIconMarkup = renderNotification({ startIcon: null });
        expect(defaultMarkup.match(/<svg\b/g)).toHaveLength(2);
        expect(noLeadingIconMarkup.match(/<svg\b/g)).toHaveLength(1);
    });
});

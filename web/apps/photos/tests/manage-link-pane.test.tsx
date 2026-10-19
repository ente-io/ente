// @vitest-environment happy-dom
import { ThemeProvider } from "@mui/material";
import { photosTheme } from "ente-base/components/utils/theme";
import type { Collection } from "ente-media/collection";
import { act } from "react";
import { createRoot, type Root } from "react-dom/client";
import { afterEach, beforeEach, expect, test, vi } from "vitest";
import { ManageLinkPane } from "../src/components/gallery/ManageLinkPane";

vi.mock("i18next", () => ({ t: (key: string) => key }));
vi.mock("@/components/share/useResolvedPublicLinkURL", () => ({
    useResolvedPublicLinkURL: () => "https://albums.example.com/#key",
}));
vi.mock("@/components/Collections/CollectionShare", () => ({
    ManagePublicLinkSettings: () => <div>Shared management controls</div>,
}));

let root: Root;
let host: HTMLDivElement;
beforeEach(() => {
    Object.assign(globalThis, { IS_REACT_ACT_ENVIRONMENT: true });
    host = document.createElement("div");
    document.body.append(host);
    root = createRoot(host);
});
afterEach(async () => {
    await act(async () => {
        root.unmount();
        await Promise.resolve();
    });
    host.remove();
});
const item = (id: number, validTill = 0): Collection => ({
    id,
    name: `Link ${id}`,
    key: "key",
    type: "album",
    owner: { id: 1 },
    sharees: [],
    updationTime: id,
    publicURLs: [
        {
            url: `https://albums.example.com/?t=${id}`,
            validTill,
            deviceLimit: 0,
            enableDownload: true,
            enableCollect: false,
            enableComment: false,
            enableJoin: false,
            passwordEnabled: false,
        },
    ],
});
const render = async (collection: Collection | undefined, loading = false) => {
    await act(async () => {
        root.render(
            <ThemeProvider theme={photosTheme}>
                <ManageLinkPane
                    collection={collection}
                    loading={loading}
                    onRemotePull={() => Promise.resolve()}
                    onLinkRemoved={() => undefined}
                />
            </ThemeProvider>,
        );
        await Promise.resolve();
    });
};

test("shows loading before the empty Links message", async () => {
    await render(undefined, true);
    expect(host.textContent).not.toContain("links_empty_title");
    await render(undefined);
    expect(host.textContent).toContain("links_empty_title");
    expect(host.textContent).toContain("links_empty_description");
    expect(host.textContent).not.toContain("Shared management controls");
});

test("switches the link heading, expiry status, and settings together", async () => {
    await render(item(1));
    expect(host.querySelector("h1")?.textContent).toBe("Link 1");
    expect(host.textContent).toContain("active");
    expect(host.textContent).toContain("Shared management controls");
    await render(item(2, 1));
    expect(host.querySelector("h1")?.textContent).toBe("Link 2");
    expect(host.textContent).toContain("link_expired");
    expect(host.textContent).not.toContain("Link 1");
    await render(undefined);
    expect(host.textContent).toContain("links_empty_title");
    expect(host.querySelector("section")).toBeNull();
});

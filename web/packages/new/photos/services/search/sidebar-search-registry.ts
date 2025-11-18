import { isDesktop } from "ente-base/app";
import { isHLSGenerationSupported } from "ente-gallery/services/video";
import { t } from "i18next";
import { isDevBuildAndUser } from "../settings";
import type { SearchOption, SidebarActionID } from "./types";

export interface SidebarAction {
    id: SidebarActionID;
    label: string;
    path: string[];
    keywords?: string[];
    available?: () => boolean;
}

const shortcutsCategory = t("shortcuts", { defaultValue: "Shortcuts" });
const preferencesCategory = t("preferences");
const accountCategory = t("account");
const helpCategory = t("help");

export const sidebarActions: SidebarAction[] = [
    {
        id: "shortcuts.uncategorized",
        label: t("section_uncategorized"),
        path: [shortcutsCategory, t("section_uncategorized")],
        keywords: ["uncategorized", "ungrouped"],
    },
    {
        id: "shortcuts.archive",
        label: t("section_archive"),
        path: [shortcutsCategory, t("section_archive")],
        keywords: ["archive", "archived"],
    },
    {
        id: "shortcuts.hidden",
        label: t("section_hidden"),
        path: [shortcutsCategory, t("section_hidden")],
        keywords: ["hidden", "private"],
    },
    {
        id: "shortcuts.trash",
        label: t("section_trash"),
        path: [shortcutsCategory, t("section_trash")],
        keywords: ["trash", "bin", "deleted"],
    },
    {
        id: "utility.account",
        label: t("account"),
        path: [preferencesCategory, t("account")],
        keywords: ["profile", "user"],
    },
    {
        id: "utility.watchFolders",
        label: t("watch_folders"),
        path: [preferencesCategory, t("watch_folders")],
        keywords: ["watch", "folder", "desktop"],
        available: () => isDesktop,
    },
    {
        id: "utility.deduplicate",
        label: t("deduplicate_files"),
        path: [preferencesCategory, t("deduplicate_files")],
        keywords: ["duplicate", "dedupe"],
    },
    {
        id: "utility.preferences",
        label: t("preferences"),
        path: [preferencesCategory],
        keywords: ["settings"],
    },
    {
        id: "utility.help",
        label: t("help"),
        path: [helpCategory],
        keywords: ["support", "docs"],
    },
    {
        id: "utility.export",
        label: t("export_data"),
        path: [preferencesCategory, t("export_data")],
        keywords: ["export", "download"],
    },
    {
        id: "utility.logout",
        label: t("logout"),
        path: [preferencesCategory, t("logout")],
        keywords: ["sign out", "signout"],
    },
    {
        id: "account.recoveryKey",
        label: t("recovery_key"),
        path: [accountCategory, t("recovery_key")],
        keywords: ["recovery", "key", "backup"],
    },
    {
        id: "account.twoFactor",
        label: t("two_factor"),
        path: [accountCategory, t("two_factor")],
        keywords: ["2fa", "otp", "mfa"],
    },
    {
        id: "account.passkeys",
        label: t("passkeys"),
        path: [accountCategory, t("passkeys")],
        keywords: ["webauthn", "security key"],
    },
    {
        id: "account.changePassword",
        label: t("change_password"),
        path: [accountCategory, t("change_password")],
        keywords: ["password"],
    },
    {
        id: "account.changeEmail",
        label: t("change_email"),
        path: [accountCategory, t("change_email")],
        keywords: ["email"],
    },
    {
        id: "account.deleteAccount",
        label: t("delete_account"),
        path: [accountCategory, t("delete_account")],
        keywords: ["delete", "remove"],
    },
    {
        id: "preferences.language",
        label: t("language"),
        path: [preferencesCategory, t("language")],
        keywords: ["locale"],
    },
    {
        id: "preferences.theme",
        label: t("theme"),
        path: [preferencesCategory, t("theme")],
        keywords: ["appearance", "dark mode", "light mode"],
    },
    {
        id: "preferences.customDomains",
        label: t("custom_domains"),
        path: [preferencesCategory, t("custom_domains")],
        keywords: ["domain", "link"],
    },
    {
        id: "preferences.map",
        label: t("map"),
        path: [preferencesCategory, t("map")],
        keywords: ["maps", "location"],
    },
    {
        id: "preferences.advanced",
        label: t("advanced"),
        path: [preferencesCategory, t("advanced")],
        keywords: ["advanced", "proxy", "upload"],
    },
    {
        id: "preferences.mlSearch",
        label: t("ml_search"),
        path: [preferencesCategory, t("ml_search")],
        keywords: ["ml", "search", "magic"],
    },
    {
        id: "preferences.streamableVideos",
        label: t("streamable_videos"),
        path: [preferencesCategory, t("streamable_videos")],
        keywords: ["hls", "video", "stream"],
        available: () => isHLSGenerationSupported,
    },
    {
        id: "help.helpCenter",
        label: t("ente_help"),
        path: [helpCategory, t("ente_help")],
        keywords: ["help", "docs"],
    },
    {
        id: "help.blog",
        label: t("blog"),
        path: [helpCategory, t("blog")],
        keywords: ["news"],
    },
    {
        id: "help.requestFeature",
        label: t("request_feature"),
        path: [helpCategory, t("request_feature")],
        keywords: ["feature", "feedback"],
    },
    {
        id: "help.support",
        label: t("support"),
        path: [helpCategory, t("support")],
        keywords: ["contact", "support"],
    },
    {
        id: "help.viewLogs",
        label: t("view_logs"),
        path: [helpCategory, t("view_logs")],
        keywords: ["logs", "debug"],
    },
    {
        id: "help.testUpload",
        label: t("test_upload"),
        path: [helpCategory, t("test_upload")],
        keywords: ["test", "upload"],
        available: () => isDevBuildAndUser(),
    },
];

export const sidebarSearchOptionsForString = (
    searchString: string,
): SearchOption[] => {
    const normalized = searchString.trim().toLowerCase();
    if (!normalized) return [];

    return sidebarActions
        .filter(({ available }) => !available || available())
        .filter(({ label, path, keywords }) =>
            matchesSearch(normalized, label, path, keywords),
        )
        .map(({ id, label, path }) => ({
            suggestion: { type: "sidebarAction", actionID: id, path, label },
            fileCount: 0,
            previewFiles: [],
        }));
};

const matchesSearch = (
    normalized: string,
    label: string,
    path: string[],
    keywords: string[] = [],
) => {
    const haystack = [label, ...path, ...keywords]
        .filter(Boolean)
        .map((s) => s.toLowerCase());

    const re = new RegExp("(^|[\\s.,!?\"'-_])" + escapeRegex(normalized));
    return haystack.some((h) => re.test(h));
};

const escapeRegex = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

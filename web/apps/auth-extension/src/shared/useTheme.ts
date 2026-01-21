/**
 * React hook for theme management.
 */
import { useEffect, useLayoutEffect, useState } from "react";
import { sendMessage } from "@shared/browser";
import type { ExtensionSettings, ThemeMode } from "@shared/types";

type ResolvedTheme = "light" | "dark";

/**
 * Get the current system color scheme preference.
 */
const getSystemPreference = (): ResolvedTheme => {
    if (typeof window === "undefined") return "dark";
    return window.matchMedia("(prefers-color-scheme: dark)").matches
        ? "dark"
        : "light";
};

/**
 * Apply theme class to document.
 */
const applyTheme = (theme: ResolvedTheme): void => {
    document.documentElement.classList.remove("theme-light", "theme-dark");
    document.documentElement.classList.add(`theme-${theme}`);
};

/**
 * Hook to manage and apply theme settings.
 * - Loads theme from settings
 * - Detects system preference when mode is "system"
 * - Applies theme class to document
 * - Listens for system preference changes
 */
export const useTheme = (): {
    theme: ThemeMode;
    resolvedTheme: ResolvedTheme;
} => {
    // Initialize system preference synchronously to avoid flash
    const [systemPreference, setSystemPreference] = useState<ResolvedTheme>(
        getSystemPreference
    );
    const [theme, setTheme] = useState<ThemeMode>("system");
    const [settingsLoaded, setSettingsLoaded] = useState(false);

    // Resolve the actual theme to apply
    const resolvedTheme: ResolvedTheme =
        theme === "system" ? systemPreference : theme;

    // Apply theme immediately on mount and when it changes
    // Using useLayoutEffect to apply before browser paint
    useLayoutEffect(() => {
        applyTheme(resolvedTheme);
    }, [resolvedTheme]);

    // Load theme from settings
    useEffect(() => {
        const loadTheme = async () => {
            try {
                const response = await sendMessage<{
                    success: boolean;
                    data?: ExtensionSettings;
                }>({ type: "GET_SETTINGS" });

                if (response.success && response.data) {
                    setTheme(response.data.theme);
                }
            } catch (e) {
                console.error("Failed to load theme:", e);
            } finally {
                setSettingsLoaded(true);
            }
        };

        loadTheme();
    }, []);

    // Listen for system preference changes
    useEffect(() => {
        const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");

        const handleChange = (e: MediaQueryListEvent) => {
            setSystemPreference(e.matches ? "dark" : "light");
        };

        mediaQuery.addEventListener("change", handleChange);

        return () => {
            mediaQuery.removeEventListener("change", handleChange);
        };
    }, []);

    return { theme, resolvedTheme };
};

/**
 * Get resolved theme (for content scripts).
 * Returns the theme that should be applied based on settings and system preference.
 */
export const getResolvedTheme = async (): Promise<ResolvedTheme> => {
    try {
        const response = await sendMessage<{
            success: boolean;
            data?: ExtensionSettings;
        }>({ type: "GET_SETTINGS" });

        const themeSetting = response.data?.theme ?? "system";

        if (themeSetting === "system") {
            return getSystemPreference();
        }

        return themeSetting;
    } catch {
        return "dark";
    }
};

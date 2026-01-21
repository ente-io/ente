/**
 * Options page application component.
 */
import React, { useEffect, useState } from "react";
import { sendMessage } from "@shared/browser";
import { useTheme } from "@shared/useTheme";
import type { AuthState, ExtensionSettings, ThemeMode } from "@shared/types";

export const App: React.FC = () => {
    // Initialize theme
    useTheme();

    const [settings, setSettings] = useState<ExtensionSettings | null>(null);
    const [authState, setAuthState] = useState<AuthState | null>(null);
    const [saving, setSaving] = useState(false);
    const [saved, setSaved] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [loggingOut, setLoggingOut] = useState(false);
    const [syncing, setSyncing] = useState(false);
    const [syncSuccess, setSyncSuccess] = useState(false);

    // Load settings and auth state on mount
    useEffect(() => {
        const loadData = async () => {
            try {
                const [settingsResponse, authResponse] = await Promise.all([
                    sendMessage<{ success: boolean; data?: ExtensionSettings }>({
                        type: "GET_SETTINGS",
                    }),
                    sendMessage<{ success: boolean; data?: AuthState }>({
                        type: "GET_AUTH_STATE",
                    }),
                ]);

                if (settingsResponse.success && settingsResponse.data) {
                    setSettings(settingsResponse.data);
                }
                if (authResponse.success && authResponse.data) {
                    setAuthState(authResponse.data);
                }
            } catch (e) {
                console.error("Failed to load data:", e);
            }
        };

        loadData();
    }, []);

    // Handle logout
    const handleLogout = async () => {
        setLoggingOut(true);
        try {
            await sendMessage({ type: "LOGOUT" });
            setAuthState({ isLoggedIn: false, isUnlocked: false });
        } catch (e) {
            console.error("Failed to logout:", e);
        } finally {
            setLoggingOut(false);
        }
    };

    // Handle manual sync
    const handleSync = async () => {
        setSyncing(true);
        setSyncSuccess(false);
        try {
            await sendMessage({ type: "SYNC_CODES" });
            setSyncSuccess(true);
            setTimeout(() => setSyncSuccess(false), 2000);
        } catch (e) {
            console.error("Failed to sync:", e);
        } finally {
            setSyncing(false);
        }
    };

    // Save settings
    const saveSettings = async (newSettings: Partial<ExtensionSettings>) => {
        setSaving(true);
        setSaved(false);
        setError(null);

        try {
            const response = await sendMessage<{
                success: boolean;
                error?: string;
            }>({
                type: "SET_SETTINGS",
                settings: newSettings,
            });

            if (response.success) {
                setSettings((prev) =>
                    prev ? { ...prev, ...newSettings } : null
                );
                setSaved(true);
                setTimeout(() => setSaved(false), 2000);
            } else {
                setError(response.error || "Failed to save settings");
            }
        } catch (e) {
            setError(e instanceof Error ? e.message : "Failed to save settings");
        } finally {
            setSaving(false);
        }
    };

    // Handle toggle change
    const handleToggle = (key: keyof ExtensionSettings) => {
        if (!settings) return;
        const newValue = !settings[key];
        saveSettings({ [key]: newValue });
    };

    // Handle theme change with page reload to apply new theme
    const handleThemeChange = (theme: ThemeMode) => {
        saveSettings({ theme }).then(() => {
            // Reload the page to apply the new theme
            window.location.reload();
        });
    };

    // Handle input change
    const handleInputChange = (
        key: keyof ExtensionSettings,
        value: string | number
    ) => {
        if (!settings) return;
        saveSettings({ [key]: value });
    };

    // Validate API endpoint
    const isValidUrl = (url: string): boolean => {
        if (!url) return true;
        try {
            new URL(url);
            return true;
        } catch {
            return false;
        }
    };

    if (!settings) {
        return (
            <div className="options-container">
                <div className="loading">Loading settings...</div>
            </div>
        );
    }

    return (
        <div className="options-container">
            <div className="options-header">
                <Logo />
                <h1>Ente Auth Settings</h1>
            </div>

            <div className="options-content">
                <section className="settings-section">
                    <h2>Appearance</h2>

                    <div className="setting-item">
                        <div className="setting-info">
                            <label>Theme</label>
                            <p>
                                Choose your preferred color scheme.
                            </p>
                        </div>
                        <select
                            value={settings.theme}
                            onChange={(e) =>
                                handleThemeChange(e.target.value as ThemeMode)
                            }
                            className="select-input"
                        >
                            <option value="system">System</option>
                            <option value="light">Light</option>
                            <option value="dark">Dark</option>
                        </select>
                    </div>
                </section>

                <section className="settings-section">
                    <h2>Autofill</h2>

                    <div className="setting-item">
                        <div className="setting-info">
                            <label>Auto-fill single match</label>
                            <p>
                                Automatically fill the code when only one match is
                                found for the current website.
                            </p>
                        </div>
                        <label className="toggle">
                            <input
                                type="checkbox"
                                checked={settings.autoFillSingleMatch}
                                onChange={() =>
                                    handleToggle("autoFillSingleMatch")
                                }
                            />
                            <span className="toggle-slider"></span>
                        </label>
                    </div>

                    <div className="setting-item">
                        <div className="setting-info">
                            <label>Show notifications</label>
                            <p>
                                Show a popup when an MFA field is detected on a
                                website.
                            </p>
                        </div>
                        <label className="toggle">
                            <input
                                type="checkbox"
                                checked={settings.showNotifications}
                                onChange={() =>
                                    handleToggle("showNotifications")
                                }
                            />
                            <span className="toggle-slider"></span>
                        </label>
                    </div>
                </section>

                <section className="settings-section">
                    <h2>Advanced</h2>

                    <div className="setting-item vertical">
                        <div className="setting-info">
                            <label>Custom API endpoint</label>
                            <p>
                                For self-hosted Ente instances. Leave empty to use
                                the default Ente servers.
                            </p>
                        </div>
                        <input
                            type="url"
                            className="text-input"
                            placeholder="https://your-ente-server.com"
                            value={settings.customApiEndpoint || ""}
                            onChange={(e) => {
                                const value = e.target.value;
                                if (isValidUrl(value)) {
                                    saveSettings({
                                        customApiEndpoint: value || undefined,
                                    });
                                }
                            }}
                        />
                    </div>
                </section>

                {authState?.isLoggedIn && (
                    <section className="settings-section">
                        <h2>Account</h2>

                        <div className="setting-item">
                            <div className="setting-info">
                                <label>Logged in as</label>
                                <p>{authState.email || "Unknown"}</p>
                            </div>
                            <button
                                className="logout-button"
                                onClick={handleLogout}
                                disabled={loggingOut}
                            >
                                {loggingOut ? "Logging out..." : "Log out"}
                            </button>
                        </div>

                        <div className="setting-item">
                            <div className="setting-info">
                                <label>Sync codes</label>
                                <p>
                                    Codes sync automatically every 5 minutes.
                                </p>
                            </div>
                            <button
                                className="sync-button"
                                onClick={handleSync}
                                disabled={syncing}
                            >
                                {syncing ? "Syncing..." : syncSuccess ? "Synced!" : "Sync now"}
                            </button>
                        </div>
                    </section>
                )}

                {(saving || saved || error) && (
                    <div className="status-bar">
                        {saving && <span className="saving">Saving...</span>}
                        {saved && <span className="saved">Settings saved!</span>}
                        {error && <span className="error">{error}</span>}
                    </div>
                )}
            </div>

            <div className="options-footer">
                <p>
                    Ente Auth v1.0.0 •{" "}
                    <a
                        href="https://ente.io"
                        target="_blank"
                        rel="noopener noreferrer"
                    >
                        ente.io
                    </a>
                </p>
            </div>
        </div>
    );
};

// Logo component - Ente Auth purple
const Logo: React.FC = () => (
    <svg width="40" height="40" viewBox="0 0 24 24" fill="none">
        <path
            d="M12 2L3 7V12C3 16.97 6.84 21.66 12 23C17.16 21.66 21 16.97 21 12V7L12 2Z"
            fill="#8F33D6"
        />
        <path
            d="M10 17L6 13L7.41 11.59L10 14.17L16.59 7.58L18 9L10 17Z"
            fill="white"
        />
    </svg>
);

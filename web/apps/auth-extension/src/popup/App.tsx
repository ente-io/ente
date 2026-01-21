/**
 * Extension popup main application component.
 */
import React, { useEffect, useState } from "react";
import { sendMessage, openOptionsPage } from "@shared/browser";
import { searchCodes } from "@shared/domain-matcher";
import { generateOTPs } from "@shared/otp";
import { useTheme } from "@shared/useTheme";
import type { AuthState, Code } from "@shared/types";
import { CodeCard } from "./CodeCard";

type View = "loading" | "login" | "unlock" | "codes";

export const App: React.FC = () => {
    // Initialize theme
    useTheme();

    const [view, setView] = useState<View>("loading");
    const [codes, setCodes] = useState<Code[]>([]);
    const [filteredCodes, setFilteredCodes] = useState<Code[]>([]);
    const [searchQuery, setSearchQuery] = useState("");
    const [timeOffset, setTimeOffset] = useState(0);
    const [password, setPassword] = useState("");
    const [error, setError] = useState<string | null>(null);
    const [syncing, setSyncing] = useState(false);
    const [loggingIn, setLoggingIn] = useState(false);
    const [otps, setOtps] = useState<Map<string, { otp: string; nextOtp: string }>>(new Map());

    // Check auth state on mount with retry logic for MV3 service worker wake-up
    useEffect(() => {
        const checkAuth = async (retries = 3): Promise<void> => {
            try {
                const response = await sendMessage<{
                    success: boolean;
                    data?: AuthState;
                    error?: string;
                }>({ type: "GET_AUTH_STATE" });

                if (!response.success || !response.data) {
                    // Retry if we got an error (service worker might be waking up)
                    if (retries > 0 && response.error) {
                        console.log(`Auth check failed, retrying... (${retries} left)`);
                        await new Promise(r => setTimeout(r, 100));
                        return checkAuth(retries - 1);
                    }
                    setView("login");
                    return;
                }

                const { isLoggedIn, isUnlocked } = response.data;

                if (!isLoggedIn) {
                    setView("login");
                } else if (!isUnlocked) {
                    setView("unlock");
                } else {
                    await loadCodes();
                    setView("codes");
                }
            } catch (e) {
                console.error("Failed to check auth:", e);
                // Retry on exception (service worker might be waking up)
                if (retries > 0) {
                    console.log(`Auth check exception, retrying... (${retries} left)`);
                    await new Promise(r => setTimeout(r, 100));
                    return checkAuth(retries - 1);
                }
                setView("login");
            }
        };

        checkAuth();
    }, []);

    // Load codes from background
    const loadCodes = async () => {
        try {
            const response = await sendMessage<{
                success: boolean;
                data?: { codes: Code[]; timeOffset: number };
            }>({ type: "GET_CODES" });

            if (response.success && response.data) {
                setCodes(response.data.codes);
                setFilteredCodes(response.data.codes);
                setTimeOffset(response.data.timeOffset);
            }
        } catch (e) {
            console.error("Failed to load codes:", e);
        }
    };

    // Update OTPs every second (codes only change once per period)
    useEffect(() => {
        if (view !== "codes" || codes.length === 0) return;

        const updateOtpCodes = () => {
            const newOtps = new Map<string, { otp: string; nextOtp: string }>();

            filteredCodes.forEach((code) => {
                const [otp, nextOtp] = generateOTPs(code, timeOffset);
                newOtps.set(code.id, { otp, nextOtp });
            });

            setOtps(newOtps);
        };

        updateOtpCodes();
        const interval = setInterval(updateOtpCodes, 1000);

        return () => clearInterval(interval);
    }, [view, filteredCodes, timeOffset]);

    // Filter codes when search query changes
    useEffect(() => {
        if (searchQuery.trim()) {
            setFilteredCodes(searchCodes(codes, searchQuery));
        } else {
            setFilteredCodes(codes);
        }
    }, [searchQuery, codes]);

    // Handle unlock
    const handleUnlock = async () => {
        if (!password.trim()) return;

        setError(null);
        try {
            const response = await sendMessage<{
                success: boolean;
                error?: string;
            }>({
                type: "UNLOCK",
                password,
            });

            if (response.success) {
                setPassword("");
                await loadCodes();
                setView("codes");
            } else {
                setError(response.error || "Invalid password");
            }
        } catch (e) {
            setError(e instanceof Error ? e.message : "Failed to unlock");
        }
    };

    // Handle sync
    const handleSync = async () => {
        setSyncing(true);
        try {
            await sendMessage({ type: "SYNC_CODES" });
            await loadCodes();
        } catch (e) {
            console.error("Sync failed:", e);
        } finally {
            setSyncing(false);
        }
    };

    // Handle logout
    const handleLogout = async () => {
        await sendMessage({ type: "LOGOUT" });
        setCodes([]);
        setFilteredCodes([]);
        setView("login");
    };

    // Handle web login - opens auth.ente.io in a new tab
    const handleWebLogin = async () => {
        setError(null);
        setLoggingIn(true);
        try {
            await sendMessage({ type: "OPEN_WEB_LOGIN" });
            // The content script on auth.ente.io will capture credentials
            // and send them back. We'll poll for auth state changes.
            pollForLogin();
        } catch (e) {
            setError(e instanceof Error ? e.message : "Failed to open login page");
            setLoggingIn(false);
        }
    };

    // Poll for login completion after opening web login
    const pollForLogin = () => {
        const checkInterval = setInterval(async () => {
            try {
                const response = await sendMessage<{
                    success: boolean;
                    data?: { isLoggedIn: boolean; isUnlocked: boolean };
                }>({ type: "GET_AUTH_STATE" });

                if (response.success && response.data?.isLoggedIn) {
                    clearInterval(checkInterval);
                    setLoggingIn(false);
                    if (response.data.isUnlocked) {
                        await loadCodes();
                        setView("codes");
                    } else {
                        setView("unlock");
                    }
                }
            } catch (e) {
                // Keep polling
            }
        }, 1000);

        // Stop polling after 5 minutes
        setTimeout(() => {
            clearInterval(checkInterval);
            setLoggingIn(false);
        }, 5 * 60 * 1000);
    };

    // Render loading state
    if (view === "loading") {
        return (
            <div className="popup-container">
                <div className="auth-container">
                    <div className="auth-logo">
                        <Logo />
                    </div>
                    <div className="auth-title">Loading...</div>
                </div>
            </div>
        );
    }

    // Render login view
    if (view === "login") {
        return (
            <div className="popup-container">
                <div className="auth-container">
                    <div className="auth-logo">
                        <Logo />
                    </div>
                    <div className="auth-title">Ente Auth</div>
                    <div className="auth-description">
                        Secure 2FA autofill from your Ente Auth vault.
                    </div>
                    <div className="auth-form">
                        <button
                            type="button"
                            className="auth-button"
                            onClick={handleWebLogin}
                            disabled={loggingIn}
                        >
                            {loggingIn ? "Waiting for login..." : "Log in with Ente"}
                        </button>
                        {loggingIn && (
                            <div className="auth-hint">
                                Complete login in the browser tab that opened.
                                This popup will update automatically.
                            </div>
                        )}
                        {error && <div className="auth-error">{error}</div>}
                    </div>
                </div>
            </div>
        );
    }

    // Render unlock view
    if (view === "unlock") {
        return (
            <div className="popup-container">
                <div className="auth-container">
                    <div className="auth-logo">
                        <Logo />
                    </div>
                    <div className="auth-title">Unlock Vault</div>
                    <div className="auth-description">
                        Enter your password to unlock your auth codes.
                    </div>
                    <form
                        className="auth-form"
                        onSubmit={(e) => {
                            e.preventDefault();
                            handleUnlock();
                        }}
                    >
                        <input
                            type="password"
                            className="auth-input"
                            placeholder="Password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            autoFocus
                        />
                        <button
                            type="submit"
                            className="auth-button"
                            disabled={!password.trim()}
                        >
                            Unlock
                        </button>
                        {error && <div className="auth-error">{error}</div>}
                    </form>
                    <span className="auth-link" onClick={handleLogout}>
                        Use a different account
                    </span>
                </div>
            </div>
        );
    }

    // Render codes view
    return (
        <div className="popup-container">
            <div className="header">
                <div className="logo">
                    <Logo />
                </div>
                <span className="title">Ente Auth</span>
                <div className="header-actions">
                    <button
                        className="icon-button"
                        onClick={handleSync}
                        title="Sync codes"
                    >
                        <SyncIcon />
                    </button>
                    <button
                        className="icon-button"
                        onClick={() => openOptionsPage()}
                        title="Settings"
                    >
                        <SettingsIcon />
                    </button>
                </div>
            </div>

            <div className="search-container">
                <input
                    type="text"
                    className="search-input"
                    placeholder="Search codes..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                />
            </div>

            <div className="codes-list">
                {filteredCodes.length === 0 ? (
                    <div className="empty-state">
                        <div className="empty-state-icon">🔐</div>
                        <div className="empty-state-text">
                            {codes.length === 0
                                ? "No codes yet. Add codes in the Ente Auth app."
                                : "No codes match your search."}
                        </div>
                    </div>
                ) : (
                    filteredCodes.map((code) => {
                        const otpData = otps.get(code.id) || {
                            otp: "",
                            nextOtp: "",
                        };
                        return (
                            <CodeCard
                                key={code.id}
                                code={code}
                                timeOffset={timeOffset}
                                otp={otpData.otp}
                                nextOtp={otpData.nextOtp}
                            />
                        );
                    })
                )}
            </div>

            <div className={`sync-indicator ${syncing ? "syncing" : ""}`}>
                {syncing ? "Syncing..." : `${codes.length} codes`}
            </div>
        </div>
    );
};

// Logo component - Ente Auth purple
const Logo: React.FC = () => (
    <svg width="32" height="32" viewBox="0 0 24 24" fill="none">
        <path
            d="M12 2L3 7V12C3 16.97 6.84 21.66 12 23C17.16 21.66 21 16.97 21 12V7L12 2Z"
            fill="#8e2de2"
        />
        <path
            d="M10 17L6 13L7.41 11.59L10 14.17L16.59 7.58L18 9L10 17Z"
            fill="white"
        />
    </svg>
);

// Sync icon
const SyncIcon: React.FC = () => (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.2"/>
    </svg>
);

// Settings icon
const SettingsIcon: React.FC = () => (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="12" cy="12" r="3"/>
        <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/>
    </svg>
);

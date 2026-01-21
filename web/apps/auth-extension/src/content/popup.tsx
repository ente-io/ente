/**
 * Inline popup component for MFA code selection.
 * Renders in a Shadow DOM for style isolation.
 */
import React, { useEffect, useState } from "react";
import { createRoot, type Root } from "react-dom/client";
import { generateOTPs, getProgress } from "@shared/otp";
import { prettyFormatCode } from "@shared/code";
import { getResolvedTheme } from "@shared/useTheme";
import type { Code, DomainMatch } from "@shared/types";

type ResolvedTheme = "light" | "dark";

// Theme color definitions matching the CSS variables
const themeColors = {
    dark: {
        background: "#000000",
        backgroundPaper: "#1B1B1B",
        textPrimary: "#FFFFFF",
        textMuted: "rgba(255, 255, 255, 0.70)",
        textFaint: "rgba(255, 255, 255, 0.50)",
        fillMuted: "rgba(255, 255, 255, 0.16)",
        fillFaint: "rgba(255, 255, 255, 0.12)",
        stroke: "rgba(255, 255, 255, 0.12)",
        accentPurple: "#8F33D6",
    },
    light: {
        background: "#FFFFFF",
        backgroundPaper: "#FAFAFA",
        textPrimary: "#000000",
        textMuted: "rgba(0, 0, 0, 0.60)",
        textFaint: "rgba(0, 0, 0, 0.50)",
        fillMuted: "rgba(0, 0, 0, 0.12)",
        fillFaint: "rgba(0, 0, 0, 0.04)",
        stroke: "rgba(0, 0, 0, 0.12)",
        accentPurple: "#8F33D6",
    },
};

interface PopupProps {
    matches: DomainMatch[];
    timeOffset: number;
    onFill: (code: string) => void;
    onDismiss: () => void;
}

const Popup: React.FC<PopupProps> = ({
    matches,
    timeOffset,
    onFill,
    onDismiss,
}) => {
    const [otps, setOtps] = useState<Map<string, string>>(new Map());
    const [progress, setProgress] = useState<Map<string, number>>(new Map());
    const [theme, setTheme] = useState<ResolvedTheme>("dark");

    // Load theme on mount
    useEffect(() => {
        getResolvedTheme().then(setTheme);
    }, []);

    // Update OTPs every second
    useEffect(() => {
        const updateOtps = () => {
            const newOtps = new Map<string, string>();
            const newProgress = new Map<string, number>();

            matches.forEach(({ code }) => {
                const [otp] = generateOTPs(code, timeOffset);
                newOtps.set(code.id, otp);
                newProgress.set(code.id, getProgress(code, timeOffset));
            });

            setOtps(newOtps);
            setProgress(newProgress);
        };

        updateOtps();
        const interval = setInterval(updateOtps, 1000);

        return () => clearInterval(interval);
    }, [matches, timeOffset]);

    // Auto-dismiss after 10 seconds
    useEffect(() => {
        const timeout = setTimeout(onDismiss, 10000);
        return () => clearTimeout(timeout);
    }, [onDismiss]);

    const colors = themeColors[theme];
    const styles = getStyles(colors);

    return (
        <div style={styles.container}>
            <div style={styles.header}>
                <svg
                    width="20"
                    height="20"
                    viewBox="0 0 24 24"
                    fill="none"
                    style={styles.logo}
                >
                    <path
                        d="M12 2L3 7V12C3 16.97 6.84 21.66 12 23C17.16 21.66 21 16.97 21 12V7L12 2Z"
                        fill="#8F33D6"
                    />
                    <path
                        d="M10 17L6 13L7.41 11.59L10 14.17L16.59 7.58L18 9L10 17Z"
                        fill="white"
                    />
                </svg>
                <span style={styles.title}>Ente Auth</span>
                <button style={styles.closeButton} onClick={onDismiss}>
                    ×
                </button>
            </div>
            <div style={styles.content}>
                {matches.map(({ code, confidence }) => (
                    <div key={code.id} style={styles.codeItem}>
                        <div style={styles.codeInfo}>
                            <div style={styles.issuer}>{code.issuer}</div>
                            {code.account && (
                                <div style={styles.account}>{code.account}</div>
                            )}
                        </div>
                        <div style={styles.codeActions}>
                            <div style={styles.otpContainer}>
                                <div style={styles.otp}>
                                    {prettyFormatCode(otps.get(code.id) || "")}
                                </div>
                                <div
                                    style={{
                                        ...styles.progressBar,
                                        width: `${(progress.get(code.id) || 0) * 100}%`,
                                    }}
                                />
                            </div>
                            <button
                                style={styles.fillButton}
                                onClick={() => onFill(otps.get(code.id) || "")}
                            >
                                Fill
                            </button>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
};

type ThemeColorSet = typeof themeColors.dark;

const getStyles = (colors: ThemeColorSet): Record<string, React.CSSProperties> => ({
    container: {
        position: "fixed",
        top: "16px",
        right: "16px",
        width: "320px",
        backgroundColor: colors.backgroundPaper,
        borderRadius: "4px",
        boxShadow: "0 2px 12px rgba(0, 0, 0, 0.75)",
        fontFamily:
            '"Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        zIndex: 2147483647,
        overflow: "hidden",
        color: colors.textPrimary,
    },
    header: {
        display: "flex",
        alignItems: "center",
        padding: "12px 16px",
        borderBottom: `1px solid ${colors.stroke}`,
        backgroundColor: colors.background,
    },
    logo: {
        marginRight: "8px",
    },
    title: {
        flex: 1,
        fontSize: "14px",
        fontWeight: 600,
        color: colors.textPrimary,
    },
    closeButton: {
        background: "none",
        border: "none",
        color: colors.textMuted,
        fontSize: "20px",
        cursor: "pointer",
        padding: "4px",
        lineHeight: 1,
        borderRadius: "4px",
    },
    content: {
        maxHeight: "300px",
        overflowY: "auto",
        backgroundColor: colors.backgroundPaper,
    },
    codeItem: {
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        padding: "12px 16px",
        borderBottom: `1px solid ${colors.fillFaint}`,
        cursor: "pointer",
        transition: "background-color 0.2s",
    },
    codeInfo: {
        flex: 1,
        minWidth: 0,
    },
    issuer: {
        fontSize: "14px",
        fontWeight: 500,
        color: colors.textPrimary,
        whiteSpace: "nowrap",
        overflow: "hidden",
        textOverflow: "ellipsis",
    },
    account: {
        fontSize: "12px",
        color: colors.textFaint,
        whiteSpace: "nowrap",
        overflow: "hidden",
        textOverflow: "ellipsis",
        marginTop: "2px",
    },
    codeActions: {
        display: "flex",
        alignItems: "center",
        gap: "8px",
    },
    otpContainer: {
        position: "relative",
        backgroundColor: colors.fillFaint,
        borderRadius: "4px",
        padding: "6px 10px",
        overflow: "hidden",
    },
    otp: {
        fontSize: "16px",
        fontWeight: 600,
        color: colors.textPrimary,
        position: "relative",
        zIndex: 1,
        letterSpacing: "-0.011em",
    },
    progressBar: {
        position: "absolute",
        bottom: 0,
        left: 0,
        height: "2px",
        backgroundColor: colors.accentPurple,
        transition: "width 1s linear",
    },
    fillButton: {
        backgroundColor: colors.accentPurple,
        color: "#fff",
        border: "none",
        borderRadius: "4px",
        padding: "6px 12px",
        fontSize: "12px",
        fontWeight: 600,
        cursor: "pointer",
        transition: "background-color 0.2s",
    },
});

// Global state for popup management
let popupRoot: Root | null = null;
let popupContainer: HTMLDivElement | null = null;
let shadowRoot: ShadowRoot | null = null;

/**
 * Show the inline popup with matching codes.
 */
export const showPopup = (
    matches: DomainMatch[],
    timeOffset: number,
    onFill: (code: string) => void
): void => {
    // Don't show if no matches
    if (matches.length === 0) return;

    // Remove existing popup
    hidePopup();

    // Create container with Shadow DOM
    popupContainer = document.createElement("div");
    popupContainer.id = "ente-auth-popup-container";
    shadowRoot = popupContainer.attachShadow({ mode: "closed" });

    // Create root element inside shadow DOM
    const rootElement = document.createElement("div");
    shadowRoot.appendChild(rootElement);

    // Mount React component
    popupRoot = createRoot(rootElement);
    popupRoot.render(
        <Popup
            matches={matches}
            timeOffset={timeOffset}
            onFill={(code) => {
                onFill(code);
                hidePopup();
            }}
            onDismiss={hidePopup}
        />
    );

    document.body.appendChild(popupContainer);
};

/**
 * Hide and cleanup the popup.
 */
export const hidePopup = (): void => {
    if (popupRoot) {
        popupRoot.unmount();
        popupRoot = null;
    }
    if (popupContainer && popupContainer.parentNode) {
        popupContainer.parentNode.removeChild(popupContainer);
        popupContainer = null;
    }
    shadowRoot = null;
};

/**
 * Check if popup is currently visible.
 */
export const isPopupVisible = (): boolean => {
    return popupContainer !== null;
};

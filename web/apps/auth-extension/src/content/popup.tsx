/**
 * Inline autofill icon and dropdown component.
 * Appears inside the MFA input field like LastPass.
 * Renders in a Shadow DOM for style isolation.
 */
import React, { useEffect, useState, useRef } from "react";
import { createRoot, type Root } from "react-dom/client";
import { generateOTPs, getProgress } from "@shared/otp";
import { prettyFormatCode } from "@shared/code";
import { getResolvedTheme } from "@shared/useTheme";
import type { Code, DomainMatch } from "@shared/types";

type ResolvedTheme = "light" | "dark";

// Theme color definitions
const themeColors = {
    dark: {
        background: "#1B1B1B",
        backgroundHover: "#252525",
        textPrimary: "#FFFFFF",
        textMuted: "rgba(255, 255, 255, 0.70)",
        textFaint: "rgba(255, 255, 255, 0.50)",
        stroke: "rgba(255, 255, 255, 0.12)",
        accentPurple: "#8F33D6",
    },
    light: {
        background: "#FFFFFF",
        backgroundHover: "#F5F5F5",
        textPrimary: "#000000",
        textMuted: "rgba(0, 0, 0, 0.60)",
        textFaint: "rgba(0, 0, 0, 0.50)",
        stroke: "rgba(0, 0, 0, 0.12)",
        accentPurple: "#8F33D6",
    },
};

interface DropdownProps {
    matches: DomainMatch[];
    timeOffset: number;
    onFill: (code: string) => void;
    onClose: () => void;
    theme: ResolvedTheme;
}

const Dropdown: React.FC<DropdownProps> = ({
    matches,
    timeOffset,
    onFill,
    onClose,
    theme,
}) => {
    const [otps, setOtps] = useState<Map<string, string>>(new Map());
    const [progress, setProgress] = useState<Map<string, number>>(new Map());
    const dropdownRef = useRef<HTMLDivElement>(null);

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

    // Close on outside click - use mousedown instead of click to avoid interfering
    useEffect(() => {
        const handleClickOutside = (e: MouseEvent) => {
            // Check if click is outside the dropdown
            if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
                onClose();
            }
        };

        // Delay to avoid immediate close, and use mousedown on bubble phase
        const timeoutId = setTimeout(() => {
            document.addEventListener("mousedown", handleClickOutside, false);
        }, 100);

        return () => {
            clearTimeout(timeoutId);
            document.removeEventListener("mousedown", handleClickOutside, false);
        };
    }, [onClose]);

    const colors = themeColors[theme];

    const styles: Record<string, React.CSSProperties> = {
        dropdown: {
            position: "absolute",
            top: "100%",
            right: 0,
            marginTop: "4px",
            minWidth: "300px",
            maxWidth: "340px",
            backgroundColor: colors.background,
            borderRadius: "8px",
            boxShadow: "0 4px 20px rgba(0, 0, 0, 0.3)",
            border: `1px solid ${colors.stroke}`,
            overflow: "hidden",
            zIndex: 2147483647,
            fontFamily: '"Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        },
        header: {
            display: "flex",
            alignItems: "center",
            padding: "12px 16px",
            borderBottom: `1px solid ${colors.stroke}`,
            gap: "8px",
            backgroundColor: colors.background,
        },
        headerText: {
            fontSize: "14px",
            fontWeight: 600,
            color: colors.textPrimary,
        },
        list: {
            maxHeight: "280px",
            overflowY: "auto",
            padding: "8px",
        },
        item: {
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            padding: "12px 16px",
            cursor: "pointer",
            transition: "background-color 0.15s",
            borderRadius: "8px",
            marginBottom: "4px",
            backgroundColor: "transparent",
        },
        itemInfo: {
            flex: 1,
            minWidth: 0,
            marginRight: "16px",
        },
        issuer: {
            fontSize: "15px",
            fontWeight: 600,
            color: colors.textPrimary,
            whiteSpace: "nowrap",
            overflow: "hidden",
            textOverflow: "ellipsis",
            marginBottom: "2px",
        },
        account: {
            fontSize: "13px",
            fontWeight: 500,
            color: colors.textFaint,
            whiteSpace: "nowrap",
            overflow: "hidden",
            textOverflow: "ellipsis",
        },
        otpContainer: {
            display: "flex",
            flexDirection: "column",
            alignItems: "flex-end",
            gap: "4px",
        },
        otp: {
            fontSize: "18px",
            fontWeight: 600,
            color: colors.textPrimary,
            letterSpacing: "0.02em",
        },
        progressBarContainer: {
            width: "50px",
            height: "3px",
            backgroundColor: colors.stroke,
            borderRadius: "2px",
            overflow: "hidden",
        },
        progressBar: {
            height: "100%",
            backgroundColor: colors.accentPurple,
            transition: "width 1s linear",
        },
        empty: {
            padding: "24px 16px",
            textAlign: "center",
            color: colors.textFaint,
            fontSize: "14px",
            fontWeight: 500,
        },
    };

    return (
        <div ref={dropdownRef} style={styles.dropdown}>
            <div style={styles.header}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                    <path
                        d="M12 2L3 7V12C3 16.97 6.84 21.66 12 23C17.16 21.66 21 16.97 21 12V7L12 2Z"
                        fill="#8F33D6"
                    />
                    <path
                        d="M10 17L6 13L7.41 11.59L10 14.17L16.59 7.58L18 9L10 17Z"
                        fill="white"
                    />
                </svg>
                <span style={styles.headerText}>Ente Auth</span>
            </div>
            <div style={styles.list}>
                {matches.length === 0 ? (
                    <div style={styles.empty}>No matching codes found</div>
                ) : (
                    matches.map(({ code }) => (
                        <div
                            key={code.id}
                            style={styles.item}
                            onMouseDown={(e) => {
                                e.preventDefault();
                                e.stopPropagation();
                                const otp = otps.get(code.id) || "";
                                onFill(otp);
                            }}
                            onMouseEnter={(e) => {
                                (e.currentTarget as HTMLDivElement).style.backgroundColor = colors.backgroundHover;
                            }}
                            onMouseLeave={(e) => {
                                (e.currentTarget as HTMLDivElement).style.backgroundColor = "transparent";
                            }}
                        >
                            <div style={styles.itemInfo}>
                                <div style={styles.issuer}>{code.issuer}</div>
                                {code.account && (
                                    <div style={styles.account}>{code.account}</div>
                                )}
                            </div>
                            <div style={styles.otpContainer}>
                                <div style={styles.otp}>
                                    {prettyFormatCode(otps.get(code.id) || "")}
                                </div>
                                <div style={styles.progressBarContainer}>
                                    <div
                                        style={{
                                            ...styles.progressBar,
                                            width: `${(progress.get(code.id) || 0) * 100}%`,
                                        }}
                                    />
                                </div>
                            </div>
                        </div>
                    ))
                )}
            </div>
        </div>
    );
};

interface AutofillIconProps {
    matches: DomainMatch[];
    timeOffset: number;
    onFill: (code: string) => void;
    inputElement: HTMLInputElement;
}

const AutofillIcon: React.FC<AutofillIconProps> = ({
    matches,
    timeOffset,
    onFill,
    inputElement,
}) => {
    const [isOpen, setIsOpen] = useState(false);
    const [theme, setTheme] = useState<ResolvedTheme>("dark");
    const containerRef = useRef<HTMLDivElement>(null);

    // Load theme on mount
    useEffect(() => {
        getResolvedTheme().then(setTheme);
    }, []);

    // Auto-fill if single match
    useEffect(() => {
        if (matches.length === 1) {
            const { code } = matches[0]!;
            const [otp] = generateOTPs(code, timeOffset);
            // Small delay to let the UI render
            setTimeout(() => {
                onFill(otp);
            }, 100);
        }
    }, [matches, timeOffset, onFill]);

    const handleIconClick = (e: React.MouseEvent) => {
        e.preventDefault();
        e.stopPropagation();
        setIsOpen(!isOpen);
    };

    const handleFill = (code: string) => {
        onFill(code);
        setIsOpen(false);
    };

    const colors = themeColors[theme];

    const styles: Record<string, React.CSSProperties> = {
        container: {
            position: "relative",
            display: "inline-flex",
            alignItems: "center",
            zIndex: 2147483647,
        },
        iconButton: {
            width: "24px",
            height: "24px",
            borderRadius: "5px",
            backgroundColor: "transparent",
            border: "none",
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            padding: 0,
            transition: "transform 0.15s, box-shadow 0.15s",
            boxShadow: "0 2px 6px rgba(0, 0, 0, 0.25)",
            overflow: "hidden",
        },
    };

    return (
        <div ref={containerRef} style={styles.container}>
            <button
                style={styles.iconButton}
                onClick={handleIconClick}
                onMouseEnter={(e) => {
                    (e.currentTarget as HTMLButtonElement).style.transform = "scale(1.05)";
                }}
                onMouseLeave={(e) => {
                    (e.currentTarget as HTMLButtonElement).style.transform = "scale(1)";
                }}
                title="Ente Auth - Click to autofill"
            >
                {/* Use the same PNG icon as extension toolbar */}
                <img
                    src={chrome.runtime.getURL("assets/icons/icon16.png")}
                    alt="Ente Auth"
                    width="20"
                    height="20"
                    style={{ borderRadius: "4px" }}
                />
            </button>
            {isOpen && (
                <Dropdown
                    matches={matches}
                    timeOffset={timeOffset}
                    onFill={handleFill}
                    onClose={() => setIsOpen(false)}
                    theme={theme}
                />
            )}
        </div>
    );
};

// Global state for popup management
let iconRoot: Root | null = null;
let iconWrapper: HTMLDivElement | null = null;
let shadowHost: HTMLDivElement | null = null;

/**
 * Position the icon inside the input field.
 */
const positionIcon = (inputElement: HTMLInputElement): void => {
    if (!shadowHost) return;

    const rect = inputElement.getBoundingClientRect();
    const scrollX = window.scrollX;
    const scrollY = window.scrollY;

    // Position to the right side inside the input (24px icon + 4px padding)
    const iconSize = 24;
    const padding = 4;
    const top = rect.top + scrollY + (rect.height - iconSize) / 2;
    const left = rect.right + scrollX - iconSize - padding;

    shadowHost.style.position = "absolute";
    shadowHost.style.top = `${top}px`;
    shadowHost.style.left = `${left}px`;
    shadowHost.style.zIndex = "2147483647";
};

/**
 * Show the autofill icon next to an input field.
 */
export const showPopup = (
    matches: DomainMatch[],
    timeOffset: number,
    onFill: (code: string) => void,
    inputElement?: HTMLInputElement
): void => {
    // Remove existing icon
    hidePopup();

    if (!inputElement) return;

    // Create shadow host
    shadowHost = document.createElement("div");
    shadowHost.id = "ente-auth-icon-host";
    shadowHost.style.cssText = "all: initial; position: absolute; z-index: 2147483647;";

    const shadow = shadowHost.attachShadow({ mode: "closed" });

    // Create wrapper inside shadow DOM
    iconWrapper = document.createElement("div");
    shadow.appendChild(iconWrapper);

    // Mount React component
    iconRoot = createRoot(iconWrapper);
    iconRoot.render(
        <AutofillIcon
            matches={matches}
            timeOffset={timeOffset}
            onFill={onFill}
            inputElement={inputElement}
        />
    );

    document.body.appendChild(shadowHost);

    // Position the icon
    positionIcon(inputElement);

    // Reposition on scroll/resize
    const handleReposition = () => positionIcon(inputElement);
    window.addEventListener("scroll", handleReposition, true);
    window.addEventListener("resize", handleReposition);

    // Store cleanup handlers
    (shadowHost as any)._cleanup = () => {
        window.removeEventListener("scroll", handleReposition, true);
        window.removeEventListener("resize", handleReposition);
    };
};

/**
 * Hide and cleanup the icon.
 */
export const hidePopup = (): void => {
    if (shadowHost) {
        // Run cleanup handlers
        if ((shadowHost as any)._cleanup) {
            (shadowHost as any)._cleanup();
        }
    }
    if (iconRoot) {
        iconRoot.unmount();
        iconRoot = null;
    }
    if (shadowHost && shadowHost.parentNode) {
        shadowHost.parentNode.removeChild(shadowHost);
        shadowHost = null;
    }
    iconWrapper = null;
};

/**
 * Check if popup is currently visible.
 */
export const isPopupVisible = (): boolean => {
    return shadowHost !== null;
};

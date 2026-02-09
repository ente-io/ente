/**
 * @file Full-viewport lock screen overlay for the app lock feature.
 *
 * Renders as a sibling of the page Component in _app.tsx, covering all content
 * when the app is locked. Supports PIN (4-digit) and password input modes,
 * with brute-force cooldown display and a logout escape hatch.
 */

import LockOutlinedIcon from "@mui/icons-material/LockOutlined";
import {
    Backdrop,
    Box,
    CircularProgress,
    Paper,
    Portal,
    Stack,
    TextField,
    Typography,
} from "@mui/material";
import { EnteLogo } from "ente-base/components/EnteLogo";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { ShowHidePasswordInputAdornment } from "ente-base/components/mui/PasswordInputAdornment";
import { useBaseContext } from "ente-base/context";
import { subscribeMainWindowFocus } from "ente-base/electron";
import log from "ente-base/log";
import { t } from "i18next";
import React, {
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import {
    attemptUnlock,
    type UnlockResult,
} from "../services/app-lock";
import { useAppLockSnapshot } from "./utils/use-snapshot";

/**
 * A full-viewport overlay that blocks interaction with the app until the user
 * authenticates with their PIN or password.
 *
 * Renders nothing when the app is not locked.
 */
export const AppLockOverlay: React.FC = () => {
    const appLock = useAppLockSnapshot();
    const { logout, showMiniDialog } = useBaseContext();
    const [now, setNow] = useState(() => Date.now());

    const handleLogout = useCallback(
        () =>
            showMiniDialog({
                message: t("logout_message"),
                continue: {
                    text: t("logout"),
                    color: "critical",
                    action: logout,
                },
                buttonDirection: "row",
            }),
        [logout, showMiniDialog],
    );

    useEffect(() => {
        if (appLock.cooldownExpiresAt <= Date.now()) {
            setNow(Date.now());
            return;
        }

        const interval = setInterval(() => setNow(Date.now()), 1000);
        return () => clearInterval(interval);
    }, [appLock.cooldownExpiresAt]);

    const isInCooldown = appLock.cooldownExpiresAt > now;

    if (!appLock.isLocked) return null;

    return (
        <Portal>
            <Backdrop
                open
                role="dialog"
                aria-modal="true"
                aria-label={t("app_lock")}
                style={{ WebkitAppRegion: "no-drag" } as React.CSSProperties}
                sx={{
                    zIndex: "calc(var(--mui-zIndex-tooltip) + 1)",
                    backgroundColor: "var(--mui-palette-background-default)",
                    flexDirection: "column",
                    pointerEvents: "auto",
                }}
            >
                {/* Top bar: logo centered, logout button at top-right */}
                <Box
                    sx={{
                        position: "absolute",
                        top: 0,
                        left: 0,
                        right: 0,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        p: 3,
                    }}
                >
                    <EnteLogo />
                    {!isInCooldown && (
                        <FocusVisibleButton
                            variant="text"
                            color="secondary"
                            size="small"
                            onClick={handleLogout}
                            sx={{
                                textTransform: "none",
                                position: "absolute",
                                right: 24,
                                color: "text.muted",
                            }}
                        >
                            {t("logout")}
                        </FocusVisibleButton>
                    )}
                </Box>

                {/* Centered form content */}
                {appLock.lockType === "pin" ? (
                    <PinUnlockForm appLock={appLock} onLogout={handleLogout} />
                ) : (
                    <PasswordUnlockForm
                        appLock={appLock}
                        onLogout={handleLogout}
                    />
                )}
            </Backdrop>
        </Portal>
    );
};

// -- Shared types and helpers --

interface UnlockFormProps {
    appLock: ReturnType<typeof useAppLockSnapshot>;
    onLogout: () => void;
}

const AppLockCard: React.FC<React.PropsWithChildren> = ({ children }) => (
    <Paper
        elevation={0}
        sx={{
            width: "min(420px, 85vw)",
            minHeight: "375px",
            px: { xs: 3, sm: 5 },
            py: 5,
            borderRadius: "20px",
            boxShadow: "var(--mui-palette-boxShadow-paper)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
        }}
    >
        {children}
    </Paper>
);

/**
 * Format remaining cooldown seconds into a human-readable string.
 */
const formatCooldown = (remainingMs: number): string => {
    const totalSeconds = Math.ceil(remainingMs / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    if (minutes > 0) {
        return `${String(minutes)}m ${String(seconds)}s`;
    }
    return `${String(seconds)}s`;
};

/**
 * Hook that returns remaining cooldown time state, updating every second.
 */
const useCooldownState = (
    cooldownExpiresAt: number,
): { remainingMs: number; text: string | undefined } => {
    const [remaining, setRemaining] = useState<number>(
        Math.max(0, cooldownExpiresAt - Date.now()),
    );

    useEffect(() => {
        if (cooldownExpiresAt <= 0) {
            setRemaining(0);
            return;
        }

        const update = () => {
            const r = Math.max(0, cooldownExpiresAt - Date.now());
            setRemaining(r);
        };
        update();

        const interval = setInterval(update, 1000);
        return () => clearInterval(interval);
    }, [cooldownExpiresAt]);

    return {
        remainingMs: remaining,
        text: remaining > 0 ? formatCooldown(remaining) : undefined,
    };
};

/**
 * Keep an input focused (with a visible caret) across mount and window/tab
 * visibility/focus transitions.
 */
const useRestoreInputFocus = (
    getInput: () => HTMLInputElement | null | undefined,
) => {
    useEffect(() => {
        const focusInput = () => {
            const input = getInput();
            if (!input) return;

            input.focus({ preventScroll: true });
            // Explicitly place caret to avoid "focused but no cursor" states
            // seen after window minimize/restore in desktop.
            try {
                const pos = input.value.length;
                input.setSelectionRange(pos, pos);
            } catch {
                // Some input modes/types may not support selection APIs.
            }
        };

        const refocus = () => {
            focusInput();
            requestAnimationFrame(focusInput);
            setTimeout(focusInput, 0);
        };

        const timer = setTimeout(refocus, 100);
        const handleVisibilityChange = () => {
            if (document.visibilityState === "visible") {
                refocus();
            }
        };

        document.addEventListener("visibilitychange", handleVisibilityChange);
        window.addEventListener("focus", refocus);
        window.addEventListener("pageshow", refocus);
        const unsubscribeMainWindowFocus = subscribeMainWindowFocus(refocus);

        return () => {
            clearTimeout(timer);
            document.removeEventListener(
                "visibilitychange",
                handleVisibilityChange,
            );
            window.removeEventListener("focus", refocus);
            window.removeEventListener("pageshow", refocus);
            unsubscribeMainWindowFocus();
        };
    }, [getInput]);
};

// -- PIN unlock form --

const PinUnlockForm: React.FC<UnlockFormProps> = ({ appLock, onLogout }) => {
    const { logout } = useBaseContext();

    const [pin, setPin] = useState(["", "", "", ""]);
    const [error, setError] = useState<string>();
    const [loading, setLoading] = useState(false);
    const inputRefs = useRef<(HTMLInputElement | null)[]>([]);
    const cooldown = useCooldownState(appLock.cooldownExpiresAt);
    const cooldownText = cooldown.text;

    useRestoreInputFocus(
        useCallback(() => inputRefs.current[0], []),
    );

    const handlePinChange = useCallback(
        (index: number, value: string) => {
            // Extract the last digit, ignoring non-digit characters.
            const digit = value.replace(/\D/g, "").slice(-1);

            const newPin = [...pin];
            newPin[index] = digit;
            setPin(newPin);
            setError(undefined);

            // Auto-advance to next field.
            if (digit && index < 3) {
                inputRefs.current[index + 1]?.focus();
            }
        },
        [pin],
    );

    const handleKeyDown = useCallback(
        (index: number, e: React.KeyboardEvent) => {
            if (e.key === "Backspace" && !pin[index] && index > 0) {
                inputRefs.current[index - 1]?.focus();
            }
        },
        [pin],
    );

    const fullPin = useMemo(() => pin.join(""), [pin]);
    const focusPinInput = useCallback(
        (index: number) => {
            const input = inputRefs.current[index];
            if (!input) return;
            input.focus({ preventScroll: true });
            try {
                const pos = input.value.length;
                input.setSelectionRange(pos, pos);
            } catch {
                // Ignore if selection range isn't supported.
            }
        },
        [],
    );
    const focusFirstEmptyPinInput = useCallback(() => {
        const firstEmptyIndex = pin.findIndex((digit) => !digit);
        focusPinInput(firstEmptyIndex === -1 ? 0 : firstEmptyIndex);
    }, [pin, focusPinInput]);

    const handleSubmit = useCallback(async () => {
        if (fullPin.length !== 4 || loading) return;

        setLoading(true);
        try {
            const result: UnlockResult = await attemptUnlock(fullPin);
            handleUnlockResult(result, setError, setLoading, logout);
        } catch (e) {
            log.error("Unlock attempt failed", e);
            setError(t("generic_error"));
            setLoading(false);
        }

        // Clear PIN on any non-success.
        setPin(["", "", "", ""]);
        focusPinInput(0);
    }, [fullPin, loading, logout, focusPinInput]);

    // Auto-submit when all 4 digits are entered.
    useEffect(() => {
        if (fullPin.length === 4) {
            void handleSubmit();
        }
    }, [fullPin, handleSubmit]);

    if (cooldownText) {
        return (
            <AppLockCard>
                <CooldownScreen
                    remainingMs={cooldown.remainingMs}
                    cooldownText={cooldownText}
                    attemptCount={appLock.invalidAttemptCount}
                    onLogout={onLogout}
                />
            </AppLockCard>
        );
    }

    return (
        <AppLockCard>
            <Stack
                spacing={2}
                alignItems="center"
                sx={{ maxWidth: 340, width: "100%" }}
            >
                <LockOutlinedIcon sx={{ fontSize: 48, color: "text.muted" }} />
                <Typography variant="h3">{t("app_locked")}</Typography>
                <Typography variant="small" color="text.muted" sx={{ mb: 1 }}>
                    {t("enter_pin")}
                </Typography>

                <Stack
                    direction="row"
                    spacing={1.5}
                    justifyContent="center"
                    onClick={focusFirstEmptyPinInput}
                >
                    {pin.map((digit, i) => (
                        <TextField
                            key={i}
                            hiddenLabel
                            inputRef={(el: HTMLInputElement | null) => {
                                inputRefs.current[i] = el;
                            }}
                            value={digit}
                            onChange={(e) => handlePinChange(i, e.target.value)}
                            onKeyDown={(e) => handleKeyDown(i, e)}
                            disabled={loading}
                            slotProps={{
                                htmlInput: {
                                    maxLength: 1,
                                    inputMode: "numeric",
                                    pattern: "[0-9]",
                                    autoComplete: "off",
                                    style: {
                                        textAlign: "center",
                                        fontSize: "1.25rem",
                                        padding: "12px 0",
                                        WebkitTextSecurity: "disc",
                                    },
                                    "aria-label": `PIN digit ${String(i + 1)}`,
                                },
                            }}
                            sx={{
                                width: 48,
                                "& .MuiOutlinedInput-root.Mui-focused .MuiOutlinedInput-notchedOutline":
                                    {
                                        borderColor: "accent.main",
                                        borderWidth: 2,
                                    },
                            }}
                        />
                    ))}
                </Stack>

                <ErrorMessage
                    error={error}
                    attemptCount={appLock.invalidAttemptCount}
                />
            </Stack>
        </AppLockCard>
    );
};

// -- Password unlock form --

const PasswordUnlockForm: React.FC<UnlockFormProps> = ({
    appLock,
    onLogout,
}) => {
    const { logout } = useBaseContext();

    const [password, setPassword] = useState("");
    const [showPassword, setShowPassword] = useState(false);
    const [error, setError] = useState<string>();
    const [loading, setLoading] = useState(false);
    const inputRef = useRef<HTMLInputElement | null>(null);
    const cooldown = useCooldownState(appLock.cooldownExpiresAt);
    const cooldownText = cooldown.text;

    useRestoreInputFocus(useCallback(() => inputRef.current, []));

    const handleSubmit = useCallback(
        async (e?: React.FormEvent) => {
            e?.preventDefault();
            if (!password || loading) return;

            setLoading(true);
            try {
                const result: UnlockResult = await attemptUnlock(password);
                handleUnlockResult(result, setError, setLoading, logout);
            } catch (e) {
                log.error("Unlock attempt failed", e);
                setError(t("generic_error"));
                setLoading(false);
            }

            setPassword("");
        },
        [password, loading, logout],
    );

    if (cooldownText) {
        return (
            <AppLockCard>
                <CooldownScreen
                    remainingMs={cooldown.remainingMs}
                    cooldownText={cooldownText}
                    attemptCount={appLock.invalidAttemptCount}
                    onLogout={onLogout}
                />
            </AppLockCard>
        );
    }

    return (
        <AppLockCard>
            <Stack
                component="form"
                onSubmit={(e: React.FormEvent) => void handleSubmit(e)}
                spacing={3}
                alignItems="center"
                sx={{ maxWidth: 340, width: "100%" }}
            >
                <LockOutlinedIcon sx={{ fontSize: 48, color: "text.muted" }} />
                <Typography variant="h3">{t("app_locked")}</Typography>
                <Typography variant="small" color="text.muted">
                    {t("app_lock_enter_password")}
                </Typography>

                <TextField
                    inputRef={inputRef}
                    fullWidth
                    hiddenLabel
                    type={showPassword ? "text" : "password"}
                    value={password}
                    onChange={(e) => {
                        setPassword(e.target.value);
                        setError(undefined);
                    }}
                    disabled={loading}
                    placeholder={t("app_lock_password")}
                    autoComplete="off"
                    slotProps={{
                        input: {
                            endAdornment: (
                                <ShowHidePasswordInputAdornment
                                    showPassword={showPassword}
                                    onToggle={() => setShowPassword((s) => !s)}
                                />
                            ),
                        },
                    }}
                />

                <FocusVisibleButton
                    type="submit"
                    fullWidth
                    color="accent"
                    disabled={!password || loading}
                >
                    {t("unlock")}
                </FocusVisibleButton>

                <ErrorMessage
                    error={error}
                    attemptCount={appLock.invalidAttemptCount}
                />
            </Stack>
        </AppLockCard>
    );
};

// -- Shared sub-components --

interface ErrorMessageProps {
    error: string | undefined;
    attemptCount: number;
}

const ErrorMessage: React.FC<ErrorMessageProps> = ({
    error,
    attemptCount,
}) => {
    if (error) {
        return (
            <Typography variant="small" color="critical.main" textAlign="center">
                {error}
                {attemptCount > 0 &&
                    ` (${String(attemptCount)}/10)`}
            </Typography>
        );
    }
    return null;
};

interface CooldownScreenProps {
    remainingMs: number;
    cooldownText: string;
    attemptCount: number;
    onLogout: () => void;
}

const cooldownDurationMs = (attemptCount: number): number => {
    if (attemptCount < 5) return 0;
    return Math.pow(2, attemptCount - 5) * 30 * 1000;
};

const CooldownScreen: React.FC<CooldownScreenProps> = ({
    remainingMs,
    cooldownText,
    attemptCount,
    onLogout,
}) => {
    const durationMs = cooldownDurationMs(attemptCount);
    const progress =
        durationMs > 0
            ? Math.min(100, ((durationMs - remainingMs) / durationMs) * 100)
            : 0;
    const nextAttemptCount = attemptCount + 1;
    const nextCooldownMs = cooldownDurationMs(nextAttemptCount);
    const attemptsLabel = attemptCount === 1 ? "time" : "times";
    const nextAttemptMessage =
        nextAttemptCount >= 10
            ? "One more wrong attempt will log you out."
            : `After the next wrong attempt, you'll need to wait ${formatCooldown(nextCooldownMs)}.`;

    return (
        <Stack
            spacing={1.25}
            useFlexGap
            alignItems="center"
            justifyContent="center"
            sx={{ maxWidth: 340, width: "100%", px: 2 }}
        >
            <Typography
                variant="h3"
                color="text.primary"
                textAlign="center"
                sx={{ mb: 2.5 }}
            >
                {t("app_locked")}
            </Typography>

            <Box sx={{ position: "relative", display: "inline-flex", mb: 2 }}>
                <CircularProgress
                    variant="determinate"
                    value={100}
                    size={112}
                    thickness={2.2}
                    sx={{ color: "var(--mui-palette-fill-faint)" }}
                />
                <CircularProgress
                    variant="determinate"
                    value={progress}
                    size={112}
                    thickness={2.6}
                    sx={{
                        position: "absolute",
                        left: 0,
                        color: "critical.main",
                    }}
                />
                <Box
                    sx={{
                        position: "absolute",
                        inset: 0,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                    }}
                >
                    <Typography variant="body" color="critical.main" textAlign="center">
                        {cooldownText}
                    </Typography>
                </Box>
            </Box>

            <Typography variant="small" color="text.muted" textAlign="center">
                {`You've entered the wrong unlock code ${String(attemptCount)} ${attemptsLabel}.`}
            </Typography>
            <Typography
                variant="mini"
                color="text.muted"
                textAlign="center"
                sx={{
                    width: "100%",
                    pt: 0.75,
                    borderTop: "1px solid var(--mui-palette-divider)",
                    opacity: 0.9,
                }}
            >
                {nextAttemptMessage}
            </Typography>
            <FocusVisibleButton
                fullWidth
                color="secondary"
                onClick={onLogout}
                sx={{ mt: 1 }}
            >
                {t("logout")}
            </FocusVisibleButton>
        </Stack>
    );
};

// -- Helpers --

/**
 * Handle the result of an unlock attempt, updating UI state accordingly.
 */
const handleUnlockResult = (
    result: UnlockResult,
    setError: (error: string | undefined) => void,
    setLoading: (loading: boolean) => void,
    logout: () => void,
) => {
    switch (result) {
        case "success":
            setError(undefined);
            setLoading(false);
            break;
        case "cooldown":
            setError(undefined);
            setLoading(false);
            break;
        case "logout":
            void Promise.resolve(logout());
            setLoading(false);
            break;
        case "failed":
            setError(t("app_lock_incorrect"));
            setLoading(false);
            break;
    }
};

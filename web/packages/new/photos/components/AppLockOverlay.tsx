/**
 * @file Full-viewport lock screen overlay for the app lock feature.
 *
 * Renders as a sibling of the page Component in _app.tsx, covering all content
 * when the app is locked. Supports PIN (4-digit), password, and local native
 * device lock unlock mode, with brute-force cooldown display and a
 * logout escape hatch.
 */

import FingerprintIcon from "@mui/icons-material/Fingerprint";
import LockOutlinedIcon from "@mui/icons-material/LockOutlined";
import {
    Box,
    CircularProgress,
    Modal,
    Paper,
    Stack,
    TextField,
    Typography,
} from "@mui/material";
import { EnteLogo } from "ente-base/components/EnteLogo";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { ShowHidePasswordInputAdornment } from "ente-base/components/mui/PasswordInputAdornment";
import { useBaseContext } from "ente-base/context";
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
    appLockCooldownDurationMs,
    attemptDeviceLockUnlock,
    attemptUnlock,
    type DeviceLockUnlockResult,
    type UnlockResult,
} from "../services/app-lock";
import { useAppLockSnapshot } from "./utils/use-snapshot";

/**
 * A full-viewport overlay that blocks interaction with the app until the user
 * authenticates with their PIN, password, or local device lock challenge.
 *
 * Renders nothing when the app is not locked.
 */
export const AppLockOverlay: React.FC = () => {
    const appLock = useAppLockSnapshot();
    const { logout } = useBaseContext();
    const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);
    const isReauthentication = appLock.lockScreenMode === "reauthenticate";

    useEffect(() => {
        if (!appLock.isLocked) setShowLogoutConfirm(false);
    }, [appLock.isLocked]);

    if (!appLock.isLocked) return null;

    const unlockForm =
        appLock.lockType === "pin" ? (
            <PinUnlockForm
                appLock={appLock}
                isReauthentication={isReauthentication}
                onLogout={() => setShowLogoutConfirm(true)}
            />
        ) : appLock.lockType === "password" ? (
            <PasswordUnlockForm
                appLock={appLock}
                isReauthentication={isReauthentication}
                onLogout={() => setShowLogoutConfirm(true)}
            />
        ) : appLock.lockType === "device" ? (
            <DeviceLockUnlockForm isReauthentication={isReauthentication} />
        ) : (
            <PinUnlockForm
                appLock={appLock}
                isReauthentication={isReauthentication}
                onLogout={() => setShowLogoutConfirm(true)}
            />
        );

    if (isReauthentication) {
        return (
            <Modal
                open
                disableEscapeKeyDown
                aria-label={t("authenticate")}
                sx={{ zIndex: "calc(var(--mui-zIndex-modal) + 1)" }}
            >
                <Box
                    sx={{
                        position: "fixed",
                        inset: 0,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        p: 2,
                        outline: "none",
                    }}
                    style={
                        { WebkitAppRegion: "no-drag" } as React.CSSProperties
                    }
                >
                    {unlockForm}
                    {showLogoutConfirm && (
                        <LogoutConfirmation
                            onConfirm={logout}
                            onCancel={() => setShowLogoutConfirm(false)}
                        />
                    )}
                </Box>
            </Modal>
        );
    }

    return (
        <Modal
            open
            disableEscapeKeyDown
            aria-label={t("app_lock")}
            slotProps={{
                backdrop: {
                    sx: {
                        backgroundColor:
                            "var(--mui-palette-background-default)",
                    },
                },
            }}
            sx={{ zIndex: "calc(var(--mui-zIndex-tooltip) + 1)" }}
        >
            <Box
                sx={{
                    position: "fixed",
                    inset: 0,
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    justifyContent: "center",
                    outline: "none",
                }}
                style={{ WebkitAppRegion: "no-drag" } as React.CSSProperties}
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
                    {!showLogoutConfirm && (
                        <FocusVisibleButton
                            variant="text"
                            color="secondary"
                            size="small"
                            onClick={() => setShowLogoutConfirm(true)}
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
                {unlockForm}

                {/* Logout confirmation overlays on top */}
                {showLogoutConfirm && (
                    <LogoutConfirmation
                        onConfirm={logout}
                        onCancel={() => setShowLogoutConfirm(false)}
                    />
                )}
            </Box>
        </Modal>
    );
};

// -- Shared types and helpers --

interface UnlockFormProps {
    appLock: ReturnType<typeof useAppLockSnapshot>;
    isReauthentication: boolean;
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
 *
 * Input is in milliseconds, so convert it to minutes and seconds for display.
 *
 *  - "Xm Ys" if at least 1 minute
 *  - "Xs" if under a minute
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
 * Move the caret to the end of the current input value.
 */
const moveCaretToInputEnd = (input: HTMLInputElement) => {
    try {
        const caretPosition = input.value.length;
        input.setSelectionRange(caretPosition, caretPosition);
    } catch {
        // Ignore if selection range isn't supported.
    }
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

const deviceLockErrorText = (result: DeviceLockUnlockResult) => {
    if (result.status === "success") return undefined;

    if (result.status === "not-supported") {
        switch (result.reason) {
            case "touchid-api-error":
                return t("device_lock_login_failed");
            case "unsupported-platform":
            case "touchid-not-enrolled":
                return t("device_lock_not_supported");
        }
    }

    switch (result.reason) {
        case "native-prompt-failed":
            return t("device_lock_login_cancelled");
        default:
            return t("device_lock_login_failed");
    }
};

// -- PIN unlock form --

const PinUnlockForm: React.FC<UnlockFormProps> = ({
    appLock,
    isReauthentication,
    onLogout,
}) => {
    const { logout } = useBaseContext();

    const [pin, setPin] = useState(["", "", "", ""]);
    const [error, setError] = useState<string>();
    const [loading, setLoading] = useState(false);
    const inputRefs = useRef<(HTMLInputElement | null)[]>([]);
    const cooldown = useCooldownState(appLock.cooldownExpiresAt);
    const cooldownText = cooldown.text;

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

    /**
     * Focus the PIN field at the given index, then place the caret at the end.
     */
    const focusPinInput = useCallback((pinIndex: number) => {
        const input = inputRefs.current[pinIndex];
        if (!input) {
            return;
        }

        input.focus({ preventScroll: true });
        moveCaretToInputEnd(input);
    }, []);
    const focusFirstEmptyPinInput = useCallback(() => {
        const firstEmptyIndex = pin.findIndex((digit) => !digit);
        focusPinInput(firstEmptyIndex === -1 ? 0 : firstEmptyIndex);
    }, [pin, focusPinInput]);

    const handleSubmit = useCallback(async () => {
        if (fullPin.length !== 4 || loading) return;

        setLoading(true);
        try {
            const result: UnlockResult = await attemptUnlock(fullPin);

            /**
             * The result can be "success", "failed", "cooldown", or "logout".
             * Apply the corresponding UI updates for each case.
             */
            handleUnlockResult(result, setError, setLoading, logout);
        } catch (e) {
            log.error("Unlock attempt failed", e);
            setError(t("generic_error"));
            setLoading(false);
        }

        // Clear PIN after each attempt and refocus the first field.
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
                <Typography variant="h3">
                    {isReauthentication ? t("authenticate") : t("app_locked")}
                </Typography>
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
                            autoFocus={i === 0}
                            error={!!error}
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
    isReauthentication,
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
            inputRef.current?.focus();
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
                <Typography variant="h3">
                    {isReauthentication ? t("password") : t("app_locked")}
                </Typography>
                <Typography variant="small" color="text.muted">
                    {t("app_lock_enter_password")}
                </Typography>

                <TextField
                    inputRef={inputRef}
                    fullWidth
                    hiddenLabel
                    autoFocus
                    error={!!error}
                    type={showPassword ? "text" : "password"}
                    value={password}
                    onChange={(e) => {
                        setPassword(e.target.value);
                        setError(undefined);
                    }}
                    disabled={loading}
                    placeholder={
                        isReauthentication
                            ? t("password")
                            : t("app_lock_password")
                    }
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
                    {isReauthentication ? t("authenticate") : t("unlock")}
                </FocusVisibleButton>

                <ErrorMessage
                    error={error}
                    attemptCount={appLock.invalidAttemptCount}
                />
            </Stack>
        </AppLockCard>
    );
};

// -- Device lock unlock form --

const DeviceLockUnlockForm: React.FC<{ isReauthentication: boolean }> = ({
    isReauthentication,
}) => {
    const [error, setError] = useState<string>();
    const [loading, setLoading] = useState(false);
    const isUnlockInProgress = useRef(false);

    const handleDeviceLockUnlock = useCallback(async () => {
        if (isUnlockInProgress.current) return;
        isUnlockInProgress.current = true;
        setLoading(true);
        setError(undefined);

        try {
            const result: DeviceLockUnlockResult =
                await attemptDeviceLockUnlock();
            setError(deviceLockErrorText(result));
        } catch (e) {
            log.error("Device lock unlock attempt failed", e);
            setError(t("generic_error"));
        } finally {
            setLoading(false);
            isUnlockInProgress.current = false;
        }
    }, []);

    return (
        <AppLockCard>
            <Stack
                spacing={3}
                alignItems="center"
                sx={{ maxWidth: 340, width: "100%" }}
            >
                <FingerprintIcon sx={{ fontSize: 48, color: "text.muted" }} />
                <Typography variant="h3">
                    {isReauthentication ? t("authenticate") : t("app_locked")}
                </Typography>
                <Typography
                    variant="small"
                    color="text.muted"
                    textAlign="center"
                >
                    {t("device_lock_login_instructions")}
                </Typography>

                <FocusVisibleButton
                    fullWidth
                    color="accent"
                    disabled={loading}
                    onClick={() => {
                        void handleDeviceLockUnlock();
                    }}
                >
                    {loading ? (
                        <CircularProgress size={18} color="inherit" />
                    ) : isReauthentication ? (
                        t("authenticate")
                    ) : (
                        t("device_lock_login")
                    )}
                </FocusVisibleButton>

                <Typography
                    variant="small"
                    color={error ? "critical.main" : "text.muted"}
                    textAlign="center"
                >
                    {error}
                </Typography>
            </Stack>
        </AppLockCard>
    );
};

// -- Shared sub-components --

interface ErrorMessageProps {
    error: string | undefined;
    attemptCount: number;
}

const ErrorMessage: React.FC<ErrorMessageProps> = ({ error, attemptCount }) => {
    if (error) {
        return (
            <Typography
                variant="small"
                color="critical.main"
                textAlign="center"
            >
                {error}
                {attemptCount > 0 && ` (${String(attemptCount)}/10)`}
            </Typography>
        );
    }
    return null;
};

interface LogoutConfirmationProps {
    onConfirm: () => void;
    onCancel: () => void;
}

const LogoutConfirmation: React.FC<LogoutConfirmationProps> = ({
    onConfirm,
    onCancel,
}) => (
    <Box
        sx={{
            position: "absolute",
            inset: 0,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            backgroundColor: "rgba(0,0,0,0.5)",
            zIndex: 1,
        }}
        onClick={onCancel}
    >
        <Paper
            elevation={0}
            sx={{
                width: "min(420px, 85vw)",
                px: { xs: 3, sm: 5 },
                py: 4,
                borderRadius: "20px",
                boxShadow: "var(--mui-palette-boxShadow-paper)",
            }}
            onClick={(e) => e.stopPropagation()}
        >
            <Stack spacing={3} alignItems="center" sx={{ width: "100%" }}>
                <Typography variant="h3">{t("logout")}</Typography>
                <Typography
                    variant="small"
                    color="text.muted"
                    textAlign="center"
                >
                    {t("logout_message")}
                </Typography>
                <Stack direction="row" spacing={1.5} sx={{ width: "100%" }}>
                    <FocusVisibleButton
                        fullWidth
                        color="secondary"
                        onClick={onCancel}
                    >
                        {t("cancel")}
                    </FocusVisibleButton>
                    <FocusVisibleButton
                        fullWidth
                        color="critical"
                        onClick={onConfirm}
                    >
                        {t("logout")}
                    </FocusVisibleButton>
                </Stack>
            </Stack>
        </Paper>
    </Box>
);

interface CooldownScreenProps {
    remainingMs: number;
    cooldownText: string;
    attemptCount: number;
    onLogout: () => void;
}

const CooldownScreen: React.FC<CooldownScreenProps> = ({
    remainingMs,
    cooldownText,
    attemptCount,
    onLogout,
}) => {
    const durationMs = appLockCooldownDurationMs(attemptCount);
    const progress =
        durationMs > 0
            ? Math.min(100, ((durationMs - remainingMs) / durationMs) * 100)
            : 0;

    return (
        <Stack
            spacing={1.25}
            useFlexGap
            alignItems="center"
            justifyContent="center"
            sx={{ maxWidth: 380, width: "100%", px: 2 }}
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
                    <Typography
                        variant="body"
                        color="critical.main"
                        textAlign="center"
                    >
                        {cooldownText}
                    </Typography>
                </Box>
            </Box>

            <Typography variant="small" color="text.muted" textAlign="center">
                {t("wrong_unlock_code", { count: attemptCount })}
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
        case "cooldown":
            setError(undefined);
            setLoading(false);
            break;
        case "logout":
            logout();
            setLoading(false);
            break;
        case "failed":
            setError(t("app_lock_incorrect"));
            setLoading(false);
            break;
    }
};

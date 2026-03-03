/**
 * @file Full-viewport lock screen overlay for the app lock feature.
 *
 * Renders as a sibling of the page Component in _app.tsx, covering all content
 * when the app is locked. Supports PIN (4-digit), password, and local native
 * device lock unlock mode, with brute-force cooldown display and a
 * logout escape hatch.
 */

import { Logout05Icon } from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import CloseIcon from "@mui/icons-material/Close";
import {
    Box,
    CircularProgress,
    IconButton,
    Modal,
    Paper,
    Stack,
    TextField,
    Typography,
} from "@mui/material";
import type { Theme } from "@mui/material/styles";
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
    attemptDeviceLockUnlock,
    attemptUnlock,
    cancelReauthentication,
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

    const closeAction =
        isReauthentication && !showLogoutConfirm ? (
            <IconButton
                aria-label={t("close")}
                onClick={cancelReauthentication}
                sx={(theme) => ({
                    backgroundColor: "#FAFAFA",
                    color: "#000",
                    p: 1.25,
                    "&:hover": { backgroundColor: "#F0F0F0" },
                    ...theme.applyStyles("dark", {
                        backgroundColor: "rgba(255, 255, 255, 0.12)",
                        color: "#fff",
                        "&:hover": {
                            backgroundColor: "rgba(255, 255, 255, 0.16)",
                        },
                    }),
                })}
            >
                <CloseIcon sx={{ fontSize: 20 }} />
            </IconButton>
        ) : undefined;

    const unlockForm =
        appLock.lockType === "pin" ? (
            <PinUnlockForm
                appLock={appLock}
                isReauthentication={isReauthentication}
                onLogout={() => setShowLogoutConfirm(true)}
                closeAction={closeAction}
            />
        ) : appLock.lockType === "password" ? (
            <PasswordUnlockForm
                appLock={appLock}
                isReauthentication={isReauthentication}
                onLogout={() => setShowLogoutConfirm(true)}
                closeAction={closeAction}
            />
        ) : appLock.lockType === "device" ? (
            <DeviceLockUnlockForm
                isReauthentication={isReauthentication}
                closeAction={closeAction}
            />
        ) : (
            <PinUnlockForm
                appLock={appLock}
                isReauthentication={isReauthentication}
                onLogout={() => setShowLogoutConfirm(true)}
                closeAction={closeAction}
            />
        );

    if (isReauthentication) {
        return (
            <Modal
                open
                disableEscapeKeyDown
                aria-label={t("authenticate")}
                slotProps={{
                    backdrop: {
                        sx: {
                            backgroundColor:
                                "var(--mui-palette-backdrop-muted)",
                        },
                    },
                }}
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
                    {showLogoutConfirm ? (
                        <LogoutConfirmation
                            onConfirm={logout}
                            onCancel={() => setShowLogoutConfirm(false)}
                        />
                    ) : (
                        unlockForm
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
                    sx: (theme) => ({
                        backgroundColor: "secondary.main",
                        ...theme.applyStyles("dark", {
                            backgroundColor: "#000",
                        }),
                    }),
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
                {showLogoutConfirm ? (
                    <LogoutConfirmation
                        onConfirm={logout}
                        onCancel={() => setShowLogoutConfirm(false)}
                    />
                ) : (
                    unlockForm
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
    closeAction?: React.ReactNode;
}

const ENTE_GREEN = "#08C225";
const ENTE_GREEN_HOVER = "#07A820";
const APP_LOCK_MODAL_WIDTH = 408;
const APP_LOCK_MODAL_CONTENT_WIDTH = APP_LOCK_MODAL_WIDTH - 32;

const titleTextSx = (theme: Theme) => ({
    fontWeight: 600,
    fontSize: 24,
    lineHeight: "28px",
    letterSpacing: "-0.48px",
    color: "#000",
    textAlign: "center" as const,
    ...theme.applyStyles("dark", { color: "#fff" }),
});

const subtitleTextSx = (theme: Theme) => ({
    fontWeight: 500,
    fontSize: 14,
    lineHeight: "20px",
    color: "#666",
    textAlign: "center" as const,
    maxWidth: 295,
    ...theme.applyStyles("dark", { color: "rgba(255, 255, 255, 0.64)" }),
});

const primaryActionButtonSx = (theme: Theme) => ({
    display: "flex",
    minHeight: 56,
    padding: "18px 16px",
    justifyContent: "center",
    alignItems: "center",
    gap: 1,
    borderRadius: "20px",
    backgroundColor: ENTE_GREEN,
    fontSize: 16,
    fontWeight: 500,
    lineHeight: "20px",
    textTransform: "none" as const,
    color: "#fff",
    boxShadow: "none",
    "&:hover": { backgroundColor: ENTE_GREEN_HOVER, boxShadow: "none" },
    "&.Mui-disabled": {
        backgroundColor: "rgba(0, 0, 0, 0.04)",
        color: "#999",
        opacity: 1,
    },
    ...theme.applyStyles("dark", {
        "&.Mui-disabled": {
            backgroundColor: "rgba(255, 255, 255, 0.08)",
            color: "rgba(255, 255, 255, 0.5)",
            opacity: 1,
        },
    }),
});

const secondaryActionButtonSx = (theme: Theme) => ({
    display: "flex",
    minHeight: 60,
    padding: "20px 16px",
    justifyContent: "center",
    alignItems: "center",
    gap: 1,
    borderRadius: "20px",
    backgroundColor: "#F2F2F2",
    fontSize: 16,
    fontWeight: 600,
    lineHeight: "20px",
    textTransform: "none" as const,
    color: "#333",
    boxShadow: "none",
    "&:hover": { backgroundColor: "#E8E8E8", boxShadow: "none" },
    ...theme.applyStyles("dark", {
        backgroundColor: "rgba(255, 255, 255, 0.08)",
        color: "rgba(255, 255, 255, 0.9)",
        "&:hover": { backgroundColor: "rgba(255, 255, 255, 0.12)" },
    }),
});

const inputFieldSx = (theme: Theme, options?: { borderRadius?: number }) => ({
    borderRadius: options?.borderRadius ?? 12,
    "& .MuiInputBase-root": {
        // Enforce shape/height at InputBase level so variant-specific styles
        // don't collapse these fields into pill/circle forms.
        height: 54,
        borderRadius: `${String(options?.borderRadius ?? 12)}px !important`,
        overflow: "hidden",
    },
    "& .MuiInput-root": {
        height: 54,
        backgroundColor: "#FAFAFA",
        borderRadius: `${String(options?.borderRadius ?? 12)}px !important`,
        "&::before": { borderBottom: "1px solid #E0E0E0" },
        "&::after": { borderBottom: `2px solid ${ENTE_GREEN}` },
        "&.Mui-error::after": { borderBottomColor: theme.palette.error.main },
        "&:hover:not(.Mui-disabled)::before": {
            borderBottom: "1px solid #BDBDBD",
        },
    },
    "& .MuiInputBase-input": {
        padding: "0 16px",
        height: "100%",
        boxSizing: "border-box" as const,
        fontSize: 16,
        color: "#000",
        "&::placeholder": { color: "#999", opacity: 1 },
    },
    ...theme.applyStyles("dark", {
        "& .MuiInput-root": {
            backgroundColor: "rgba(255, 255, 255, 0.08)",
            "&::before": { borderBottom: "1px solid rgba(255, 255, 255, 0.3)" },
            "&:hover:not(.Mui-disabled)::before": {
                borderBottom: "1px solid rgba(255, 255, 255, 0.5)",
            },
        },
        "& .MuiInputBase-root": {
            backgroundColor: "rgba(255, 255, 255, 0.08)",
        },
        "& .MuiInputBase-input": {
            color: "#fff",
            "&::placeholder": { color: "rgba(255, 255, 255, 0.5)" },
        },
    }),
});

const LOCK_ILLUSTRATION_SRC = new URL(
    "./icons/lock.svg",
    import.meta.url,
).toString();

const LockIllustration: React.FC = () => (
    <Box
        component="img"
        src={LOCK_ILLUSTRATION_SRC}
        alt=""
        aria-hidden
        draggable={false}
        sx={{
            width: 124,
            maxWidth: "100%",
            height: "auto",
            display: "block",
            lineHeight: 0,
            userSelect: "none",
        }}
    />
);

const AppLockCard: React.FC<
    React.PropsWithChildren<{ closeAction?: React.ReactNode }>
> = ({ children, closeAction }) => (
    <Paper
        elevation={0}
        sx={(theme) => ({
            width: APP_LOCK_MODAL_WIDTH,
            maxWidth: "calc(100% - 32px)",
            borderRadius: "28px",
            backgroundColor: "#fff",
            border: "1px solid #E0E0E0",
            boxShadow: "none",
            overflow: "visible",
            ...theme.applyStyles("dark", {
                backgroundColor: "#1B1B1B",
                border: "1px solid rgba(255, 255, 255, 0.18)",
            }),
        })}
    >
        <Box
            sx={{
                position: "relative",
                width: "100%",
                pt: closeAction ? 2 : 6,
                px: 2,
                pb: 2.5,
            }}
        >
            {closeAction && (
                <Box
                    sx={{
                        width: "100%",
                        display: "flex",
                        justifyContent: "flex-end",
                        mb: 1,
                    }}
                >
                    {closeAction}
                </Box>
            )}
            <Box
                sx={{
                    width: "100%",
                    display: "flex",
                    justifyContent: "center",
                }}
            >
                {children}
            </Box>
        </Box>
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
    closeAction,
}) => {
    const { logout } = useBaseContext();

    const [pin, setPin] = useState(["", "", "", ""]);
    const [error, setError] = useState<string>();
    const [loading, setLoading] = useState(false);
    const inputRefs = useRef<(HTMLInputElement | null)[]>([]);
    const isSubmittingRef = useRef(false);
    const hasAutoSubmittedRef = useRef(false);
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
        if (fullPin.length !== 4 || loading || isSubmittingRef.current) return;

        isSubmittingRef.current = true;
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
        } finally {
            isSubmittingRef.current = false;
        }

        // Clear PIN after each attempt and refocus the first field.
        setPin(["", "", "", ""]);
        focusPinInput(0);
    }, [fullPin, loading, logout, focusPinInput]);

    useEffect(() => {
        if (fullPin.length !== 4) {
            hasAutoSubmittedRef.current = false;
            return;
        }

        if (loading || hasAutoSubmittedRef.current) return;

        hasAutoSubmittedRef.current = true;
        void handleSubmit();
    }, [fullPin, loading, handleSubmit]);

    useEffect(() => {
        if (!error || loading || cooldownText) return;

        const rafID = requestAnimationFrame(() => {
            focusPinInput(0);
        });
        return () => cancelAnimationFrame(rafID);
    }, [error, loading, cooldownText, focusPinInput]);

    if (cooldownText) {
        return (
            <AppLockCard closeAction={closeAction}>
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
        <Stack spacing={0} useFlexGap alignItems="center">
            <AppLockCard closeAction={closeAction}>
                <Stack
                    spacing={0}
                    useFlexGap
                    alignItems="center"
                    sx={{ maxWidth: APP_LOCK_MODAL_CONTENT_WIDTH, width: "100%" }}
                >
                <Box
                    sx={{
                        mt: -0.5,
                        mb: 1.5,
                        display: "flex",
                        justifyContent: "center",
                        width: "100%",
                    }}
                >
                    <LockIllustration />
                </Box>

                <Box
                    sx={{
                        display: "flex",
                        flexDirection: "column",
                        alignItems: "center",
                        gap: "9px",
                        textAlign: "center",
                        mb: 4,
                    }}
                >
                    <Typography
                        sx={(theme) => ({
                            ...titleTextSx(theme),
                            ...(isReauthentication ? {} : { mb: 0.5 }),
                        })}
                    >
                        {isReauthentication
                            ? t("authenticate")
                            : t("app_locked")}
                    </Typography>
                    <Typography sx={subtitleTextSx}>
                        {t("app_lock_enter_pin_to_unlock")}
                    </Typography>
                </Box>

                <Stack
                    direction="row"
                    spacing={1.25}
                    justifyContent="center"
                    onClick={focusFirstEmptyPinInput}
                    sx={{ mb: 0, width: "100%" }}
                >
                    {pin.map((digit, i) => (
                        <TextField
                            key={i}
                            variant="standard"
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
                                        WebkitTextSecurity: "disc",
                                    },
                                    "aria-label": t(
                                        "app_lock_pin_digit_label",
                                        { index: i + 1 },
                                    ),
                                },
                            }}
                            sx={(theme) => ({
                                ...inputFieldSx(theme, { borderRadius: 12 }),
                                flex: 1,
                                minWidth: 0,
                                "& .MuiInputBase-input": {
                                    padding: 0,
                                    textAlign: "center",
                                    height: "100%",
                                    fontSize: 20,
                                    fontWeight: 600,
                                },
                            })}
                        />
                    ))}
                </Stack>

                    <FocusVisibleButton
                        fullWidth
                        color="accent"
                        disabled={fullPin.length !== 4 || loading}
                        onClick={() => {
                            void handleSubmit();
                        }}
                        sx={(theme) => ({
                            ...primaryActionButtonSx(theme),
                            mt: 2,
                        })}
                    >
                        {loading ? (
                            <CircularProgress size={18} color="inherit" />
                        ) : isReauthentication ? (
                            t("authenticate")
                        ) : (
                            t("unlock")
                        )}
                    </FocusVisibleButton>
                </Stack>
            </AppLockCard>

            <ErrorMessage
                error={error}
                attemptCount={appLock.invalidAttemptCount}
            />
        </Stack>
    );
};

// -- Password unlock form --

const PasswordUnlockForm: React.FC<UnlockFormProps> = ({
    appLock,
    isReauthentication,
    onLogout,
    closeAction,
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

    useEffect(() => {
        if (!error || loading || cooldownText) return;

        const rafID = requestAnimationFrame(() => {
            inputRef.current?.focus();
        });
        return () => cancelAnimationFrame(rafID);
    }, [error, loading, cooldownText]);

    if (cooldownText) {
        return (
            <AppLockCard closeAction={closeAction}>
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
        <Stack spacing={0} useFlexGap alignItems="center">
            <AppLockCard closeAction={closeAction}>
                <Stack
                    component="form"
                    onSubmit={(e: React.FormEvent) => void handleSubmit(e)}
                    spacing={0}
                    useFlexGap
                    alignItems="center"
                    sx={{ maxWidth: APP_LOCK_MODAL_CONTENT_WIDTH, width: "100%" }}
                >
                    <Box
                        sx={{
                            mt: -0.5,
                            mb: 1.5,
                            display: "flex",
                            justifyContent: "center",
                            width: "100%",
                        }}
                    >
                        <LockIllustration />
                    </Box>

                    <Box
                        sx={{
                            display: "flex",
                            flexDirection: "column",
                            alignItems: "center",
                            gap: "9px",
                            textAlign: "center",
                            mb: 2,
                        }}
                    >
                        <Typography
                            sx={(theme) => ({
                                ...titleTextSx(theme),
                                ...(isReauthentication ? {} : { mb: 0.5 }),
                            })}
                        >
                            {isReauthentication
                                ? t("password")
                                : t("app_locked")}
                        </Typography>
                        <Typography sx={subtitleTextSx}>
                            {t("app_lock_enter_password")}
                        </Typography>
                    </Box>

                    <TextField
                        inputRef={inputRef}
                        fullWidth
                        hiddenLabel
                        variant="standard"
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
                        sx={(theme) => ({
                            ...inputFieldSx(theme),
                            mt: 1,
                            "& .MuiInputAdornment-positionEnd": {
                                pr: 0.5,
                            },
                        })}
                    />

                    <FocusVisibleButton
                        type="submit"
                        fullWidth
                        color="accent"
                        disabled={!password || loading}
                        sx={(theme) => ({
                            ...primaryActionButtonSx(theme),
                            mt: 2,
                        })}
                    >
                        {isReauthentication ? t("authenticate") : t("unlock")}
                    </FocusVisibleButton>
                </Stack>
            </AppLockCard>

            <ErrorMessage
                error={error}
                attemptCount={appLock.invalidAttemptCount}
            />
        </Stack>
    );
};

// -- Device lock unlock form --

const DeviceLockUnlockForm: React.FC<{
    isReauthentication: boolean;
    closeAction?: React.ReactNode;
}> = ({ isReauthentication, closeAction }) => {
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
        <Stack spacing={0} useFlexGap alignItems="center">
            <AppLockCard closeAction={closeAction}>
                <Stack
                    spacing={0}
                    useFlexGap
                    alignItems="center"
                    sx={{ maxWidth: APP_LOCK_MODAL_CONTENT_WIDTH, width: "100%" }}
                >
                    <Box
                        sx={{
                            mt: -0.5,
                            mb: 1.5,
                            display: "flex",
                            justifyContent: "center",
                            width: "100%",
                        }}
                    >
                        <LockIllustration />
                    </Box>

                    <Box
                        sx={{
                            display: "flex",
                            flexDirection: "column",
                            alignItems: "center",
                            gap: "9px",
                            textAlign: "center",
                            mb: 2,
                        }}
                    >
                        <Typography
                            sx={(theme) => ({
                                ...titleTextSx(theme),
                                ...(isReauthentication ? {} : { mb: 0.5 }),
                            })}
                        >
                            {isReauthentication
                                ? t("authenticate")
                                : t("app_locked")}
                        </Typography>
                        <Typography sx={subtitleTextSx}>
                            {t("device_lock_login_instructions")}
                        </Typography>
                    </Box>

                    <FocusVisibleButton
                        fullWidth
                        color="accent"
                        disabled={loading}
                        onClick={() => {
                            void handleDeviceLockUnlock();
                        }}
                        sx={(theme) => ({
                            ...primaryActionButtonSx(theme),
                            backgroundColor: ENTE_GREEN,
                            "&:hover": { backgroundColor: ENTE_GREEN_HOVER },
                            fontWeight: 600,
                            mt: 2,
                        })}
                    >
                        {loading ? (
                            <CircularProgress size={18} color="inherit" />
                        ) : isReauthentication ? (
                            t("authenticate")
                        ) : (
                            t("device_lock_login")
                        )}
                    </FocusVisibleButton>
                </Stack>
            </AppLockCard>

            <ErrorMessage error={error} attemptCount={0} />
        </Stack>
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
                sx={(theme) => ({
                    ...subtitleTextSx(theme),
                    color: "#E53935",
                    mt: 3,
                    ...theme.applyStyles("dark", {
                        color: "#FF6B6B",
                    }),
                })}
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
    <AppLockCard
        closeAction={
            <IconButton
                aria-label={t("close")}
                onClick={onCancel}
                sx={(theme) => ({
                    backgroundColor: "#FAFAFA",
                    color: "#000",
                    p: 1.25,
                    "&:hover": { backgroundColor: "#F0F0F0" },
                    ...theme.applyStyles("dark", {
                        backgroundColor: "rgba(255, 255, 255, 0.12)",
                        color: "#fff",
                        "&:hover": {
                            backgroundColor: "rgba(255, 255, 255, 0.16)",
                        },
                    }),
                })}
            >
                <CloseIcon sx={{ fontSize: 20 }} />
            </IconButton>
        }
    >
        <Stack
            spacing={2}
            useFlexGap
            alignItems="center"
            justifyContent="center"
            sx={{ maxWidth: APP_LOCK_MODAL_CONTENT_WIDTH, width: "100%" }}
        >
            <Box
                sx={{
                    mb: 1,
                    display: "flex",
                    justifyContent: "center",
                    width: "100%",
                }}
            >
                <HugeiconsIcon icon={Logout05Icon} size={42} color="#08C225" />
            </Box>

            <Box
                sx={{
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    gap: "9px",
                    textAlign: "center",
                    mb: 2,
                }}
            >
                <Typography sx={titleTextSx}>{t("logout")}</Typography>
                <Typography
                    sx={(theme) => ({
                        ...subtitleTextSx(theme),
                        maxWidth: 240,
                    })}
                >
                    {t("logout_message")}
                </Typography>
            </Box>

            <Stack spacing={1.5} sx={{ width: "100%" }}>
                <FocusVisibleButton
                    fullWidth
                    onClick={onCancel}
                    sx={secondaryActionButtonSx}
                >
                    {t("cancel")}
                </FocusVisibleButton>
                <FocusVisibleButton
                    fullWidth
                    onClick={onConfirm}
                    sx={primaryActionButtonSx}
                >
                    {t("logout")}
                </FocusVisibleButton>
            </Stack>
        </Stack>
    </AppLockCard>
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
    void remainingMs;

    return (
        <Stack
            spacing={0}
            useFlexGap
            alignItems="center"
            justifyContent="center"
            sx={{ maxWidth: APP_LOCK_MODAL_CONTENT_WIDTH, width: "100%" }}
        >
            <Box
                sx={{
                    mt: -0.5,
                    mb: 1.5,
                    display: "flex",
                    justifyContent: "center",
                    width: "100%",
                }}
            >
                <LockIllustration />
            </Box>

            <Box
                sx={{
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    gap: "9px",
                    textAlign: "center",
                    mb: 2,
                }}
            >
                <Typography sx={(theme) => ({ ...titleTextSx(theme), mb: 0.5 })}>
                    {t("app_locked")}
                </Typography>
                <Typography sx={subtitleTextSx}>
                    {t("app_lock_please_try_again_in")}
                </Typography>
            </Box>

            <Typography
                sx={(theme) => ({
                    fontWeight: 600,
                    fontSize: 33,
                    lineHeight: "40px",
                    color: theme.palette.error.main,
                    textAlign: "center",
                    mb: 2,
                })}
            >
                {cooldownText}
            </Typography>

            <FocusVisibleButton
                fullWidth
                color="secondary"
                onClick={onLogout}
                sx={secondaryActionButtonSx}
            >
                {t("logout")}
            </FocusVisibleButton>
            <Typography
                sx={(theme) => ({
                    ...subtitleTextSx(theme),
                    mt: 1.25,
                    fontSize: 12,
                    lineHeight: "16px",
                })}
            >
                {t("wrong_unlock_code", { count: attemptCount })}
            </Typography>
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

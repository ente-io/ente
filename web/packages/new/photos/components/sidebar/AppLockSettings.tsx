import CheckIcon from "@mui/icons-material/Check";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import {
    DialogActions,
    Stack,
    TextField,
    Typography,
} from "@mui/material";
import {
    RowButton,
    RowButtonDivider,
    RowButtonGroup,
    RowButtonGroupHint,
    RowSwitch,
} from "ente-base/components/RowButton";
import { TitledMiniDialog } from "ente-base/components/MiniDialog";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { ShowHidePasswordInputAdornment } from "ente-base/components/mui/PasswordInputAdornment";
import {
    TitledNestedSidebarDrawer,
    type NestedSidebarDrawerVisibilityProps,
} from "ente-base/components/mui/SidebarDrawer";
import { useBaseContext } from "ente-base/context";
import {
    setupPin,
    setupPassword,
    disableAppLock,
    setAutoLockTime,
    setHideContentOnBlur,
} from "../../services/app-lock";
import { t } from "i18next";
import React, { useCallback, useRef, useState } from "react";
import { useAppLockSnapshot } from "../utils/use-snapshot";

export const AppLockSettings: React.FC<
    NestedSidebarDrawerVisibilityProps
> = ({ open, onClose, onRootClose }) => {
    const state = useAppLockSnapshot();

    const [pinDialogOpen, setPinDialogOpen] = useState(false);
    const [passwordDialogOpen, setPasswordDialogOpen] = useState(false);
    const [autoLockDialogOpen, setAutoLockDialogOpen] = useState(false);

    const { showMiniDialog } = useBaseContext();

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const handleToggleEnabled = useCallback(() => {
        if (state.enabled) {
            showMiniDialog({
                title: t("disable"),
                message: t("app_lock_disable_confirm"),
                continue: {
                    text: t("disable"),
                    color: "critical",
                    action: () => void disableAppLock(),
                },
            });
        } else {
            // When enabling, default to PIN setup.
            setPinDialogOpen(true);
        }
    }, [state.enabled, showMiniDialog]);

    const handleSelectPin = useCallback(() => {
        setPinDialogOpen(true);
    }, []);

    const handleSelectPassword = useCallback(() => {
        setPasswordDialogOpen(true);
    }, []);

    const handlePinSetupComplete = useCallback(() => {
        setPinDialogOpen(false);
    }, []);

    const handlePasswordSetupComplete = useCallback(() => {
        setPasswordDialogOpen(false);
    }, []);

    const handleToggleHideContent = useCallback(() => {
        setHideContentOnBlur(!state.hideContentOnBlur);
    }, [state.hideContentOnBlur]);

    return (
        <>
            <TitledNestedSidebarDrawer
                {...{ open, onClose }}
                onRootClose={handleRootClose}
                title={t("app_lock")}
            >
                <Stack sx={{ px: "16px", py: "20px", gap: "24px" }}>
                    <RowButtonGroup>
                        <RowSwitch
                            label={t("enabled")}
                            checked={state.enabled}
                            onClick={handleToggleEnabled}
                        />
                    </RowButtonGroup>

                    {state.enabled && (
                        <>
                            <Stack>
                                <Typography
                                    variant="small"
                                    sx={{ px: 1, pb: "6px", color: "text.muted" }}
                                >
                                    {t("lock_type")}
                                </Typography>
                                <RowButtonGroup>
                                    <RowButton
                                        label="PIN"
                                        endIcon={
                                            state.lockType === "pin" ? (
                                                <CheckIcon
                                                    sx={{ color: "accent.main" }}
                                                />
                                            ) : undefined
                                        }
                                        onClick={handleSelectPin}
                                    />
                                    <RowButtonDivider />
                                    <RowButton
                                        label={t("app_lock_password")}
                                        endIcon={
                                            state.lockType === "password" ? (
                                                <CheckIcon
                                                    sx={{ color: "accent.main" }}
                                                />
                                            ) : undefined
                                        }
                                        onClick={handleSelectPassword}
                                    />
                                </RowButtonGroup>
                            </Stack>

                            <Stack>
                                <RowButtonGroup>
                                    <RowButton
                                        label={t("auto_lock")}
                                        endIcon={<ChevronRightIcon />}
                                        caption={autoLockLabel(
                                            state.autoLockTimeMs,
                                        )}
                                        onClick={() =>
                                            setAutoLockDialogOpen(true)
                                        }
                                    />
                                </RowButtonGroup>
                                <RowButtonGroupHint>
                                    {t("auto_lock_hint")}
                                </RowButtonGroupHint>
                            </Stack>
                        </>
                    )}

                    <RowButtonGroup>
                        <RowSwitch
                            label={t("hide_content_on_blur")}
                            checked={state.hideContentOnBlur}
                            onClick={handleToggleHideContent}
                        />
                    </RowButtonGroup>
                </Stack>
            </TitledNestedSidebarDrawer>

            <PinSetupDialog
                open={pinDialogOpen}
                onClose={() => setPinDialogOpen(false)}
                onComplete={handlePinSetupComplete}
            />
            <PasswordSetupDialog
                open={passwordDialogOpen}
                onClose={() => setPasswordDialogOpen(false)}
                onComplete={handlePasswordSetupComplete}
            />
            <AutoLockDialog
                open={autoLockDialogOpen}
                onClose={() => setAutoLockDialogOpen(false)}
                currentValue={state.autoLockTimeMs}
            />
        </>
    );
};

// -- Auto-lock duration helpers --

const autoLockOptions: { label: string; ms: number }[] = [
    { label: "Immediately", ms: 0 },
    { label: "5 seconds", ms: 5_000 },
    { label: "15 seconds", ms: 15_000 },
    { label: "1 minute", ms: 60_000 },
    { label: "5 minutes", ms: 300_000 },
    { label: "30 minutes", ms: 1_800_000 },
];

const autoLockLabel = (ms: number): string => {
    const option = autoLockOptions.find((o) => o.ms === ms);
    return option?.label ?? "Immediately";
};

// -- PIN Setup Dialog --

interface SetupDialogProps {
    open: boolean;
    onClose: () => void;
    onComplete: () => void;
}

const PinSetupDialog: React.FC<SetupDialogProps> = ({
    open,
    onClose,
    onComplete,
}) => {
    const [step, setStep] = useState<"enter" | "confirm">("enter");
    const [pin, setPin] = useState(["", "", "", ""]);
    const [confirmPin, setConfirmPin] = useState(["", "", "", ""]);
    const [error, setError] = useState("");

    const inputRefs = useRef<(HTMLInputElement | null)[]>([]);
    const confirmInputRefs = useRef<(HTMLInputElement | null)[]>([]);

    const resetState = useCallback(() => {
        setStep("enter");
        setPin(["", "", "", ""]);
        setConfirmPin(["", "", "", ""]);
        setError("");
    }, []);

    const handleClose = useCallback(() => {
        resetState();
        onClose();
    }, [resetState, onClose]);

    const handlePinDigitChange = (
        index: number,
        value: string,
        isConfirm: boolean,
    ) => {
        const digit = value.replace(/\D/g, "").slice(-1);
        if (isConfirm) {
            const next = [...confirmPin];
            next[index] = digit;
            setConfirmPin(next);
            if (digit && index < 3) {
                confirmInputRefs.current[index + 1]?.focus();
            }
        } else {
            const next = [...pin];
            next[index] = digit;
            setPin(next);
            if (digit && index < 3) {
                inputRefs.current[index + 1]?.focus();
            }
        }
        setError("");
    };

    const handlePinKeyDown = (
        index: number,
        e: React.KeyboardEvent,
        isConfirm: boolean,
    ) => {
        if (e.key === "Backspace") {
            const current = isConfirm ? confirmPin : pin;
            if (!current[index] && index > 0) {
                const refs = isConfirm ? confirmInputRefs : inputRefs;
                refs.current[index - 1]?.focus();
            }
        }
    };

    const handleNext = useCallback(() => {
        if (pin.some((d) => !d)) return;
        setStep("confirm");
        setTimeout(() => confirmInputRefs.current[0]?.focus(), 50);
    }, [pin]);

    const handleBack = useCallback(() => {
        setStep("enter");
        setConfirmPin(["", "", "", ""]);
        setError("");
        setTimeout(() => inputRefs.current[0]?.focus(), 50);
    }, []);

    const handleConfirm = useCallback(async () => {
        const pinStr = pin.join("");
        const confirmStr = confirmPin.join("");
        if (pinStr !== confirmStr) {
            setError(t("pin_mismatch"));
            setConfirmPin(["", "", "", ""]);
            setTimeout(() => confirmInputRefs.current[0]?.focus(), 50);
            return;
        }
        await setupPin(pinStr);
        onComplete();
        resetState();
    }, [pin, confirmPin, onComplete, resetState]);

    const renderPinInputs = (
        values: string[],
        refs: React.RefObject<(HTMLInputElement | null)[]>,
        isConfirm: boolean,
    ) => (
        <Stack
            direction="row"
            sx={{ gap: 1.5, width: "100%", justifyContent: "space-between" }}
        >
            {values.map((digit, i) => (
                <TextField
                    key={i}
                    hiddenLabel
                    value={digit}
                    onChange={(e) =>
                        handlePinDigitChange(i, e.target.value, isConfirm)
                    }
                    onKeyDown={(e) => handlePinKeyDown(i, e, isConfirm)}
                    inputRef={(el: HTMLInputElement | null) => {
                        refs.current[i] = el;
                    }}
                    type="password"
                    slotProps={{
                        htmlInput: {
                            maxLength: 1,
                            inputMode: "numeric",
                            autoComplete: "off",
                            style: {
                                textAlign: "center",
                                fontSize: "1.25rem",
                                padding: "12px 0",
                            },
                            "aria-label": `PIN digit ${String(i + 1)}`,
                        },
                    }}
                    sx={{ flex: 1, minWidth: 0 }}
                />
            ))}
        </Stack>
    );

    return (
        <TitledMiniDialog
            open={open}
            onClose={handleClose}
            title="Set PIN"
            sx={{
                "& .MuiDialogTitle-root": { pb: 0 },
                "& .MuiDialogTitle-root + .MuiDialogContent-root": { pt: 0 },
            }}
        >
            <Stack sx={{ gap: 1.5, py: 0 }}>
                {step === "enter" ? (
                    <>
                        <Typography sx={{ color: "text.muted", textAlign: "left" }}>
                            {t("enter_pin")}
                        </Typography>
                        {renderPinInputs(pin, inputRefs, false)}
                        <FocusVisibleButton
                            fullWidth
                            color="accent"
                            disabled={pin.some((d) => !d)}
                            onClick={handleNext}
                        >
                            {t("next")}
                        </FocusVisibleButton>
                    </>
                ) : (
                    <>
                        <Typography sx={{ color: "text.muted", textAlign: "left" }}>
                            {t("confirm_pin")}
                        </Typography>
                        {renderPinInputs(confirmPin, confirmInputRefs, true)}
                        {error && (
                            <Typography
                                variant="small"
                                sx={{ color: "critical.main", textAlign: "left" }}
                            >
                                {error}
                            </Typography>
                        )}
                        <Stack direction="row" sx={{ gap: 1.5, width: "100%" }}>
                            <FocusVisibleButton
                                fullWidth
                                color="secondary"
                                onClick={handleBack}
                            >
                                {t("go_back")}
                            </FocusVisibleButton>
                            <FocusVisibleButton
                                fullWidth
                                color="accent"
                                disabled={confirmPin.some((d) => !d)}
                                onClick={() => void handleConfirm()}
                            >
                                {t("confirm")}
                            </FocusVisibleButton>
                        </Stack>
                    </>
                )}
            </Stack>
        </TitledMiniDialog>
    );
};

// -- Password Setup Dialog --

const PasswordSetupDialog: React.FC<SetupDialogProps> = ({
    open,
    onClose,
    onComplete,
}) => {
    const [step, setStep] = useState<"enter" | "confirm">("enter");
    const [password, setPassword] = useState("");
    const [confirmPassword, setConfirmPassword] = useState("");
    const [showPassword, setShowPassword] = useState(false);
    const [showConfirmPassword, setShowConfirmPassword] = useState(false);
    const [error, setError] = useState("");

    const resetState = useCallback(() => {
        setStep("enter");
        setPassword("");
        setConfirmPassword("");
        setShowPassword(false);
        setShowConfirmPassword(false);
        setError("");
    }, []);

    const handleClose = useCallback(() => {
        resetState();
        onClose();
    }, [resetState, onClose]);

    const handleNext = useCallback(() => {
        if (!password) return;
        setStep("confirm");
    }, [password]);

    const handleBack = useCallback(() => {
        setStep("enter");
        setConfirmPassword("");
        setError("");
    }, []);

    const handleConfirm = useCallback(async () => {
        if (password !== confirmPassword) {
            setError(t("app_lock_password_mismatch"));
            setConfirmPassword("");
            return;
        }
        await setupPassword(password);
        onComplete();
        resetState();
    }, [password, confirmPassword, onComplete, resetState]);

    return (
        <TitledMiniDialog
            open={open}
            onClose={handleClose}
            title={t("app_lock_set_password")}
        >
            <Stack sx={{ gap: 2, py: 1 }}>
                {step === "enter" ? (
                    <>
                        <Typography sx={{ color: "text.muted" }}>
                            {t("app_lock_enter_password")}
                        </Typography>
                        <TextField
                            fullWidth
                            type={showPassword ? "text" : "password"}
                            value={password}
                            onChange={(e) => {
                                setPassword(e.target.value);
                                setError("");
                            }}
                            autoFocus
                            slotProps={{
                                input: {
                                    endAdornment: (
                                        <ShowHidePasswordInputAdornment
                                            showPassword={showPassword}
                                            onToggle={() =>
                                                setShowPassword((s) => !s)
                                            }
                                        />
                                    ),
                                },
                            }}
                        />
                        <FocusVisibleButton
                            fullWidth
                            color="accent"
                            disabled={!password}
                            onClick={handleNext}
                        >
                            {t("next")}
                        </FocusVisibleButton>
                    </>
                ) : (
                    <>
                        <Typography sx={{ color: "text.muted" }}>
                            {t("app_lock_confirm_password")}
                        </Typography>
                        <TextField
                            fullWidth
                            type={showConfirmPassword ? "text" : "password"}
                            value={confirmPassword}
                            onChange={(e) => {
                                setConfirmPassword(e.target.value);
                                setError("");
                            }}
                            autoFocus
                            slotProps={{
                                input: {
                                    endAdornment: (
                                        <ShowHidePasswordInputAdornment
                                            showPassword={showConfirmPassword}
                                            onToggle={() =>
                                                setShowConfirmPassword(
                                                    (s) => !s,
                                                )
                                            }
                                        />
                                    ),
                                },
                            }}
                        />
                        {error && (
                            <Typography
                                variant="small"
                                sx={{
                                    color: "critical.main",
                                    textAlign: "center",
                                }}
                            >
                                {error}
                            </Typography>
                        )}
                        <Stack direction="row" sx={{ gap: 1.5, width: "100%" }}>
                            <FocusVisibleButton
                                fullWidth
                                color="secondary"
                                onClick={handleBack}
                            >
                                {t("go_back")}
                            </FocusVisibleButton>
                            <FocusVisibleButton
                                fullWidth
                                color="accent"
                                disabled={!confirmPassword}
                                onClick={() => void handleConfirm()}
                            >
                                {t("confirm")}
                            </FocusVisibleButton>
                        </Stack>
                    </>
                )}
            </Stack>
        </TitledMiniDialog>
    );
};

// -- Auto-Lock Duration Dialog --

interface AutoLockDialogProps {
    open: boolean;
    onClose: () => void;
    currentValue: number;
}

const AutoLockDialog: React.FC<AutoLockDialogProps> = ({
    open,
    onClose,
    currentValue,
}) => {
    const handleSelect = (ms: number) => {
        setAutoLockTime(ms);
        onClose();
    };

    return (
        <TitledMiniDialog open={open} onClose={onClose} title={t("auto_lock")}>
            <Stack sx={{ gap: 0.5, py: 1 }}>
                {autoLockOptions.map(({ label, ms }) => (
                    <RowButton
                        key={ms}
                        label={label}
                        endIcon={
                            currentValue === ms ? (
                                <CheckIcon sx={{ color: "accent.main" }} />
                            ) : undefined
                        }
                        onClick={() => handleSelect(ms)}
                    />
                ))}
            </Stack>
            <DialogActions>
                <FocusVisibleButton
                    fullWidth
                    color="secondary"
                    onClick={onClose}
                >
                    {t("cancel")}
                </FocusVisibleButton>
            </DialogActions>
        </TitledMiniDialog>
    );
};

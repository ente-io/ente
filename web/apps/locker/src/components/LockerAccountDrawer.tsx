import {
    ComputerPhoneSyncIcon,
    Key01Icon,
    Key02Icon,
    Mail01Icon,
    PasswordValidationIcon,
    SecurityCheckIcon,
} from "@hugeicons/core-free-icons";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import NorthEastIcon from "@mui/icons-material/NorthEast";
import { Box, Stack, Typography, useTheme } from "@mui/material";
import { RecoveryKey } from "ente-accounts-rs/components/RecoveryKey";
import { openAccountsManagePasskeysPage } from "ente-accounts-rs/services/passkey";
import { useBaseContext } from "ente-base/context";
import { t } from "i18next";
import { useRouter } from "next/router";
import React, { useEffect, useState } from "react";
import { LockerSessionsDrawer } from "./LockerSessionsDrawer";
import { LockerSidebarCardButton } from "./LockerSidebarCardButton";
import {
    LockerTitledNestedSidebarDrawer,
    type LockerNestedSidebarDrawerVisibilityProps,
} from "./LockerSidebarShell";

export const LockerAccountDrawer: React.FC<
    LockerNestedSidebarDrawerVisibilityProps
> = ({ open, onClose, onRootClose }) => {
    const { showMiniDialog, onGenericError } = useBaseContext();
    const router = useRouter();
    const theme = useTheme();

    const [isRecoveryKeyOpen, setIsRecoveryKeyOpen] = useState(false);
    const [isSessionsOpen, setIsSessionsOpen] = useState(false);

    useEffect(() => {
        if (!open) {
            setIsRecoveryKeyOpen(false);
            setIsSessionsOpen(false);
        }
    }, [open]);

    const handleRootClose = () => {
        setIsRecoveryKeyOpen(false);
        setIsSessionsOpen(false);
        onClose();
        onRootClose();
    };

    const handleNavigate = (path: string) => {
        handleRootClose();
        void router.push(path);
    };

    const handleOpenPasskeys = async () => {
        handleRootClose();
        try {
            await openAccountsManagePasskeysPage();
        } catch (e) {
            onGenericError(e);
        }
    };

    return (
        <>
            <LockerTitledNestedSidebarDrawer
                {...{ open, onClose }}
                onRootClose={handleRootClose}
                title={t("account")}
                hideRootCloseButton
            >
                <Stack
                    sx={{
                        px: 2,
                        pb: 2,
                        gap: 2,
                        backgroundColor: "background.default",
                        ...theme.applyStyles("dark", {
                            backgroundColor: "background.paper",
                        }),
                    }}
                >
                    <LockerSidebarCardButton
                        icon={Key02Icon}
                        label={t("recovery_key")}
                        onClick={() => setIsRecoveryKeyOpen(true)}
                    />

                    <Stack sx={{ gap: 1 }}>
                        <Typography
                            variant="mini"
                            sx={{
                                px: 1,
                                color: "text.faint",
                                textTransform: "uppercase",
                                letterSpacing: "0.08em",
                                fontWeight: "bold",
                            }}
                        >
                            {t("security")}
                        </Typography>
                        <LockerSidebarCardButton
                            icon={SecurityCheckIcon}
                            label={t("two_factor")}
                            onClick={() => handleNavigate("/two-factor/setup")}
                        />
                        <LockerSidebarCardButton
                            icon={Key01Icon}
                            label={t("passkeys")}
                            endIcon={<NorthEastIcon />}
                            onClick={handleOpenPasskeys}
                        />
                        <LockerSidebarCardButton
                            icon={ComputerPhoneSyncIcon}
                            label={t("active_sessions")}
                            endIcon={<ChevronRightIcon />}
                            onClick={() => setIsSessionsOpen(true)}
                        />
                    </Stack>

                    <Box sx={{ borderTop: 1, borderColor: "divider", mx: 1 }} />

                    <Stack sx={{ gap: 1 }}>
                        <LockerSidebarCardButton
                            icon={PasswordValidationIcon}
                            label={t("change_password")}
                            onClick={() => handleNavigate("/change-password")}
                        />
                        <LockerSidebarCardButton
                            icon={Mail01Icon}
                            label={t("change_email")}
                            onClick={() => handleNavigate("/change-email")}
                        />
                    </Stack>
                </Stack>
            </LockerTitledNestedSidebarDrawer>

            <LockerSessionsDrawer
                open={isSessionsOpen}
                onClose={() => setIsSessionsOpen(false)}
                onRootClose={handleRootClose}
            />

            <RecoveryKey
                open={isRecoveryKeyOpen}
                onClose={() => setIsRecoveryKeyOpen(false)}
                showMiniDialog={showMiniDialog}
            />
        </>
    );
};

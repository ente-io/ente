import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import OpenInNewOutlinedIcon from "@mui/icons-material/OpenInNewOutlined";
import VerifiedUserOutlinedIcon from "@mui/icons-material/VerifiedUserOutlined";
import { Stack } from "@mui/material";
import { RecoveryKey } from "ente-accounts-rs/components/RecoveryKey";
import { openAccountsManagePasskeysPage } from "ente-accounts-rs/services/passkey";
import {
    RowButton,
    RowButtonDivider,
    RowButtonGroup,
    RowButtonGroupTitle,
} from "ente-base/components/RowButton";
import {
    TitledNestedSidebarDrawer,
    type NestedSidebarDrawerVisibilityProps,
} from "ente-base/components/mui/SidebarDrawer";
import { useBaseContext } from "ente-base/context";
import { t } from "i18next";
import { useRouter } from "next/router";
import React, { useEffect, useState } from "react";
import { LockerSessionsDrawer } from "./LockerSessionsDrawer";

export const LockerAccountDrawer: React.FC<
    NestedSidebarDrawerVisibilityProps
> = ({ open, onClose, onRootClose }) => {
    const { showMiniDialog, onGenericError } = useBaseContext();
    const router = useRouter();

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
            <TitledNestedSidebarDrawer
                {...{ open, onClose }}
                onRootClose={handleRootClose}
                title={t("account")}
            >
                <Stack sx={{ px: 2, pb: 2, gap: 2 }}>
                    <RowButtonGroup>
                        <RowButton
                            label={t("recovery_key")}
                            endIcon={
                                <VerifiedUserOutlinedIcon
                                    sx={{ color: "success.main" }}
                                />
                            }
                            onClick={() => setIsRecoveryKeyOpen(true)}
                        />
                    </RowButtonGroup>

                    <Stack sx={{ gap: 0.5 }}>
                        <RowButtonGroupTitle>
                            {t("security")}
                        </RowButtonGroupTitle>
                        <RowButtonGroup>
                            <RowButton
                                label={t("two_factor")}
                                onClick={() =>
                                    handleNavigate("/two-factor/setup")
                                }
                            />
                            <RowButtonDivider />
                            <RowButton
                                label={t("passkeys")}
                                endIcon={<OpenInNewOutlinedIcon />}
                                onClick={handleOpenPasskeys}
                            />
                            <RowButtonDivider />
                            <RowButton
                                label={t("active_sessions")}
                                endIcon={<ChevronRightIcon />}
                                onClick={() => setIsSessionsOpen(true)}
                            />
                        </RowButtonGroup>
                    </Stack>

                    <RowButtonGroup>
                        <RowButton
                            label={t("change_password")}
                            onClick={() => handleNavigate("/change-password")}
                        />
                        <RowButtonDivider />
                        <RowButton
                            label={t("change_email")}
                            onClick={() => handleNavigate("/change-email")}
                        />
                    </RowButtonGroup>
                </Stack>
            </TitledNestedSidebarDrawer>

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

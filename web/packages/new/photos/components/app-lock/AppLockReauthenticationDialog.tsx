/**
 * @file Reauthentication dialog for app-lock protected actions.
 */

import { Box, Modal } from "@mui/material";
import { t } from "i18next";
import type { CSSProperties } from "react";
import { AppLockPrompt } from "./AppLockPrompt";
import { useAppLockSnapshot } from "../utils/use-snapshot";

export const AppLockReauthenticationDialog = () => {
    const appLock = useAppLockSnapshot();
    const isVisible =
        appLock.isLocked && appLock.lockScreenMode === "reauthenticate";

    if (!isVisible) return null;

    return (
        <Modal
            open
            disableEscapeKeyDown
            aria-label={t("authenticate")}
            slotProps={{
                backdrop: {
                    sx: {
                        backgroundColor: "var(--mui-palette-backdrop-muted)",
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
                style={{ WebkitAppRegion: "no-drag" } as CSSProperties}
            >
                <AppLockPrompt lockScreenMode="reauthenticate" />
            </Box>
        </Modal>
    );
};

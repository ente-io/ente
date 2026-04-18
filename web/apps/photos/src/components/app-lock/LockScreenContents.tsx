import { Box } from "@mui/material";
import { EnteLogo } from "ente-base/components/EnteLogo";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { AppLockPrompt } from "ente-new/photos/components/app-lock/AppLockPrompt";
import { t } from "i18next";
import type { CSSProperties } from "react";

export const LockScreenContents = () => {
    return (
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
            style={{ WebkitAppRegion: "no-drag" } as CSSProperties}
        >
            <AppLockPrompt
                lockScreenMode="lock"
                renderHeader={({ showLogoutConfirm, showLogout }) => (
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
                                onClick={showLogout}
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
                )}
            />
        </Box>
    );
};

import MenuIcon from "@mui/icons-material/Menu";
import WarningAmberRoundedIcon from "@mui/icons-material/WarningAmberRounded";
import { Box, IconButton, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import React from "react";

interface LockerNavbarProps {
    /** Called when the user taps the hamburger menu icon. */
    onOpenSidebar: () => void;
    /** True when the mobile drawer trigger should be shown. */
    showMenuButton: boolean;
}

/**
 * Top navigation bar for the Locker web app.
 *
 * Blue gradient header matching the Figma design — hamburger on left,
 * "Locker" title centered. The blue gradient continues into the search
 * bar area rendered by ItemList below.
 */
export const LockerNavbar: React.FC<LockerNavbarProps> = ({
    onOpenSidebar,
    showMenuButton,
}) => (
    <Box
        sx={{
            position: "sticky",
            top: 0,
            left: 0,
            zIndex: 1,
            background: "linear-gradient(135deg, #1071FF 0%, #0056CC 100%)",
            color: "#fff",
            px: { xs: 2, sm: 3 },
            pt: 1,
            pb: 0.25,
        }}
    >
        <Stack
            direction="row"
            sx={{ alignItems: "center", justifyContent: "space-between" }}
        >
            {showMenuButton ? (
                <IconButton onClick={onOpenSidebar} sx={{ color: "#fff" }}>
                    <MenuIcon />
                </IconButton>
            ) : (
                <Box sx={{ width: 40 }} />
            )}

            <Box
                component="img"
                src="/images/ente-locker-white.svg"
                alt="Ente Locker"
                sx={{ height: 26, width: "auto" }}
            ></Box>

            <Box sx={{ width: 40 }} />
        </Stack>
        <Stack
            direction="row"
            role="status"
            aria-live="polite"
            sx={{
                mt: 0.75,
                px: 1.25,
                py: 0.75,
                gap: 0.75,
                alignItems: "center",
                borderRadius: "10px",
                backgroundColor: "rgba(255, 188, 77, 0.18)",
                border: "1px solid rgba(255, 220, 153, 0.45)",
            }}
        >
            <WarningAmberRoundedIcon
                sx={{ fontSize: 16, color: "#FFE3A8", flexShrink: 0 }}
            />
            <Typography variant="mini" sx={{ color: "#FFF5E0", lineHeight: 1.4 }}>
                {t("lockerAlphaCryptoWarning")}
            </Typography>
        </Stack>
    </Box>
);

import MenuIcon from "@mui/icons-material/Menu";
import WarningAmberRoundedIcon from "@mui/icons-material/WarningAmberRounded";
import { Box, IconButton, Stack, Typography } from "@mui/material";
import React from "react";

const contentMaxWidth = 620;

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
                width: "100%",
                maxWidth: contentMaxWidth,
                mx: "auto",
                mt: 1,
                px: 1.5,
                py: 1,
                gap: 1,
                alignItems: "center",
                borderRadius: "12px",
                backgroundColor: "#FFE08A",
                border: "1px solid #FFD057",
                boxShadow: "0 8px 20px rgba(0, 0, 0, 0.2)",
            }}
        >
            <WarningAmberRoundedIcon
                sx={{ fontSize: 20, color: "#5C3A00", flexShrink: 0 }}
            />
            <Typography
                variant="mini"
                sx={{
                    px: 0.75,
                    py: 0.25,
                    borderRadius: "999px",
                    border: "1px solid rgba(92, 58, 0, 0.3)",
                    backgroundColor: "rgba(255, 255, 255, 0.45)",
                    color: "#5C3A00",
                    fontWeight: 800,
                    letterSpacing: "0.03em",
                    flexShrink: 0,
                }}
            >
                WARNING
            </Typography>
            <Typography
                variant="small"
                sx={{ color: "#3B2500", lineHeight: 1.4, fontWeight: 700 }}
            >
                The web version of Locker is unstable
            </Typography>
        </Stack>
    </Box>
);

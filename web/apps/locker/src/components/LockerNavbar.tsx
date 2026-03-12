import MenuIcon from "@mui/icons-material/Menu";
import { Box, IconButton, Stack } from "@mui/material";
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
    </Box>
);

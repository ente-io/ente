import { Menu01Icon } from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import SearchIcon from "@mui/icons-material/Search";
import WarningAmberRoundedIcon from "@mui/icons-material/WarningAmberRounded";
import {
    Box,
    IconButton,
    InputAdornment,
    Stack,
    TextField,
    Typography,
} from "@mui/material";
import { t } from "i18next";
import React from "react";

const contentMaxWidth = 560;

interface LockerNavbarProps {
    /** Called when the user taps the hamburger menu icon. */
    onOpenSidebar: () => void;
    /** True when the mobile drawer trigger should be shown. */
    showMenuButton: boolean;
    /** Current value of the Locker search query. */
    searchTerm: string;
    /** Update callback for the Locker search query. */
    onSearchTermChange: (value: string) => void;
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
    searchTerm,
    onSearchTermChange,
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
                    <HugeiconsIcon
                        icon={Menu01Icon}
                        size={24}
                        strokeWidth={2.25}
                    />
                </IconButton>
            ) : (
                <Box sx={{ width: 40 }} />
            )}

            <Box
                component="img"
                src="/images/locker.svg"
                alt="Locker"
                sx={{
                    height: 20,
                    width: "auto",
                    filter: "brightness(0) invert(1)",
                }}
            ></Box>

            <Box sx={{ width: 40 }} />
        </Stack>

        <Box sx={{ maxWidth: contentMaxWidth, mx: "auto", mt: 0.5, pb: 1.5 }}>
            <TextField
                size="small"
                placeholder={t("searchHint")}
                value={searchTerm}
                onChange={(event) => onSearchTermChange(event.target.value)}
                variant="outlined"
                fullWidth
                slotProps={{
                    input: {
                        startAdornment: (
                            <InputAdornment position="start">
                                <SearchIcon
                                    sx={{
                                        fontSize: 20,
                                        color: "text.faint",
                                    }}
                                />
                            </InputAdornment>
                        ),
                    },
                }}
                sx={{
                    "& .MuiOutlinedInput-root": {
                        minHeight: 48,
                        borderRadius: "24px",
                        backgroundColor: "background.paper",
                        "& .MuiOutlinedInput-input": { py: 1.5 },
                        "& fieldset": {
                            borderColor: "transparent",
                        },
                        "&:hover fieldset": {
                            borderColor: "transparent",
                        },
                        "&.Mui-focused fieldset": {
                            borderColor: "rgba(255, 255, 255, 0.28)",
                            borderWidth: "1px",
                        },
                        "&.Mui-focused": {
                            boxShadow: "0 0 0 2px rgba(255, 255, 255, 0.1)",
                        },
                    },
                }}
            />
        </Box>
    </Box>
);

export const LockerUnstableToast: React.FC = () => (
    <Stack
        direction="row"
        role="status"
        aria-live="polite"
        sx={{
            position: "fixed",
            left: "50%",
            bottom: { xs: 16, sm: 24 },
            transform: "translateX(-50%)",
            width: "calc(100% - 32px)",
            maxWidth: contentMaxWidth,
            px: 1.5,
            py: 1,
            gap: 1,
            alignItems: "center",
            borderRadius: "16px",
            backgroundColor: "#FFE08A",
            border: "1px solid #FFD057",
            boxShadow: "0 12px 30px rgba(0, 0, 0, 0.24)",
            zIndex: 1400,
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
            You are using an unstable version of Locker.
        </Typography>
    </Stack>
);

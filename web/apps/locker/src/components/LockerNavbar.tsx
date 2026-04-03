import {
    InformationCircleIcon,
    Menu01Icon,
} from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import SearchIcon from "@mui/icons-material/Search";
import {
    Box,
    IconButton,
    InputAdornment,
    Stack,
    TextField,
    Typography,
} from "@mui/material";
import { t } from "i18next";
import React, { useDeferredValue, useEffect, useState } from "react";

const contentMaxWidth = 560;

interface LockerNavbarProps {
    /** Called when the user taps the hamburger menu icon. */
    onOpenSidebar: () => void;
    /** True when the mobile drawer trigger should be shown. */
    showMenuButton: boolean;
    /** Sticky top offset to account for any pinned content above the navbar. */
    stickyTop?: number;
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
    stickyTop = 0,
    searchTerm,
    onSearchTermChange,
}) => {
    const [localSearchTerm, setLocalSearchTerm] = useState(searchTerm);
    const deferredSearchTerm = useDeferredValue(localSearchTerm);

    useEffect(() => {
        onSearchTermChange(deferredSearchTerm);
    }, [deferredSearchTerm, onSearchTermChange]);

    // Sync local state when parent resets searchTerm (e.g. navigation).
    useEffect(() => {
        setLocalSearchTerm(searchTerm);
    }, [searchTerm]);

    return (
        <Box
            sx={{
                position: "sticky",
                top: stickyTop,
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

            <Box
                sx={{ maxWidth: contentMaxWidth, mx: "auto", mt: 0.5, pb: 1.5 }}
            >
                <TextField
                    size="small"
                    placeholder={t("searchHint")}
                    value={localSearchTerm}
                    onChange={(event) => setLocalSearchTerm(event.target.value)}
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
                            "& fieldset": { borderColor: "transparent" },
                            "&:hover fieldset": { borderColor: "transparent" },
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
};

export const LockerUnstableToast: React.FC = () => (
    <Box sx={{ position: "sticky", top: 0, zIndex: 2 }}>
        <Stack
            direction="row"
            role="status"
            aria-live="polite"
            sx={{
                width: "100%",
                px: { xs: 2, sm: 3 },
                py: 1.25,
                gap: 1,
                alignItems: "center",
                backgroundColor: "#EEF5FF",
                border: "1px solid #C9DEFF",
                borderRadius: 0,
                boxShadow: "0 6px 18px rgba(16, 113, 255, 0.08)",
            }}
        >
            <Stack
                direction="row"
                sx={{
                    width: "100%",
                    maxWidth: contentMaxWidth,
                    mx: "auto",
                    gap: 1,
                    alignItems: "center",
                    justifyContent: "center",
                }}
            >
                <HugeiconsIcon
                    icon={InformationCircleIcon}
                    size={20}
                    strokeWidth={2.1}
                    color="#0056CC"
                />
                <Typography
                    variant="mini"
                    sx={{
                        px: 0.75,
                        py: 0.25,
                        borderRadius: "999px",
                        border: "1px solid rgba(16, 113, 255, 0.18)",
                        backgroundColor: "rgba(16, 113, 255, 0.08)",
                        color: "#0056CC",
                        fontWeight: 700,
                        letterSpacing: "0.03em",
                        flexShrink: 0,
                    }}
                >
                    Note
                </Typography>
                <Typography
                    variant="small"
                    sx={{ color: "#163B72", lineHeight: 1.4, fontWeight: 700 }}
                >
                    This is a beta version of Locker web.
                </Typography>
            </Stack>
        </Stack>
    </Box>
);

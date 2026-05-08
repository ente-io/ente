import { Menu01Icon } from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import SearchIcon from "@mui/icons-material/Search";
import {
    Box,
    IconButton,
    InputAdornment,
    Stack,
    TextField,
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
 * Blue gradient header matching the Figma design, with the Locker branding
 * centered. The blue gradient continues into the search bar area rendered by
 * ItemList below.
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
                    src="/images/locker-beta.svg"
                    alt="Locker beta"
                    sx={{ height: 29, width: "auto" }}
                />

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

import { Stack, ToggleButton, ToggleButtonGroup } from "@mui/material";
import React from "react";

export const legacyRecoveryDayOptions = [7, 14, 30] as const;

interface LegacyRecoveryDayPickerProps {
    selectedDays: number;
    onChange: (days: number) => void;
}

export const LegacyRecoveryDayPicker: React.FC<
    LegacyRecoveryDayPickerProps
> = ({ selectedDays, onChange }) => (
    <ToggleButtonGroup
        exclusive
        value={selectedDays}
        onChange={(_, value: number | null) => value && onChange(value)}
        fullWidth
        sx={{
            gap: 1,
            "& .MuiToggleButton-root": {
                flex: 1,
                px: 1.5,
                py: 1.25,
                border: 0,
                borderRadius: "14px !important",
                textTransform: "none",
                fontWeight: 600,
                color: "text.base",
                backgroundColor: "fill.faint",
            },
            "& .MuiToggleButton-root.Mui-selected": {
                color: "#FFFFFF",
                backgroundColor: "accent.main",
            },
            "& .MuiToggleButton-root:hover": { backgroundColor: "fill.muted" },
            "& .MuiToggleButton-root.Mui-selected:hover": {
                backgroundColor: "accent.main",
            },
        }}
    >
        {legacyRecoveryDayOptions.map((days) => (
            <ToggleButton key={days} value={days}>
                <Stack sx={{ alignItems: "center" }}>{days} days</Stack>
            </ToggleButton>
        ))}
    </ToggleButtonGroup>
);

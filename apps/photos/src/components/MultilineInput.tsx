import { Stack, TextField, Typography, TypographyProps } from "@mui/material";

interface Iprops {
    label: string;
    labelProps?: TypographyProps;
    message?: string;
    messageProps?: TypographyProps;
    placeholder?: string;
    value: string;
    rowCount: number;
    onChange: (value: string) => void;
}

export default function MultilineInput({
    label,
    labelProps,
    message,
    messageProps,
    placeholder,
    value,
    rowCount,
    onChange,
}: Iprops) {
    return (
        <Stack spacing={"4px"}>
            <Typography {...labelProps}>{label}</Typography>
            <TextField
                variant="standard"
                multiline
                rows={rowCount}
                value={value}
                onChange={(e) => onChange(e.target.value)}
                placeholder={placeholder}
                sx={(theme) => ({
                    border: "1px solid",
                    borderColor: theme.colors.stroke.faint,
                    borderRadius: "8px",
                    padding: "12px",
                    ".MuiInputBase-formControl": {
                        "::before, ::after": {
                            borderBottom: "none !important",
                        },
                    },
                })}
            />
            <Typography
                px={"8px"}
                variant="small"
                color="text.secondary"
                {...messageProps}
            >
                {message}
            </Typography>
        </Stack>
    );
}

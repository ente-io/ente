import ExpandMore from "@mui/icons-material/ExpandMore";
import {
    Box,
    MenuItem,
    Select,
    SelectChangeEvent,
    Stack,
    Typography,
    type TypographyProps,
} from "@mui/material";

export interface DropdownOption<T> {
    label: string;
    value: T;
}

interface Iprops<T> {
    label: string;
    labelProps?: TypographyProps;
    options: DropdownOption<T>[];
    message?: string;
    messageProps?: TypographyProps;
    selected: T;
    setSelected: (selectedValue: T) => void;
    placeholder?: string;
}

export default function DropdownInput<T extends string>({
    label,
    labelProps,
    options,
    message,
    selected,
    placeholder,
    setSelected,
    messageProps,
}: Iprops<T>) {
    return (
        <Stack spacing={"4px"}>
            <Typography {...labelProps}>{label}</Typography>
            <Select
                IconComponent={ExpandMore}
                displayEmpty
                variant="standard"
                MenuProps={{
                    PaperProps: {
                        sx: {
                            // Select component automatically sets the min width of the element to the width
                            // of the select input's width, so setting the maxWidth to 0, forces to element
                            // width to equal to minWidth
                            maxWidth: 0,
                        },
                    },
                    MenuListProps: {
                        sx: (theme) => ({
                            backgroundColor: theme.colors.background.elevated2,
                            ".MuiMenuItem-root ": {
                                color: theme.colors.text.faint,
                                whiteSpace: "normal",
                            },
                            "&&& > .Mui-selected": {
                                background: theme.colors.background.elevated2,
                                color: theme.colors.text.base,
                            },
                        }),
                    },
                }}
                sx={(theme) => ({
                    "::before , ::after": {
                        borderBottom: "none !important",
                    },
                    ".MuiInput-root": {
                        background: theme.colors.fill.faint,
                        borderRadius: "8px",
                    },
                    ".MuiSelect-select": {
                        background: theme.colors.fill.faint,
                        borderRadius: "8px",
                    },
                    "&&& .MuiSelect-select": {
                        p: "12px 36px 12px 16px",
                    },
                    ".MuiSelect-icon": {
                        mr: "12px",
                        color: theme.colors.stroke.muted,
                    },
                })}
                renderValue={(selected) => {
                    return !selected?.length ? (
                        <Box color={"text.muted"}>{placeholder ?? ""}</Box>
                    ) : (
                        options.find((o) => o.value === selected).label
                    );
                }}
                value={selected}
                onChange={(event: SelectChangeEvent) => {
                    setSelected(event.target.value as T);
                }}
            >
                {options.map((option, index) => (
                    <MenuItem
                        key={option.value}
                        divider={index !== options.length - 1}
                        value={option.value}
                        sx={{
                            px: "16px",
                            py: "14px",
                            color: (theme) => theme.palette.primary.main,
                        }}
                    >
                        {option.label}
                    </MenuItem>
                ))}
            </Select>
            {message && (
                <Typography
                    variant="small"
                    px={"8px"}
                    color={"text.muted"}
                    {...messageProps}
                >
                    {message}
                </Typography>
            )}
        </Stack>
    );
}
